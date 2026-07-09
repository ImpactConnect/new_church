const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// Helper to get effective date of an event, matching Dart logic
function getEffectiveDate(startDate, endDate, recurrence) {
    // We use server's local time for evaluation, assuming server time aligns with the target audience (or adjusted if needed).
    const now = new Date();
    if (recurrence === 'daily') {
        if (now > endDate || now > startDate) {
            let next = new Date(now.getFullYear(), now.getMonth(), now.getDate(), startDate.getHours(), startDate.getMinutes());
            if (now > next) {
                next.setDate(next.getDate() + 1);
            }
            return next;
        }
    }
    return startDate;
}

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
    let celebrantsCache = [];

    membersSnapshot.forEach(doc => {
      const data = doc.data();
      
      // Check Birthdays
      if (data.birthDate) {
        const bDateStr = data.birthDate.toDate().toLocaleString("en-US", {timeZone: "Africa/Lagos"});
        const bDate = new Date(bDateStr);
        if (bDate.getMonth() + 1 === currentMonth && bDate.getDate() === currentDay) {
          birthdayUsers.push(data.name);
          celebrantsCache.push({ id: doc.id, ...data, isBirthday: true });
        }
      }

      // Check Anniversaries
      if (data.weddingDate) {
        const wDateStr = data.weddingDate.toDate().toLocaleString("en-US", {timeZone: "Africa/Lagos"});
        const wDate = new Date(wDateStr);
        if (wDate.getMonth() + 1 === currentMonth && wDate.getDate() === currentDay) {
          anniversaryUsers.push(data.name);
          celebrantsCache.push({ id: doc.id, ...data, isBirthday: false });
        }
      }
    });

    // Save to daily_cache
    await admin.firestore().collection('daily_cache').doc('celebrants').set({
      date: admin.firestore.FieldValue.serverTimestamp(),
      celebrants: celebrantsCache
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

// 3. Process Admin Tasks (e.g., Password Reset)
exports.processAdminTasks = functions.firestore
  .document('admin_tasks/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();

    if (data.type === 'password_reset') {
      try {
        const userRecord = await admin.auth().getUserByEmail(data.email);
        await admin.auth().updateUser(userRecord.uid, {
          password: data.newPassword
        });
        
        console.log(`Successfully updated password for user: ${data.email}`);
        return snap.ref.update({ status: 'completed', completedAt: admin.firestore.FieldValue.serverTimestamp() });
      } catch (error) {
        console.error('Error updating user password:', error);
        return snap.ref.update({ status: 'failed', error: error.toString() });
      }
    }
    
    return null;
});

// 4. Runs every day at 8:00 AM to notify about today's events
exports.dailyEventNotifications = functions.pubsub.schedule('0 8 * * *')
  .timeZone('Africa/Lagos')
  .onRun(async (context) => {
    const eventsSnapshot = await admin.firestore().collection('events').get();
    
    // Get current date in Nigeria Time
    const todayStr = new Date().toLocaleString("en-US", {timeZone: "Africa/Lagos"});
    const today = new Date(todayStr);

    let todaysEvents = [];
    eventsSnapshot.forEach(doc => {
      const data = doc.data();
      const startDate = data.startDate.toDate();
      const endDate = data.endDate.toDate();
      const effective = getEffectiveDate(startDate, endDate, data.recurrence || 'none');
      
      const effStr = effective.toLocaleString("en-US", {timeZone: "Africa/Lagos"});
      const effDate = new Date(effStr);

      if (effDate.getFullYear() === today.getFullYear() && 
          effDate.getMonth() === today.getMonth() && 
          effDate.getDate() === today.getDate()) {
        todaysEvents.push(data);
      }
    });

    for (let event of todaysEvents) {
      const title = event.title || 'Event Today';
      const time = event.programmeTime || '';
      await admin.messaging().send({
        notification: {
            title: `📅 Happening Today: ${title}`,
            body: `Don't forget about ${title} happening today${time ? ' at ' + time : ''}.`
        },
        topic: 'all'
      });
    }
    return null;
});

// 5. Runs every 10 minutes to notify about events starting in the next 10-20 minutes
exports.upcomingEventNotifications = functions.pubsub.schedule('*/10 * * * *')
  .onRun(async (context) => {
    const eventsSnapshot = await admin.firestore().collection('events').get();
    const now = new Date();
    // Look ahead 10-20 minutes from now
    const targetStart = new Date(now.getTime() + 10 * 60000);
    const targetEnd = new Date(now.getTime() + 20 * 60000);

    let upcomingEvents = [];
    eventsSnapshot.forEach(doc => {
      const data = doc.data();
      const startDate = data.startDate.toDate();
      const endDate = data.endDate.toDate();
      const effective = getEffectiveDate(startDate, endDate, data.recurrence || 'none');
      
      if (effective >= targetStart && effective < targetEnd) {
        upcomingEvents.push({ id: doc.id, ...data });
      }
    });

    for (let event of upcomingEvents) {
      // Check if we already notified for this event instance
      const cacheRef = admin.firestore().collection('notification_cache').doc(`${event.id}_${now.getFullYear()}${now.getMonth()}${now.getDate()}_${now.getHours()}`);
      const cacheDoc = await cacheRef.get();
      if (!cacheDoc.exists) {
        const title = event.title || 'Upcoming Event';
        await admin.messaging().send({
          notification: {
              title: `⏰ Starting Soon: ${title}`,
              body: `${title} is starting in 10 minutes at ${event.venue || 'its venue'}.`
          },
          topic: 'all'
        });
        await cacheRef.set({ sentAt: admin.firestore.FieldValue.serverTimestamp() });
      }
    }
    return null;
});
