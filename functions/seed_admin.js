const admin = require('firebase-admin');

// When loaded in functions:shell, admin is already initialized.
async function seedAdmin() {
  const uid = 'VDC7kEVyB3hOD6GBDNSBGyf464z1';
  
  console.log('Seeding admin user data...');
  
  await admin.firestore().collection('members').doc(uid).set({
    name: 'Admin',
    email: 'dev@churchmobile.com',
    role: 'admin',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  await admin.firestore().collection('admin_users').doc(uid).set({
    role: 'admin',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  console.log('Seeding complete!');
  process.exit(0);
}

seedAdmin().catch(console.error);
