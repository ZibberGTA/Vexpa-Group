import * as admin from "firebase-admin";
import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type DocumentReference,
  type DocumentSnapshot,
  type Transaction,
} from "firebase-admin/firestore";
import {type CallableRequest, HttpsError, onCall} from "firebase-functions/v2/https";

admin.initializeApp();

const db = admin.firestore();
const autoApprovalThreshold = 75;

const claimStatuses = {
  draft: "draft",
  pendingReview: "pending_review",
  needsMoreInfo: "needs_more_info",
  autoApproved: "auto_approved",
  approved: "approved",
  rejected: "rejected",
  completed: "completed",
  error: "error",
} as const;

type ClaimStatus = (typeof claimStatuses)[keyof typeof claimStatuses];

type AuditType =
  | "claim_created"
  | "evidence_submitted"
  | "confidence_evaluated"
  | "auto_approved"
  | "manual_review_required"
  | "admin_approved"
  | "admin_rejected"
  | "more_info_requested"
  | "draft_published"
  | "ownership_assigned"
  | "error";

type Evidence = {
  businessEmail?: string;
  website?: string;
  phone?: string;
  companyRegistration?: string;
  notes?: string;
  documentUrls?: string[];
};

type ClaimData = {
  claimId: string;
  venueId: string;
  claimantUid: string;
  claimantEmail?: string;
  status: ClaimStatus;
  submittedEvidence?: Evidence;
  draftVenueData?: Record<string, unknown>;
  confidenceScore?: number;
  confidenceReasons?: string[];
  autoApproved?: boolean;
};

const publishableDraftFields = new Set([
  "name",
  "description",
  "logoUrl",
  "bannerImageUrl",
  "openingHours",
  "tags",
  "featureTags",
  "venueFeatures",
  "phone",
  "website",
  "websiteUrl",
  "socials",
  "socialLinks",
  "category",
  "venueType",
  "drinks",
  "deals",
  "events",
  "galleryImageUrls",
  "galleryImages",
]);

const ownershipFields = [
  "ownerUid",
  "ownerId",
  "ownerIds",
  "managers",
  "managedBy",
  "teamMembers",
  "claimedBy",
  "subscriptionOwner",
  "verifiedOwner",
];

const allowedTransitions: Record<ClaimStatus, ClaimStatus[]> = {
  draft: [claimStatuses.pendingReview],
  pending_review: [
    claimStatuses.approved,
    claimStatuses.rejected,
    claimStatuses.needsMoreInfo,
    claimStatuses.autoApproved,
  ],
  needs_more_info: [claimStatuses.pendingReview, claimStatuses.rejected],
  auto_approved: [claimStatuses.completed, claimStatuses.error],
  approved: [claimStatuses.completed, claimStatuses.error],
  rejected: [claimStatuses.pendingReview],
  completed: [],
  error: [claimStatuses.pendingReview],
};

