import 'package:flutter/material.dart';
import '../services/local_notification_service.dart';
import '../services/reminder_preferences.dart';

class ReminderSettingsDialog extends StatefulWidget {
  const ReminderSettingsDialog({Key? key}) : super(key: key);

  @override
  State<ReminderSettingsDialog> createState() => _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState extends State<ReminderSettingsDialog> {
  bool _remindersEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _selectedWeekDay = DateTime.sunday;
  TimeOfDay _selectedWeeklyTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final enabled = await ReminderPreferences.getRemindersEnabled();
    final dailyTime = await ReminderPreferences.getDailyReminderTime();
    final weeklyTime = await ReminderPreferences.getWeeklyReminderTime();

    setState(() {
      _remindersEnabled = enabled;
      if (dailyTime != null) {
        _selectedTime = TimeOfDay.fromDateTime(dailyTime);
      }
      if (weeklyTime != null) {
        _selectedWeekDay = weeklyTime.weekday;
        _selectedWeeklyTime = TimeOfDay.fromDateTime(weeklyTime);
      }
    });
  }

  Future<void> _savePreferences() async {
    await ReminderPreferences.setRemindersEnabled(_remindersEnabled);
    
    if (_remindersEnabled) {
      final now = DateTime.now();
      final dailyTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      await ReminderPreferences.setDailyReminderTime(dailyTime);

      // Schedule daily reminder using OneSignal
      await LocalNotificationService().scheduleReadingReminder(
        time: _selectedTime,
        title: 'Bible Reading Reminder',
        body: 'Time for your daily Bible reading!',
      );

      // Schedule weekly summary
      final weeklyTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedWeeklyTime.hour,
        _selectedWeeklyTime.minute,
      );
      await ReminderPreferences.setWeeklyReminderTime(weeklyTime);
      await LocalNotificationService().scheduleWeeklySummary(
        time: _selectedWeeklyTime,
        weekday: _selectedWeekDay,
        completedDays: 0,
        totalDays: 365,
      );
    } else {
      await LocalNotificationService().cancelAllNotifications();
    }
  }

  Future<void> _selectDailyTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectWeeklyTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedWeeklyTime,
    );
    if (picked != null && picked != _selectedWeeklyTime) {
      setState(() {
        _selectedWeeklyTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reading Reminder Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Reminders'),
              value: _remindersEnabled,
              onChanged: (value) {
                setState(() {
                  _remindersEnabled = value;
                });
              },
            ),
            const Divider(),
            if (_remindersEnabled) ...[
              ListTile(
                title: const Text('Daily Reminder Time'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _selectDailyTime,
              ),
              const Divider(),
              ListTile(
                title: const Text('Weekly Summary'),
                subtitle: Text(
                  '${_getWeekDayName(_selectedWeekDay)} at ${_selectedWeeklyTime.format(context)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectWeeklyTime,
              ),
              DropdownButton<int>(
                value: _selectedWeekDay,
                items: [
                  for (int i = 1; i <= 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(_getWeekDayName(i)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedWeekDay = value;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _savePreferences();
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getWeekDayName(int day) {
    switch (day) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }
}
