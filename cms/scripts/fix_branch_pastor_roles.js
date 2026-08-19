#!/usr/bin/env node
/**
 * Migration: Fix existing branch pastor accounts
 * 
 * This script updates any /users documents where roleId == 'leadPastor'
 * AND branchId != 'default-branch' to roleId = 'branchPastor'.
 * 
 * Run with: node fix_branch_pastor_roles.js
 */

const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize with application default credentials
initializeApp({ credential: applicationDefault(), projectId: 'church-mobile-a1758' });
const db = getFirestore();

async function migrate() {
  console.log('🔍 Finding branch pastor accounts with wrong roleId...');

  const snapshot = await db.collection('users')
    .where('roleId', '==', 'leadPastor')
    .get();

  let fixed = 0;
  const batch = db.batch();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    // Skip main branch (HQ) users — only fix sub-branch pastors
    if (data.branchId && data.branchId !== 'default-branch') {
      console.log(`  Fixing: ${data.email} (branchId: ${data.branchId})`);
      batch.update(doc.ref, { roleId: 'branchPastor' });

      // Also seed branchPastor role in their branch if missing
      const roleRef = db.collection('branches').doc(data.branchId).collection('roles').doc('branchPastor');
      batch.set(roleRef, {
        name: 'Branch Pastor',
        permissions: [
          'isBranchPastor',
          'manageMembers',
          'recordAttendance',
          'manageEvents',
          'recordIncome',
          'createBudgetRequest',
          'createExpenditureRequest',
          'sendIncomeReport',
          'viewBranchReports',
        ],
      }, { merge: true });

      fixed++;
    }
  }

  if (fixed === 0) {
    console.log('✅ No accounts needed fixing.');
    return;
  }

  await batch.commit();
  console.log(`✅ Fixed ${fixed} branch pastor account(s).`);
}

migrate().catch(console.error);
