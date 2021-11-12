
# Hound Queries


#Get User Data
###(given user_id)
SELECT
user_first_name,
user_last_name,
user_email
FROM users
WHERE user_id = 'VARIABLE';

###(given user_email)
SELECT
user_id,
user_first_name,
user_last_name
FROM users
WHERE users.email = 'VARIABLE';



#Get User Configuration
###(given user_id)
SELECT
*
FROM user_configuration
WHERE users.user_id = 'VARIABLE';



#Get Dogs
###given user_id)
SELECT
dogs.dog_id,
dogs.icon,
dogs.name
FROM dogs
WHERE dogs.user_id = 'VARIABLE';



#Get Logs
###(given dog_id)
SELECT
dog_logs.log_id,
dog_logs.date,
dog_logs.note,
log_types.type_name,
dog_logs.custom_type_name
FROM dog_logs JOIN log_types ON dog_logs.log_type = log_types.type_int
WHERE dog_logs.dog_id = 'VARIABLE';

###(given user_id)
SELECT
dogs_logs.dog_id
dog_logs.log_id,
dog_logs.date,
dog_logs.note,
log_types.type_name,
dog_logs.custom_type_name
FROM dog_logs JOIN log_types ON dog_logs.log_type = log_types.type_int
JOIN dogs ON dog_logs.dog_id = dogs.dog_id
WHERE dog.user_id = 'VARIABLE';



#Get Reminders
###(given dog_id)
SELECT
dog_reminders.reminder_id,
reminder_types.type_name,
dog_reminders.custom_type_name,
dog_reminders.timing_style,
dog_reminders.execution_basis,
dog_reminders.enabled
FROM dog_reminders
JOIN reminder_types ON dog_reminders.reminder_type = reminder_types.type_int
WHERE dog_reminders.dog_id = 'VARIABLE';

###(given user_id)
SELECT
dogs.dog_id,
dog_reminders.reminder_id,
reminder_types.type_name,
dog_reminders.custom_type_name,
dog_reminders.timing_style,
dog_reminders.execution_basis,
dog_reminders.enabled
FROM dog_reminders
JOIN reminder_types ON dog_reminders.reminder_type = reminder_types.type_int
JOIN dogs ON dog_reminders.dog_id = dogs.dog_id
WHERE dogs.user_id = 'VARIABLE';



#Get Reminder Components
###(given reminder_id)
SELECT
reminder_countdown_components.execution_interval,
reminder_countdown_components.interval_elapsed,
reminder_time_of_day_components.day_of_month,
reminder_time_of_day_components.weekdays,
reminder_time_of_day_components.hour,
reminder_time_of_day_components.minute,
reminder_time_of_day_components.skipping,
reminder_time_of_day_components.skip_date,
reminder_one_time_components.year,
reminder_one_time_components.month,
reminder_one_time_components.day,
reminder_one_time_components.hour,
reminder_one_time_components.minute
FROM reminder_countdown_components
JOIN reminder_time_of_day_components ON reminder_countdown_components.reminder_id = reminder_time_of_day_components.reminder_id
JOIN reminder_one_time_components ON reminder_countdown_components.reminder_id = reminder_one_time_components.reminder_id
WHERE reminder_countdown_components.reminder_id = 'VARIABLE';

