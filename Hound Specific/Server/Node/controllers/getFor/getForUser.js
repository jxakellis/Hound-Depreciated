const { DatabaseError } = require('../../main/tools/errors/databaseError');
const { ValidationError } = require('../../main/tools/errors/validationError');
const { queryPromise } = require('../../main/tools/database/queryPromise');
const { areAllDefined } = require('../../main/tools/format/validateDefined');

const userColumns = 'users.userId, users.userNotificationToken, users.userFirstName, users.userLastName, users.userEmail';
const userConfigurationColumns = 'userConfiguration.isNotificationEnabled, userConfiguration.isLoudNotification, userConfiguration.isFollowUpEnabled, userConfiguration.followUpDelay, userConfiguration.logsInterfaceScale, userConfiguration.remindersInterfaceScale, userConfiguration.interfaceStyle, userConfiguration.snoozeLength, userConfiguration.notificationSound';

/**
 * Returns the user for the userId. Errors not handled
 */
const getUserForUserId = async (req, userId) => {
  if (areAllDefined(req, userId) === false) {
    throw new ValidationError('userId missing', global.constant.error.value.MISSING);
  }

  let userInformation;
  // only one user should exist for any userId otherwise the table is broken
  try {
    // have to specifically reference the columns, otherwise familyMembers.userId will override users.userId.
    // Therefore setting userId to null (if there is no family member) even though the userId isn't null.
    userInformation = await queryPromise(
      req,
      `SELECT ${userColumns}, familyMembers.familyId, ${userConfigurationColumns} FROM users JOIN userConfiguration ON users.userId = userConfiguration.userId LEFT JOIN familyMembers ON users.userId = familyMembers.userId WHERE users.userId = ? LIMIT 1`,
      [userId],
    );
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
  userInformation = userInformation[0];

  // array has item(s), meaning there was a user found, successful!
  return userInformation;
};

/**
 * Returns the user for the userIdentifier. Errors not handled
 */
const getUserForUserIdentifier = async (req, userIdentifier) => {
  if (areAllDefined(req, userIdentifier) === false) {
    throw new ValidationError('userIdentifier missing', global.constant.error.value.MISSING);
  }

  // userIdentifier method of finding corresponding user(s)
  let userInformation;
  try {
    // have to specifically reference the columns, otherwise familyMembers.userId will override users.userId.
    // Therefore setting userId to null (if there is no family member) even though the userId isn't null.
    userInformation = await queryPromise(
      req,
      `SELECT ${userColumns}, familyMembers.familyId, ${userConfigurationColumns} FROM users JOIN userConfiguration ON users.userId = userConfiguration.userId LEFT JOIN familyMembers ON users.userId = familyMembers.userId WHERE users.userIdentifier = ? LIMIT 1`,
      [userIdentifier],
    );
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }

  // in this case, there was no middleware to verify the userIdentifer so we must make sure that it is valid
  if (userInformation.length === 0) {
    // successful but empty array, no user to return.
    // Theoretically could be multiple users found but that means the table is broken. Just do catch all
    throw new ValidationError('No user found or invalid permissions', global.constant.error.value.INVALID);
  }
  userInformation = userInformation[0];

  // array has item(s), meaning there was a user found, successful!
  return userInformation;
};

module.exports = { getUserForUserId, getUserForUserIdentifier };
