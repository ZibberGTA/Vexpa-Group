/**
 * Firestore security rules regression tests for Vexda admin dashboard access.
 *
 * Run from nightlife_app:
 *   npm install
 *   npm run test:rules
 */
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  serverTimestamp,
  writeBatch,
} = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'nightlife-app-19acd';

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

async function seedBaseData() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'venues/public-venue'), {
      name: 'Public Bar',
      ownerId: 'owner-1',
      isDeleted: false,
      searchablePublic: true,
      isHidden: false,
      publicVisible: true,
      isVisible: true,
      status: 'active',
    });

    await setDoc(doc(db, 'venues/hidden-venue'), {
      name: 'Hidden Bar',
      ownerId: 'owner-1',
      isDeleted: false,
      searchablePublic: false,
      isHidden: true,
      publicVisible: false,
      status: 'hidden',
    });

    await setDoc(doc(db, 'users/customer-1'), {
      role: 'user',
      status: 'active',
    });

    await setDoc(doc(db, 'users/owner-1'), {
      role: 'owner',
      status: 'active',
      venueIds: ['public-venue'],
    });

    await setDoc(doc(db, 'venues/other-venue'), {
      name: 'Other Bar',
      ownerId: 'owner-2',
      isDeleted: false,
      searchablePublic: true,
      isHidden: false,
      publicVisible: true,
      isVisible: true,
      status: 'active',
    });

    await setDoc(doc(db, 'users/owner-2'), {
      role: 'owner',
      status: 'active',
      venueIds: ['other-venue'],
    });

    await setDoc(doc(db, 'users/admin-1'), {
      role: 'admin',
      isAdmin: true,
      status: 'active',
    });

    await setDoc(doc(db, 'staff/admin-1'), {
      role: 'admin',
      roleLevel: 30,
      staff: true,
      email: 'admin@vexda.test',
      status: 'active',
    });

    await setDoc(doc(db, 'venue_claims/claim-1'), {
      claimId: 'claim-1',
      venueId: 'public-venue',
      claimantUid: 'owner-1',
      status: 'pending_review',
      confidenceScore: 0.5,
      submittedEvidence: {},
      draftVenueData: {},
      autoApproved: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await setDoc(doc(db, 'reports/report-1'), {
      reason: 'spam',
      userId: 'customer-1',
      createdAt: new Date(),
    });

    await setDoc(doc(db, 'secret_collection/secret-1'), {
      value: 'classified',
    });
  });
}

function validVenueManagementActivity(overrides = {}) {
  return {
    venueId: 'public-venue',
    sourceArea: 'drinks',
    actionType: 'created',
    entityType: 'drink',
    entityId: 'drink-1',
    entityName: 'Negroni',
    description: 'Drink created',
    actorUid: 'owner-1',
    metadata: {},
    version: 1,
    occurredAt: serverTimestamp(),
    ...overrides,
  };
}

async function seedActivityDoc(activityId, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `venue_management_activity/${activityId}`), data);
  });
}

function validTrailParticipationPayload(overrides = {}) {
  const trailId = overrides.trailId ?? 'trail-1';
  const venueId = overrides.venueId ?? 'public-venue';
  return {
    schemaVersion: 1,
    trailId,
    venueId,
    requestedStopOrder: 1,
    participationNote: 'We would love to join this trail.',
    ...overrides,
  };
}

function validWorkflowRequest(overrides = {}) {
  const requestId = overrides.requestId ?? 'wf-req-1';
  const subjectTrailId = overrides.subjectTrailId ?? 'trail-1';
  const subjectVenueId = overrides.subjectVenueId ?? 'public-venue';
  const submittedByUid = overrides.submittedByUid ?? 'owner-1';
  const payload =
    overrides.payload ??
    validTrailParticipationPayload({
      trailId: subjectTrailId,
      venueId: subjectVenueId,
    });

  return {
    requestId,
    workflowType: 'trail.venue_participation',
    status: 'draft',
    submittedByUid,
    subjectTrailId,
    subjectVenueId,
    subjectRefs: {
      trailId: subjectTrailId,
      venueId: subjectVenueId,
    },
    payload,
    revision: 1,
    assignedReviewerUids: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
    subjectRefs: overrides.subjectRefs ?? {
      trailId: subjectTrailId,
      venueId: subjectVenueId,
    },
    payload,
  };
}

