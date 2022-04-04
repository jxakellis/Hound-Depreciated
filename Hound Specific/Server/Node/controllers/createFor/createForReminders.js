const DatabaseError = require('../../utils/errors/databaseError');
const ValidationError = require('../../utils/errors/validationError');
const { queryPromise } = require('../../utils/queryPromise');
const {
  formatDate, formatBoolean, formatNumber, formatArray, areAllDefined,
} = require('../../utils/validateFormat');

const { createCountdownComponents } = require('../reminderComponents/countdown');
const { createWeeklyComponents } = require('../reminderComponents/weekly');
const { createMonthlyComponents } = require('../reminderComponents/monthly');
const { createOneTimeComponents } = require('../reminderComponents/oneTime');

/**
 *  Queries the database to create a single reminder. If the query is successful, then returns the reminder with created reminderId.
 *  If a problem is encountered, creates and throws custom error
 */
const createReminderQuery = async (req) => {
  const dogId = formatNumber(req.params.dogId);
  const { reminderAction, customActionName, reminderType } = req.body;
  const executionBasis = formatDate(req.body.executionBasis);
  const isEnabled = formatBoolean(req.body.isEnabled);

  // check to see that necessary generic reminder componetns are present
  if (areAllDefined([reminderAction, reminderType, executionBasis, isEnabled]) === false) {
    // >= 1 of the objects are undefined
    throw new ValidationError('reminderAction, reminderType, executionBasis, or isEnabled missing', 'ER_VALUES_MISSING');
  }

  // define out here so reminderId can be accessed in catch block to delete entries
  let reminderId;

  try {
    // need to check reminderType before querying because a partially correct timing style can have the query data added to the database but kick back a warning, we only want exact matches

    // no need to check for snooze components as a newly created reminder cant be snoozed, it can only be updated to be snoozing
    if (reminderType === 'countdown') {
      // first insert to main reminder table to get reminderId, then insert to other tables
      const result = await queryPromise(
        req,
        'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
        [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
      );
      reminderId = formatNumber(result.insertId);
      req.body.reminderId = reminderId;
      await createCountdownComponents(req, req.body);
    }
    else if (reminderType === 'weekly') {
      // first insert to main reminder table to get reminderId, then insert to other tables
      const result = await queryPromise(
        req,
        'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
        [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
      );
      reminderId = formatNumber(result.insertId);
      req.body.reminderId = reminderId;
      await createWeeklyComponents(req, req.body);
    }
    else if (reminderType === 'monthly') {
      // first insert to main reminder table to get reminderId, then insert to other tables
      const result = await queryPromise(
        req,
        'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
        [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
      );
      reminderId = formatNumber(result.insertId);
      req.body.reminderId = reminderId;
      await createMonthlyComponents(req, req.body);
    }
    else if (reminderType === 'oneTime') {
      // first insert to main reminder table to get reminderId, then insert to other tables
      const result = await queryPromise(
        req,
        'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
        [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
      );
      reminderId = formatNumber(result.insertId);
      req.body.reminderId = reminderId;
      await createOneTimeComponents(req, req.body);
    }
    else {
      // nothing matched reminderType
      // req.rollbackQueries(req);
      // return res.status(400).json(new ValidationError('reminderType Invalid', 'ER_VALUES_INVALID'));
      throw new ValidationError('reminderType Invalid', 'ER_VALUES_INVALID');
    }
    // was able to successfully create components for a certain timing style
    // req.commitQueries(req);
    // return res.status(200).json({ result: [req.body] });
    return [req.body];
  }
  catch (error) {
    // req.rollbackQueries(req);
    // return res.status(400).json(new DatabaseError(error.code));
    throw new DatabaseError(error.code);
  }
};

/**
   * Queries the database to create a multiple reminders. If the query is successful, then returns the reminders with their created reminderIds.
 *  If a problem is encountered, creates and throws custom error
   */
const createRemindersQuery = async (req) => {
  // assume .reminders is an array
  const dogId = formatNumber(req.params.dogId);
  const reminders = formatArray(req.body.reminders);
  const createdReminders = [];

  // synchronously iterate through all reminders provided to create them all
  // if there is a problem, we rollback all our queries and send the failure response
  // if there is no problem, we append the created reminder (with its freshly assigned id) to the array
  // if there are no problems with any of the reminders, we commit our queries and send the success response
  for (let i = 0; i < reminders.length; i += 1) {
    const { reminderAction, customActionName, reminderType } = reminders[i];
    const executionBasis = formatDate(reminders[i].executionBasis);
    const isEnabled = formatBoolean(reminders[i].isEnabled);

    // check to see that necessary generic reminder componetns are present
    if (areAllDefined([reminderAction, reminderType, executionBasis, isEnabled]) === false) {
      // >= 1 of the objects are undefined
      // req.rollbackQueries(req);
      // return res.status(400).json(new ValidationError('reminderAction, reminderType, executionBasis, or isEnabled missing', 'ER_VALUES_MISSING'));
      throw new ValidationError('reminderAction, reminderType, executionBasis, or isEnabled missing', 'ER_VALUES_MISSING');
    }
    // if the reminder is custom, then it needs its custom name
    // if (reminderAction === 'Custom' && !customActionName) {
    // req.rollbackQueries(req);
    // return res.status(400).json(new ValidationError('No customActionName provided for "Custom" reminderAction', 'ER_VALUES_MISSING'));
    // throw new ValidationError('No customActionName provided for "Custom" reminderAction', 'ER_VALUES_MISSING');
    // }

    // define out here so reminderId can be accessed in catch block to delete entries
    let reminderId;

    try {
      // need to check reminderType before querying because a partially correct timing style can have the query data added to the database but kick back a warning, we only want exact matches

      // no need to check for snooze components as a newly created reminder cant be snoozed, it can only be updated to be snoozing
      if (reminderType === 'countdown') {
        // first insert to main reminder table to get reminderId, then insert to other tables
        const result = await queryPromise(
          req,
          'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
          [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
        );
        reminderId = formatNumber(result.insertId);
        reminders[i].reminderId = reminderId;
        await createCountdownComponents(req, reminders[i]);
      }
      else if (reminderType === 'weekly') {
        // first insert to main reminder table to get reminderId, then insert to other tables
        const result = await queryPromise(
          req,
          'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
          [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
        );
        reminderId = formatNumber(result.insertId);
        reminders[i].reminderId = reminderId;
        await createWeeklyComponents(req, reminders[i]);
      }
      else if (reminderType === 'monthly') {
        // first insert to main reminder table to get reminderId, then insert to other tables
        const result = await queryPromise(
          req,
          'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
          [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
        );
        reminderId = formatNumber(result.insertId);
        reminders[i].reminderId = reminderId;
        await createMonthlyComponents(req, reminders[i]);
      }
      else if (reminderType === 'oneTime') {
        // first insert to main reminder table to get reminderId, then insert to other tables
        const result = await queryPromise(
          req,
          'INSERT INTO dogReminders(dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled) VALUES (?, ?, ?, ?, ?, ?)',
          [dogId, reminderAction, customActionName, reminderType, executionBasis, isEnabled],
        );
        reminderId = formatNumber(result.insertId);
        reminders[i].reminderId = reminderId;
        await createOneTimeComponents(req, reminders[i]);
      }
      else {
        // nothing matched reminderType
        // req.rollbackQueries(req);
        // return res.status(400).json(new ValidationError('reminderType Invalid', 'ER_VALUES_INVALID'));
        throw new ValidationError('reminderType Invalid', 'ER_VALUES_INVALID');
      }
      // was able to successfully create components for a certain timing style
      createdReminders.push(reminders[i]);
    }
    catch (error) {
      // req.rollbackQueries(req);
      // return res.status(400).json(new DatabaseError(error.code));
      throw new DatabaseError(error.code);
    }
  }
  // nothing created a problem so we return the created reminders
  // req.commitQueries(req);
  // return res.status(200).json({ result: createdReminders });
  return createdReminders;
};

module.exports = { createReminderQuery, createRemindersQuery };
