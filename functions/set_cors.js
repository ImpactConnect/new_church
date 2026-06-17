const admin = require('firebase-admin');

// Initialize the app with application default credentials
admin.initializeApp({
  storageBucket: 'church-mobile-a1758.firebasestorage.app'
});

async function setCors() {
  const bucket = admin.storage().bucket();
  const corsConfig = [
    {
      origin: ['*'],
      method: ['GET', 'PUT', 'POST', 'DELETE', 'HEAD', 'OPTIONS'],
      responseHeader: ['Content-Type', 'Authorization', 'Content-Length', 'User-Agent', 'x-goog-resumable'],
      maxAgeSeconds: 3600
    }
  ];

  try {
    await bucket.setCorsConfiguration(corsConfig);
    console.log('CORS configuration successfully updated!');
  } catch (error) {
    console.error('Failed to set CORS:', error);
  }
}

setCors();
