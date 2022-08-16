const { ValidationError } = require('../../main/tools/general/errors');
const { areAllDefined } = require('../../main/tools/format/validateDefined');
const {
  formatNumber, formatDate, formatBoolean, formatString,
} = require('../../main/tools/format/formatObject');

const { getUserForUserApplicationUsername } = require('../getFor/getForUser');
const { getAppStoreServerNotificationForNotificationUUID } = require('../getFor/getForAppStoreServerNotifications');
const { getInAppSubscriptionForTransactionId } = require('../getFor/getForInAppSubscriptions');
const { databaseQuery } = require('../../main/tools/database/databaseQuery');

async function createAppStoreServerNotificationForSignedPayload(databaseConnection, signedPayload) {
  console.log('createAppStoreServerNotificationForSignedPayload');
  if (areAllDefined(databaseConnection, signedPayload) === false) {
    throw new ValidationError('databaseConnection or signedPayload missing', global.constant.error.value.MISSING);
  }
  const signedPayloadBuffer = Buffer.from(signedPayload.split('.')[1], 'base64');
  const notification = JSON.parse(signedPayloadBuffer.toString());

  if (areAllDefined(notification) === false) {
    throw new ValidationError('notification missing', global.constant.error.value.MISSING);
  }

  const {
    // A unique identifier for the notification. Use this value to identify a duplicate notification.
    notificationUUID,
    // The object that contains the app metadata and signed renewal and transaction information.
    data,
  } = notification;

  if (areAllDefined(notificationUUID, data) === false) {
    throw new ValidationError('notificationUUID or data missing', global.constant.error.value.MISSING);
  }

  const {
    // Subscription renewal information signed by the App Store, in JSON Web Signature format.
    signedRenewalInfo,
    // Transaction information signed by the App Store, in JSON Web Signature format.
    signedTransactionInfo,
  } = data;

  if (areAllDefined(signedRenewalInfo, signedTransactionInfo) === false) {
    throw new ValidationError('signedRenewalInfo or signedTransactionInfo missing', global.constant.error.value.MISSING);
  }

  const signedRenewalInfoBuffer = Buffer.from(signedRenewalInfo.split('.')[1], 'base64');
  const renewalInfo = JSON.parse(signedRenewalInfoBuffer.toString());

  const signedTransactionInfoBuffer = Buffer.from(signedTransactionInfo.split('.')[1], 'base64');
  const transactionInfo = JSON.parse(signedTransactionInfoBuffer.toString());

  const storedNotification = await getAppStoreServerNotificationForNotificationUUID(databaseConnection, notificationUUID);

  // Check if we have logged this notification before
  if (areAllDefined(storedNotification)) {
    console.log('Notification has been logged into database, return');
    // Notification has been logged into database, return
    return;
  }

  console.log('Notification hasnt been logged before');

  await createAppStoreServerNotificationForNotification(databaseConnection, notification, data, renewalInfo, transactionInfo);

  console.log('Logged notification');

  const transactionId = formatNumber(transactionInfo.transactionId);

  // Check to see if the notification provided a transactionId
  if (areAllDefined(transactionId) === false) {
    console.log('transactionId doesnt exist');
    return;
  }

  console.log('transactionId exists');

  // If notification provided a transactionId, then attempt to see if we have a transaction stored for that transactionId
  const storedTransaction = await getInAppSubscriptionForTransactionId(databaseConnection, transactionId);

  if (areAllDefined(storedTransaction)) {
    console.log('Update the existing stored subscription with new information recieved');
    // Update the existing stored subscription with new information recieved
  }
  // Insert a new subscription into s
  console.log('Insert a new subscription into subscriptions');

  // Attempt to find a corresponding userId
  const applicationUsername = transactionInfo.appAccountToken;
  let userId;
  if (areAllDefined(applicationUsername)) {
    const user = await getUserForUserApplicationUsername(databaseConnection, applicationUsername);
    userId = areAllDefined(user) ? user.userId : undefined;
  }

  // Couldn't find user because applicationUsername was undefined or because no user had that applicationUsername
  if (areAllDefined(userId) === false) {
    // attempt to find userId with most recent transaction. Use originalTransactionId to link to potential transactions
  }

  // SELECT userId FROM subscriptions WHERE userId IS NOT NULL AND (originalTransationId = originalTransationId OR transactionId = originalTransationId) ORDER BY purchaseDate DESC LIMIT 1; (getForInAppSubscriptions)

  // If userId == undefined, then ValidationError
  // else, find familyId with userId and insert transaction into database (createForAppStoreServerNotification)
}

