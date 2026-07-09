const admin = require("firebase-admin");

function getEffectiveDate(startDate, endDate, recurrence) {
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
console.log("Done");
