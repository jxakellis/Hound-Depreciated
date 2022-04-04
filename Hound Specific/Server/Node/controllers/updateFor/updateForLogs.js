const DatabaseError = require('../../utils/errors/databaseError');
const ValidationError = require('../../utils/errors/validationError');

const { queryPromise } = require('../../utils/queryPromise');
const {
  formatDate, formatNumber, atLeastOneDefined,
} = require('../../utils/validateFormat');

/**
 *  Queries the database to update a log. If the query is successful, then returns
 *  If a problem is encountered, creates and throws custom error
 */
const updateLogQuery = async (req) => {
  const logId = formatNumber(req.params.logId);
  const logDate = formatDate(req.body.date);
  const { note } = req.body;
  const { logAction } = req.body;
  const { customActionName } = req.body;

  // if all undefined, then there is nothing to update
  if (atLeastOneDefined([logDate, note, logAction]) === false) {
    throw new ValidationError('No date, note, or logAction provided', 'ER_NO_VALUES_PROVIDED');
  }

  try {
    if (logDate) {
      await queryPromise(req, 'UPDATE dogLogs SET date = ? WHERE logId = ?', [logDate, logId]);
    }
    if (note) {
      await queryPromise(req, 'UPDATE dogLogs SET note = ? WHERE logId = ?', [note, logId]);
    }
    if (logAction) {
      await queryPromise(req, 'UPDATE dogLogs SET logAction = ? WHERE logId = ?', [logAction, logId]);
    }
    if (customActionName) {
      await queryPromise(req, 'UPDATE dogLogs SET customActionName = ? WHERE logId = ?', [customActionName, logId]);
    }
    return;
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
};

module.exports = { updateLogQuery };