function seededWorkflowRequest(overrides = {}) {
  const base = validWorkflowRequest(overrides);
  return {
    ...base,
    createdAt: overrides.createdAt ?? new Date('2026-07-18T12:00:00.000Z'),
    updatedAt: overrides.updatedAt ?? new Date('2026-07-18T12:00:00.000Z'),
    ...(overrides.submittedAt != null ? { submittedAt: overrides.submittedAt } : {}),
    ...(overrides.decidedAt != null ? { decidedAt: overrides.decidedAt } : {}),
  };
}

function validWorkflowAudit(overrides = {}) {
  const requestId = overrides.requestId ?? 'wf-req-1';
  const auditId = overrides.auditId ?? `${requestId}-2-submitted`;
  return {
    auditId,
    requestId,
    action: 'submitted',
    fromStatus: 'draft',
    toStatus: 'submitted',
    actorUid: 'owner-1',
    actorKind: 'submitter',
    metadata: {},
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

function seededWorkflowAudit(overrides = {}) {
  return {
    ...validWorkflowAudit(overrides),
    createdAt: overrides.createdAt ?? new Date('2026-07-18T12:00:00.000Z'),
  };
}

async function seedWorkflowRequest(requestId, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `workflow_requests/${requestId}`), data);
  });
}

async function seedWorkflowAudit(requestId, auditId, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `workflow_requests/${requestId}/audit/${auditId}`), data);
  });
}

describe('public discovery', () => {
  test('unauthenticated user can read public venue', async () => {
    await seedBaseData();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(db, 'venues/public-venue')));
  });

  test('unauthenticated user cannot read hidden venue', async () => {
    await seedBaseData();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'venues/hidden-venue')));
  });

  test('unauthenticated user cannot list users', async () => {
    await seedBaseData();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDocs(query(collection(db, 'users'), limit(5))));
  });
});

describe('customer restrictions', () => {
  test('customer cannot read staff collection', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('customer-1').firestore();
    await assertFails(getDocs(query(collection(db, 'staff'), limit(5))));
  });

  test('customer cannot read venue claims', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('customer-1').firestore();
    await assertFails(getDoc(doc(db, 'venue_claims/claim-1')));
  });
});

describe('venue owner restrictions', () => {
  test('venue owner can read own hidden venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'venues/hidden-venue')));
  });

  test('venue owner cannot list users', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(getDocs(query(collection(db, 'users'), limit(5))));
  });

  test('venue owner can read own claim', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'venue_claims/claim-1')));
  });
});

describe('admin dashboard access', () => {
  test('admin can read own staff document without custom claims', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'staff/admin-1')));
  });

  test('admin can list users', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'users'), limit(10))));
  });

  test('admin can list venues including hidden', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'venues'), limit(10))));
  });

  test('admin can list venue claims', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'venue_claims'), limit(10))));
  });

  test('admin can list reports', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'reports'), limit(10))));
  });
});

describe('default deny', () => {
  test('admin cannot read unknown collections', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertFails(getDoc(doc(db, 'secret_collection/secret-1')));
  });

  test('unauthenticated user cannot read unknown collections', async () => {
    await seedBaseData();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'secret_collection/secret-1')));
  });
});

