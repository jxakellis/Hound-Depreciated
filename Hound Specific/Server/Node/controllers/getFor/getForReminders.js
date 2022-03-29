const {
  formatNumber,
} = require('../../utils/validateFormat');
const { queryPromise } = require('../../utils/queryPromise');

/**
 * Returns the reminder for the dogId. Errors not handled
 * @param {*} req
 * @param {*} reminderId
 * @returns
 */
const getReminderQuery = async (req, res) => {
  const reminderId = formatNumber(req.params.reminderId);
  try {
    // left joins dogReminders and component tables so that a reminder has all of its components attached
  // tables where the dogReminder isn't present (i.e. its reminderType is different) will just append lots of null values to result
    const result = await queryPromise(
      req,
      'SELECT *, dogReminders.reminderId as reminderId FROM dogReminders LEFT JOIN reminderCountdownComponents ON dogReminders.reminderId = reminderCountdownComponents.reminderId LEFT JOIN reminderWeeklyComponents ON dogReminders.reminderId = reminderWeeklyComponents.reminderId LEFT JOIN reminderMonthlyComponents ON dogReminders.reminderId = reminderMonthlyComponents.reminderId LEFT JOIN reminderOneTimeComponents ON dogReminders.reminderId = reminderOneTimeComponents.reminderId LEFT JOIN reminderSnoozeComponents ON dogReminders.reminderId = reminderSnoozeComponents.reminderId WHERE dogReminders.reminderId = ?',
      [reminderId],
    );

    // because of all the null values from left join, since only one component table (for the corresponding reminderType) will have the reminder, we need to remve
    // eslint-disable-next-line no-restricted-syntax
    for (const [key, value] of Object.entries(result)) {
    // checks for null json values, if json value is null then removes the key
      if (value === null) {
        delete result[key];
      }
    }

    req.commitQueries(req);
    return res.status(200).json({ result });
  }
  catch (error) {
    req.rollbackQueries(req);
    return res.status(400).json({ message: 'Invalid Parameters; Database query failed', error: error.code });
  }
};

/**
 * Returns an array of all the reminders for the dogId. Errors not handled
 * @param {*} req
 * @param {*} dogId
 * @returns
 */
const getRemindersQuery = async (req, res) => {
  const dogId = formatNumber(req.params.dogId);
  try {
    // get all reminders for the dogId, then left join to all reminder components table so each reminder has components attached
    const result = await queryPromise(
      req,
      'SELECT *, dogReminders.reminderId as reminderId FROM dogReminders LEFT JOIN reminderCountdownComponents ON dogReminders.reminderId = reminderCountdownComponents.reminderId LEFT JOIN reminderWeeklyComponents ON dogReminders.reminderId = reminderWeeklyComponents.reminderId LEFT JOIN reminderMonthlyComponents ON dogReminders.reminderId = reminderMonthlyComponents.reminderId LEFT JOIN reminderOneTimeComponents ON dogReminders.reminderId = reminderOneTimeComponents.reminderId LEFT JOIN reminderSnoozeComponents ON dogReminders.reminderId = reminderSnoozeComponents.reminderId WHERE dogReminders.dogId = ?',
      [dogId],
    );

    // iterate through all the reminders returned
    for (let i = 0; i < result.length; i += 1) {
      // because of all the null values from left join, since only one component table (for the corresponding reminderType) will have the reminder, we need to remve
      // eslint-disable-next-line no-restricted-syntax
      for (const [key, value] of Object.entries(result[i])) {
        // checks for null json values, if json value is null then removes the key
        if (value === null) {
          delete result[i][key];
        }
      }
    }

    if (result.length === 0) {
      // successful but empty array, no reminders to return
      req.commitQueries(req);
      // return res.status(204).json({ result: [] });
      return res.status(200).json({ result: [] });
    }
    else {
      // array has items, meaning there were reminders found, successful!
      req.commitQueries(req);
      return res.status(200).json({ result });
    }
  }
  catch (error) {
    // error when trying to do query to database
    req.rollbackQueries(req);
    return res.status(400).json({ message: 'Invalid Parameters; Database query failed', error: error.code });
  }
};

module.exports = { getReminderQuery, getRemindersQuery };