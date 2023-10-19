const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions/logger");
const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();
const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;


exports.createMonthlyMenuEntries = onRequest(async(request, response) => {
    try {
        const monthlyMenuCollection = db.collection("MonthlyMenu");
        const menuEntry = {
            date: null,
            breakfast: [],
            lunch: [],
            dinner: [],
        };

        const currentDate = new Date();
        currentDate.setHours(15, 28, 0, 0);

        const today = {...menuEntry, date: Timestamp.fromDate(currentDate) };

        const addTodayEntry = monthlyMenuCollection.add(today);

        await addTodayEntry;

        logger.info("Monthly menu entry created for today.");

        response.send("Monthly menu entry created for today.");
    } catch (error) {
        console.error("Error:", error);
        response.status(500).send("Internal Server Error");
    }
});

exports.scheduleMonthlyMenuUpdates = functions.pubsub
    .schedule("every 5 minutes")
    .timeZone("GMT+1:00")
    .onRun(async() => {
        const monthlyMenuCollection = db.collection("MonthlyMenu");

        const currentDate = new Date();
        currentDate.setHours(15, 28, 0, 0);

        const nextDate = new Date(currentDate);
        nextDate.setDate(currentDate.getDate() + 1);

        const menuEntry = {
            date: admin.firestore.Timestamp.fromDate(nextDate),
            breakfast: [],
            lunch: [],
            dinner: [],
        };

        const addNextDayEntry = monthlyMenuCollection.add(menuEntry);

        try {
            await addNextDayEntry;
            logger.info("Monthly menu entry created for the next day.");
            return null;
        } catch (error) {
            console.error("Error:", error);
            throw new functions.https.HttpsError("internal",
                "An error occurred while creating the next daily menu entry.");
        }
    });