describe('venue management activity', () => {
  test('unauthenticated user cannot create activity', async () => {
    await seedBaseData();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity(),
      ),
    );
  });

  test('authorised manager can create activity for their venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity(),
      ),
    );
  });

  test('authorised manager cannot create activity for another venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity({
          venueId: 'other-venue',
        }),
      ),
    );
  });

  test('manager cannot forge actorUid as another user', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity({
          actorUid: 'owner-2',
        }),
      ),
    );
  });

  test('create with missing required fields is denied', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    const payload = validVenueManagementActivity();
    delete payload.description;
    await assertFails(
      setDoc(doc(db, 'venue_management_activity/activity-1'), payload),
    );
  });

  test('create with unexpected fields is denied', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity({
          forgedField: true,
        }),
      ),
    );
  });

  test('create with invalid field types is denied', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity({
          version: '1',
        }),
      ),
    );
  });

  test('create with arbitrary occurredAt timestamp is denied', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity({
          occurredAt: new Date('2020-01-01T00:00:00.000Z'),
        }),
      ),
    );
  });

  test('valid server-timestamp create is allowed', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity({
          occurredAt: serverTimestamp(),
        }),
      ),
    );
  });

  test('create with optional actorDisplayName is allowed', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(
        doc(db, 'venue_management_activity/activity-1'),
        validVenueManagementActivity({
          actorDisplayName: 'Alex Owner',
        }),
      ),
    );
  });

  test('authorised manager can read activity for their venue', async () => {
    await seedBaseData();
    await seedActivityDoc('activity-1', {
      ...validVenueManagementActivity(),
      occurredAt: new Date('2026-07-18T12:00:00.000Z'),
    });
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'venue_management_activity/activity-1')));
  });

  test('authorised manager cannot read another venue activity', async () => {
    await seedBaseData();
    await seedActivityDoc('activity-other', {
      ...validVenueManagementActivity({
        venueId: 'other-venue',
        actorUid: 'owner-2',
      }),
      occurredAt: new Date('2026-07-18T12:00:00.000Z'),
    });
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(getDoc(doc(db, 'venue_management_activity/activity-other')));
  });

  test('venue-scoped list query succeeds for authorised manager', async () => {
    await seedBaseData();
    await seedActivityDoc('activity-1', {
      ...validVenueManagementActivity(),
      occurredAt: new Date('2026-07-18T12:00:00.000Z'),
    });
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      getDocs(
        query(
          collection(db, 'venue_management_activity'),
          where('venueId', '==', 'public-venue'),
          orderBy('occurredAt', 'desc'),
          limit(10),
        ),
      ),
    );
  });

  test('unscoped list query is denied', async () => {
    await seedBaseData();
    await seedActivityDoc('activity-1', {
      ...validVenueManagementActivity(),
      occurredAt: new Date('2026-07-18T12:00:00.000Z'),
    });
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      getDocs(query(collection(db, 'venue_management_activity'), limit(10))),
    );
  });

  test('updates are denied', async () => {
    await seedBaseData();
    await seedActivityDoc('activity-1', {
      ...validVenueManagementActivity(),
      occurredAt: new Date('2026-07-18T12:00:00.000Z'),
    });
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'venue_management_activity/activity-1'), {
        description: 'Changed',
      }),
    );
  });

  test('deletes are denied', async () => {
    await seedBaseData();
    await seedActivityDoc('activity-1', {
      ...validVenueManagementActivity(),
      occurredAt: new Date('2026-07-18T12:00:00.000Z'),
    });
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(deleteDoc(doc(db, 'venue_management_activity/activity-1')));
  });
});

