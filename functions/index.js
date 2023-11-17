const admin = require("firebase-admin");
const functions = require("firebase-functions");
const createCsvWriter = require("csv-writer").createObjectCsvWriter;

admin.initializeApp();
const db = admin.firestore();

exports.downloadOrders = functions.https.onRequest(async (req, res) => {
  try {
    const dateParam = req.query.date;

    if (!dateParam) {
      return res.status(400).send("Missing date parameter");
    }

    const date = new Date(dateParam);
    const nextDate = new Date(date);
    nextDate.setDate(date.getDate() + 1);

    const prevDate = new Date(date);
    prevDate.setDate(date.getDate() - 1);

    const ordersCollection = db.collection("Orders");
    const querySnapshot = await ordersCollection
        .where("deliveryDate", ">", prevDate)
        .where("deliveryDate", "<", nextDate)
        .where("deliveryDate", "==", date)
        .get();

    const orders = [];
    querySnapshot.forEach((doc) => {
      const orderData = doc.data();
      orders.push({
        orderId: doc.id,
        deliveryDate: orderData.deliveryDate,
        orderName: orderData.orderName,
        numberOfItems: orderData.numberOfItems,
        orderType: orderData.orderType,
      });
    });

    // Convert orders to CSV string
    const csvWriter = createCsvWriter({
      // Cloud Functions have a writeable /tmp directory
      path: "/tmp/orders.csv",
      header: [
        {id: "orderId", title: "Order ID"},
        {id: "deliveryDate", title: "Delivery Date"},
        {id: "orderName", title: "Order Name"},
        {id: "numberOfItems", title: "Number of Items"},
        {id: "orderType", title: "Order Type"},
      ],
    });

    await csvWriter.writeRecords(orders);

    // Return the CSV file as a response
    return res.status(200).download("/tmp/orders"+date+".csv", "orders.csv");
  } catch (error) {
    console.error("Error in downloadOrders function:", error);
    return res.status(500).send("Internal Server Error");
  }
});
