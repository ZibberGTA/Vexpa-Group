/**
 * Firebase Storage security rules regression tests.
 *
 * Run from apps/nightlife_app/tests:
 *   npm install
 *   npm run test:storage-rules
 */
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');
const {
  ref,
  uploadBytes,
  getBytes,
  deleteObject,
} = require('firebase/storage');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'nightlife-app-19acd';
const MAX_BYTES = 10 * 1024 * 1024;

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
    storage: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'storage.rules'),
        'utf8',
      ),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

async function seedStorageFixtures() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'venues/public-venue'), {
      name: 'Public Bar',
      ownerId: 'owner-1',
      isDeleted: false,
      searchablePublic: true,
      isHidden: false,
      publicVisible: true,
    });

    await setDoc(doc(db, 'users/owner-1'), {
      role: 'owner',
      status: 'active',
      venueIds: ['public-venue'],
    });

    await setDoc(doc(db, 'users/customer-1'), {
      role: 'user',
      status: 'active',
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
      status: 'active',
    });
  });
}

function storageFor(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

function unauthenticatedStorage() {
  return testEnv.unauthenticatedContext().storage();
}

describe('claim evidence storage rules', () => {
  const evidencePath = 'claims/claimant-1/evidence/proof.pdf';

  beforeEach(async () => {
    await seedStorageFixtures();
  });

  test('signed-out user cannot upload claim evidence', async () => {
    const storage = unauthenticatedStorage();
    const evidenceRef = ref(storage, evidencePath);
    await assertFails(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'application/pdf',
      }),
    );
  });

  test('claimant can upload valid image evidence to their own path', async () => {
    const storage = storageFor('claimant-1');
    const evidenceRef = ref(storage, 'claims/claimant-1/evidence/photo.jpg');
    await assertSucceeds(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'image/jpeg',
      }),
    );
  });

  test('claimant can upload valid PDF evidence to their own path', async () => {
    const storage = storageFor('claimant-1');
    const evidenceRef = ref(storage, evidencePath);
    await assertSucceeds(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'application/pdf',
      }),
    );
  });

  test('claimant cannot upload to another claimant path', async () => {
    const storage = storageFor('claimant-1');
    const evidenceRef = ref(storage, 'claims/other-user/evidence/proof.pdf');
    await assertFails(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'application/pdf',
      }),
    );
  });

  test('invalid MIME type is denied', async () => {
    const storage = storageFor('claimant-1');
    const evidenceRef = ref(storage, evidencePath);
    await assertFails(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'text/plain',
      }),
    );
  });

  test('oversized file is denied', async () => {
    const storage = storageFor('claimant-1');
    const evidenceRef = ref(storage, evidencePath);
    const oversized = new Uint8Array(MAX_BYTES + 1);
    await assertFails(
      uploadBytes(evidenceRef, oversized, {
        contentType: 'application/pdf',
      }),
    );
  });

  test('unrelated signed-in user cannot read claim evidence', async () => {
    const claimantStorage = storageFor('claimant-1');
    const evidenceRef = ref(claimantStorage, evidencePath);
    await assertSucceeds(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'application/pdf',
      }),
    );

    const otherStorage = storageFor('customer-1');
    await assertFails(getBytes(ref(otherStorage, evidencePath)));
  });

  test('claimant can read their own evidence', async () => {
    const storage = storageFor('claimant-1');
    const evidenceRef = ref(storage, evidencePath);
    await assertSucceeds(
      uploadBytes(evidenceRef, new Uint8Array([9, 9, 9]), {
        contentType: 'application/pdf',
      }),
    );
    await assertSucceeds(getBytes(evidenceRef));
  });

  test('authorised admin can read claim evidence', async () => {
    const claimantStorage = storageFor('claimant-1');
    const evidenceRef = ref(claimantStorage, evidencePath);
    await assertSucceeds(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'application/pdf',
      }),
    );

    const adminStorage = storageFor('admin-1');
    await assertSucceeds(getBytes(ref(adminStorage, evidencePath)));
  });

  test('claimant cannot overwrite an existing evidence file', async () => {
    const storage = storageFor('claimant-1');
    const evidenceRef = ref(storage, evidencePath);
    await assertSucceeds(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'application/pdf',
      }),
    );
    await assertFails(
      uploadBytes(evidenceRef, new Uint8Array([4, 5, 6]), {
        contentType: 'application/pdf',
      }),
    );
  });

  test('public users cannot read claim evidence', async () => {
    const claimantStorage = storageFor('claimant-1');
    const evidenceRef = ref(claimantStorage, evidencePath);
    await assertSucceeds(
      uploadBytes(evidenceRef, new Uint8Array([1, 2, 3]), {
        contentType: 'application/pdf',
      }),
    );

    const publicStorage = unauthenticatedStorage();
    await assertFails(getBytes(ref(publicStorage, evidencePath)));
  });
});

describe('venue media storage parity', () => {
  const logoPath = 'venues/public-venue/media/logo/logo-1.jpg';

  beforeEach(async () => {
    await seedStorageFixtures();
  });

  test('venue owner can upload public venue logo media', async () => {
    const storage = storageFor('owner-1');
    const logoRef = ref(storage, logoPath);
    await assertSucceeds(
      uploadBytes(logoRef, new Uint8Array([1, 2, 3]), {
        contentType: 'image/jpeg',
      }),
    );
  });

  test('unrelated user cannot upload venue media', async () => {
    const storage = storageFor('customer-1');
    const logoRef = ref(storage, logoPath);
    await assertFails(
      uploadBytes(logoRef, new Uint8Array([1, 2, 3]), {
        contentType: 'image/jpeg',
      }),
    );
  });

  test('public users can read public venue media', async () => {
    const ownerStorage = storageFor('owner-1');
    const logoRef = ref(ownerStorage, logoPath);
    await assertSucceeds(
      uploadBytes(logoRef, new Uint8Array([1, 2, 3]), {
        contentType: 'image/jpeg',
      }),
    );

    const publicStorage = unauthenticatedStorage();
    await assertSucceeds(getBytes(ref(publicStorage, logoPath)));
  });
});