const appStoreServerNotificationsColumns = 'notificationType, subtype, notificationUUID, version, signedDate, dataAppAppleId, dataBundleId, dataBundleVersion, dataEnvironment, renewalInfoAutoRenewProductId, renewalInfoAutoRenewStatus, renewalInfoExpirationIntent, renewalInfoGracePeriodExpiresDate, renewalInfoIsInBillingRetryPeriod, renewalInfoOfferIdentifier, renewalInfoOfferType, renewalInfoOriginalTransactionId, renewalInfoPriceIncreaseStatus, renewalInfoProductId, renewalInfoRecentSubscriptionStartDate, renewalInfoSignedDate, renewalInfoEnvironment, transactionInfoAppAccountToken, transactionInfoBundleId, transactionInfoEnvironment, transactionInfoExpiresDate, transactionInfoInAppOwnershipType, transactionInfoIsUpgraded, transactionInfoOfferIdentifier, transactionInfoOfferType, transactionInfoOriginalPurchaseDate, transactionInfoOriginalTransactionId, transactionInfoProductId, transactionInfoPurchaseDate, transactionInfoQuantity, transactionInfoRevocationDate, transactionInfoRevocationReason, transactionInfoSignedDate, transactionInfoSubscriptionGroupIdentifier, transactionInfoTransactionId, transactionInfoType, transactionInfoWebOrderLineItemId';
const appStoreServerNotificationsValues = '?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?';

