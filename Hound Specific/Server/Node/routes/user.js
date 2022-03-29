const express = require('express');

const router = express.Router({ mergeParams: true });

const {
  getUser, createUser, updateUser, deleteUser,
} = require('../controllers/main/user');

const { validateUserId } = require('../utils/validateId');

// gets user with userId then return information from users and userConfiguration table
router.get('/:userIdentifier', getUser);
// no body

// validation that params are formatted correctly and have adequate permissions
router.use('/:userId', validateUserId);

// dogs: /api/v1/user/:userId/dogs
const dogsRouter = require('./dogs');

router.use('/:userId/dogs', dogsRouter);

// BASE PATH /api/v1/user/...

// creates user and userConfiguration
router.post('/', createUser);
/* BODY:
{
"userEmail":"requiredEmail",
"userFirstName":"requiredString",
"userLastName":"requiredString",
"isNotificationEnabled":"requiredBool",
"isLoudNotification":"requiredBool",
"isFollowUpEnabled":"requiredBool",
"followUpDelay":"requiredInt",
"isPaused":"requiredBool",
"isCompactView":"requiredBool",
"interfaceStyle":"requiredString",
"snoozeLength":"requiredInt",
"notificationSound":"requiredString"
}
*/

// updates user
router.put('/:userId', updateUser);
/* BODY:

//At least one of the following must be defined: userEmail, userFirstName, userLastName, isNotificationEnabled,
        isLoudNotification, isFollowUpEnabled, followUpDelay, isPaused, isCompactView,
        interfaceStyle, snoozeLength, or notificationSound

{
"userEmail":"optionalEmail",
"userFirstName":"optionalString",
"userLastName":"optionalString",
"isNotificationEnabled":"optionalBool",
"isLoudNotification":"optionalBool",
"isFollowUpEnabled":"optionalBool",
"followUpDelay":"optionalInt",
"isPaused":"optionalBool",
"isCompactView":"optionalBool",
"interfaceStyle":"optionalString",
"snoozeLength":"optionalInt",
"notificationSound":"optionalString"
}
*/

// deletes user
router.delete('/:userId', deleteUser);
// no body

module.exports = router;