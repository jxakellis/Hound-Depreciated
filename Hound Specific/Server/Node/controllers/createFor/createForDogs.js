const DatabaseError = require('../../main/tools/errors/databaseError');
const ValidationError = require('../../main/tools/errors/validationError');
const { queryPromise } = require('../../main/tools/database/queryPromise');
const { areAllDefined } = require('../../main/tools/validation/validateFormat');

/**
 *  Queries the database to create a dog. If the query is successful, then returns the dogId.
 *  If a problem is encountered, creates and throws custom error
 */
const createDogQuery = async (req) => {
  const familyId = req.params.familyId;
  const dogName = req.body.dogName;

  if (areAllDefined(familyId, dogName) === false) {
    throw new ValidationError('familyId or dogName missing', 'ER_VALUES_MISSING');
  }

  try {
    const result = await queryPromise(
      req,
      'INSERT INTO dogs(familyId, dogIcon, dogName) VALUES (?,?,?)',
      [familyId, undefined, dogName],
    );
    return result.insertId;
  }
  catch (error) {
    throw new DatabaseError(error.code);
  }
};

module.exports = { createDogQuery };
