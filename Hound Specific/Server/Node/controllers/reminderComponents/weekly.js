const { queryPromise } = require('../../main/tools/database/queryPromise');
const { formatDate, formatBoolean, formatNumber } = require('../../main/tools/validation/validateFormat');

const createWeeklyComponents = async (req, reminder) => {
  const weeklyHour = formatNumber(reminder.weeklyHour);
  const weeklyMinute = formatNumber(reminder.weeklyMinute);
  const sunday = formatBoolean(reminder.sunday);
  const monday = formatBoolean(reminder.monday);
  const tuesday = formatBoolean(reminder.tuesday);
  const wednesday = formatBoolean(reminder.wednesday);
  const thursday = formatBoolean(reminder.thursday);
  const friday = formatBoolean(reminder.friday);
  const saturday = formatBoolean(reminder.saturday);

  // TO DO add check that all components are defined (or throw validation error)

  // Errors intentionally uncaught so they are passed to invocation in reminders
  // Newly created weekly reminder cant be weeklyIsSkipping, so no need for skip data
  await queryPromise(
    req,
    'INSERT INTO reminderWeeklyComponents(reminderId, weeklyHour, weeklyMinute, sunday, monday, tuesday, wednesday, thursday, friday, saturday) VALUES (?,?,?,?,?,?,?,?,?,?)',
    [reminder.reminderId, weeklyHour, weeklyMinute, sunday, monday, tuesday, wednesday, thursday, friday, saturday],
  );
};

// Attempts to first add the new components to the table. iI this fails then it is known the reminder is already present or components are invalid. If the update statement fails then it is know the components are invalid, error passed to invocer.
const updateWeeklyComponents = async (req, reminder) => {
  const weeklyHour = formatNumber(reminder.weeklyHour);
  const weeklyMinute = formatNumber(reminder.weeklyMinute);
  const sunday = formatBoolean(reminder.sunday);
  const monday = formatBoolean(reminder.monday);
  const tuesday = formatBoolean(reminder.tuesday);
  const wednesday = formatBoolean(reminder.wednesday);
  const thursday = formatBoolean(reminder.thursday);
  const friday = formatBoolean(reminder.friday);
  const saturday = formatBoolean(reminder.saturday);
  const weeklyIsSkipping = formatBoolean(reminder.weeklyIsSkipping);
  const weeklyIsSkippingDate = formatDate(reminder.weeklyIsSkippingDate);

  // TO DO add check that all components are defined (or throw validation error)

  try {
    // If this succeeds: Reminder was not present in the weekly table and the reminderType was changed. The old components will be deleted from the other table by reminders
    // If this fails: The components provided are invalid or reminder already present in table (reminderId UNIQUE in DB)
    await queryPromise(
      req,
      'INSERT INTO reminderWeeklyComponents(reminderId, weeklyHour, weeklyMinute, sunday, monday, tuesday, wednesday, thursday, friday, saturday) VALUES (?,?,?,?,?,?,?,?,?,?)',
      [reminder.reminderId, weeklyHour, weeklyMinute, sunday, monday, tuesday, wednesday, thursday, friday, saturday],
    );
    return;
  }
  catch (error) {
    // If this succeeds: Reminder was present in the weekly table, reminderType didn't change, and the components were successfully updated
    // If this fails: The components provided are invalid. It is uncaught here to intentionally be caught by invocation from reminders.
    await queryPromise(
      req,
      'UPDATE reminderWeeklyComponents SET weeklyHour = ?, weeklyMinute = ?, sunday = ?, monday = ?, tuesday = ?, wednesday = ?, thursday = ?, friday = ?, saturday = ?, weeklyIsSkipping = ?, weeklyIsSkippingDate = ? WHERE reminderId = ?',
      [weeklyHour, weeklyMinute, sunday, monday, tuesday, wednesday, thursday, friday, saturday, weeklyIsSkipping, weeklyIsSkippingDate, reminder.reminderId],
    );
  }
};

module.exports = { createWeeklyComponents, updateWeeklyComponents };
