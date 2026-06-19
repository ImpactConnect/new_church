import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_reading_plan.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/local_notification_service.dart';
import '../services/reminder_preferences.dart';

class BibleReadingPlanScreen extends StatefulWidget {
  const BibleReadingPlanScreen({Key? key}) : super(key: key);

  @override
  State<BibleReadingPlanScreen> createState() => _BibleReadingPlanScreenState();
}

class _BibleReadingPlanScreenState extends State<BibleReadingPlanScreen> {
  List<BibleReading>? _readingPlan;
  BibleReading? _todaysReading;
  late DateTime _selectedDate;
  late int _selectedMonth;
  late int _selectedYear;
  bool _isLoading = true;
  int _completedDays = 0;

  // Reminder settings
  bool _remindersEnabled = false;
  TimeOfDay? _reminderTime;
  int _totalDays = 365; // Total days in the reading plan
  TimeOfDay? _reportTime;
  int _reportWeekDay = DateTime.sunday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadReadingPlan();
    _loadReminderPreferences();
  }

  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _loadReadingPlan() async {
    try {
      _readingPlan = await BibleReadingPlan.generateYearlyPlan();
      _todaysReading = _getReadingForDate(DateTime.now());
      await _loadSavedProgress();
    } catch (e) {
      print('Error loading Bible reading plan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateCompletedDays() {
    if (_readingPlan == null) return;
    _completedDays =
        _readingPlan!.where((reading) => reading.isCompleted).length;
    _saveProgress();
    setState(() {});
  }

  Future<void> _saveProgress() async {
    if (_readingPlan == null) return;
    final prefs = await SharedPreferences.getInstance();
    final completedDates = _readingPlan!
        .where((reading) => reading.isCompleted)
        .map((reading) => reading.date.toIso8601String())
        .toList();
    await prefs.setStringList('completed_readings', completedDates);
  }

  Future<void> _loadSavedProgress() async {
    if (_readingPlan == null) return;
    final prefs = await SharedPreferences.getInstance();
    final completedDates = prefs.getStringList('completed_readings') ?? [];
    for (var reading in _readingPlan!) {
      reading.isCompleted =
          completedDates.contains(reading.date.toIso8601String());
    }
    _updateCompletedDays();
  }

  BibleReading? _getReadingForDate(DateTime date) {
    if (_readingPlan == null) return null;
    try {
      return _readingPlan!.firstWhere(
        (reading) => _isSameDay(reading.date, date),
      );
    } catch (e) {
      return BibleReading(
        date: date,
        passages: ['No reading scheduled for this date'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text('Bible Reading Plan'),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/bible_reading_plan.jpg',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Progress Tracker
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Reading Progress',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: _readingPlan != null
                                  ? _completedDays / 365
                                  : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_completedDays/365 days completed',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Today's Reading Card
                    if (_todaysReading != null)
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Today\'s Reading',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (_todaysReading!.isCompleted)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...(_todaysReading!.passages.map(
                                (passage) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(passage),
                                ),
                              )).toList(),
                              const SizedBox(height: 16),
                              if (!_todaysReading!.isCompleted)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _todaysReading!.isCompleted = true;
                                      _updateCompletedDays();
                                    });
                                  },
                                  child: const Text('Mark as Completed'),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // Month Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                if (_selectedMonth == 1) {
                                  _selectedMonth = 12;
                                  _selectedYear--;
                                } else {
                                  _selectedMonth--;
                                }
                              });
                            },
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(
                                DateTime(_selectedYear, _selectedMonth)),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                if (_selectedMonth == 12) {
                                  _selectedMonth = 1;
                                  _selectedYear++;
                                } else {
                                  _selectedMonth++;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Calendar Grid
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              mainAxisExtent: 35,
                            ),
                            itemCount: 7 +
                                DateTime(_selectedYear, _selectedMonth + 1, 0)
                                    .day,
                            itemBuilder: (context, index) {
                              if (index < 7) {
                                // Weekday headers
                                final weekday =
                                    ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index];
                                return Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    weekday,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                );
                              }

                              final day = index - 7 + 1;
                              final date =
                                  DateTime(_selectedYear, _selectedMonth, day);
                              final isToday = _isSameDay(date, DateTime.now());
                              final isSelected =
                                  _isSameDay(date, _selectedDate);
                              final reading = _getReadingForDate(date);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = date;
                                    _todaysReading = reading;
                                  });
                                  _showReadingDialog(context, reading);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : null,
                                    border: Border.all(
                                      color: isToday
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Text(
                                          day.toString(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : isToday
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : null,
                                            fontWeight: isToday || isSelected
                                                ? FontWeight.bold
                                                : null,
                                          ),
                                        ),
                                      ),
                                      if (reading?.isCompleted ?? false)
                                        const Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Icon(
                                            Icons.check_circle,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Reminder Settings Section
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Reading Reminders',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Switch(
                                        value: _remindersEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _remindersEnabled = value;
                                            _saveReminderPreferences();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_remindersEnabled) ...[
                                    ListTile(
                                      leading: const Icon(Icons.access_time),
                                      title: const Text('Reminder Time'),
                                      subtitle: Text(
                                          _reminderTime?.format(context) ??
                                              'Not set'),
                                      onTap: () => _selectReminderTime(context),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.summarize),
                                      title: const Text('Weekly Report'),
                                      subtitle: Text(_reportTime != null
                                          ? '${_getWeekDayName(_reportWeekDay)} at ${_reportTime!.format(context)}'
                                          : 'Not set'),
                                      onTap: () => _selectReportTime(context),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _loadReminderPreferences() async {
    final enabled = await ReminderPreferences.getRemindersEnabled();
    final dailyTime = await ReminderPreferences.getDailyReminderTime();
    final weeklyTime = await ReminderPreferences.getWeeklyReminderTime();

    setState(() {
      _remindersEnabled = enabled;
      _reminderTime = dailyTime != null
          ? TimeOfDay.fromDateTime(dailyTime)
          : const TimeOfDay(hour: 8, minute: 0);
      if (weeklyTime != null) {
        _reportWeekDay = weeklyTime.weekday;
        _reportTime = TimeOfDay.fromDateTime(weeklyTime);
      }
    });
  }

  Future<void> _saveReminderPreferences() async {
    await ReminderPreferences.setRemindersEnabled(_remindersEnabled);

    if (_remindersEnabled) {
      final now = DateTime.now();
      if (_reminderTime != null) {
        final dailyTime = DateTime(
          now.year,
          now.month,
          now.day,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );
        await ReminderPreferences.setDailyReminderTime(dailyTime);
        await LocalNotificationService().scheduleReadingReminder(
          time: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
          title: 'Bible Reading Reminder',
          body: 'Time for your daily Bible reading!',
        );
      }

      if (_reportTime != null) {
        final weeklyTime = DateTime(
          now.year,
          now.month,
          now.day,
          _reportTime!.hour,
          _reportTime!.minute,
        );
        await ReminderPreferences.setWeeklyReminderTime(weeklyTime);
        await LocalNotificationService().scheduleWeeklySummary(
          time: _reportTime ?? const TimeOfDay(hour: 20, minute: 0),
          weekday: _reportWeekDay,
          completedDays: _completedDays ?? 0,
          totalDays: _totalDays,
        );
      }
    } else {
      await LocalNotificationService().cancelAllNotifications();
    }
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await _saveReminderPreferences();
    }
  }

  Future<void> _selectReportTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reportTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null && picked != _reportTime) {
      setState(() {
        _reportTime = picked;
      });
      await _saveReminderPreferences();
    }
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

  void _showReadingDialog(BuildContext context, BibleReading? reading) {
    if (reading == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DateFormat('MMMM d, yyyy').format(reading.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reading for today:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...reading.passages.map(
                (passage) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(passage),
                ),
              ),
              const SizedBox(height: 16),
              if (!reading.isCompleted)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      reading.isCompleted = true;
                      _updateCompletedDays();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mark as Completed'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
