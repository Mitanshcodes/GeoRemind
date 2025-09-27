const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();
(async () => {
  const ref = db.collection('test').doc('smoke');
  await ref.set({ ok: true, ts: new Date().toISOString() });
  const snap = await ref.get();
  console.log('wrote:', snap.data());
})();
