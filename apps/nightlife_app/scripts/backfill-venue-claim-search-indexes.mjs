/**
 * One-off backfill for venue claim search indexes.
 *
 * Default: dry-run (no Firestore writes).
 * Pass --write to apply updates.
 *
 * Usage (from nightlife_app/scripts):
 *   set GOOGLE_APPLICATION_CREDENTIALS=path\to\serviceAccount.json
 *   node backfill-venue-claim-search-indexes.mjs
 *   node backfill-venue-claim-search-indexes.mjs --write
 *   node backfill-venue-claim-search-indexes.mjs --write --verbose
 */
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { readFileSync, existsSync } from 'node:fs';

const BATCH_SIZE = 200; // 2 writes per venue (venue + directory) => 400 ops max
const PAGE_SIZE = 150;

const PRESERVED_CLAIM_STATUSES = new Set([
  'blocked',
  'suspended',
  'deleted',
  'rejected',
  'pending',
  'pending_review',
  'needs_more_info',
  'in_review',
  'review',
  'available',
  'open',
]);

const BLOCKED_VENUE_STATUSES = new Set(['deleted', 'suspended', 'blocked', 'archived']);

const args = new Set(process.argv.slice(2));
const WRITE_MODE = args.has('--write');
const VERBOSE = args.has('--verbose');

const stats = {
  scanned: 0,
  updated: 0,
  skipped: 0,
  claimed: 0,
  unclaimed: 0,
  directoryWrites: 0,
  venueWrites: 0,
  errors: 0,
};

function initFirebase() {
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (serviceAccountPath && existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    initializeApp({ credential: cert(serviceAccount) });
    return;
  }

  initializeApp({ credential: applicationDefault() });
}

function firstNonEmpty(source, keys) {
  if (!source || typeof source !== 'object') return '';
  for (const key of keys) {
    const value = source[key];
    const text = `${value ?? ''}`.trim();
    if (text) return text;
  }
  return '';
}

function tokenize(value) {
  return `${value ?? ''}`
    .trim()
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((token) => token.length >= 2);
}

function addValue(values, value) {
  const text = `${value ?? ''}`.trim().toLowerCase();
  if (!text) return;
  values.add(text);
  for (const token of tokenize(text)) {
    values.add(token);
  }
}

function addPostcodeTokens(values, postcode) {
  const normalized = `${postcode ?? ''}`.trim().toLowerCase();
  if (!normalized) return;

  addValue(values, normalized);
  addValue(values, normalized.replace(/\s+/g, ''));

  const compact = normalized.replace(/[^a-z0-9]/g, '');
  if (compact.length >= 2) {
    values.add(compact);
    for (let size = 2; size <= Math.min(6, compact.length); size += 1) {
      values.add(compact.slice(0, size));
    }
  }

  const outward = normalized.split(/\s+/)[0] ?? '';
  if (outward.length >= 2) {
    values.add(outward);
    if (outward.length > 2) {
      values.add(outward.slice(0, 2));
    }
  }
}

function addNameCombinations(values, name) {
  const tokens = tokenize(name);
  if (tokens.length === 0) return;

  for (const token of tokens) {
    values.add(token);
  }

  for (let start = 0; start < tokens.length; start += 1) {
    for (let end = start + 1; end <= Math.min(start + 4, tokens.length); end += 1) {
      const slice = tokens.slice(start, end);
      values.add(slice.join(' '));
      if (slice.length > 1) {
        values.add(slice.join(''));
      }
    }
  }
}

function parseAddress(data) {
  const address = data.address;
  let line = '';
  let town = '';
  let postcode = '';

  if (typeof address === 'string') {
    line = address.trim();
  } else if (address && typeof address === 'object') {
    line = firstNonEmpty(address, [
      'line',
      'line1',
      'street',
      'addressLine1',
      'addressLine',
      'formattedAddress',
      'formatted',
    ]);
    town = firstNonEmpty(address, ['city', 'town', 'locality', 'postalTown']);
    postcode = firstNonEmpty(address, ['postcode', 'postalCode', 'zip']);
  }

  if (!town) {
    town = firstNonEmpty(data, ['city', 'town', 'locality', 'postalTown']);
  }
  if (!postcode) {
    postcode = firstNonEmpty(data, ['postcode', 'postalCode', 'zip']);
  }

  const location = data.location;
  if (location && typeof location === 'object') {
    if (!line) {
      line = firstNonEmpty(location, [
        'address',
        'formattedAddress',
        'line',
        'street',
      ]);
    }
    if (!town) {
      town = firstNonEmpty(location, ['city', 'town', 'locality']);
    }
    if (!postcode) {
      postcode = firstNonEmpty(location, ['postcode', 'postalCode', 'zip']);
    }
  }

  return {
    line,
    town,
    postcode,
  };
}

