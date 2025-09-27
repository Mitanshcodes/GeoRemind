/*
  Safe Firestore test:
  - If FIRESTORE_EMULATOR_HOST is set, talks to emulator.
  - Otherwise requires GOOGLE_APPLICATION_CREDENTIALS to be set (NOT recommended for local dev).
*/

const admin = require('firebase-admin');

const usingEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || 'unknown-project';

if (!usingEmulator && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Refusing to run: no FIRESTORE_EMULATOR_HOST and no GOOGLE_APPLICATION_CREDENTIALS set.');
  console.error('For local dev run: export FIRESTORE_EMULATOR_HOST=localhost:8080 && export GCLOUD_PROJECT=<your-project-id>');
  process.exit(1);
}

if (usingEmulator) {
  console.log('Using Firestore emulator at', process.env.FIRESTORE_EMULATOR_HOST);
  // ensure project id is set so admin SDK doesn't try to auto-detect
  process.env.GCLOUD_PROJECT = projectId;
  admin.initializeApp({ projectId });
} else {
  // When running against cloud, GOOGLE_APPLICATION_CREDENTIALS must be set
  admin.initializeApp();
}

const db = admin.firestore();

(async () => {
  try {
    const ref = db.collection('test').doc('smoke');
    await ref.set({ ok: true, ts: new Date().toISOString() });
    const snap = await ref.get();
    console.log('wrote:', snap.data());
  } catch (err) {
    console.error('Error writing to Firestore:', err);
  } finally {
    process.exit(0);
  }
})();
