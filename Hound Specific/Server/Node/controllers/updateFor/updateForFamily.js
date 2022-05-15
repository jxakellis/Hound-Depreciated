const DatabaseError = require('../../main/tools/errors/databaseError');
const ValidationError = require('../../main/tools/errors/validationError');

const { queryPromise } = require('../../main/tools/database/queryPromise');
const {
  formatBoolean, formatDate, areAllDefined, formatNumber,
} = require('../../main/tools/validation/validateFormat');

const { deleteAlarmNotificationsForFamily, deleteSecondaryAlarmNotificationsForUser } = require('../../main/tools/notifications/alarm/deleteAlarmNotification');
const { getFamilyMembersForUserIdQuery } = require('../getFor/getForFamily');
/**
 *  Queries the database to update a family to add a new user. If the query is successful, then returns
 *  If a problem is encountered, creates and throws custom error
 */
const updateFamilyQuery = async (req) => {
  const familyId = req.params.familyId;
  const isLocked = formatBoolean(req.body.isLocked);
  const isPaused = formatBoolean(req.body.isPaused);
  const kickUserId = formatNumber(req.body.kickUserId);

  // familyId doesn't exist, so user must want to join a family
  if (areAllDefined(familyId) === false) {
    await addFamilyMemberQuery(req);
  }
  // try updating individual components
  else if (areAllDefined(isLocked)) {
    try {
      await queryPromise(
        req,
        'UPDATE families SET isLocked = ? WHERE familyId = ?',
        [isLocked, familyId],
      );
    }
    catch (error) {
      throw new DatabaseError(error.code);
    }
  }
  else if (areAllDefined(isPaused)) {
    await updateIsPausedQuery(req);
  }
  else if (areAllDefined(kickUserId)) {
    await kickFamilyMemberQuery(req);
  }
};

// columns for SELECT statement for updateIsPausedQuery
const reminderSnoozeComponentsSelect = 'reminderSnoozeComponents.snoozeIsEnabled, reminderSnoozeComponents.snoozeExecutionInterval, reminderSnoozeComponents.snoozeIntervalElapsed';
const reminderCountdownComponentsSelect = 'reminderCountdownComponents.countdownExecutionInterval, reminderCountdownComponents.countdownIntervalElapsed';

const reminderSnoozeComponentsLeftJoin = 'LEFT JOIN reminderSnoozeComponents ON dogReminders.reminderId = reminderSnoozeComponents.reminderId';
const reminderCountdownComponentsLeftJoin = 'LEFT JOIN reminderCountdownComponents ON dogReminders.reminderId = reminderCountdownComponents.reminderId';

/**
 * Helper method for updateFamilyQuery, goes through all of the logic to update isPaused, lastPause, lastUnpause
 * If pausing, saves all intervalElapsed, sets all reminderExecutionDates to nil, and deleteAlarmNotifications
 * If unpausing, sets reminderExecutionBasis to Date(). The new reminderExecutionDates must be calculated by the user and sent to the server
 */
