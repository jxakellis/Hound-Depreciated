const { alarmLogger } = require('../../logging/loggers');

const { schedule } = require('./schedules');

const { areAllDefined } = require('../../validation/validateFormat');

/**
 * Cancels primary jobs scheduled with the provided familyId and reminderId
 */
const cancelPrimaryJobForFamilyForReminder = async (familyId, reminderId) => {
  // cannot cancel job without familyId and reminderId
  if (areAllDefined(familyId, reminderId) === false) {
    return;
  }
  // attempt to locate job that has the userId and reminderId
  const primaryJob = schedule.scheduledJobs[`Family${familyId}Reminder${reminderId}`];
  if (areAllDefined(primaryJob)) {
    alarmLogger.debug(`Cancelling Primary Job: ${primaryJob.name}`);
    primaryJob.cancel();
  }
};

/**
 * Cancels any secondary jobs scheduled with the provided userId and reminderId
 */
const cancelSecondaryJobForUserForReminder = async (userId, reminderId) => {
  // cannot cancel job without userId and reminderId
  if (areAllDefined(userId, reminderId) === false) {
    return;
  }
  // attempt to locate job that has the userId and reminderId  (note: names are in strings, so must convert int to string)
  const secondaryJob = schedule.scheduledJobs[`User${userId}Reminder${reminderId}`];
  if (areAllDefined(secondaryJob)) {
    alarmLogger.debug(`Cancelling Secondary Job: ${secondaryJob.name}`);
    secondaryJob.cancel();
  }
};

module.exports = { cancelPrimaryJobForFamilyForReminder, cancelSecondaryJobForUserForReminder };
