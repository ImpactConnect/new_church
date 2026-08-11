const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Creates an immutable audit log entry in /branches/{branchId}/auditLogs
 */
async function writeAuditLog(branchId, moduleName, docId, action, context, before, after) {
  const logRef = db.collection("branches").doc(branchId).collection("auditLogs").doc();
  const performedBy = context.auth ? context.auth.uid : "system";
  
  let performedByName = "System";
  if (context.auth && context.auth.token) {
    performedByName = context.auth.token.name || context.auth.token.email || performedBy;
  }

  await logRef.set({
    module: moduleName,
    documentId: docId,
    action: action,
    performedBy: performedBy,
    performedByName: performedByName,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    before: before || null,
    after: after || null,
  });
}

// ── 1. Audit Members onWrite ──────────────────────────────────────────────────
exports.auditMembers = functions.firestore
  .document("branches/{branchId}/members/{memberId}")
  .onWrite(async (change, context) => {
    const branchId = context.params.branchId;
    const memberId = context.params.memberId;
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    let action = "update";
    if (!before && after) action = "create";
    if (before && !after) action = "delete";

    await writeAuditLog(branchId, "members", memberId, action, context, before, after);
  });

// ── 2. Audit Departments onWrite ──────────────────────────────────────────────
exports.auditDepartments = functions.firestore
  .document("branches/{branchId}/departments/{deptId}")
  .onWrite(async (change, context) => {
    const branchId = context.params.branchId;
    const deptId = context.params.deptId;
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    let action = "update";
    if (!before && after) action = "create";
    if (before && !after) action = "delete";

    await writeAuditLog(branchId, "departments", deptId, action, context, before, after);
  });

// ── 3. Audit Roles onWrite ────────────────────────────────────────────────────
exports.auditRoles = functions.firestore
  .document("branches/{branchId}/roles/{roleId}")
  .onWrite(async (change, context) => {
    const branchId = context.params.branchId;
    const roleId = context.params.roleId;
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    let action = "update";
    if (!before && after) action = "create";
    if (before && !after) action = "delete";

    await writeAuditLog(branchId, "roles", roleId, action, context, before, after);
  });
