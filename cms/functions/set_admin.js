const admin = require('firebase-admin');

// Initialize with default credentials
admin.initializeApp({
  projectId: "church-mobile-a1758" // using the project ID from earlier
});

const uid = 'JY7zakFQdIVATigkX7KAlZQnzOr1';

async function setAdmin() {
  try {
    await admin.auth().setCustomUserClaims(uid, {
      branchId: 'default-branch',
      roleId: 'leadPastor'
    });
    console.log(`Success! leadPastor claims set for ${uid}`);
    process.exit(0);
  } catch (error) {
    console.error('Error setting claims:', error);
    process.exit(1);
  }
}

setAdmin();
