const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Callable function to delete a Firebase Auth user.
 * Only callable by authenticated admins (role === 'admin').
 */
exports.deleteAuthUser = onCall(async (request) => {
  // Verify the caller is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  // Verify the caller has admin role via custom claims
  const callerUid = request.auth.uid;
  const callerRecord = await admin.auth().getUser(callerUid);
  const isAdmin =
    callerRecord.customClaims?.role === "admin" ||
    callerRecord.customClaims?.isAdmin === true;

  if (!isAdmin) {
    // Fallback: check Firestore role field
    const callerDoc = await admin
      .firestore()
      .collection("users")
      .doc(callerUid)
      .get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError(
        "permission-denied",
        "Only admins can delete accounts."
      );
    }
  }

  const { uid } = request.data;
  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "A valid uid is required.");
  }

  await admin.auth().deleteUser(uid);
  return { success: true };
});

/**
 * Callable function to bulk-delete Firebase Auth users.
 * Only callable by authenticated admins.
 */
exports.bulkDeleteAuthUsers = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const callerUid = request.auth.uid;
  const callerRecord = await admin.auth().getUser(callerUid);
  const isAdmin =
    callerRecord.customClaims?.role === "admin" ||
    callerRecord.customClaims?.isAdmin === true;

  if (!isAdmin) {
    const callerDoc = await admin
      .firestore()
      .collection("users")
      .doc(callerUid)
      .get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError(
        "permission-denied",
        "Only admins can delete accounts."
      );
    }
  }

  const { uids } = request.data;
  if (!Array.isArray(uids) || uids.length === 0) {
    throw new HttpsError("invalid-argument", "A non-empty uids array is required.");
  }

  // deleteUsers supports up to 1000 uids at once
  const result = await admin.auth().deleteUsers(uids);
  return {
    successCount: result.successCount,
    failureCount: result.failureCount,
    errors: result.errors.map((e) => ({
      index: e.index,
      message: e.error.message,
    })),
  };
});
