/* eslint-disable linebreak-style */
const axios = require("axios");
const data = {
  Status: "Placed", // Change this to the appropriate order status
  userID: "eGTnucYHvfMWkOLZOdtqPDIQVoq2", // Replace with the user's ID
// eslint-disable-next-line linebreak-style
};
axios.post("https://us-central1-tummybox-f2238.cloudfunctions.net/orderNotification", data)
    .then((response) => {
      console.log(response.data);
    })
    .catch((error) => {
      console.error(error);
    });
