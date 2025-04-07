const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.setAdminRole = functions.https.onCall(async (data, context) => {
  const uid = data.uid;

  if (!uid) {
    throw new functions.https.HttpsError("invalid-argument", "User ID is required");
  }

  await admin.auth().setCustomUserClaims(uid, { usertype: "admin" });

  return { message: `✅ Admin role set for UID: ${uid}` };
});