const updateIsPausedQuery = async (req) => {
  const familyId = req.params.familyId;
  const isPaused = formatBoolean(req.body.isPaused);

  if (areAllDefined(familyId, isPaused) === false) {
    throw new ValidationError('familyId or isPaused missing', 'ER_VALUES_MISSING');
  }

  try {
    // find out the family's current pause status
    const familyConfiguration = await queryPromise(
      req,
      'SELECT isPaused, lastPause, lastUnpause FROM families WHERE familyId = ? LIMIT 1',
      [familyId],
    );

    // if we got a result for the family configuration and if the new pause status is different from the current one, then continue
    if (familyConfiguration.length === 1 && isPaused !== formatBoolean(familyConfiguration[0].isPaused)) {
      // toggling everything to paused from unpaused
      if (isPaused === true) {
        // update the family's pause configuration to reflect changes
        const lastPause = new Date();
        await queryPromise(
          req,
          'UPDATE families SET isPaused = ?, lastPause = ? WHERE familyId = ?',
          [true, lastPause, familyId],
        );

        // retrieves reminders that match the familyId, have a non-null reminderExecutionDate, and either have isSnoozeEnabled = 1 or reminderType = 'countdown'
        // there are the reminders that will need their intervals elapsed saved before we pause, everything else doesn't need touched.
        const reminders = await queryPromise(
          req,
          `SELECT dogReminders.reminderId, dogReminders.reminderType, dogReminders.reminderExecutionBasis, ${reminderSnoozeComponentsSelect}, ${reminderCountdownComponentsSelect} FROM dogReminders JOIN dogs ON dogReminders.dogId = dogs.dogId ${reminderSnoozeComponentsLeftJoin} ${reminderCountdownComponentsLeftJoin} WHERE dogs.familyId = ? AND dogReminders.reminderExecutionDate IS NOT NULL AND (reminderSnoozeComponents.snoozeIsEnabled = 1 OR dogReminders.reminderType = 'countdown') LIMIT 18446744073709551615`,
          [familyId],
        );

        // Update the intervalElapsed for countdown reminders and snoozed reminders
        for (let i = 0; i < reminders.length; i += 1) {
          const reminder = reminders[i];
          // update countdown timing
          if (reminder.reminderType === 'countdown') {
            let millisecondsElapsed;
            // the reminder has not has its interval elapsed changed before, meaning it's not been paused or unpaused since its current reminderExecutionBasis
            if (reminder.countdownIntervalElapsed === 0) {
            // the time greater in the future will have a greater number of milliseconds elapsed, so future - past = positive millisecond difference
              millisecondsElapsed = Math.abs(lastPause.getTime() - formatDate(reminder.reminderExecutionBasis).getTime());
            }
            // the reminder has had its interval elapsed changed, meaning it's been paused or unpaused since its current reminderExecutionBasis
            else {
            // since the reminder has been paused before, we must find the time elapsed since the last unpause to this pause
              millisecondsElapsed = Math.abs(lastPause.getTime() - formatDate(familyConfiguration[0].lastUnpause).getTime());
            }
            await queryPromise(
              req,
              'UPDATE reminderCountdownComponents SET countdownIntervalElapsed = ? WHERE reminderId = ?',
              [(millisecondsElapsed / 1000) + reminder.countdownIntervalElapsed, reminder.reminderId],
            );
          }
          // update snooze timing
          else if (formatBoolean(reminder.isSnoozeEnabled) === true) {
            let millisecondsElapsed;
            // the reminder has not has its interval elapsed changed before, meaning it's not been paused or unpaused since its current reminderExecutionBasis
            if (reminder.snoozeIntervalElapsed === 0) {
            // the time greater in the future will have a greater number of milliseconds elapsed, so future - past = positive millisecond difference
              millisecondsElapsed = Math.abs(lastPause.getTime() - formatDate(reminder.reminderExecutionBasis).getTime());
            }
            // the reminder has had its interval elapsed changed, meaning it's been paused or unpaused since its current reminderExecutionBasis
            else {
            // since the reminder has been paused before, we must find the time elapsed since the last unpause to this pause
              millisecondsElapsed = Math.abs(lastPause.getTime() - formatDate(familyConfiguration[0].lastUnpause).getTime());
            }
            await queryPromise(
              req,
              'UPDATE reminderSnoozeComponents SET snoozeIntervalElapsed = ? WHERE reminderId = ?',
              [(millisecondsElapsed / 1000) + reminder.snoozeIntervalElapsed, reminder.reminderId],
            );
          }
        }

        // none of the reminders will be going off since their paused, meaning their executionDates will be null.
        // Update the reminderExecutionDates to NULL for all of the family's reminders
        await queryPromise(
          req,
          'UPDATE dogReminders JOIN dogs ON dogReminders.dogId = dogs.dogId SET dogReminders.reminderExecutionDate = NULL WHERE dogs.familyId = ?',
          [familyId],
        );

        // remove any alarm notifications that may be scheduled since everything is now paused and no need for alarms.
        deleteAlarmNotificationsForFamily(familyId);
      }
      // toggling everything to unpaused from paused
      else {
        const lastUnpause = new Date();
        // update the family's pause configuration to reflect changes
        await queryPromise(
          req,
          'UPDATE families SET isPaused = ?, lastUnpause = ? WHERE familyId = ?',
          [false, lastUnpause, familyId],
        );

        // once reminders are unpaused, they have an up to date intervalElapsed so need to base their timing off of the lastUnpause.
        // Update the reminderExecutionBasis to lastUnpause for all of the family's reminders
        await queryPromise(
          req,
          'UPDATE dogReminders JOIN dogs ON dogReminders.dogId = dogs.dogId SET dogReminders.reminderExecutionBasis = ? WHERE dogs.familyId = ?',
          [lastUnpause, familyId],
        );

        // currently no need to recreate/refresh alarm notifications. This is because the executionDates will all still be nil
        // User needs to update reminders with the executioDates calculated on their device

        // TO DO have the server calculate the new reminderExecutionDates (if we do this, then have alarm notifications created for family)
      }
    }
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
};

/**
 * Helper method for updateFamilyQuery, goes through checks to attempt to add user to desired family
 */
const addFamilyMemberQuery = async (req) => {
  let familyCode = req.body.familyCode;
  // make sure familyCode was provided
  if (areAllDefined(familyCode) === false) {
    throw new ValidationError('familyCode missing', 'ER_FAMILY_CODE_INVALID');
  }
  familyCode = familyCode.toUpperCase();

  let family;
  try {
    // retrieve information about the family linked to the familyCode
    family = await queryPromise(
      req,
      'SELECT familyId, isLocked FROM families WHERE familyCode = ? LIMIT 1',
      [familyCode],
    );
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }

  // make sure the familyCode was valid by checking if it matched a family
  if (family.length === 0) {
    // result length is zero so there are no families with that familyCode
    throw new ValidationError('familyCode invalid, not found', 'ER_FAMILY_NOT_FOUND');
  }
  family = family[0];
  const isLocked = formatBoolean(family.isLocked);
  // familyCode exists and is linked to a family, now check if family is locked against new members
  if (isLocked === true) {
    throw new ValidationError('Family is locked', 'ER_FAMILY_LOCKED');
  }

  // the familyCode is valid and linked to an UNLOCKED family
  const userId = req.params.userId;

  const isFamilyMember = await getFamilyMembersForUserIdQuery(req, userId);

  if (isFamilyMember.length !== 0) {
    // user is already in a family
    throw new ValidationError('You are already in a family', 'ER_FAMILY_ALREADY');
  }

  // familyCode validated and user is not a family member in any family
  try {
    // insert the user into the family as a family member.
    await queryPromise(
      req,
      'INSERT INTO familyMembers(familyId, userId) VALUES (?, ?)',
      [family.familyId, userId],
    );
    return;
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
};

/**
 * Helper method for updateFamilyQuery, goes through checks to attempt to kick a user from the family
 */
const kickFamilyMemberQuery = async (req) => {
  const userId = req.params.userId;
  const familyId = req.params.familyId;
  const kickUserId = formatNumber(req.body.kickUserId);

  // have to specify who to kick from the family
  if (areAllDefined(userId, familyId, kickUserId) === false) {
    throw new ValidationError('userId, familyId, or kickUserId missing', 'ER_VALUES_MISSING');
  }
  // a user cannot kick themselves
  if (userId === kickUserId) {
    throw new ValidationError('kickUserId invalid', 'ER_VALUES_INVALID');
  }
  let family;
  try {
    family = await queryPromise(
      req,
      'SELECT userId, familyId FROM families WHERE userId = ? AND familyId = ? LIMIT 1',
      [userId, familyId],
    );
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
  // check to see if the user is the family head, as only the family head has permissions to kick
  if (family.length === 0) {
    throw new ValidationError('Invalid permissions to kick family member', 'ER_NOT_FOUND');
  }

  // kickUserId is valid, kickUserId is different then the requester, requester is the family head so everything is valid
  try {
    // kick the user by deleting them from the family
    await queryPromise(
      req,
      'DELETE FROM familyMembers WHERE userId = ?',
      [kickUserId],
    );
    // remove any pending secondary alarm notifications they have queued
    // The primary alarm notifications retrieve the notification tokens of familyMembers right as they fire, so the user will not be included
    deleteSecondaryAlarmNotificationsForUser(kickUserId);
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
};

module.exports = { updateFamilyQuery };
