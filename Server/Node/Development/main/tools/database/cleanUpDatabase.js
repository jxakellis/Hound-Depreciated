const { databaseConnectionForGeneral } = require('./establishDatabaseConnections');
const { databaseQuery } = require('./databaseQuery');
const { serverLogger } = require('../logging/loggers');

/**
 * Retrieves every familyId and the oldest userConfigurationPreviousDogManagerSynchronization of it's familyMembers
 * For each family, it DELETEs every dog, reminder, and log that is xxxIsDeleted = 1 and xxxLastModified < userConfigurationPreviousDogManagerSynchronization
 * We can safely clear out this data because it is deleted (not needed for new users) and it's delete has been synced by all current users (indicated by xxxLastModified being older than userConfigurationPreviousDogManagerSynchronization)
 */
async function cleanUpIsDeleted() {
// retrieve the familyId and oldest userConfigurationPreviousDogManagerSynchronization for each family
  const result = await databaseQuery(
    databaseConnectionForGeneral,
    'SELECT familyMembers.familyId, MIN(userConfiguration.userConfigurationPreviousDogManagerSynchronization) AS userConfigurationPreviousDogManagerSynchronization FROM userConfiguration JOIN familyMembers ON userConfiguration.userId = familyMembers.userId GROUP BY familyMembers.familyId',
  );

  const promises = [];
  for (let i = 0; i < result.length; i += 1) {
    serverLogger.info(`cleanUpIsDeleted for familyId: ${result[i].familyId}`);
    // Find the dogReminders for the given familyId
    // Then delete any dogReminders where reminderIsDeleted = 1 && reminderLastModified < userConfigurationPreviousDogManagerSynchronization. Meaning the reminder was deleted and all current users have synced the change
    promises.push(databaseQuery(
      undefined,
      'DELETE dogReminders FROM dogReminders JOIN dogs ON dogReminders.dogId = dogs.dogId WHERE dogs.familyId = ? AND dogReminders.reminderLastModified < ? AND dogReminders.reminderIsDeleted = 1',
      [result[i].familyId, result[i].userConfigurationPreviousDogManagerSynchronization],
    ));
    // Find the dogLogs for the given familyId
    // Then delete any dogLogs where logIsDeleted = 1 && logLastModified < userConfigurationPreviousDogManagerSynchronization. Meaning the log was deleted and all current users have synced the change
    promises.push(databaseQuery(
      undefined,
      'DELETE dogLogs FROM dogLogs JOIN dogs ON dogLogs.dogId = dogs.dogId WHERE dogs.familyId = ? AND dogLogs.logLastModified < ? AND dogLogs.logIsDeleted = 1',
      [result[i].familyId, result[i].userConfigurationPreviousDogManagerSynchronization],
    ));
    // Find the dogs for the given familyId
    // Then delete any dogs where dogIsDeleted = 1 && dogLastModified < userConfigurationPreviousDogManagerSynchronization. Meaning the dog was deleted and all current users have synced the change
    promises.push(databaseQuery(
      undefined,
      'DELETE FROM dogs WHERE familyId = ? AND dogLastModified < ? AND dogIsDeleted = 1',
      [result[i].familyId, result[i].userConfigurationPreviousDogManagerSynchronization],
    ));
    // iterate to next family
  }

  await Promise.all(promises);
}

module.exports = { cleanUpIsDeleted };