async function createAppStoreServerNotificationForNotification(databaseConnection, notification, data, renewalInfo, transactionInfo) {
  console.log('createAppStoreServerNotificationForNotification');
  if (areAllDefined(databaseConnection, notification, data, renewalInfo, transactionInfo) === false) {
    throw new ValidationError('databaseConnection or notification missing', global.constant.error.value.MISSING);
  }

  console.log(`notification: ${notification}`);
  console.log(`data: ${data}`);
  console.log(`renewalInfo: ${renewalInfo}`);
  console.log(`transactionInfo: ${transactionInfo}`);

  // https://developer.apple.com/documentation/appstoreservernotifications/responsebodyv2decodedpayload
  // The in-app purchase event for which the App Store sent this version 2 notification.
  const notificationType = formatString(notification.notificationType, 25);
  // Additional information that identifies the notification event, or an empty string. The subtype applies only to select version 2 notifications.
  const subtype = formatString(notification.subtype, 19);
  // A unique identifier for the notification. Use this value to identify a duplicate notification.
  const notificationUUID = formatString(notification.notificationUUID, 36);
  // A string that indicates the App Store Server Notification version number.
  const version = formatString(notification.version, 3);
  // The UNIX time, in milliseconds, that the App Store signed the JSON Web Signature data.
  const signedDate = formatDate(notification.signedDate);

  // https://developer.apple.com/documentation/appstoreservernotifications/data
  // The unique identifier of the app that the notification applies to. This property is available for apps that are downloaded from the App Store; it isn’t present in the sandbox environment.
  const dataAppAppleId = formatString(data.appAppleId, 100);
  // The bundle identifier of the app.
  const dataBundleId = formatString(data.bundleId, 19);
  // The version of the build that identifies an iteration of the bundle.
  const dataBundleVersion = formatNumber(data.bundleVersion);
  // The server environment that the notification applies to, either sandbox or production.
  const dataEnvironment = formatString(data.environment, 10);

  // https://developer.apple.com/documentation/appstoreservernotifications/jwsrenewalinfodecodedpayload
  // The product identifier of the product that renews at the next billing period.
  const renewalInfoAutoRenewProductId = formatString(renewalInfo.autoRenewProductId, 60);
  // The renewal status for an auto-renewable subscription.
  const renewalInfoAutoRenewStatus = formatBoolean(renewalInfo.autoRenewStatus);
  // The server environment, either sandbox or production.
  const renewalInfoEnvironment = formatString(renewalInfo.environment, 10);
  // The reason a subscription expired.
  const renewalInfoExpirationIntent = formatNumber(renewalInfo.expirationIntent);
  // The time when the billing grace period for subscription renewals expires.
  const renewalInfoGracePeriodExpiresDate = formatDate(renewalInfo.gracePeriodExpiresDate);
  // The Boolean value that indicates whether the App Store is attempting to automatically renew an expired subscription.
  const renewalInfoIsInBillingRetryPeriod = formatBoolean(renewalInfo.isInBillingRetryPeriod);
  // The offer code or the promotional offer identifier.
  const renewalInfoOfferIdentifier = formatString(renewalInfo.offerIdentifier, 100);
  // The type of subscription offer.
  const renewalInfoOfferType = formatNumber(renewalInfo.offerType);
  // The original transaction identifier of a purchase.
  const renewalInfoOriginalTransactionId = formatNumber(renewalInfo.originalTransactionId);
  // The status that indicates whether the auto-renewable subscription is subject to a price increase.
  const renewalInfoPriceIncreaseStatus = formatBoolean(renewalInfo.priceIncreaseStatus);
  // The product identifier of the in-app purchase.
  const renewalInfoProductId = formatString(renewalInfo.productId, 60);
  // The earliest start date of an auto-renewable subscription in a series of subscription purchases that ignores all lapses of paid service that are 60 days or less.
  const renewalInfoRecentSubscriptionStartDate = formatDate(renewalInfo.recentSubscriptionStartDate);
  // The UNIX time, in milliseconds, that the App Store signed the JSON Web Signature data.
  const renewalInfoSignedDate = formatDate(renewalInfo.signedDate);

  // https://developer.apple.com/documentation/appstoreservernotifications/jwstransactiondecodedpayload
  // A UUID that associates the transaction with a user on your own service. If your app doesn’t provide an appAccountToken, this string is empty. For more information, see appAccountToken(_:).
  const transactionInfoAppAccountToken = formatString(transactionInfo.appAccountToken, 36);
  // The bundle identifier of the app.
  const transactionInfoBundleId = formatString(transactionInfo.bundleId, 19);
  // The server environment, either sandbox or production.
  const transactionInfoEnvironment = formatString(transactionInfo.environment, 10);
  // The UNIX time, in milliseconds, the subscription expires or renews.
  const transactionInfoExpiresDate = formatDate(transactionInfo.expiresDate);
  // A string that describes whether the transaction was purchased by the user, or is available to them through Family Sharing.
  const transactionInfoInAppOwnershipType = formatString(transactionInfo.inAppOwnershipType, 13);
  // A Boolean value that indicates whether the user upgraded to another subscription.
  const transactionInfoIsUpgraded = formatBoolean(transactionInfo.isUpgraded);
  // The identifier that contains the promo code or the promotional offer identifier.
  const transactionInfoOfferIdentifier = formatString(transactionInfo.offerIdentifier, 100);
  // A value that represents the promotional offer type.
  const transactionInfoOfferType = formatNumber(transactionInfo.offerType);
  // The UNIX time, in milliseconds, that represents the purchase date of the original transaction identifier.
  const transactionInfoOriginalPurchaseDate = formatDate(transactionInfo.originalPurchaseDate);
  // The transaction identifier of the original purchase.
  const transactionInfoOriginalTransactionId = formatNumber(transactionInfo.originalTransactionId);
  // The product identifier of the in-app purchase.
  const transactionInfoProductId = formatString(transactionInfo.productId, 60);
  // The UNIX time, in milliseconds, that the App Store charged the user’s account for a purchase, restored product, subscription, or subscription renewal after a lapse.
  const transactionInfoPurchaseDate = formatDate(transactionInfo.purchaseDate);
  // The number of consumable products the user purchased.
  const transactionInfoQuantity = formatNumber(transactionInfo.quantity);
  // The UNIX time, in milliseconds, that the App Store refunded the transaction or revoked it from Family Sharing.
  const transactionInfoRevocationDate = formatDate(transactionInfo.revocationDate);
  // The reason that the App Store refunded the transaction or revoked it from Family Sharing.
  const transactionInfoRevocationReason = formatNumber(transactionInfo.revocationReason);
  // The UNIX time, in milliseconds, that the App Store signed the JSON Web Signature (JWS) data.
  const transactionInfoSignedDate = formatDate(transactionInfo.signedDate);
  // The identifier of the subscription group the subscription belongs to.
  const transactionInfoSubscriptionGroupIdentifier = formatNumber(transactionInfo.subscriptionGroupIdentifier);
  // The unique identifier of the transaction.
  const transactionInfoTransactionId = formatNumber(transactionInfo.transactionId);
  // The type of the in-app purchase.
  const transactionInfoType = formatString(transactionInfo.type, 27);
  // The unique identifier of subscription purchase events across devices, including subscription renewals.
  const transactionInfoWebOrderLineItemId = formatNumber(transactionInfo.webOrderLineItemId);

  console.log('Insert appStoreServerNotifications with values:');
  console.log(
    notificationType,
    subtype,
    notificationUUID,
    version,
    signedDate,
    dataAppAppleId,
    dataBundleId,
    dataBundleVersion,
    dataEnvironment,
    renewalInfoAutoRenewProductId,
    renewalInfoAutoRenewStatus,
    renewalInfoEnvironment,
    renewalInfoExpirationIntent,
    renewalInfoGracePeriodExpiresDate,
    renewalInfoIsInBillingRetryPeriod,
    renewalInfoOfferIdentifier,
    renewalInfoOfferType,
    renewalInfoOriginalTransactionId,
    renewalInfoPriceIncreaseStatus,
    renewalInfoProductId,
    renewalInfoRecentSubscriptionStartDate,
    renewalInfoSignedDate,
    transactionInfoAppAccountToken,
    transactionInfoBundleId,
    transactionInfoEnvironment,
    transactionInfoExpiresDate,
    transactionInfoInAppOwnershipType,
    transactionInfoIsUpgraded,
    transactionInfoOfferIdentifier,
    transactionInfoOfferType,
    transactionInfoOriginalPurchaseDate,
    transactionInfoOriginalTransactionId,
    transactionInfoProductId,
    transactionInfoPurchaseDate,
    transactionInfoQuantity,
    transactionInfoRevocationDate,
    transactionInfoRevocationReason,
    transactionInfoSignedDate,
    transactionInfoSubscriptionGroupIdentifier,
    transactionInfoTransactionId,
    transactionInfoType,
    transactionInfoWebOrderLineItemId,
  );

  await databaseQuery(
    databaseConnection,
    `INSERT INTO appStoreServerNotifications(${appStoreServerNotificationsColumns}) VALUES (${appStoreServerNotificationsValues})`,
    [
      notificationType,
      subtype,
      notificationUUID,
      version,
      signedDate,
      dataAppAppleId,
      dataBundleId,
      dataBundleVersion,
      dataEnvironment,
      renewalInfoAutoRenewProductId,
      renewalInfoAutoRenewStatus,
      renewalInfoEnvironment,
      renewalInfoExpirationIntent,
      renewalInfoGracePeriodExpiresDate,
      renewalInfoIsInBillingRetryPeriod,
      renewalInfoOfferIdentifier,
      renewalInfoOfferType,
      renewalInfoOriginalTransactionId,
      renewalInfoPriceIncreaseStatus,
      renewalInfoProductId,
      renewalInfoRecentSubscriptionStartDate,
      renewalInfoSignedDate,
      transactionInfoAppAccountToken,
      transactionInfoBundleId,
      transactionInfoEnvironment,
      transactionInfoExpiresDate,
      transactionInfoInAppOwnershipType,
      transactionInfoIsUpgraded,
      transactionInfoOfferIdentifier,
      transactionInfoOfferType,
      transactionInfoOriginalPurchaseDate,
      transactionInfoOriginalTransactionId,
      transactionInfoProductId,
      transactionInfoPurchaseDate,
      transactionInfoQuantity,
      transactionInfoRevocationDate,
      transactionInfoRevocationReason,
      transactionInfoSignedDate,
      transactionInfoSubscriptionGroupIdentifier,
      transactionInfoTransactionId,
      transactionInfoType,
      transactionInfoWebOrderLineItemId,
    ],
  );
}

module.exports = {
  createAppStoreServerNotificationForSignedPayload,
};
