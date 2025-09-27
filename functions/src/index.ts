import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Simple HTTP function
export const helloWorld = functions.https.onRequest((req, res) => {
  res.json({ message: 'Hello from GeoReminders!' });
});

// Firestore trigger: when a doc is created in "reminders" log it and write to reminderLogs
export const onReminderCreate = functions.firestore
  .document('reminders/{reminderId}')
  .onCreate(async (snap, ctx) => {
    const data = snap.data();
    console.log('New reminder created:', ctx.params.reminderId, data);
    try {
      await admin.firestore().collection('reminderLogs').add({
        reminderId: ctx.params.reminderId,
        data,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (err) {
      console.error('Failed to write reminderLog:', err);
    }
  });