export const submitVenueClaim = onCall(async (request) => {
  const uid = requireAuth(request);
  const venueId = requireString(request.data?.venueId, "venueId");
  const evidence = sanitizeEvidence(request.data?.submittedEvidence);
  const draftVenueData = sanitizeDraft(request.data?.draftVenueData);

  const venueRef = db.collection("venues").doc(venueId);
  const venueSnapshot = await venueRef.get();
  if (!venueSnapshot.exists) {
    throw new HttpsError("not-found", "Venue not found.");
  }

  const duplicate = await db
    .collection("venue_claims")
    .where("venueId", "==", venueId)
    .where("claimantUid", "==", uid)
    .where("status", "in", [
      claimStatuses.draft,
      claimStatuses.pendingReview,
      claimStatuses.needsMoreInfo,
      claimStatuses.autoApproved,
      claimStatuses.approved,
    ])
    .limit(1)
    .get();
  if (!duplicate.empty) {
    throw new HttpsError("already-exists", "You already have an active claim for this venue.");
  }

  const claimRef = db.collection("venue_claims").doc();
  const venueData = venueSnapshot.data() ?? {};
  const score = calculateConfidence({venueData, evidence});
  const autoApproved = score.score >= autoApprovalThreshold;
  const baseClaim: ClaimData = {
    claimId: claimRef.id,
    venueId,
    claimantUid: uid,
    claimantEmail: request.auth?.token.email?.toString() ?? evidence.businessEmail ?? "",
    status: claimStatuses.pendingReview,
    submittedEvidence: evidence,
    draftVenueData,
    confidenceScore: score.score,
    confidenceReasons: score.reasons,
    autoApproved,
  };

  await db.runTransaction(async (transaction) => {
    transaction.set(claimRef, {
      ...baseClaim,
      venueName: readString(venueData, ["name", "venueName"], "Unnamed venue"),
      venueAddress: readVenueAddress(venueData),
      confidenceThreshold: autoApprovalThreshold,
      submittedAt: FieldValue.serverTimestamp(),
      reviewedAt: null,
      reviewedBy: null,
      reviewNotes: "",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    writeAudit(transaction, claimRef, "claim_created", uid, "claimant", "Venue claim submitted.", {
      venueId,
    });
    writeAudit(transaction, claimRef, "evidence_submitted", uid, "claimant", "Evidence submitted.", {
      evidenceKeys: Object.keys(evidence),
    });
    writeAudit(transaction, claimRef, "confidence_evaluated", "system", "system", "Confidence evaluated.", {
      score: score.score,
      reasons: score.reasons,
    });

    if (autoApproved) {
      transaction.update(claimRef, {
        status: claimStatuses.autoApproved,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: "system",
        reviewNotes: "Automatically approved by trusted confidence scoring.",
        updatedAt: FieldValue.serverTimestamp(),
      });
      writeAudit(transaction, claimRef, "auto_approved", "system", "system", "Claim auto-approved.", {
        score: score.score,
      });
      publishApprovedClaimDraftInTransaction(transaction, claimRef, {
        ...baseClaim,
        status: claimStatuses.autoApproved,
      });
    } else {
      writeAudit(transaction, claimRef, "manual_review_required", "system", "system", "Manual review required.", {
        score: score.score,
      });
      createAdminAlert(transaction, claimRef.id, venueId, uid);
    }
  });

  const finalStatus = autoApproved ? claimStatuses.completed : claimStatuses.pendingReview;
  return {
    success: true,
    claimId: claimRef.id,
    venueId,
    status: finalStatus,
    autoApproved,
    confidenceScore: score.score,
    confidenceReasons: score.reasons,
  };
});

export const evaluateVenueClaim = onCall(async (request) => {
  requireAuth(request);
  const claimId = requireString(request.data?.claimId, "claimId");
  const claimRef = db.collection("venue_claims").doc(claimId);
  const claimSnapshot = await claimRef.get();
  const claim = readClaim(claimSnapshot);
  requireClaimActor(request, claim);

  const venueSnapshot = await db.collection("venues").doc(claim.venueId).get();
  if (!venueSnapshot.exists) {
    throw new HttpsError("not-found", "Venue not found.");
  }
  const score = calculateConfidence({
    venueData: venueSnapshot.data() ?? {},
    evidence: claim.submittedEvidence ?? {},
  });

  await claimRef.set(
    {
      confidenceScore: score.score,
      confidenceReasons: score.reasons,
      autoApproved: score.score >= autoApprovalThreshold,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  await appendAudit(claimRef, "confidence_evaluated", "system", "system", "Confidence re-evaluated.", {
    score: score.score,
    reasons: score.reasons,
  });
  return {
    success: true,
    claimId,
    confidenceScore: score.score,
    confidenceReasons: score.reasons,
    autoApproved: score.score >= autoApprovalThreshold,
  };
});

export const approveVenueClaim = onCall(async (request) => {
  const uid = requireAdmin(request);
  const claimId = requireString(request.data?.claimId, "claimId");
  const notes = optionalString(request.data?.notes);
  await reviewAndPublishClaim({
    claimId,
    reviewerUid: uid,
    notes,
    auditType: "admin_approved",
    message: "Claim approved by admin.",
  });
  return {success: true, claimId, status: claimStatuses.completed};
});

export const rejectVenueClaim = onCall(async (request) => {
  const uid = requireAdmin(request);
  const claimId = requireString(request.data?.claimId, "claimId");
  const notes = requireString(request.data?.notes, "notes");
  const claimRef = db.collection("venue_claims").doc(claimId);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(claimRef);
    const claim = readClaim(snapshot);
    assertTransition(claim.status, claimStatuses.rejected);
    transaction.set(
      claimRef,
      {
        status: claimStatuses.rejected,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: uid,
        reviewNotes: notes,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    writeAudit(transaction, claimRef, "admin_rejected", uid, "admin", "Claim rejected by admin.", {
      notes,
    });
  });

  return {success: true, claimId, status: claimStatuses.rejected};
});

export const requestMoreClaimInfo = onCall(async (request) => {
  const uid = requireAdmin(request);
  const claimId = requireString(request.data?.claimId, "claimId");
  const notes = requireString(request.data?.notes, "notes");
  const claimRef = db.collection("venue_claims").doc(claimId);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(claimRef);
    const claim = readClaim(snapshot);
    assertTransition(claim.status, claimStatuses.needsMoreInfo);
    transaction.set(
      claimRef,
      {
        status: claimStatuses.needsMoreInfo,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: uid,
        reviewNotes: notes,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    writeAudit(transaction, claimRef, "more_info_requested", uid, "admin", "More information requested.", {
      notes,
    });
  });

  return {success: true, claimId, status: claimStatuses.needsMoreInfo};
});

export const publishApprovedClaimDraft = onCall(async (request) => {
  const uid = requireAdmin(request);
  const claimId = requireString(request.data?.claimId, "claimId");
  await reviewAndPublishClaim({
    claimId,
    reviewerUid: uid,
    notes: optionalString(request.data?.notes),
    auditType: "admin_approved",
    message: "Approved claim draft published by admin.",
    allowApprovedOnly: true,
  });
  return {success: true, claimId, status: claimStatuses.completed};
});

export const createVenueInstant = onCall(async (request) => {
  const uid = requireAuth(request);
  const name = requireString(request.data?.name, "name");
  const address = optionalString(request.data?.address);
  const city = optionalString(request.data?.city);
  const postcode = optionalString(request.data?.postcode);
  const category = optionalString(request.data?.category) || "Venue";
  const website = optionalString(request.data?.website);
  const phone = optionalString(request.data?.phone);
  const venueRef = db.collection("venues").doc();

  await db.runTransaction(async (transaction) => {
    transaction.set(venueRef, {
      name,
      address: {line1: address, city, postcode},
      city,
      postcode,
      category,
      venueType: category,
      website,
      websiteUrl: website,
      phone,
      ownerId: uid,
      ownerUid: uid,
      ownerIds: [uid],
      ownerEmail: request.auth?.token.email?.toString() ?? "",
      isClaimed: true,
      claimStatus: "claimed",
      isVerified: false,
      isDeleted: false,
      subscriptionPlanId: "starter",
      subscriptionPlan: "starter",
      createdVia: "trusted_owner_onboarding",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      db.collection("users").doc(uid),
      {
        role: "venueOwner",
        venueIds: FieldValue.arrayUnion(venueRef.id),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });

  return {success: true, venueId: venueRef.id};
});

async function reviewAndPublishClaim(options: {
  claimId: string;
  reviewerUid: string;
  notes: string;
  auditType: AuditType;
  message: string;
  allowApprovedOnly?: boolean;
}) {
  const claimRef = db.collection("venue_claims").doc(options.claimId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(claimRef);
    const claim = readClaim(snapshot);
    if (options.allowApprovedOnly && claim.status !== claimStatuses.approved) {
      throw new HttpsError("failed-precondition", "Only approved claims can be published.");
    }
    if (!options.allowApprovedOnly) {
      assertTransition(claim.status, claimStatuses.approved);
    }
    transaction.set(
      claimRef,
      {
        status: claimStatuses.approved,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: options.reviewerUid,
        reviewNotes: options.notes,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    writeAudit(transaction, claimRef, options.auditType, options.reviewerUid, "admin", options.message, {
      notes: options.notes,
    });
    publishApprovedClaimDraftInTransaction(transaction, claimRef, {
      ...claim,
      status: claimStatuses.approved,
    });
  });
}

function publishApprovedClaimDraftInTransaction(
  transaction: Transaction,
  claimRef: DocumentReference,
  claim: ClaimData,
) {
  const safeDraft = sanitizeDraft(claim.draftVenueData ?? {});
  const venueRef = db.collection("venues").doc(claim.venueId);
  const userRef = db.collection("users").doc(claim.claimantUid);
  transaction.set(
    venueRef,
    {
      ...safeDraft,
      ownerId: claim.claimantUid,
      ownerUid: claim.claimantUid,
      ownerIds: FieldValue.arrayUnion(claim.claimantUid),
      ownerEmail: claim.claimantEmail ?? "",
      claimedBy: claim.claimantUid,
      verifiedOwner: claim.claimantUid,
      isClaimed: true,
      claimStatus: "claimed",
      claimCompletedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  transaction.set(
    userRef,
    {
      role: "venueOwner",
      venueIds: FieldValue.arrayUnion(claim.venueId),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  transaction.set(
    claimRef,
    {
      status: claimStatuses.completed,
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  writeAudit(transaction, claimRef, "ownership_assigned", "system", "system", "Venue ownership assigned.", {
    venueId: claim.venueId,
    claimantUid: claim.claimantUid,
  });
  writeAudit(transaction, claimRef, "draft_published", "system", "system", "Approved draft published.", {
    publishedFields: Object.keys(safeDraft),
  });
}

function calculateConfidence(params: {
  venueData: DocumentData;
  evidence: Evidence;
}): {score: number; reasons: string[]} {
  const venueWebsite = readString(params.venueData, ["website", "websiteUrl"], "");
  const venueDomain = domainFromUrl(venueWebsite);
  const businessEmailDomain = domainFromEmail(params.evidence.businessEmail ?? "");
  const evidenceWebsiteDomain = domainFromUrl(params.evidence.website ?? "");
  const venuePhone = digits(readString(params.venueData, ["phone", "telephone"], ""));
  const evidencePhone = digits(params.evidence.phone ?? "");
  const reasons: string[] = [];
  let score = 0;

  function add(condition: boolean, points: number, reason: string) {
    if (!condition) return;
    score += points;
    reasons.push(reason);
  }

  add(venueDomain !== "" && venueDomain === businessEmailDomain, 35, "Business email domain matches venue website domain.");
  add(venueDomain !== "" && venueDomain === evidenceWebsiteDomain, 30, "Submitted website matches existing venue website.");
  add(venuePhone !== "" && venuePhone === evidencePhone, 20, "Submitted phone matches venue phone.");
  add((params.evidence.companyRegistration ?? "").trim() !== "", 20, "Company registration supplied.");
  add((params.evidence.documentUrls ?? []).length > 0, 15, "Supporting document uploaded.");
  add((params.evidence.notes ?? "").trim() !== "", 5, "Additional notes supplied.");

  return {score: Math.min(score, 100), reasons};
}

function sanitizeEvidence(raw: unknown): Evidence {
  const source = isRecord(raw) ? raw : {};
  const rawUrls = source.documentUrls;
  return {
    businessEmail: optionalString(source.businessEmail),
    website: optionalString(source.website),
    phone: optionalString(source.phone),
    companyRegistration: optionalString(source.companyRegistration),
    notes: optionalString(source.notes),
    documentUrls: Array.isArray(rawUrls) ? rawUrls.map((url) => String(url)).slice(0, 12) : [],
  };
}

function sanitizeDraft(raw: unknown): Record<string, unknown> {
  if (!isRecord(raw)) return {};
  const safe: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(raw)) {
    if (publishableDraftFields.has(key) && !ownershipFields.includes(key)) {
      safe[key] = value;
    }
  }
  return safe;
}

function createAdminAlert(
  transaction: Transaction,
  claimId: string,
  venueId: string,
  claimantUid: string,
) {
  const alertRef = db.collection("admin_alerts").doc();
  transaction.set(alertRef, {
    type: "venue_claim_pending",
    claimId,
    venueId,
    claimantUid,
    title: "Venue claim pending",
    message: "A venue claim requires manual review.",
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

function writeAudit(
  transaction: Transaction,
  claimRef: DocumentReference,
  type: AuditType,
  actorUid: string,
  actorRole: string,
  message: string,
  metadata: Record<string, unknown> = {},
) {
  transaction.set(claimRef.collection("audit").doc(), {
    type,
    actorUid,
    actorRole,
    message,
    metadata,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function appendAudit(
  claimRef: DocumentReference,
  type: AuditType,
  actorUid: string,
  actorRole: string,
  message: string,
  metadata: Record<string, unknown> = {},
) {
  await claimRef.collection("audit").add({
    type,
    actorUid,
    actorRole,
    message,
    metadata,
    createdAt: FieldValue.serverTimestamp(),
  });
}

function readClaim(snapshot: DocumentSnapshot): ClaimData {
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Claim not found.");
  }
  const data = snapshot.data();
  if (!data) throw new HttpsError("not-found", "Claim not found.");
  return {
    claimId: snapshot.id,
    venueId: requireString(data.venueId, "venueId"),
    claimantUid: requireString(data.claimantUid, "claimantUid"),
    claimantEmail: optionalString(data.claimantEmail),
    status: readStatus(data.status),
    submittedEvidence: sanitizeEvidence(data.submittedEvidence),
    draftVenueData: sanitizeDraft(data.draftVenueData),
    confidenceScore: typeof data.confidenceScore === "number" ? data.confidenceScore : 0,
    confidenceReasons: Array.isArray(data.confidenceReasons) ? data.confidenceReasons.map((reason) => String(reason)) : [],
    autoApproved: data.autoApproved === true,
  };
}

function assertTransition(from: ClaimStatus, to: ClaimStatus) {
  if (!allowedTransitions[from]?.includes(to)) {
    throw new HttpsError("failed-precondition", `Invalid claim status transition from ${from} to ${to}.`);
  }
}

function requireClaimActor(request: CallableRequest, claim: ClaimData) {
  const uid = requireAuth(request);
  if (uid === claim.claimantUid || isAdminRequest(request)) return;
  throw new HttpsError("permission-denied", "You do not have permission to access this claim.");
}

function requireAuth(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in to continue.");
  return uid;
}

function requireAdmin(request: CallableRequest): string {
  const uid = requireAuth(request);
  if (!isAdminRequest(request)) {
    throw new HttpsError("permission-denied", "Admin permission required.");
  }
  return uid;
}

function isAdminRequest(request: CallableRequest): boolean {
  const token = request.auth?.token;
  return token?.staff === true && Number(token?.roleLevel ?? 0) >= 30;
}

function requireString(value: unknown, field: string): string {
  const text = optionalString(value);
  if (text === "") {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return text;
}

function optionalString(value: unknown): string {
  return typeof value === "string" ? value.trim() : value == null ? "" : String(value).trim();
}

function readStatus(value: unknown): ClaimStatus {
  const status = optionalString(value) as ClaimStatus;
  if (Object.values(claimStatuses).includes(status)) return status;
  throw new HttpsError("failed-precondition", "Claim has an invalid status.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value) && !(value instanceof Timestamp);
}

function readString(data: DocumentData, keys: string[], fallback: string): string {
  for (const key of keys) {
    const value = data[key];
    if (typeof value === "string" && value.trim() !== "") return value.trim();
  }
  return fallback;
}

function readVenueAddress(data: DocumentData): string {
  const rawAddress = data.address;
  if (isRecord(rawAddress)) {
    return [rawAddress.line1, rawAddress.city, rawAddress.postcode]
      .map(optionalString)
      .filter((part) => part !== "")
      .join(", ");
  }
  return optionalString(rawAddress);
}

function digits(value: string): string {
  return value.replace(/\D/g, "");
}

function domainFromEmail(value: string): string {
  const parts = value.trim().toLowerCase().split("@");
  return parts.length === 2 ? normaliseDomain(parts[1]) : "";
}

function domainFromUrl(value: string): string {
  const trimmed = value.trim().toLowerCase();
  if (trimmed === "") return "";
  try {
    const url = new URL(trimmed.startsWith("http://") || trimmed.startsWith("https://") ? trimmed : `https://${trimmed}`);
    return normaliseDomain(url.hostname);
  } catch {
    return "";
  }
}

function normaliseDomain(value: string): string {
  return value.trim().toLowerCase().replace(/^www\./, "");
}
