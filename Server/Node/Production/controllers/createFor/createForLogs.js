const { ValidationError } = require('../../main/tools/general/errors');
const { databaseQuery } = require('../../main/tools/database/databaseQuery');
const { formatDate } = require('../../main/tools/format/formatObject');
const { areAllDefined } = require('../../main/tools/format/validateDefined');

/**
 *  Queries the database to create a log. If the query is successful, then returns the logId.
 *  If a problem is encountered, creates and throws custom error
 */
async function createLogForUserIdDogId(databaseConnection, userId, dogId, forLogDate, logAction, logCustomActionName, logNote) {
  const logDate = formatDate(forLogDate);
  const dogLastModified = new Date();
  const logLastModified = dogLastModified;

  // logCustomActionName optional
  if (areAllDefined(databaseConnection, userId, dogId, logDate, logAction, logNote) === false) {
    throw new ValidationError('databaseConnection, userId, dogId, logDate, logAction, or logNote missing', global.constant.error.value.MISSING);
  }

  // only retrieve enough not deleted logs that would exceed the limit
  const logs = await databaseQuery(
    databaseConnection,
    'SELECT logId FROM dogLogs WHERE logIsDeleted = 0 AND dogId = ? LIMIT ?',
    [dogId, global.constant.limit.NUMBER_OF_LOGS_PER_DOG],
  );

  // make sure that the user isn't creating too many logs
  if (logs.length >= global.constant.limit.NUMBER_OF_LOGS_PER_DOG) {
    throw new ValidationError(`Dog log limit of ${global.constant.limit.NUMBER_OF_LOGS_PER_DOG} exceeded`, global.constant.error.family.limit.LOG_TOO_LOW);
  }

  const result = await databaseQuery(
    databaseConnection,
    'INSERT INTO dogLogs(userId, dogId, logDate, logNote, logAction, logCustomActionName, logLastModified) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [userId, dogId, logDate, logNote, logAction, logCustomActionName, logLastModified],
  );

  // update the dog last modified since one of its compoents was updated
  await databaseQuery(
    databaseConnection,
    'UPDATE dogs SET dogLastModified = ? WHERE dogId = ?',
    [dogLastModified, dogId],
  );

  return result.insertId;
}

module.exports = { createLogForUserIdDogId };