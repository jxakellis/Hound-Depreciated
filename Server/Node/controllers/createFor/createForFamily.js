const { ValidationError } = require('../../main/tools/general/errors');
const { databaseQuery } = require('../../main/tools/database/databaseQuery');
const { areAllDefined } = require('../../main/tools/format/validateDefined');
const { hash } = require('../../main/tools/format/hash');

const { generateVerifiedFamilyCode } = require('../../main/tools/general/generateVerifiedFamilyCode');
const { getFamilyMemberUserIdForUserId } = require('../getFor/getForFamily');

/**
 *  Queries the database to create a family. If the query is successful, then returns the familyId.
 *  If a problem is encountered, creates and throws custom error
 */
async function createFamilyForUserId(connection, userId) {
  if (areAllDefined(connection, userId) === false) {
    throw new ValidationError('connection or userId missing', global.constant.error.value.MISSING);
  }

  const familyAccountCreationDate = new Date();
  const familyId = hash(userId, familyAccountCreationDate.toISOString());

  if (areAllDefined(familyAccountCreationDate, familyId) === false) {
    throw new ValidationError('familyAccountCreationDate or familyId missing', global.constant.error.value.MISSING);
  }

  // check if the user is already in a family
  const existingFamilyResult = await getFamilyMemberUserIdForUserId(connection, userId);

  // validate that the user is not in a family
  if (existingFamilyResult.length !== 0) {
    throw new ValidationError('User is already in a family', global.constant.error.family.join.IN_FAMILY_ALREADY);
  }

  // create a family code for the new family
  const familyCode = await generateVerifiedFamilyCode(connection);
  await databaseQuery(
    connection,
    'INSERT INTO families(familyId, userId, familyCode, isLocked, isPaused, familyAccountCreationDate) VALUES (?, ?, ?, ?, ?, ?)',
    [familyId, userId, familyCode, false, false, familyAccountCreationDate],
  );
  await databaseQuery(
    connection,
    'INSERT INTO familyMembers(familyId, userId) VALUES (?, ?)',
    [familyId, userId],
  );

  return familyId;
}

module.exports = { createFamilyForUserId };
