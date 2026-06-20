import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_plan_repository.g.dart';

/// Stub active reading plan model.
class ReadingPlan {
  final String id;
  final String title;
  final List<ReadingDay> days;
  final DateTime startDate;
  final int completedDays;

  const ReadingPlan({
    required this.id,
    required this.title,
    required this.days,
    required this.startDate,
    required this.completedDays,
  });
}

class ReadingDay {
  final int dayNumber;
  final String title;
  final List<String> readings;

  const ReadingDay({
    required this.dayNumber,
    required this.title,
    required this.readings,
  });
}

/// Always returns null (no active plan) — stub until reading plans are implemented.
@riverpod
Future<ReadingPlan?> activePlan(ActivePlanRef ref) async => null;
