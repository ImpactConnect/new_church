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

    const membersSnapshot = await admin.firestore().collection('branches').doc('default-branch').collection('members').get();
    // Also read from flat top-level members (Admin Panel creates members here)
    const flatMembersSnapshot = await admin.firestore().collection('members').get();

    // Merge both snapshots, deduplicate by doc.id (branch data takes priority)
    const allDocsMap = new Map();
    flatMembersSnapshot.forEach(doc => allDocsMap.set(doc.id, doc));
    membersSnapshot.forEach(doc => allDocsMap.set(doc.id, doc)); // branch overrides flat
    const allDocs = Array.from(allDocsMap.values());

    let birthdayUsers = [];
    let anniversaryUsers = [];
    let celebrantsCache = [];

    allDocs.forEach(doc => {
      const data = doc.data();
      const name = (data.name || `${data.firstName || ''} ${data.lastName || ''}`).trim() || 'Member';

      // Check Birthdays — CMS uses 'dob', Admin Panel uses 'birthDate'
      const rawDob = data.dob || data.birthDate;
      if (rawDob) {
        try {
          const bDateObj = rawDob.toDate ? rawDob.toDate() : new Date(rawDob);
          const bDateStr = bDateObj.toLocaleString("en-US", {timeZone: "Africa/Lagos"});
          const bDate = new Date(bDateStr);
          if (bDate.getMonth() + 1 === currentMonth && bDate.getDate() === currentDay) {
            birthdayUsers.push(name);
            celebrantsCache.push({ id: doc.id, name, ...data, isBirthday: true });
          }
        } catch (_) {}
      }

      // Check Anniversaries
      if (data.weddingDate) {
        try {
          const wDateObj = data.weddingDate.toDate ? data.weddingDate.toDate() : new Date(data.weddingDate);
          const wDateStr = wDateObj.toLocaleString("en-US", {timeZone: "Africa/Lagos"});
          const wDate = new Date(wDateStr);
          if (wDate.getMonth() + 1 === currentMonth && wDate.getDate() === currentDay) {
            anniversaryUsers.push(name);
            celebrantsCache.push({ id: doc.id, name, ...data, isBirthday: false });
          }
        } catch (_) {}
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

    if (data.type === 'password_reset' || data.type === 'create_community_user') {
      try {
        let userRecord;
        try {
          userRecord = await admin.auth().getUserByEmail(data.email);
          await admin.auth().updateUser(userRecord.uid, {
            password: data.newPassword,
            displayName: data.displayName || data.name || userRecord.displayName
          });
        } catch (authError) {
          if (authError.code === 'auth/user-not-found') {
            userRecord = await admin.auth().createUser({
              email: data.email,
              password: data.newPassword,
              displayName: data.displayName || data.name || '',
            });
          } else {
            throw authError;
          }
        }
        
        console.log(`Successfully processed admin user task (${data.type}) for: ${data.email}`);
        return snap.ref.update({ status: 'completed', completedAt: admin.firestore.FieldValue.serverTimestamp() });
      } catch (error) {
        console.error('Error processing admin user task:', error);
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

// ─── CMS Setup Functions ──────────────────────────────────────────────────────

const CMS_ROLES = {
  leadPastor: {
    name: 'Lead Pastor',
    permissions: [
      'manageMembers', 'manageRoles', 'manageEvents', 'manageDepartments',
      'approveAnnouncement', 'approveBudget', 'approveExpenditure',
      'viewFinancialReports', 'viewNonFinancialReports', 'sendNotifications',
    ],
    scope: { type: 'branch' },
  },
  secretary: {
    name: 'Secretary',
    permissions: [
      'manageMembers', 'recordAttendance', 'manageEvents', 'manageDepartments',
      'createAnnouncement', 'logCorrespondence', 'manageAssetPhysical',
      'viewNonFinancialReports',
    ],
    scope: { type: 'branch' },
  },
  financeDept: {
    name: 'Finance Department',
    permissions: [
      'recordIncome', 'createBudgetRequest', 'createExpenditureRequest',
      'recordDisbursement', 'manageAssetFinancial', 'viewFinancialReports',
    ],
    scope: { type: 'branch' },
  },
};

/**
 * One-time setup: seeds the CMS branch + roles, then sets custom claims
 * for the Lead Pastor UID provided via query param.
 * Usage: GET /seedCmsSetup?uid=<LEAD_PASTOR_UID>&secret=churchcms2024
 */
exports.seedCmsSetup = functions.https.onRequest(async (req, res) => {
  if (req.query.secret !== 'churchcms2024') {
    res.status(403).send('Forbidden');
    return;
  }

  const uid = req.query.uid;
  const branchId = req.query.branchId || 'default-branch';

  try {
    const db = admin.firestore();
    const auth = admin.auth();

    // 1. Create/update branch document
    await db.collection('branches').doc(branchId).set({
      name: 'Main Branch',
      address: '',
      phone: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // 2. Seed roles
    const batch = db.batch();
    for (const [roleId, roleData] of Object.entries(CMS_ROLES)) {
      const ref = db.collection('branches').doc(branchId).collection('roles').doc(roleId);
      batch.set(ref, roleData, { merge: true });
    }
    await batch.commit();

    // 3. Set custom claims (if UID provided)
    if (uid) {
      await auth.setCustomUserClaims(uid, { branchId, roleId: 'leadPastor' });
      const user = await auth.getUser(uid);
      res.status(200).json({
        success: true,
        message: 'CMS setup complete!',
        branchId,
        uid,
        claims: user.customClaims,
        rolesSeeded: Object.keys(CMS_ROLES),
      });
    } else {
      res.status(200).json({
        success: true,
        message: 'Branch and roles seeded. No UID provided, skipped claims.',
        branchId,
        rolesSeeded: Object.keys(CMS_ROLES),
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Creates Demo Accounts (Lead Pastor, Secretary, Finance) in Firebase Auth
 * with custom claims and populates complete, connected demo data across all modules in Firestore.
 * Usage: GET /seedDemoAccountsAndData?secret=churchcms2024
 */
exports.seedDemoAccountsAndData = functions.https.onRequest(async (req, res) => {
  if (req.query.secret !== 'churchcms2024') {
    res.status(403).send('Forbidden');
    return;
  }

  const branchId = 'default-branch';
  const db = admin.firestore();
  const auth = admin.auth();

  try {
    const accounts = [
      { email: 'lead@churchmobile.com', password: 'password123', displayName: 'Lead Pastor', roleId: 'leadPastor' },
      { email: 'secretary@churchmobile.com', password: 'password123', displayName: 'Sarah Secretary', roleId: 'secretary' },
      { email: 'finance@churchmobile.com', password: 'password123', displayName: 'Frank Finance', roleId: 'financeDept' },
    ];

    const createdAccounts = [];

    for (const acc of accounts) {
      let user;
      try {
        user = await auth.getUserByEmail(acc.email);
        await auth.updateUser(user.uid, { password: acc.password, displayName: acc.displayName });
      } catch (e) {
        user = await auth.createUser({
          email: acc.email,
          password: acc.password,
          displayName: acc.displayName,
        });
      }
      await auth.setCustomUserClaims(user.uid, { branchId, roleId: acc.roleId });
      createdAccounts.push({ email: acc.email, password: acc.password, roleId: acc.roleId, uid: user.uid });
    }

    // 1. Branch
    await db.collection('branches').doc(branchId).set({
      name: 'Grace Cathedral Main Branch',
      address: '123 Kingdom Way, Victoria Island, Lagos',
      phone: '+2348012345678',
      pastorInCharge: 'Lead Pastor',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // 2. Roles
    const rolesBatch = db.batch();
    for (const [roleId, roleData] of Object.entries(CMS_ROLES)) {
      const ref = db.collection('branches').doc(branchId).collection('roles').doc(roleId);
      rolesBatch.set(ref, roleData, { merge: true });
    }
    await rolesBatch.commit();

    // 3. Departments
    const depts = [
      { id: 'dept-choir', name: 'Choir / Music Ministry', departmentType: 'Choir', memberIds: [] },
      { id: 'dept-ushering', name: 'Ushering & Protocol', departmentType: 'Ushering', memberIds: [] },
      { id: 'dept-media', name: 'Media & Technical', departmentType: 'Media', memberIds: [] },
      { id: 'dept-welfare', name: 'Welfare & Care Unit', departmentType: 'Welfare', memberIds: [] },
    ];
    for (const d of depts) {
      await db.collection('branches').doc(branchId).collection('departments').doc(d.id).set(d, { merge: true });
    }

    // 4. Members
    const members = [
      { id: 'mem-1', firstName: 'John', lastName: 'Doe', phone: '+2348031112233', gender: 'male', dob: '1988-05-14', maritalStatus: 'married', departmentIds: ['dept-choir'], joinDate: '2022-01-10', memberStatus: 'active', roleId: null },
      { id: 'mem-2', firstName: 'Mary', lastName: 'Smith', phone: '+2348032223344', gender: 'female', dob: '1992-08-22', maritalStatus: 'single', departmentIds: ['dept-ushering'], joinDate: '2022-03-15', memberStatus: 'active', roleId: null },
      { id: 'mem-3', firstName: 'David', lastName: 'Johnson', phone: '+2348033334455', gender: 'male', dob: '1995-11-03', maritalStatus: 'single', departmentIds: ['dept-media'], joinDate: '2023-02-01', memberStatus: 'active', roleId: null },
      { id: 'mem-4', firstName: 'Grace', lastName: 'Adebayo', phone: '+2348034445566', gender: 'female', dob: '1985-02-19', maritalStatus: 'married', departmentIds: ['dept-welfare'], joinDate: '2021-06-20', memberStatus: 'active', roleId: null },
      { id: 'mem-lead', firstName: 'Lead', lastName: 'Pastor', phone: '+2348012345678', gender: 'male', dob: '1975-01-01', maritalStatus: 'married', departmentIds: [], joinDate: '2020-01-01', memberStatus: 'active', roleId: 'leadPastor' },
      { id: 'mem-sec', firstName: 'Sarah', lastName: 'Secretary', phone: '+2348023456789', gender: 'female', dob: '1990-04-12', maritalStatus: 'single', departmentIds: ['dept-welfare'], joinDate: '2021-01-15', memberStatus: 'active', roleId: 'secretary' },
      { id: 'mem-fin', firstName: 'Frank', lastName: 'Finance', phone: '+2348034567890', gender: 'male', dob: '1984-09-30', maritalStatus: 'married', departmentIds: [], joinDate: '2021-02-01', memberStatus: 'active', roleId: 'financeDept' },
    ];
    for (const m of members) {
      await db.collection('branches').doc(branchId).collection('members').doc(m.id).set({
        ...m,
        dob: new Date(m.dob),
        joinDate: new Date(m.joinDate),
      }, { merge: true });
    }

    // 5. Events & Attendance
    const now = new Date();
    const event1Ref = db.collection('branches').doc(branchId).collection('events').doc('event-sun-service');
    await event1Ref.set({
      title: 'Sunday Celebration & Thanksgiving Service',
      description: 'Join us for an uplifting time in God\'s presence with intense worship and praise.',
      dateTime: now.toISOString(),
      date: admin.firestore.Timestamp.fromDate(now),
      location: 'Main Church Sanctuary',
      category: 'Sunday Service',
      headcount: 142,
      type: 'recurring',
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=SU',
      departmentIds: ['dept-choir', 'dept-ushering', 'dept-media'],
    }, { merge: true });

    await event1Ref.collection('attendance').doc('att-1').set({
      checkedInMemberIds: ['mem-1', 'mem-2', 'mem-3', 'mem-4'],
      totalCount: 142,
      recordedBy: 'Sarah Secretary',
      recordedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    const event2Ref = db.collection('branches').doc(branchId).collection('events').doc('event-midweek');
    await event2Ref.set({
      title: 'Midweek Power Service & Bible Study',
      description: 'Deep dive into spiritual warfare and biblical truths for daily victory.',
      dateTime: now.toISOString(),
      date: admin.firestore.Timestamp.fromDate(now),
      location: 'Faith Chapel / Online Stream',
      category: 'Midweek',
      headcount: 85,
      type: 'recurring',
      recurrenceRule: 'FREQ=WEEKLY;BYDAY=WE',
      departmentIds: ['dept-media'],
    }, { merge: true });

    await event2Ref.collection('attendance').doc('att-2').set({
      checkedInMemberIds: ['mem-1', 'mem-4'],
      totalCount: 85,
      recordedBy: 'Sarah Secretary',
      recordedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Demographic Service Attendance Records (4 past weeks)
    const attRecsCol = db.collection('branches').doc(branchId).collection('attendance_records');
    const d1 = new Date(now); d1.setDate(d1.getDate() - 21);
    const d2 = new Date(now); d2.setDate(d2.getDate() - 14);
    const d3 = new Date(now); d3.setDate(d3.getDate() - 7);
    const d4 = new Date(now);

    await attRecsCol.doc('rec-sun-1').set({
      eventId: 'event-sun-service',
      eventName: 'Sunday Celebration & Thanksgiving Service',
      eventCategory: 'Sunday Service',
      date: d1.toISOString(),
      dayType: 'weekend',
      male: 52, female: 68, adult: 75, youth: 30, children: 15, total: 120,
      recordedBy: 'secretary', recordedByName: 'Sarah Secretary',
      createdAt: d1.toISOString(),
    }, { merge: true });

    await attRecsCol.doc('rec-mid-1').set({
      eventId: 'event-midweek',
      eventName: 'Midweek Power Service & Bible Study',
      eventCategory: 'Midweek',
      date: d2.toISOString(),
      dayType: 'weekday',
      male: 30, female: 45, adult: 55, youth: 15, children: 5, total: 75,
      recordedBy: 'secretary', recordedByName: 'Sarah Secretary',
      createdAt: d2.toISOString(),
    }, { merge: true });

    await attRecsCol.doc('rec-sun-2').set({
      eventId: 'event-sun-service',
      eventName: 'Sunday Celebration & Thanksgiving Service',
      eventCategory: 'Sunday Service',
      date: d3.toISOString(),
      dayType: 'weekend',
      male: 60, female: 75, adult: 85, youth: 35, children: 15, total: 135,
      recordedBy: 'secretary', recordedByName: 'Sarah Secretary',
      createdAt: d3.toISOString(),
    }, { merge: true });

    await attRecsCol.doc('rec-sun-3').set({
      eventId: 'event-sun-service',
      eventName: 'Sunday Celebration & Thanksgiving Service',
      eventCategory: 'Sunday Service',
      date: d4.toISOString(),
      dayType: 'weekend',
      male: 64, female: 78, adult: 90, youth: 36, children: 16, total: 142,
      recordedBy: 'secretary', recordedByName: 'Sarah Secretary',
      createdAt: d4.toISOString(),
    }, { merge: true });

    // 6. Announcements
    await db.collection('branches').doc(branchId).collection('announcements').doc('ann-1').set({
      title: 'Annual Thanksgiving Convention 2026',
      body: 'Join us for 3 days of powerful worship, word, and blessings from Nov 15th - 17th.',
      originalBody: 'Join us for 3 days of worship.',
      approvedBody: 'Join us for 3 days of powerful worship, word, and blessings from Nov 15th - 17th.',
      status: 'approved',
      createdBy: 'Sarah Secretary',
      approvedBy: 'Lead Pastor',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      smsTriggered: true,
    }, { merge: true });

    await db.collection('branches').doc(branchId).collection('announcements').doc('ann-2').set({
      title: 'Community Welfare & Food Bank Distribution',
      body: 'The Welfare team will be distributing food items to widows and families this Saturday.',
      originalBody: 'The Welfare team will be distributing food items to widows and families this Saturday.',
      status: 'pending',
      createdBy: 'Sarah Secretary',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // 7. Correspondence
    await db.collection('branches').doc(branchId).collection('correspondence').doc('corr-1').set({
      type: 'Incoming Letter',
      summary: 'Official Notification regarding Annual Conference from National Headquarters',
      source: 'National HQ Office',
      documentedBy: 'Sarah Secretary',
      date: admin.firestore.Timestamp.fromDate(now),
      viewedByPastor: true,
      viewedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await db.collection('branches').doc(branchId).collection('correspondence').doc('corr-2').set({
      type: 'Community Request',
      summary: 'Request for venue partnership for Community Health Outreach Day',
      source: 'Local Government Council',
      documentedBy: 'Sarah Secretary',
      date: admin.firestore.Timestamp.fromDate(now),
      viewedByPastor: false,
    }, { merge: true });

    // 8. Income & Giving
    await db.collection('branches').doc(branchId).collection('income').doc('inc-1').set({
      amount: 450000,
      source: 'Sunday Service Offering & Tithes',
      formType: 'transfer',
      comment: 'Direct bank transfer from Sunday service collections',
      recordedBy: 'Frank Finance',
      date: admin.firestore.Timestamp.fromDate(now),
    }, { merge: true });

    await db.collection('branches').doc(branchId).collection('income').doc('inc-2').set({
      amount: 250000,
      source: 'Midweek Service Collection',
      formType: 'cash',
      comment: 'Cash count lodged in bank account',
      recordedBy: 'Frank Finance',
      date: admin.firestore.Timestamp.fromDate(now),
    }, { merge: true });

    await db.collection('branches').doc(branchId).collection('giving').doc('giv-1').set({
      memberId: 'mem-1',
      type: 'tithe',
      amount: 50000,
      date: admin.firestore.Timestamp.fromDate(now),
      recordedBy: 'Frank Finance',
    }, { merge: true });

    await db.collection('branches').doc(branchId).collection('giving').doc('giv-2').set({
      memberId: 'mem-4',
      type: 'pledge',
      amount: 100000,
      date: admin.firestore.Timestamp.fromDate(now),
      recordedBy: 'Frank Finance',
    }, { merge: true });

    // 9. Budgets
    await db.collection('branches').doc(branchId).collection('budgets').doc('bud-1').set({
      fiscalPeriod: '2026-Q4',
      departmentId: 'dept-media',
      category: 'Media & Tech Upgrade',
      requestedAmount: 1200000,
      approvedAmount: 1000000,
      status: 'approved',
      requestedBy: 'Frank Finance',
      approvedBy: 'Lead Pastor',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      changesSummary: [{ field: 'approvedAmount', from: 1200000, to: 1000000 }],
    }, { merge: true });

    await db.collection('branches').doc(branchId).collection('budgets').doc('bud-2').set({
      fiscalPeriod: '2026-Q4',
      departmentId: 'dept-welfare',
      category: 'Christmas Outreach & Welfare Drive',
      requestedAmount: 450000,
      status: 'pending',
      requestedBy: 'Frank Finance',
    }, { merge: true });

    // 10. Expenditure Requests & Official Expenditure Ledger
    await db.collection('branches').doc(branchId).collection('expenditureRequests').doc('exp-req-1').set({
      amount: 1000000,
      category: 'Media Equipment',
      description: 'Purchase of 4K PTZ Camera and Audio Mixer Console',
      requestedBy: 'Frank Finance',
      status: 'approved',
      approvedAmount: 1000000,
      approvedCategory: 'Media Equipment',
      approvedDescription: 'Purchase of 4K PTZ Camera and Audio Mixer Console',
      approvedBy: 'Lead Pastor',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    const expLedgerRef = db.collection('branches').doc(branchId).collection('expenditures').doc('exp-ledger-1');
    await expLedgerRef.set({
      approvedAmount: 1000000,
      category: 'Media Equipment',
      description: 'Purchase of 4K PTZ Camera and Audio Mixer Console',
      approvedBy: 'Lead Pastor',
      sourceRequestId: 'exp-req-1',
      date: admin.firestore.Timestamp.fromDate(now),
      totalDisbursed: 600000,
      status: 'partially-disbursed',
    }, { merge: true });

    await expLedgerRef.collection('disbursements').doc('disb-1').set({
      amountDisbursed: 600000,
      date: admin.firestore.Timestamp.fromDate(now),
      recipientName: 'ProAudio Tech Nigeria Ltd',
      purpose: 'Downpayment for 4K Streaming Camera & Accessories',
      disbursedBy: 'Frank Finance',
    }, { merge: true });

    // 11. Assets (Split Ownership)
    await db.collection('branches').doc(branchId).collection('assets').doc('asset-1').set({
      itemName: 'Yamaha Montage 8 Digital Workstation',
      quantity: 1,
      condition: 'Excellent',
      location: 'Main Choir Stage',
      assignedDepartment: 'dept-choir',
      lastMaintenanceDate: '2026-06-10',
      purchaseValue: 1850000,
      purchaseDate: '2024-03-15',
      vendor: 'SoundWorks Electronics Ltd',
    }, { merge: true });

    await db.collection('branches').doc(branchId).collection('assets').doc('asset-2').set({
      itemName: '4K Studio Live Streaming Camera',
      quantity: 2,
      condition: 'Good',
      location: 'Media Control Gallery',
      assignedDepartment: 'dept-media',
      lastMaintenanceDate: '2026-07-20',
      purchaseValue: 600000,
      purchaseDate: '2026-08-14',
      vendor: 'ProAudio Tech Nigeria Ltd',
    }, { merge: true });

    // 12. Audit Logs
    await db.collection('branches').doc(branchId).collection('auditLogs').doc('log-1').set({
      module: 'system',
      documentId: 'seed',
      action: 'seed_demo_environment',
      performedBy: 'system',
      performedByName: 'System Initializer',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      before: null,
      after: { status: 'complete' },
    }, { merge: true });

    res.status(200).json({
      success: true,
      message: 'Demo accounts and connected Firestore dataset seeded successfully!',
      accountsCreated: createdAccounts,
      modulesSeeded: [
        'branches', 'roles', 'departments', 'members',
        'events', 'attendance', 'announcements', 'correspondence',
        'income', 'giving', 'budgets', 'expenditures',
        'disbursements', 'assets', 'auditLogs'
      ]
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// ── CMS → Mobile App Member Sync ─────────────────────────────────────────────
// Firestore trigger: whenever a member doc is created/updated/deleted in the
// CMS branch collection, mirror the data into the flat root-level 'members'
// collection that the Mobile App and Admin Panel consume.

/**
 * Maps CMS member fields to the flat mobile-app-friendly schema.
 * Preserves any existing mobile-specific fields (username, role, etc.)
 * that may already be on the flat doc.
 */
async function mapCmsMemberToFlat(cmsMemberId, cmsData, branchId) {
  const db = admin.firestore();

  // Resolve department IDs to department names for churchGroups
  let churchGroups = [];
  const deptIds = cmsData.departmentIds || [];
  if (deptIds.length > 0) {
    try {
      const deptSnaps = await Promise.all(
        deptIds.map(id =>
          db.collection('branches').doc(branchId).collection('departments').doc(id).get()
        )
      );
      churchGroups = deptSnaps
        .filter(d => d.exists)
        .map(d => d.data().name || d.id);
    } catch (e) {
      console.warn('Could not resolve department names:', e.message);
      churchGroups = deptIds;
    }
  }

  // Build the flat member doc
  const fullName = `${(cmsData.firstName || '').trim()} ${(cmsData.lastName || '').trim()}`.trim();

  const flatDoc = {
    name: fullName || cmsData.name || '',
    email: cmsData.email || null,
    phoneNumber: cmsData.phone || cmsData.phoneNumber || null,
    gender: cmsData.gender || null,
    maritalStatus: cmsData.maritalStatus || null,
    occupation: cmsData.profession || cmsData.occupation || null,
    address: cmsData.residentAddress || cmsData.address || null,
    memberStatus: cmsData.memberStatus || 'active',
    churchGroups: churchGroups,
    _cmsSync: true,
    _cmsBranchId: branchId,
    _cmsMemberId: cmsMemberId,
    _lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (cmsData.username) flatDoc.username = cmsData.username;
  if (cmsData.role) flatDoc.role = cmsData.role;
  if (cmsData.hasCredentials !== undefined) flatDoc.hasCredentials = cmsData.hasCredentials;
  if (cmsData._authUid) flatDoc._authUid = cmsData._authUid;
  if (cmsData.communityAccountCreated !== undefined) flatDoc.communityAccountCreated = cmsData.communityAccountCreated;
  if (cmsData.hasCommunityAccount !== undefined) flatDoc.hasCommunityAccount = cmsData.hasCommunityAccount;

  // Handle date fields: CMS stores ISO strings or Firestore Timestamps
  if (cmsData.dob) {
    try {
      const dobDate = cmsData.dob.toDate ? cmsData.dob.toDate() : new Date(cmsData.dob);
      if (!isNaN(dobDate.getTime())) {
        flatDoc.birthDate = admin.firestore.Timestamp.fromDate(dobDate);
      }
    } catch (e) { /* skip if invalid */ }
  }

  if (cmsData.weddingDate) {
    try {
      const wDate = cmsData.weddingDate.toDate ? cmsData.weddingDate.toDate() : new Date(cmsData.weddingDate);
      if (!isNaN(wDate.getTime())) {
        flatDoc.weddingDate = admin.firestore.Timestamp.fromDate(wDate);
      }
    } catch (e) { /* skip if invalid */ }
  }

  // Photo URL mapping
  if (cmsData.profileImageUrl) {
    flatDoc.photoUrl = cmsData.profileImageUrl;
    flatDoc.imageUrl = cmsData.profileImageUrl;
  }

  // Preserve CMS-specific fields for reference
  if (cmsData.firstName) flatDoc._cmsFirstName = cmsData.firstName;
  if (cmsData.lastName) flatDoc._cmsLastName = cmsData.lastName;
  if (cmsData.relations) flatDoc._cmsRelations = cmsData.relations;
  if (cmsData.joinDate) flatDoc._cmsJoinDate = cmsData.joinDate;

  return flatDoc;
}

// Trigger: sync on create/update/delete of CMS branch members
exports.syncCmsMemberOnWrite = functions.firestore
  .document('branches/{branchId}/members/{memberId}')
  .onWrite(async (change, context) => {
    const { branchId, memberId } = context.params;
    const db = admin.firestore();
    const flatRef = db.collection('members').doc(memberId);

    // DELETE: member was removed from CMS
    if (!change.after.exists) {
      console.log(`CMS member ${memberId} deleted from branch ${branchId}, removing from flat collection.`);
      try {
        await flatRef.delete();
      } catch (e) {
        console.warn('Could not delete flat member doc:', e.message);
      }
      return null;
    }

    // CREATE or UPDATE: sync CMS data to flat doc
    const cmsData = change.after.data();
    const flatData = await mapCmsMemberToFlat(memberId, cmsData, branchId);

    // Use set with merge to preserve mobile-specific fields like username, role
    await flatRef.set(flatData, { merge: true });
    console.log(`Synced CMS member ${memberId} (${flatData.name}) to flat members collection.`);
    return null;
  });

// One-time callable: bulk sync all CMS members to flat collection
exports.migrateAllCmsMembers = functions.https.onRequest(async (req, res) => {
  const branchId = req.query.branchId || 'default-branch';
  const db = admin.firestore();

  try {
    // 1. Delete all existing flat members (override with CMS data)
    const existingFlat = await db.collection('members').get();
    const batch = db.batch();
    existingFlat.forEach(doc => {
      batch.delete(db.collection('members').doc(doc.id));
    });
    await batch.commit();
    console.log(`Deleted ${existingFlat.size} old flat member docs.`);

    // 2. Sync all CMS members
    const cmsSnap = await db.collection('branches').doc(branchId).collection('members').get();
    let synced = 0;

    for (const doc of cmsSnap.docs) {
      const flatData = await mapCmsMemberToFlat(doc.id, doc.data(), branchId);
      await db.collection('members').doc(doc.id).set(flatData);
      synced++;
    }

    console.log(`Migration complete: synced ${synced} CMS members from branch ${branchId}.`);
    res.status(200).json({
      success: true,
      message: `Migrated ${synced} members from CMS branch '${branchId}' to flat members collection. Deleted ${existingFlat.size} old records.`,
      synced,
      deleted: existingFlat.size,
    });
  } catch (error) {
    console.error('Migration error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Callable: provision staff user with credentials, claims, and Firestore docs
exports.provisionStaffUser = functions.https.onCall(async (data, context) => {
  const { email, password, displayName, roleId, branchId = 'default-branch', phone = '' } = data;
  if (!email || !password || !roleId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields (email, password, roleId)');
  }

  const db = admin.firestore();
  const auth = admin.auth();

  try {
    let user;
    try {
      user = await auth.getUserByEmail(email);
      await auth.updateUser(user.uid, { password, displayName: displayName || email.split('@')[0] });
    } catch (e) {
      user = await auth.createUser({
        email,
        password,
        displayName: displayName || email.split('@')[0],
      });
    }

    // Set Custom Claims
    await auth.setCustomUserClaims(user.uid, { branchId, roleId });

    // Write to /users/{uid}
    await db.collection('users').doc(user.uid).set({
      uid: user.uid,
      email,
      roleId,
      branchId,
      displayName: displayName || email.split('@')[0],
      phone,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Write to /branches/{branchId}/members/{uid}
    const nameParts = (displayName || '').split(' ');
    const firstName = nameParts[0] || 'Staff';
    const lastName = nameParts.slice(1).join(' ') || 'Member';

    await db.collection('branches').doc(branchId).collection('members').doc(user.uid).set({
      firstName,
      lastName,
      email,
      phone,
      roleId,
      isStaff: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true, uid: user.uid, message: `Provisioned staff account for ${email}` };
  } catch (error) {
    console.error('Error provisioning staff user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});


// ═══════════════════════════════════════════════════════════════════════════════
// ── PRIORITY 1: CMS Financial Integrity Cloud Functions ──────────────────────
// These are the server-side guardians that the client CANNOT bypass.
// The UI does pre-checks for fast UX feedback, but these are the REAL authority.
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * P1.1 — onBudgetStatusChange
 * Fires when a budget request status changes to 'approved' or 'rejected'.
 * - Computes changesSummary diff (original vs approved) SERVER-SIDE
 * - Writes Finance notification document
 */
exports.onBudgetStatusChange = functions.firestore
  .document('branches/{branchId}/budgets/{budgetId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { branchId, budgetId } = context.params;

    if (before.status === after.status) return null;
    if (!['approved', 'rejected'].includes(after.status)) return null;

    const db = admin.firestore();
    const requestedBy = after.requestedBy || before.requestedBy;
    if (!requestedBy) return null;

    if (after.status === 'rejected') {
      await db.collection('branches').doc(branchId).collection('financeNotifications').add({
        recipientUid: requestedBy,
        type: 'budget-rejected',
        referenceId: budgetId,
        message: `Your budget request for "${after.category || before.category}" was rejected.${after.rejectionReason ? ' Reason: ' + after.rejectionReason : ''}`,
        changesSummary: [],
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    // Compute changesSummary diff server-side
    const changesSummary = [];
    const origAmount = before.requestedAmount;
    const approvedAmount = after.approvedAmount;
    if (approvedAmount !== undefined && approvedAmount !== null && approvedAmount !== origAmount) {
      changesSummary.push({ field: 'Amount', from: origAmount, to: approvedAmount });
    }
    if (after.approvedCategory && after.approvedCategory !== before.category) {
      changesSummary.push({ field: 'Category', from: before.category, to: after.approvedCategory });
    }
    if (after.approvedDescription && after.approvedDescription !== before.requestedDescription) {
      changesSummary.push({ field: 'Description', from: before.requestedDescription, to: after.approvedDescription });
    }

    // Write the authoritative changesSummary back to the document
    await change.after.ref.update({ changesSummary });

    const notifType = changesSummary.length > 0 ? 'budget-approved-with-changes' : 'budget-approved';
    const finalAmount = approvedAmount ?? before.requestedAmount;
    const message = changesSummary.length > 0
      ? `Your budget for "${after.approvedCategory || after.category}" was approved with changes. Final: ₦${Number(finalAmount).toLocaleString()}.`
      : `Your budget for "${after.category}" was approved. Amount: ₦${Number(finalAmount).toLocaleString()}.`;

    await db.collection('branches').doc(branchId).collection('financeNotifications').add({
      recipientUid: requestedBy,
      type: notifType,
      referenceId: budgetId,
      message,
      changesSummary,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Budget ${budgetId} ${after.status}. Notification sent. Changes: ${changesSummary.length}`);
    return null;
  });


/**
 * P1.2 — onExpenditureRequestStatusChange
 * Fires when expenditure request status changes to 'approved' or 'rejected'.
 * - Computes changesSummary diff server-side
 * - On approval: creates official /expenditures/{id} LEDGER RECORD (server-only)
 * - Writes Finance notification
 */
exports.onExpenditureRequestStatusChange = functions.firestore
  .document('branches/{branchId}/expenditureRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { branchId, requestId } = context.params;

    if (before.status === after.status) return null;
    if (!['approved', 'rejected'].includes(after.status)) return null;

    const db = admin.firestore();
    const requestedBy = after.requestedBy || before.requestedBy;
    if (!requestedBy) return null;

    if (after.status === 'rejected') {
      await db.collection('branches').doc(branchId).collection('financeNotifications').add({
        recipientUid: requestedBy,
        type: 'expenditure-rejected',
        referenceId: requestId,
        message: `Your expenditure request "${after.description || before.description}" was rejected.${after.rejectionReason ? ' Reason: ' + after.rejectionReason : ''}`,
        changesSummary: [],
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    // Compute changesSummary diff
    const changesSummary = [];
    const origAmount = after.originalAmount ?? before.amount;
    const origCategory = after.originalCategory ?? before.category;
    const origDesc = after.originalDescription ?? before.description;

    if (after.approvedAmount !== undefined && after.approvedAmount !== origAmount) {
      changesSummary.push({ field: 'Amount', from: origAmount, to: after.approvedAmount });
    }
    if (after.approvedCategory && after.approvedCategory !== origCategory) {
      changesSummary.push({ field: 'Category', from: origCategory, to: after.approvedCategory });
    }
    if (after.approvedDescription && after.approvedDescription !== origDesc) {
      changesSummary.push({ field: 'Description', from: origDesc, to: after.approvedDescription });
    }

    await change.after.ref.update({ changesSummary });

    // ── SERVER-SIDE ONLY: Create the official expenditure ledger record ──────
    // Idempotency: check if already created for this request
    const existingQuery = await db
      .collection('branches').doc(branchId)
      .collection('expenditures')
      .where('sourceRequestId', '==', requestId)
      .limit(1).get();

    if (existingQuery.empty) {
      await db.collection('branches').doc(branchId).collection('expenditures').add({
        sourceRequestId: requestId,
        approvedAmount: after.approvedAmount ?? after.amount,
        category: after.approvedCategory ?? after.category,
        description: after.approvedDescription ?? after.description,
        approvedBy: after.approvedBy || 'system',
        date: admin.firestore.FieldValue.serverTimestamp(),
        totalDisbursed: 0,
        status: 'not-disbursed',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Created official expenditure ledger record for request ${requestId}`);
    }

    const notifType = changesSummary.length > 0 ? 'expenditure-approved-with-changes' : 'expenditure-approved';
    const finalAmount = after.approvedAmount ?? after.amount;
    const message = changesSummary.length > 0
      ? `Your expenditure "${after.approvedDescription || after.description}" was approved with changes. Final: ₦${Number(finalAmount).toLocaleString()}.`
      : `Your expenditure "${after.description}" was approved. Amount: ₦${Number(finalAmount).toLocaleString()}.`;

    await db.collection('branches').doc(branchId).collection('financeNotifications').add({
      recipientUid: requestedBy,
      type: notifType,
      referenceId: requestId,
      message,
      changesSummary,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`ExpenditureRequest ${requestId} ${after.status}. Changes: ${changesSummary.length}`);
    return null;
  });


/**
 * P1.3 — onDisbursementCreated (CRITICAL FINANCIAL GUARD)
 * Fires on every new disbursement.
 * - Validates against parent expenditure's approvedAmount (server-trusted value)
 * - BLOCKS (deletes) the disbursement if it would exceed approvedAmount
 * - Atomically increments totalDisbursed via FieldValue.increment (race-condition safe)
 * - Updates expenditure status
 */
exports.onDisbursementCreated = functions.firestore
  .document('branches/{branchId}/expenditures/{expenditureId}/disbursements/{disbursementId}')
  .onCreate(async (snap, context) => {
    const { branchId, expenditureId, disbursementId } = context.params;
    const disbData = snap.data();
    const newAmount = Number(disbData.amountDisbursed) || 0;

    const db = admin.firestore();
    const expenditureRef = db
      .collection('branches').doc(branchId)
      .collection('expenditures').doc(expenditureId);

    try {
      const expenditureSnap = await expenditureRef.get();
      if (!expenditureSnap.exists) {
        console.error(`Parent expenditure ${expenditureId} not found. Deleting disbursement.`);
        await snap.ref.delete();
        return null;
      }

      const expData = expenditureSnap.data();
      const approvedAmount = Number(expData.approvedAmount) || 0;
      const currentTotal = Number(expData.totalDisbursed) || 0;
      const newTotal = currentTotal + newAmount;

      // ── OVER-DISBURSEMENT GUARD ──────────────────────────────────────────
      if (newTotal > approvedAmount + 0.01) { // 0.01 tolerance for float rounding
        console.warn(`BLOCKED over-disbursement: ${newTotal} > ${approvedAmount} on expenditure ${expenditureId}`);
        await snap.ref.delete();

        if (disbData.disbursedBy) {
          await db.collection('branches').doc(branchId).collection('financeNotifications').add({
            recipientUid: disbData.disbursedBy,
            type: 'disbursement-over-limit',
            referenceId: expenditureId,
            message: `Disbursement of ₦${Number(newAmount).toLocaleString()} was blocked. It would exceed the approved ₦${Number(approvedAmount).toLocaleString()} (current disbursed: ₦${Number(currentTotal).toLocaleString()}).`,
            changesSummary: [],
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        return null;
      }

      // ── ATOMIC INCREMENT ─────────────────────────────────────────────────
      const newStatus = newTotal >= approvedAmount - 0.01
        ? 'fully-disbursed'
        : 'partially-disbursed';

      await expenditureRef.update({
        totalDisbursed: admin.firestore.FieldValue.increment(newAmount),
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Disbursement OK: +₦${newAmount} → total ₦${newTotal}/₦${approvedAmount} [${newStatus}]`);
    } catch (error) {
      console.error(`Error processing disbursement ${disbursementId}:`, error);
    }
    return null;
  });


// ── P1.4: Generic Audit Log Writer helper ─────────────────────────────────────
async function writeAuditLog(db, branchId, module, documentId, action, before, after) {
  const doc = after || before || {};
  const performedBy = doc.approvedBy || doc.requestedBy || doc.recordedBy ||
    doc.disbursedBy || doc.documentedBy || doc.createdBy || 'system';
  try {
    await db.collection('branches').doc(branchId).collection('auditLogs').add({
      module,
      documentId,
      action,
      before: before || null,
      after: after || null,
      performedBy,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error(`Audit log write failed for ${module}/${documentId}:`, e.message);
  }
}

exports.auditBudgets = functions.firestore
  .document('branches/{branchId}/budgets/{docId}')
  .onWrite(async (change, context) => {
    const { branchId, docId } = context.params;
    const action = !change.before.exists ? 'create' : !change.after.exists ? 'delete' : 'update';
    await writeAuditLog(admin.firestore(), branchId, 'budgets', docId, action,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null);
    return null;
  });

exports.auditExpenditureRequests = functions.firestore
  .document('branches/{branchId}/expenditureRequests/{docId}')
  .onWrite(async (change, context) => {
    const { branchId, docId } = context.params;
    const action = !change.before.exists ? 'create' : !change.after.exists ? 'delete' : 'update';
    await writeAuditLog(admin.firestore(), branchId, 'expenditureRequests', docId, action,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null);
    return null;
  });

exports.auditExpenditures = functions.firestore
  .document('branches/{branchId}/expenditures/{docId}')
  .onWrite(async (change, context) => {
    const { branchId, docId } = context.params;
    const action = !change.before.exists ? 'create' : !change.after.exists ? 'delete' : 'update';
    await writeAuditLog(admin.firestore(), branchId, 'expenditures', docId, action,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null);
    return null;
  });

exports.auditDisbursements = functions.firestore
  .document('branches/{branchId}/expenditures/{expenditureId}/disbursements/{docId}')
  .onWrite(async (change, context) => {
    const { branchId, docId } = context.params;
    const action = !change.before.exists ? 'create' : !change.after.exists ? 'delete' : 'update';
    await writeAuditLog(admin.firestore(), branchId, 'disbursements', docId, action,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null);
    return null;
  });

exports.auditIncome = functions.firestore
  .document('branches/{branchId}/income/{docId}')
  .onWrite(async (change, context) => {
    const { branchId, docId } = context.params;
    const action = !change.before.exists ? 'create' : !change.after.exists ? 'delete' : 'update';
    await writeAuditLog(admin.firestore(), branchId, 'income', docId, action,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null);
    return null;
  });

exports.auditMembers = functions.firestore
  .document('branches/{branchId}/members/{docId}')
  .onWrite(async (change, context) => {
    const { branchId, docId } = context.params;
    const action = !change.before.exists ? 'create' : !change.after.exists ? 'delete' : 'update';
    await writeAuditLog(admin.firestore(), branchId, 'members', docId, action,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null);
    return null;
  });

exports.auditRoles = functions.firestore
  .document('branches/{branchId}/roles/{docId}')
  .onWrite(async (change, context) => {
    const { branchId, docId } = context.params;
    const action = !change.before.exists ? 'create' : !change.after.exists ? 'delete' : 'update';
    await writeAuditLog(admin.firestore(), branchId, 'roles', docId, action,
      change.before.exists ? change.before.data() : null,
      change.after.exists ? change.after.data() : null);
    return null;
  });


/**
 * P3.5 — onAnnouncementApproved
 * Fires when an announcement status becomes 'approved' AND smsTriggered == true.
 * Auto-dispatches bulk SMS via Termii to all branch members.
 * Termii API key is read from app_settings/sms_config (never hardcoded).
 */
exports.onAnnouncementApproved = functions.firestore
  .document('branches/{branchId}/announcements/{announcementId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { branchId, announcementId } = context.params;

    if (before.status === after.status) return null;
    if (after.status !== 'approved') return null;
    if (!after.smsTriggered) return null;
    if (after.smsSentAt) return null; // Idempotency guard

    const db = admin.firestore();

    // Collect phone numbers from branch members
    let phoneNumbers = [];
    try {
      const membersSnap = await db
        .collection('branches').doc(branchId)
        .collection('members').get();
      membersSnap.forEach(doc => {
        const data = doc.data();
        const phone = data.phone || data.phoneNumber;
        if (phone && typeof phone === 'string' && phone.replace(/\D/g, '').length >= 10) {
          let normalized = phone.replace(/\s+/g, '').replace(/[^\d+]/g, '');
          if (normalized.startsWith('0')) normalized = '+234' + normalized.slice(1);
          else if (!normalized.startsWith('+')) normalized = '+234' + normalized;
          phoneNumbers.push(normalized);
        }
      });
    } catch (e) {
      console.error('Failed to fetch members for SMS:', e.message);
    }

    if (phoneNumbers.length === 0) {
      await change.after.ref.update({ smsStatus: 'no_recipients', smsSentAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    }

    // Read Termii config from Firestore (secure — not hardcoded)
    let termiiApiKey = null;
    let termiiSenderId = 'ChurchApp';
    try {
      const settingsDoc = await db.collection('app_settings').doc('sms_config').get();
      if (settingsDoc.exists) {
        termiiApiKey = settingsDoc.data().termiiApiKey;
        termiiSenderId = settingsDoc.data().termiiSenderId || termiiSenderId;
      }
    } catch (e) {
      console.warn('Could not read SMS config:', e.message);
    }

    if (!termiiApiKey) {
      console.warn('No Termii API key in app_settings/sms_config. SMS skipped.');
      await change.after.ref.update({ smsStatus: 'no_api_key', smsSentAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    }

    const smsBody = `${after.title}: ${after.approvedBody || after.body || ''}`.slice(0, 160);
    const https = require('https');
    let sentCount = 0;
    let failedCount = 0;

    // Chunk to 100 numbers per call
    const chunkSize = 100;
    for (let i = 0; i < phoneNumbers.length; i += chunkSize) {
      const chunk = phoneNumbers.slice(i, i + chunkSize);
      const payload = JSON.stringify({
        to: chunk,
        from: termiiSenderId,
        sms: smsBody,
        type: 'plain',
        api_key: termiiApiKey,
        channel: 'generic',
      });
      try {
        await new Promise((resolve, reject) => {
          const req = https.request({
            hostname: 'api.ng.termii.com',
            path: '/api/sms/send/bulk',
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) },
          }, (res) => {
            res.on('data', () => {});
            res.on('end', resolve);
          });
          req.on('error', reject);
          req.write(payload);
          req.end();
        });
        sentCount += chunk.length;
      } catch (e) {
        console.error(`SMS chunk failed:`, e.message);
        failedCount += chunk.length;
      }
    }

    await change.after.ref.update({
      smsStatus: failedCount === 0 ? 'sent' : sentCount > 0 ? 'partial' : 'failed',
      smsSentCount: sentCount,
      smsFailedCount: failedCount,
      smsSentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Announcement SMS ${announcementId}: ${sentCount} sent, ${failedCount} failed.`);
    return null;
  });
