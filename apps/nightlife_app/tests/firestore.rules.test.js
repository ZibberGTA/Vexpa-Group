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
  collection,
  getDocs,
  query,
  limit,
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
