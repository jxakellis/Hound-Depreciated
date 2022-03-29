const express = require('express');

const router = express.Router({ mergeParams: true });

const {
  getReminders, createReminder, updateReminder, deleteReminder,
} = require('../controllers/main/reminders');
const { validateParamsReminderId, validateBodyReminderId } = require('../utils/validateId');

// No need to validate body for get ( no body exists)
// No need to validate body for create ( there are no passed reminders )
// validation body for put and delete below at their specific routes
// validation that params are formatted correctly and have adequate permissions
router.use('/:reminderId', validateParamsReminderId);

// BASE PATH /api/v1/user/:userId/dogs/:dogId/reminders/...

// gets all reminders
router.get('/', getReminders);
// no body

// gets specific reminder
router.get('/:reminderId', getReminders);
// no body

// create reminder(s)
router.post('/', createReminder);
/* BODY:
Single: { reminderInfo }
Multiple: { reminders: [reminderInfo1, reminderInfo2...] }

reminderInfo:
{
"reminderAction": "requiredString", // If reminderAction is "Custom", then customTypeName must be provided
"customTypeName": "optionalString",
"reminderType": "requiredString", //Only components for reminderType type specified must be provided
"executionBasis": "requiredDate",
"isEnabled":"requiredBool",

    //FOR countdown
    "countdownExecutionInterval":"requiredInt",
    "countdownIntervalElapsed":"requiredInt"

    //FOR weekly
    "weeklyHour":"requiredInt",
    "weeklyMinute":"requiredInt",
    "sunday":"requiredBool",
    "monday":"requiredBool",
    "tuesday":"requiredBool",
    "wednesday":"requiredBool",
    "thursday":"requiredBool",
    "friday":"requiredBool",
    "saturday":"requiredBool",
    "weeklyIsSkipping":"requiredBool",
    "weeklyIsSkippingDate":"optionalDate"

    //FOR monthly
    "monthlyHour":"requiredInt",
    "monthlyMinute":"requiredInt",
    "dayOfMonth":"requiredInt"
    "weeklyIsSkipping":"requiredBool",
    "monthlyIsSkippingDate":"optionalDate"

    //FOR oneTime
    "date":"requiredDate"

    //FOR snooze
    no snooze components in creation, only when actually snoozed
}
}
*/

// update reminder(s)
router.put('/', validateBodyReminderId, updateReminder);
router.put('/:reminderId', updateReminder);
/* BODY:
Single: { reminderInfo }
Multiple: { reminders: [reminderInfo1, reminderInfo2...] }

reminderInfo:
//At least one of the following must be defined: reminderAction, reminderType, executionBasis, isEnabled, or isSnoozed

{
"reminderAction": "optionalString", // If reminderAction is "Custom", then customTypeName must be provided
"customTypeName": "optionalString",
"reminderType": "optionalString", // If reminderType provided, then all components for reminderType type must be provided
"executionBasis": "optionalDate",
"isEnabled":"optionalBool",

    //components only required if reminderType provided

    //FOR countdown
    "countdownExecutionInterval":"requiredInt",
    "countdownIntervalElapsed":"requiredInt"

    //FOR weekly
    "weeklyHour":"requiredInt",
    "weeklyMinute":"requiredInt",
    "sunday":"requiredBool",
    "monday":"requiredBool",
    "tuesday":"requiredBool",
    "wednesday":"requiredBool",
    "thursday":"requiredBool",
    "friday":"requiredBool",
    "saturday":"requiredBool",
    "weeklyIsSkipping":"optionalBool", //if weeklyIsSkipping is provided, then weeklyIsSkippingDate is required
    "weeklyIsSkippingDate":"optionalDate"

    //FOR monthly
    "monthlyHour":"requiredInt",
    "monthlyMinute":"requiredInt",
    "dayOfMonth":"requiredInt"
    "monthlyIsSkipping":"optionalBool", //if monthlyIsSkipping is provided, then monthlyIsSkippingDate is required
    "weeklyIsSkippingDate":"optionalDate"

    //FOR oneTime
    "date":"requiredDate"

    //FOR snooze
    "isSnoozed":"requiredBool",
    "snoozeExecutionInterval":"optionalInt", //if isSnoozed is true, then snoozeExecutionInterval and snoozeIntervalElapsed are required
    "snoozeIntervalElapsed":"optionalInt"
}
}
*/

// delete reminder(s)
router.delete('/', validateBodyReminderId, deleteReminder);
router.delete('/:reminderId', deleteReminder);
/* BODY:
Single: No Body
Multiple: { reminders: [reminderId1, reminderId2...] }
*/

module.exports = router;