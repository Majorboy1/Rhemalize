const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

// Initialize the Firebase Admin SDK
initializeApp();

exports.sendSermonNotification = onDocumentCreated("sermons/{sermonId}", async (event) => {
    // 1. Get the data from the new sermon document
    const snapshot = event.data;
    if (!snapshot) return null;
    
    const sermonData = snapshot.data();
    const sermonTitle = sermonData.title || "New Sermon Available";

    // 2. Define the notification payload
    const message = {
        notification: {
            title: "New Sermon Uploaded! 📖",
            body: `Listen now: ${sermonTitle}`,
        },
        // This targets everyone who subscribed to 'new_sermons' in your Flutter app
        topic: "new_sermons", 
        android: {
            notification: {
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
        },
    };

    // 3. Send the message
    try {
        const response = await getMessaging().send(message);
        console.log("Successfully sent message:", response);
    } catch (error) {
        console.log("Error sending message:", error);
    }
});