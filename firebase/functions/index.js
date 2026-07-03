const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.database();
const firestore = admin.firestore();

exports.onDeviceAccidentAlert = functions.database
  .ref('/devices/{serial}/status/alert')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    if (before === after || after !== 'ACCIDENT_DETECTED') return null;

    const serial = context.params.serial;
    const statusSnap = await db.ref(`devices/${serial}/status`).once('value');
    const status = statusSnap.val() || {};

    const usersSnap = await firestore
      .collection('users')
      .where('pairedDevice', '==', serial)
      .limit(1)
      .get();

    if (usersSnap.empty) return null;

    const userDoc = usersSnap.docs[0];
    const userData = userDoc.data();
    const token = userData.fcmToken;
    if (!token) return null;

    const message = {
      token,
      notification: {
        title: 'Accident Detected',
        body: 'OnAlert detected a possible accident. Open the app immediately.',
      },
      data: {
        type: 'ACCIDENT_DETECTED',
        lat: String(status.lat ?? '0'),
        lng: String(status.lng ?? '0'),
        serial,
      },
      android: { priority: 'high' },
    };

    await admin.messaging().send(message);
    return null;
  });
