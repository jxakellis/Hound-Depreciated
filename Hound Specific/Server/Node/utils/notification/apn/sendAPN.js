const apn = require('apn');
const { apnLogger } = require('../../logging/pino');

const { formatArray, areAllDefined } = require('../../database/validateFormat');

const { apnProvider } = require('./apnProvider');
const { getUserToken, getAllFamilyMemberTokens, getOtherFamilyMemberTokens } = require('./apnTokens');

/**
 * Creates a notification that is immediately sent to Apple Push Services and informs users
 * Takes an array of notificationTokens that identifies all the recipients of the notification
 * Takes a string that will be the title of the notification
 * Takes a string that will be the body of the notification
 */
const sendAPN = (recipientTokens, category, alertTitle, alertBody) => {
  const tokens = formatArray(recipientTokens);

  // the tokens array is defined and has at least one element
  if (areAllDefined([tokens, category, alertTitle, alertBody]) === true && tokens.length >= 1) {
    // https://github.com/node-apn/node-apn/blob/master/doc/notification.markdown
  // https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification#2990112

    const notification = new apn.Notification();

    // Properties are sent along side the payload and are defined by node-apn

    // App Bundle Id
    notification.topic = 'com.example.Pupotty';

    // A UNIX timestamp when the notification should expire. If the notification cannot be delivered to the device, APNS will retry until it expires
    // An expiry of 0 indicates that the notification expires immediately, therefore no retries will be attempted.
    notification.expiry = Math.floor(Date.now() / 1000) + 300;

    // The type of the notification. The value of this header is alert or background. Specify alert when the delivery of your notification displays an alert, plays a sound, or badges your app's icon. Specify background for silent notifications that do not interact with the user.
    // The value of this header must accurately reflect the contents of your notification's payload. If there is a mismatch, or if the header is missing on required systems, APNs may delay the delivery of the notification or drop it altogether.
    notification.pushType = 'alert';

    // Multiple notifications with same collapse identifier are displayed to the user as a single notification. The value should not exceed 64 bytes.
    // notification.collapseId = 1;

    /// Raw Payload takes after apple's definition of the APS body
    notification.rawPayload = {
      aps: {
      // TO DO create categories for the notifications
      // The notification’s type
      // This string must correspond to the identifier of one of the UNNotificationCategory objects you register at launch time.
        category,
        // The background notification flag.
        // To perform a silent background update, specify the value 1 and don’t include the alert, badge, or sound keys in your payload.
        'content-available': 1,
        // The notification service app extension flag
        // If the value is 1, the system passes the notification to your notification service app extension before delivery.
        // Use your extension to modify the notification’s content.
        'mutable-content': 1,
        // A string that indicates the importance and delivery timing of a notification
        // The string values “passive”, “active”, “time-sensitive”, or “critical” correspond to the
        'interruption-level': 'active',
        // The number to display in a badge on your app’s icon. Specify 0 to remove the current badge, if any.
        // badge: 0,
        // sound Dictionary
        // sound: {
        // The critical alert flag. Set to 1 to enable the critical alert.
        // critical: 0,
        // The name of a sound file in your app’s main bundle or in the Library/Sounds folder of your app’s container directory. Specify the string “default” to play the system sound.
        // name: 'default',
        // The volume for the critical alert’s sound. Set this to a value between 0 (silent) and 1 (full volume).
        // volume: 1,
        // },
        // alert Dictionary
        alert: {
        // The title of the notification. Apple Watch displays this string in the short look notification interface. Specify a string that’s quickly understood by the user.
          title: alertTitle,
          // The content of the alert message.
          body: alertBody,
        },
      },
    };

    // aps Dictionary Keys
    // https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification#2943363

    // alert Dictionary Keys
    // https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification#2943365

    // sound Dictionary Keys
    // https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification#2990112

    apnProvider.send(notification, tokens).then((response) => {
      // response.sent: Array of device tokens to which the notification was sent succesfully
      if (response.sent.length !== 0) {
        apnLogger.info(`Response Sent (successful): ${JSON.stringify(response.sent)}`);
      }
      // response.failed: Array of objects containing the device token (`device`) and either an `error`, or a `status` and `response` from the API
      if (response.failed.length !== 0) {
        apnLogger.info(`Response Failed (rejected): ${JSON.stringify(response.failed)}`);
      }
    }).catch((error) => {
      apnLogger.error(`Response Failed (error): ${JSON.stringify(error)}`);
    });
  }
};

/**
* Takes a userId and retrieves the userNotificationToken for the user
* Invokes sendAPN with the tokens, alertTitle, and alertBody
*/
const sendAPNForUser = async (userId, category, alertTitle, alertBody) => {
  apnLogger.info(`sendAPNForUser ${userId}, ${category}, ${alertTitle}, ${alertBody}`);

  try {
    // get tokens of all qualifying family members that aren't the user
    const tokens = formatArray(await getUserToken(userId));

    // sendAPN if there are > 0 user notification tokens
    if (areAllDefined([tokens, category, alertTitle, alertBody]) && tokens.length !== 0) {
      sendAPN(tokens, category, alertTitle, alertBody);
    }
  }
  catch (error) {
    apnLogger.error(`sendAPNForUser ${JSON.stringify(error)}`);
  }
};

/**
 * Takes a familyId and retrieves the userNotificationToken for all familyMembers
 * Invokes sendAPN with the tokens, alertTitle, and alertBody
 */
const sendAPNForFamily = async (familyId, category, alertTitle, alertBody) => {
  apnLogger.info(`sendAPNForFamily ${familyId}, ${category}, ${alertTitle}, ${alertBody}`);

  try {
    // get notification tokens of all qualifying family members
    const tokens = formatArray(await getAllFamilyMemberTokens(familyId));
    // sendAPN if there are > 0 user notification tokens
    if (areAllDefined([tokens, category, alertTitle, alertBody]) && tokens.length !== 0) {
      sendAPN(tokens, category, alertTitle, alertBody);
    }
  }
  catch (error) {
    apnLogger.error(`sendAPNForFamily ${JSON.stringify(error)}`);
  }
};

/**
 * Takes a familyId and retrieves the userNotificationToken for all familyMembers (excluding the userId provided)
 * Invokes sendAPN with the tokens, alertTitle, and alertBody
 */
const sendAPNForFamilyExcludingUser = async (userId, familyId, category, alertTitle, alertBody) => {
  apnLogger.info(`sendAPNForFamilyExcludingUser ${userId}, ${familyId}, ${category}, ${alertTitle}, ${alertBody}`);
  // get tokens of all qualifying family members that aren't the user
  const tokens = formatArray(await getOtherFamilyMemberTokens(userId, familyId));
  // sendAPN if there are > 0 user notification tokens
  if (areAllDefined([tokens, category, alertTitle, alertBody]) && tokens.length !== 0) {
    try {
      sendAPN(tokens, category, alertTitle, alertBody);
    }
    catch (error) {
      apnLogger.error(`sendAPNForFamilyExcludingUser ${JSON.stringify(error)}`);
    }
  }
};

module.exports = {
  sendAPNForUser, sendAPNForFamily, sendAPNForFamilyExcludingUser,
};