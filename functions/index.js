const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// 1. Instantly send notifications requested by the Admin Panel
exports.sendPushNotification = functions.firestore
  .document('push_notifications/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // If it's scheduled for the future, ignore it. 
    // (You would need a separate cron job to process scheduled notifications later)
    if (data.sendAfter) {
      return null; 
    }

    const payload = {
      notification: {
        title: data.title,
        body: data.body,
      },
      topic: data.topic || 'all'
    };

    try {
      await admin.messaging().send(payload);
      console.log(`Successfully sent message: ${data.title}`);
      return snap.ref.update({ status: 'sent', sentAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (error) {
      console.error('Error sending FCM message:', error);
      return snap.ref.update({ status: 'failed', error: error.toString() });
    }
});


// 2. Runs every day at 8:00 AM to check Birthdays and Anniversaries
exports.dailyCelebrationNotifications = functions.pubsub.schedule('0 8 * * *')
  .timeZone('Africa/Lagos') 
  .onRun(async (context) => {
    // Get current date in Nigeria Time
    const todayStr = new Date().toLocaleString("en-US", {timeZone: "Africa/Lagos"});
    const today = new Date(todayStr);
    const currentMonth = today.getMonth() + 1; // JS months are 0-11
    const currentDay = today.getDate();

    const membersSnapshot = await admin.firestore().collection('members').get();
    
    let birthdayUsers = [];
    let anniversaryUsers = [];

    membersSnapshot.forEach(doc => {
      const data = doc.data();
      
      // Check Birthdays
      if (data.birthDate) {
        const bDateStr = data.birthDate.toDate().toLocaleString("en-US", {timeZone: "Africa/Lagos"});
        const bDate = new Date(bDateStr);
        if (bDate.getMonth() + 1 === currentMonth && bDate.getDate() === currentDay) {
          birthdayUsers.push(data.name);
        }
      }

      // Check Anniversaries
      if (data.weddingDate) {
        const wDateStr = data.weddingDate.toDate().toLocaleString("en-US", {timeZone: "Africa/Lagos"});
        const wDate = new Date(wDateStr);
        if (wDate.getMonth() + 1 === currentMonth && wDate.getDate() === currentDay) {
          anniversaryUsers.push(data.name);
        }
      }
    });

    // Send Birthday Notification to all users
    if (birthdayUsers.length > 0) {
      const names = birthdayUsers.join(", ");
      await admin.messaging().send({
        notification: {
            title: '🎉 Happy Birthday!',
            body: `Join us in wishing a very Happy Birthday to ${names} today! God bless your new age.`
        },
        topic: 'all'
      });
    }

    // Send Anniversary Notification
    if (anniversaryUsers.length > 0) {
      const names = anniversaryUsers.join(", ");
      await admin.messaging().send({
        notification: {
            title: '💍 Happy Anniversary!',
            body: `Happy Wedding Anniversary to ${names}! Wishing you more love and joy.`
        },
        topic: 'all'
      });
    }

    return null;
});
