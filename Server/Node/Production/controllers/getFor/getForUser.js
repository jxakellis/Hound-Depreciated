const { ValidationError } = require('../../main/tools/general/errors');
const { databaseQuery } = require('../../main/tools/database/databaseQuery');
const { areAllDefined } = require('../../main/tools/format/validateDefined');

const userColumns = 'users.userId, users.userApplicationUsername, users.userNotificationToken, users.userFirstName, users.userLastName, users.userEmail';
const userNameColumns = 'users.userFirstName, users.userLastName';
const userConfigurationColumns = 'userConfiguration.isNotificationEnabled, userConfiguration.isLoudNotification, userConfiguration.isFollowUpEnabled, userConfiguration.followUpDelay, userConfiguration.snoozeLength, userConfiguration.notificationSound, userConfiguration.logsInterfaceScale, userConfiguration.remindersInterfaceScale, userConfiguration.interfaceStyle, userConfiguration.maximumNumberOfLogsDisplayed';

/**
 * If the query is successful, returns the user for the userId.
 *  If a problem is encountered, creates and throws custom error
 */
async function getUserForUserId(databaseConnection, userId) {
  if (areAllDefined(databaseConnection, userId) === false) {
    throw new ValidationError('databaseConnection or userId missing', global.constant.error.value.MISSING);
  }

  // have to specifically reference the columns, otherwise familyMembers.userId will override users.userId.
  // Therefore setting userId to null (if there is no family member) even though the userId isn't null.
  const userInformation = await databaseQuery(
    databaseConnection,
    `SELECT ${userColumns}, familyMembers.familyId, ${userConfigurationColumns} FROM users JOIN userConfiguration ON users.userId = userConfiguration.userId LEFT JOIN familyMembers ON users.userId = familyMembers.userId WHERE users.userId = ? LIMIT 1`,
    [userId],
  );

  return userInformation[0];
}

/**
* If the query is successful, returns the user for the userIdentifier.
 *  If a problem is encountered, creates and throws custom error
 */
async function getUserForUserIdentifier(databaseConnection, userIdentifier) {
  if (areAllDefined(databaseConnection, userIdentifier) === false) {
    throw new ValidationError('databaseConnection or userIdentifier missing', global.constant.error.value.MISSING);
  }

  // userIdentifier method of finding corresponding user(s)
  // have to specifically reference the columns, otherwise familyMembers.userId will override users.userId.
  // Therefore setting userId to null (if there is no family member) even though the userId isn't null.
  const userInformation = await databaseQuery(
    databaseConnection,
    `SELECT ${userColumns}, familyMembers.familyId, ${userConfigurationColumns} FROM users JOIN userConfiguration ON users.userId = userConfiguration.userId LEFT JOIN familyMembers ON users.userId = familyMembers.userId WHERE users.userIdentifier = ? LIMIT 1`,
    [userIdentifier],
  );

  // array has item(s), meaning there was a user found, successful!
  return userInformation[0];
}

/**
*  If the query is successful, returns the user for the userApplicationUsername.
 * If a problem is encountered, creates and throws custom error
 */
async function getUserForUserApplicationUsername(databaseConnection, userApplicationUsername) {
  if (areAllDefined(databaseConnection, userApplicationUsername) === false) {
    throw new ValidationError('databaseConnection or userApplicationUsername missing', global.constant.error.value.MISSING);
  }

  // have to specifically reference the columns, otherwise familyMembers.userId will override users.userId.
  // Therefore setting userId to null (if there is no family member) even though the userId isn't null.
  const userInformation = await databaseQuery(
    databaseConnection,
    `SELECT ${userColumns}, familyMembers.familyId, ${userConfigurationColumns} FROM users JOIN userConfiguration ON users.userId = userConfiguration.userId LEFT JOIN familyMembers ON users.userId = familyMembers.userId WHERE users.userApplicationUsername = ? LIMIT 1`,
    [userApplicationUsername],
  );

  return userInformation[0];
}

async function getUserFirstNameLastNameForUserId(databaseConnection, userId) {
  if (areAllDefined(databaseConnection, userId) === false) {
    throw new ValidationError('databaseConnection or userId missing', global.constant.error.value.MISSING);
  }

  const userInformation = await databaseQuery(
    databaseConnection,
    `SELECT ${userNameColumns} FROM users WHERE users.userId = ? LIMIT 1`,
    [userId],
  );

  return userInformation[0];
}

module.exports = {
  getUserForUserId, getUserForUserIdentifier, getUserForUserApplicationUsername, getUserFirstNameLastNameForUserId,
};