function readVenueName(data) {
  return firstNonEmpty(data, ['name', 'venueName', 'businessName', 'title', 'displayName']);
}

function readCategory(data) {
  return firstNonEmpty(data, ['category', 'venueType', 'type', 'primaryCategory']);
}

function readBannerUrl(data) {
  return firstNonEmpty(data, [
    'bannerImageUrl',
    'bannerUrl',
    'imageUrl',
    'coverImageUrl',
  ]);
}

function readLogoUrl(data) {
  return firstNonEmpty(data, ['logoUrl', 'logoImageUrl', 'logo']);
}

function hasOwnerAssigned(data) {
  const ownerId = firstNonEmpty(data, ['ownerId', 'ownerUid']);
  if (ownerId) return true;

  const ownerIds = data.ownerIds;
  if (Array.isArray(ownerIds) && ownerIds.some((item) => `${item ?? ''}`.trim())) {
    return true;
  }

  const claimedBy = firstNonEmpty(data, ['claimedBy', 'verifiedOwner', 'subscriptionOwner']);
  return Boolean(claimedBy);
}

function resolveClaimFields(data) {
  const existingStatus = firstNonEmpty(data, [
    'claimStatus',
    'claimedStatus',
    'verificationStatus',
  ]).toLowerCase();

  const venueStatus = firstNonEmpty(data, ['status']).toLowerCase();
  const isDeleted = data.isDeleted === true || venueStatus === 'deleted';

  if (isDeleted) {
    return {
      isClaimed: data.isClaimed === true,
      claimStatus: existingStatus || 'deleted',
      preserved: true,
    };
  }

  if (existingStatus && PRESERVED_CLAIM_STATUSES.has(existingStatus)) {
    return {
      isClaimed: data.isClaimed === true || existingStatus === 'claimed',
      claimStatus: existingStatus,
      preserved: true,
    };
  }

  if (venueStatus && BLOCKED_VENUE_STATUSES.has(venueStatus)) {
    return {
      isClaimed: data.isClaimed === true,
      claimStatus: existingStatus || venueStatus,
      preserved: true,
    };
  }

  if (hasOwnerAssigned(data) || data.isClaimed === true) {
    return {
      isClaimed: true,
      claimStatus: 'claimed',
      preserved: false,
    };
  }

  return {
    isClaimed: false,
    claimStatus: 'unclaimed',
    preserved: false,
  };
}

function buildSearchKeywords({ name, town, postcode, addressLine, category }) {
  const values = new Set();

  addValue(values, name);
  addNameCombinations(values, name);
  addValue(values, town);
  addValue(values, addressLine);
  addValue(values, category);
  addPostcodeTokens(values, postcode);

  return [...values].sort();
}

function arraysEqual(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b)) return false;
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i += 1) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

function buildIndexPayload(data) {
  const name = readVenueName(data) || 'Unnamed venue';
  const category = readCategory(data) || 'Venue';
  const { line, town, postcode } = parseAddress(data);
  const claim = resolveClaimFields(data);

  const nameLower = name.toLowerCase();
  const townLower = town.toLowerCase();
  const postcodeLower = postcode.toLowerCase();
  const addressLower = line.toLowerCase();
  const searchKeywords = buildSearchKeywords({
    name,
    town,
    postcode,
    addressLine: line,
    category,
  });

  const venuePatch = {
    nameLower,
    townLower,
    cityLower: townLower,
    postcodeLower,
    addressLower,
    searchKeywords,
    isClaimed: claim.isClaimed,
    claimStatus: claim.claimStatus,
    updatedAt: FieldValue.serverTimestamp(),
  };

  const directoryPatch = {
    venueId: null, // filled by caller
    name,
    nameLower,
    address: line,
    addressLower,
    town,
    townLower,
    postcode,
    postcodeLower,
    category,
    bannerImageUrl: readBannerUrl(data),
    logoUrl: readLogoUrl(data),
    isClaimed: claim.isClaimed,
    claimStatus: claim.claimStatus,
    searchKeywords,
    updatedAt: FieldValue.serverTimestamp(),
  };

  return { venuePatch, directoryPatch, claim, name, town, postcode, line };
}

function needsVenueUpdate(existing, venuePatch) {
  const comparableKeys = [
    'nameLower',
    'townLower',
    'cityLower',
    'postcodeLower',
    'addressLower',
    'searchKeywords',
    'isClaimed',
    'claimStatus',
  ];

  for (const key of comparableKeys) {
    const next = venuePatch[key];
    const current = existing[key];

    if (key === 'searchKeywords') {
      const currentSorted = Array.isArray(current) ? [...current].sort() : [];
      if (!arraysEqual(currentSorted, next)) return true;
      continue;
    }

    if (current !== next) return true;
  }

  return false;
}

