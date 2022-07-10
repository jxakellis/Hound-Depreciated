const { DatabaseError } = require('../../main/tools/errors/databaseError');
const { ValidationError } = require('../../main/tools/errors/validationError');
const { queryPromise } = require('../../main/tools/database/queryPromise');
const { formatDate } = require('../../main/tools/format/formatObject');
const { areAllDefined } = require('../../main/tools/format/validateDefined');

// Select every column except for dogId, reminderExecutionDate, and reminderLastModified (by not transmitting, increases network efficiency)
// dogId is already known, reminderExecutionDate is calculated client-side and server-side is only used for notification sending, and reminderLastModified has no use client-side
const dogRemindersColumns = 'reminderId, reminderAction, reminderCustomActionName, reminderType, reminderIsEnabled, reminderExecutionBasis, reminderIsDeleted, snoozeIsEnabled, snoozeExecutionInterval, snoozeIntervalElapsed, countdownExecutionInterval, countdownIntervalElapsed, weeklyHour, weeklyMinute, weeklySunday, weeklyMonday, weeklyTuesday, weeklyWednesday, weeklyThursday, weeklyFriday, weeklySaturday, weeklyIsSkipping, weeklyIsSkippingDate, monthlyDay, monthlyHour, monthlyMinute, monthlyIsSkipping, monthlyIsSkippingDate, oneTimeDate';

/**
 *  If the query is successful, returns the reminder for the reminderId.
 *  If a problem is encountered, creates and throws custom error
 */
const getReminderForReminderId = async (req, reminderId, lastDogManagerSynchronization) => {
  if (areAllDefined(req, reminderId) === false) {
    throw new ValidationError('req or reminderId missing', global.constant.error.value.MISSING);
  }

  const lastSynchronization = formatDate(lastDogManagerSynchronization);

  try {
    let result;

    if (areAllDefined(lastSynchronization)) {
      // find reminder that matches the id
      result = await queryPromise(
        req,
        `SELECT ${dogRemindersColumns} FROM dogReminders WHERE reminderLastModified >= ? AND reminderId = ? LIMIT 1`,
        [lastSynchronization, reminderId],
      );
    }
    else {
      // find reminder that matches the id
      result = await queryPromise(
        req,
        `SELECT ${dogRemindersColumns} FROM dogReminders WHERE reminderId = ? LIMIT 1`,
        [reminderId],
      );
    }

    // don't trim 'unnecessary' components (e.g. if weekly only send back weekly components)
    // its unnecessary processing and its easier for the reminders to remember their old states
    return result;
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
};

/**
 *  If the query is successful, returns an array of all the reminders for the dogId.
 *  If a problem is encountered, creates and throws custom error
 */
const getAllRemindersForDogId = async (req, dogId, lastDogManagerSynchronization) => {
  if (areAllDefined(req, dogId) === false) {
    throw new ValidationError('req or dogId missing', global.constant.error.value.MISSING);
  }

  const lastSynchronization = formatDate(lastDogManagerSynchronization);

  try {
    let result;

    if (areAllDefined(lastSynchronization)) {
      result = await queryPromise(
        req,
        `SELECT ${dogRemindersColumns} FROM dogReminders WHERE reminderLastModified >= ? AND dogId = ? LIMIT 18446744073709551615`,
        [lastSynchronization, dogId],
      );
    }
    else {
      // find reminder that matches the dogId
      result = await queryPromise(
        req,
        `SELECT ${dogRemindersColumns} FROM dogReminders WHERE dogId = ? LIMIT 18446744073709551615`,
        [dogId],
      );
    }

    // don't trim 'unnecessary' components (e.g. if weekly only send back weekly components)
    // its unnecessary processing and its easier for the reminders to remember their old states

    return result;
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
};

module.exports = { getReminderForReminderId, getAllRemindersForDogId };