describe('venue management activity regression safety', () => {
  test('venue owner can still read own venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'venues/public-venue')));
  });

  test('venue owner can still create drinks for own venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'drinks/drink-1'), {
        venueId: 'public-venue',
        name: 'Negroni',
        isDeleted: false,
      }),
    );
  });

  test('venue owner can still create deals for own venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'deals/deal-1'), {
        venueId: 'public-venue',
        title: 'Happy Hour',
        isDeleted: false,
      }),
    );
  });

  test('venue owner can still create events for own venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'events/event-1'), {
        venueId: 'public-venue',
        title: 'DJ Night',
        isDeleted: false,
      }),
    );
  });

  test('venue owner can still write gallery media metadata', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'venues/public-venue/media/media-1'), {
        venueId: 'public-venue',
        mediaId: 'media-1',
        mediaType: 'gallery',
        imageUrl: 'https://example.com/photo.jpg',
        visible: true,
        status: 'active',
      }),
    );
  });

  test('venue owner can still read analytics for own venue', async () => {
    await seedBaseData();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'analytics/analytics-1'), {
        venueId: 'public-venue',
        type: 'drink_view',
        createdAt: new Date(),
      });
    });
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'analytics/analytics-1')));
  });

  test('admin access still behaves as before for users collection', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDocs(query(collection(db, 'users'), limit(10))));
  });

  test('admin can read venue management activity via support access', async () => {
    await seedBaseData();
    await seedActivityDoc('activity-1', {
      ...validVenueManagementActivity(),
      occurredAt: new Date('2026-07-18T12:00:00.000Z'),
    });
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'venue_management_activity/activity-1')));
  });
});

