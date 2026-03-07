const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyNewSermon = functions.firestore
    .document('sermons/{sermonId}')
    .onCreate(async (snapshot, context) => {
        const newValue = snapshot.data();

        const message = {
            notification: {
                title: 'New Message Uploaded!',
                body: `${newValue.title} by ${newValue.speaker}`,
            },
            topic: 'new_sermons', // Send to everyone subscribed
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                sermonId: context.params.sermonId,
            }
        };

        try {
            await admin.messaging().send(message);
            console.log('Notification sent successfully');
        } catch (error) {
            console.log('Error sending notification:', error);
        }
    });