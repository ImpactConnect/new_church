const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({ projectId: 'church-mobile-a1758' });
const db = getFirestore();

// We can't easily test rules without a user token. 
// Instead, let's just use firebase-tools to get the user document for the currently logged in user to see what's actually there.