describe('workflow_requests trail venue participation', () => {
  // Atomicity / enforcement notes:
  // - Submit/resubmit/withdraw + audit in the same batch is allowed when the parent
  //   request already exists (get() resolves against the post-batch parent state).
  // - Draft create + audit in the same batch is denied: audit create get() on the
  //   parent request throws a null-value error before the parent write is visible.
  // - Audit create rules do not validate action/fromStatus/toStatus alignment, actorUid,
  //   or monotonic revision on the parent request; venue managers can append audit docs
  //   with arbitrary action values if they manage the venue and own the request.
  // - Admin updates bypass workflowVenueCanUpdate field guards (isAdmin() short-circuit);
  //   privileged transitions are blocked in application code, not in these rules.
  // - Revision monotonicity is not enforced in rules; only changedKeys are restricted.

  test('managed venue user can create draft for venue they manage', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'workflow_requests/wf-req-1'), validWorkflowRequest()),
    );
  });

  test('managed venue user can read their request', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'workflow_requests/wf-req-1')));
  });

  test('managed venue user can update permitted draft payload fields', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        payload: validTrailParticipationPayload({
          requestedStopOrder: 2,
          participationNote: 'Updated stop order.',
        }),
        revision: 2,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('managed venue user can submit draft (draft -> submitted)', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        status: 'submitted',
        revision: 2,
        submittedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('managed venue user can resubmit information_requested -> submitted', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-1',
      seededWorkflowRequest({
        status: 'information_requested',
        revision: 3,
        submittedAt: new Date('2026-07-17T12:00:00.000Z'),
        reviewNotesSummary: 'Please clarify stop order.',
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        status: 'submitted',
        payload: validTrailParticipationPayload({
          requestedStopOrder: 3,
          participationNote: 'Clarified stop order.',
        }),
        revision: 4,
        submittedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('managed venue user can withdraw eligible request (submitted -> withdrawn)', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-1',
      seededWorkflowRequest({
        status: 'submitted',
        revision: 2,
        submittedAt: new Date('2026-07-17T12:00:00.000Z'),
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        status: 'withdrawn',
        revision: 3,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('managed venue user can read permitted audit entries', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    await seedWorkflowAudit(
      'wf-req-1',
      'wf-req-1-1-draft_created',
      seededWorkflowAudit({
        auditId: 'wf-req-1-1-draft_created',
        action: 'draft_created',
        fromStatus: 'draft',
        toStatus: 'draft',
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      getDoc(doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-1-draft_created')),
    );
  });

  test('managed venue user can atomically submit request and create audit in batch', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    const batch = writeBatch(db);
    batch.update(doc(db, 'workflow_requests/wf-req-1'), {
      status: 'submitted',
      revision: 2,
      submittedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    batch.set(
      doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-2-submitted'),
      validWorkflowAudit({
        auditId: 'wf-req-1-2-submitted',
        action: 'submitted',
        fromStatus: 'draft',
        toStatus: 'submitted',
      }),
    );
    await assertSucceeds(batch.commit());
  });

  test('managed venue user cannot atomically create draft and audit in batch', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, 'workflow_requests/wf-req-1'), validWorkflowRequest());
    batch.set(
      doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-1-draft_created'),
      validWorkflowAudit({
        auditId: 'wf-req-1-1-draft_created',
        action: 'draft_created',
        fromStatus: 'draft',
        toStatus: 'draft',
      }),
    );
    await assertFails(batch.commit());
  });

  test('unrelated user cannot create for another venue', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-2').firestore();
    await assertFails(
      setDoc(
        doc(db, 'workflow_requests/wf-req-other'),
        validWorkflowRequest({
          requestId: 'wf-req-other',
          subjectVenueId: 'public-venue',
          subjectTrailId: 'trail-1',
          submittedByUid: 'owner-2',
          subjectRefs: {
            trailId: 'trail-1',
            venueId: 'public-venue',
          },
          payload: validTrailParticipationPayload({
            venueId: 'public-venue',
          }),
        }),
      ),
    );
  });

  test('unrelated user cannot read another venue request', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-2').firestore();
    await assertFails(getDoc(doc(db, 'workflow_requests/wf-req-1')));
  });

  test('unrelated user cannot update another venue request', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-2').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        payload: validTrailParticipationPayload({
          participationNote: 'Hostile takeover.',
        }),
        revision: 2,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('unrelated user cannot read another venue audit', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    await seedWorkflowAudit(
      'wf-req-1',
      'wf-req-1-1-draft_created',
      seededWorkflowAudit({
        auditId: 'wf-req-1-1-draft_created',
        action: 'draft_created',
        fromStatus: 'draft',
        toStatus: 'draft',
      }),
    );
    const db = testEnv.authenticatedContext('owner-2').firestore();
    await assertFails(
      getDoc(doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-1-draft_created')),
    );
  });

  test('venue user cannot approve request', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-1',
      seededWorkflowRequest({
        status: 'submitted',
        revision: 2,
        submittedAt: new Date('2026-07-17T12:00:00.000Z'),
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        status: 'approved',
        revision: 3,
        decidedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('venue user cannot reject request', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-1',
      seededWorkflowRequest({
        status: 'submitted',
        revision: 2,
        submittedAt: new Date('2026-07-17T12:00:00.000Z'),
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        status: 'rejected',
        revision: 3,
        decisionReason: 'Not eligible',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('venue user cannot set privileged reviewer fields', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        assignedReviewerUid: 'admin-1',
        assignedReviewerUids: ['admin-1'],
        reviewNotesSummary: 'Escalated',
        revision: 2,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('venue user cannot change workflow type', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        workflowType: 'venue.claim',
        revision: 2,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('venue user cannot change subject refs', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        subjectTrailId: 'trail-2',
        subjectRefs: {
          trailId: 'trail-2',
          venueId: 'public-venue',
        },
        revision: 2,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('venue user cannot change submittedByUid', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        submittedByUid: 'owner-2',
        revision: 2,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('venue user cannot create request for another venue with forged submittedByUid', async () => {
    await seedBaseData();
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'workflow_requests/wf-req-forged'),
        validWorkflowRequest({
          requestId: 'wf-req-forged',
          subjectVenueId: 'other-venue',
          subjectRefs: {
            trailId: 'trail-1',
            venueId: 'other-venue',
          },
          payload: validTrailParticipationPayload({
            venueId: 'other-venue',
          }),
        }),
      ),
    );
  });

  test('venue user cannot delete request', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(deleteDoc(doc(db, 'workflow_requests/wf-req-1')));
  });

  test('venue user cannot update terminal request', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-1',
      seededWorkflowRequest({
        status: 'approved',
        revision: 4,
        submittedAt: new Date('2026-07-16T12:00:00.000Z'),
        decidedAt: new Date('2026-07-17T12:00:00.000Z'),
        decisionCode: 'approved',
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        payload: validTrailParticipationPayload({
          participationNote: 'Too late.',
        }),
        revision: 5,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('venue user cannot update audit entry', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    await seedWorkflowAudit(
      'wf-req-1',
      'wf-req-1-1-draft_created',
      seededWorkflowAudit({
        auditId: 'wf-req-1-1-draft_created',
        action: 'draft_created',
        fromStatus: 'draft',
        toStatus: 'draft',
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      updateDoc(doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-1-draft_created'), {
        notes: 'Forged notes',
      }),
    );
  });

  test('venue user cannot delete audit entry', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    await seedWorkflowAudit(
      'wf-req-1',
      'wf-req-1-1-draft_created',
      seededWorkflowAudit({
        auditId: 'wf-req-1-1-draft_created',
        action: 'draft_created',
        fromStatus: 'draft',
        toStatus: 'draft',
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      deleteDoc(doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-1-draft_created')),
    );
  });

  test('venue user cannot create audit for another venue request', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-other',
      seededWorkflowRequest({
        requestId: 'wf-req-other',
        submittedByUid: 'owner-2',
        subjectVenueId: 'other-venue',
        subjectRefs: {
          trailId: 'trail-1',
          venueId: 'other-venue',
        },
        payload: validTrailParticipationPayload({
          venueId: 'other-venue',
        }),
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertFails(
      setDoc(
        doc(db, 'workflow_requests/wf-req-other/audit/wf-req-other-2-forged'),
        validWorkflowAudit({
          auditId: 'wf-req-other-2-forged',
          requestId: 'wf-req-other',
          actorUid: 'owner-1',
        }),
      ),
    );
  });

  test('rules allow venue user to create audit with arbitrary action value', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      setDoc(
        doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-9-forged'),
        validWorkflowAudit({
          auditId: 'wf-req-1-9-forged',
          action: 'approved',
          fromStatus: 'submitted',
          toStatus: 'approved',
          actorUid: 'owner-1',
        }),
      ),
    );
  });

  test('rules allow venue user to decrease revision on draft update', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-1',
      seededWorkflowRequest({
        revision: 3,
      }),
    );
    const db = testEnv.authenticatedContext('owner-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        payload: validTrailParticipationPayload({
          participationNote: 'Revision rollback attempt.',
        }),
        revision: 1,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('admin can read workflow request', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(getDoc(doc(db, 'workflow_requests/wf-req-1')));
  });

  test('admin can read workflow audit entry', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    await seedWorkflowAudit(
      'wf-req-1',
      'wf-req-1-1-draft_created',
      seededWorkflowAudit({
        auditId: 'wf-req-1-1-draft_created',
        action: 'draft_created',
        fromStatus: 'draft',
        toStatus: 'draft',
      }),
    );
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      getDoc(doc(db, 'workflow_requests/wf-req-1/audit/wf-req-1-1-draft_created')),
    );
  });

  test('admin client update can approve request because rules bypass field guards', async () => {
    await seedBaseData();
    await seedWorkflowRequest(
      'wf-req-1',
      seededWorkflowRequest({
        status: 'submitted',
        revision: 2,
        submittedAt: new Date('2026-07-17T12:00:00.000Z'),
      }),
    );
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertSucceeds(
      updateDoc(doc(db, 'workflow_requests/wf-req-1'), {
        status: 'approved',
        decisionCode: 'approved',
        decisionReason: 'Looks good',
        decidedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test('admin cannot delete workflow request', async () => {
    await seedBaseData();
    await seedWorkflowRequest('wf-req-1', seededWorkflowRequest());
    const db = testEnv.authenticatedContext('admin-1').firestore();
    await assertFails(deleteDoc(doc(db, 'workflow_requests/wf-req-1')));
  });
});
