const express = require('express');

const router = express.Router({ mergeParams: true });

const {
  getFamily, createFamily, updateFamily, deleteFamily,
} = require('../controllers/main/family');

const { validateFamilyId } = require('../main/tools/validation/validateId');

router.param('familyId', validateFamilyId);

// router.use('/:familyId', validateFamilyId);

// gets family with userId then return information from families and familyMembers table
router.get('/', getFamily);
// no body

// gets family with familyId then return information from families and familyMembers table
router.get('/:familyId', getFamily);
// no body

const dogsRouter = require('./dogs');

router.use('/:familyId/dogs', dogsRouter);

// creates family
router.post('/', createFamily);
/* BODY:
*/

// lets a user join a new family
router.put('/', updateFamily);

// updates family
router.put('/:familyId', updateFamily);
/* BODY:
*/

// deletes family
router.delete('/:familyId', deleteFamily);
// no body

module.exports = router;