function needsDirectoryUpdate(existing, directoryPatch) {
  const comparableKeys = [
    'venueId',
    'name',
    'nameLower',
    'address',
    'addressLower',
    'town',
    'townLower',
    'postcode',
    'postcodeLower',
    'category',
    'bannerImageUrl',
    'logoUrl',
    'isClaimed',
    'claimStatus',
    'searchKeywords',
  ];

  for (const key of comparableKeys) {
    const next = directoryPatch[key];
    const current = existing?.[key];

    if (key === 'searchKeywords') {
      const currentSorted = Array.isArray(current) ? [...current].sort() : [];
      if (!arraysEqual(currentSorted, next)) return true;
      continue;
    }

    if ((current ?? '') !== (next ?? '')) return true;
  }

  return !existing;
}

async function flushBatch(db, pendingWrites) {
  if (pendingWrites.length === 0) return;

  if (!WRITE_MODE) {
    pendingWrites.length = 0;
    return;
  }

  const batch = db.batch();
  for (const { ref, data } of pendingWrites) {
    batch.set(ref, data, { merge: true });
  }
  await batch.commit();
  pendingWrites.length = 0;
}

async function processVenue(db, doc, pendingWrites) {
  stats.scanned += 1;
  const data = doc.data() ?? {};
  const venueId = doc.id;

  try {
    const { venuePatch, directoryPatch, claim, name } = buildIndexPayload(data);
    directoryPatch.venueId = venueId;

    if (claim.isClaimed) stats.claimed += 1;
    else stats.unclaimed += 1;

    const venueRef = db.collection('venues').doc(venueId);
    const directoryRef = db.collection('venue_claim_directory').doc(venueId);

    const directorySnap = await directoryRef.get();
    const venueNeedsUpdate = needsVenueUpdate(data, venuePatch);
    const directoryNeedsUpdate = needsDirectoryUpdate(
      directorySnap.exists ? directorySnap.data() : null,
      directoryPatch,
    );

    if (!venueNeedsUpdate && !directoryNeedsUpdate) {
      stats.skipped += 1;
      if (VERBOSE) {
        console.log(`[skip] ${venueId} "${name}" — indexes already current`);
      }
      return;
    }

    stats.updated += 1;

    if (VERBOSE || !WRITE_MODE) {
      console.log(
        `[${WRITE_MODE ? 'update' : 'dry-run'}] ${venueId} "${name}" ` +
          `claim=${claim.claimStatus} keywords=${venuePatch.searchKeywords.length}`,
      );
    }

    if (venueNeedsUpdate) {
      pendingWrites.push({ ref: venueRef, data: venuePatch });
      stats.venueWrites += 1;
    }

    if (directoryNeedsUpdate) {
      pendingWrites.push({ ref: directoryRef, data: directoryPatch });
      stats.directoryWrites += 1;
    }

    if (pendingWrites.length >= BATCH_SIZE * 2) {
      await flushBatch(db, pendingWrites);
    }
  } catch (error) {
    stats.errors += 1;
    console.error(`[error] ${venueId}: ${error.message}`);
  }
}

async function main() {
  initFirebase();
  const db = getFirestore();
  const pendingWrites = [];

  console.log(`Venue claim search index backfill (${WRITE_MODE ? 'WRITE' : 'DRY-RUN'})`);
  console.log('');

  let lastDocument = null;

  while (true) {
    let query = db.collection('venues').orderBy('__name__').limit(PAGE_SIZE);
    if (lastDocument) {
      query = query.startAfter(lastDocument);
    }

    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const doc of snapshot.docs) {
      await processVenue(db, doc, pendingWrites);
    }

    lastDocument = snapshot.docs[snapshot.docs.length - 1];
  }

  await flushBatch(db, pendingWrites);

  console.log('');
  console.log('Summary');
  console.log('-------');
  console.log(`Mode:              ${WRITE_MODE ? 'write' : 'dry-run'}`);
  console.log(`Venues scanned:    ${stats.scanned}`);
  console.log(`Venues updated:    ${stats.updated}`);
  console.log(`Venues skipped:    ${stats.skipped}`);
  console.log(`Claimed venues:    ${stats.claimed}`);
  console.log(`Unclaimed venues:  ${stats.unclaimed}`);
  console.log(`Venue writes:      ${stats.venueWrites}${WRITE_MODE ? '' : ' (planned)'}`);
  console.log(`Directory writes:  ${stats.directoryWrites}${WRITE_MODE ? '' : ' (planned)'}`);
  console.log(`Errors:            ${stats.errors}`);

  if (!WRITE_MODE) {
    console.log('');
    console.log('Dry-run complete. Re-run with --write to apply changes.');
  }
}

main().catch((error) => {
  console.error('Backfill failed:', error);
  process.exitCode = 1;
});
