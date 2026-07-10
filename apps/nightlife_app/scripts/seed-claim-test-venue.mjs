/**
 * Seeds safe unclaimed test venues for venue-claim E2E testing.
 *
 * Usage (from nightlife_app/scripts):
 *   set GOOGLE_APPLICATION_CREDENTIALS=path\to\serviceAccount.json
 *   node seed-claim-test-venue.mjs
 *
 * Creates documents only when missing — never overwrites existing venue data.
 */
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { readFileSync, existsSync } from 'node:fs';

const TEST_VENUES = [
  {
    id: 'test-pulse-bar-lounge',
    name: 'Pulse Bar & Lounge Test',
    category: 'Bar',
    addressLine: '12 Test Lane',
    city: 'Testville',
    postcode: 'TE5 7NG',
    website: 'https://pulsebar-test.example.com',
    email: 'hello@pulsebar-test.example.com',
    phone: '+44 161 555 0100',
  },
  {
    id: 'test-red-lion-venue',
    name: 'Red Lion Test Venue',
    category: 'Pub',
    addressLine: '1 High Street',
    city: 'Basildon',
    postcode: 'CM12 9AB',
    website: 'https://redlion-test.example.com',
    email: 'hello@redlion-test.example.com',
    phone: '+44 1268 555 0101',
  },
];

function initFirebase() {
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (serviceAccountPath && existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    initializeApp({ credential: cert(serviceAccount) });
    return;
  }

  initializeApp({ credential: applicationDefault() });
}

function tokenize(value) {
  return `${value}`
    .trim()
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((token) => token.length >= 2);
}

function buildSearchKeywords(venue) {
  const values = new Set();
  const add = (value) => {
    const text = `${value ?? ''}`.trim().toLowerCase();
    if (!text) return;
    values.add(text);
    for (const token of tokenize(text)) values.add(token);
  };

  add(venue.name);
  add(venue.city);
  add(venue.postcode);
  add(venue.addressLine);
  add(venue.category);
  add('test');
  add('venue');

  return [...values];
}

function buildVenuePayload(venue) {
  const nameLower = venue.name.toLowerCase();
  const townLower = venue.city.toLowerCase();
  const postcodeLower = venue.postcode.toLowerCase();
  const addressLower = venue.addressLine.toLowerCase();
  const searchKeywords = buildSearchKeywords(venue);

  return {
    name: venue.name,
    venueName: venue.name,
    category: venue.category,
    venueType: venue.category,
    description: `Test venue for Vexda venue-claim E2E flows (${venue.name}).`,
    address: {
      line: venue.addressLine,
      city: venue.city,
      postcode: venue.postcode,
    },
    city: venue.city,
    town: venue.city,
    postcode: venue.postcode,
    website: venue.website,
    websiteUrl: venue.website,
    email: venue.email,
    phone: venue.phone,
    claimStatus: 'unclaimed',
    isClaimed: false,
    isDeleted: false,
    isTestData: true,
    status: 'active',
    nameLower,
    townLower,
    cityLower: townLower,
    postcodeLower,
    addressLower,
    searchKeywords,
    featureTags: ['test-data', 'claim-flow'],
    openingHours: {
      monday: '12:00-23:00',
      tuesday: '12:00-23:00',
      wednesday: '12:00-23:00',
      thursday: '12:00-23:00',
      friday: '12:00-01:00',
      saturday: '12:00-01:00',
      sunday: '12:00-22:00',
    },
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function buildDirectoryPayload(venueId, venue) {
  return {
    venueId,
    name: venue.name,
    category: venue.category,
    address: venue.addressLine,
    city: venue.city,
    town: venue.city,
    postcode: venue.postcode,
    claimStatus: 'unclaimed',
    isClaimed: false,
    isTestData: true,
    website: venue.website,
    phone: venue.phone,
    nameLower: venue.name.toLowerCase(),
    townLower: venue.city.toLowerCase(),
    postcodeLower: venue.postcode.toLowerCase(),
    addressLower: venue.addressLine.toLowerCase(),
    searchKeywords: buildSearchKeywords(venue),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

async function seedVenue(db, venue) {
  const venueRef = db.collection('venues').doc(venue.id);
  const existing = await venueRef.get();

  if (existing.exists) {
    console.log(`Venue already exists (${venue.id}): ${existing.data()?.name ?? 'unnamed'}`);
    return false;
  }

  await venueRef.set(buildVenuePayload(venue));
  console.log(`Created venue "${venue.name}" (${venue.id}).`);
  return true;
}

async function seedDirectoryEntry(db, venue) {
  const directoryRef = db.collection('venue_claim_directory').doc(venue.id);
  const existing = await directoryRef.get();
  if (existing.exists) {
    console.log(`Directory entry already exists (${venue.id}).`);
    return;
  }

  await directoryRef.set(buildDirectoryPayload(venue.id, venue));
  console.log(`Created venue_claim_directory entry (${venue.id}).`);
}

async function main() {
  initFirebase();
  const db = getFirestore();

  for (const venue of TEST_VENUES) {
    await seedVenue(db, venue);
    await seedDirectoryEntry(db, venue);
  }

  console.log('');
  console.log('Search suggestions:');
  console.log('- "red" or "lion" -> Red Lion Test Venue');
  console.log('- "pulse" or "test" -> Pulse Bar & Lounge Test');
  console.log('- "cm" or "basildon" -> Red Lion Test Venue');
}

main().catch((error) => {
  console.error('Seed failed:', error);
  process.exitCode = 1;
});
