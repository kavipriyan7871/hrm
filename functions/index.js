const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Intha function 'notification_triggers' collection-ai watch pannum
exports.onNotificationTrigger = functions.firestore
    .document('notification_triggers/{triggerId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();

        // Data-vai edukurom (Tokens, Title, Body)
        const recipientTokens = data.tokens;
        const payload = {
            notification: {
                title: data.title,
                body: data.body,
                sound: 'default'
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                groupId: data.groupId || '',
                senderId: data.senderId || ''
            }
        };

        try {
            if (recipientTokens && recipientTokens.length > 0) {
                // FCM moolama notification send pannuroam
                const response = await admin.messaging().sendMulticast({
                    tokens: recipientTokens,
                    notification: payload.notification,
                    data: payload.data
                });

                console.log(`Successfully sent to ${response.successCount} devices.`);
            }

            // Task mudinjathum trigger-ai delete pannidalaam (Cleanup)
            return snapshot.ref.delete();

        } catch (error) {
            console.error("Error sending notification:", error);
            return null;
        }
    });
