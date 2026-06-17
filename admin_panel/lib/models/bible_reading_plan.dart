import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class BibleReading {
  final DateTime date;
  final List<String> passages;
  bool isCompleted;

  BibleReading({
    required this.date,
    required this.passages,
    this.isCompleted = false,
  });

  factory BibleReading.fromMap(Map<String, dynamic> map) {
    return BibleReading(
      date: (map['date'] as Timestamp).toDate(),
      passages: List<String>.from(map['passages']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'passages': passages,
      'isCompleted': isCompleted,
    };
  }
}

class BibleReadingPlan {
  static Future<List<BibleReading>> generateYearlyPlan() async {
    final List<BibleReading> plan = [];
    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);

    // Load KJV Bible data
    final String jsonString = await rootBundle.loadString('assets/docs/kjv.json');
    final List<dynamic> bibleData = json.decode(jsonString);

    // Group verses by book and chapter
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedVerses = {};
    for (var verse in bibleData) {
      final book = verse['book'];
      final chapter = verse['chapter'];
      groupedVerses[book] ??= {};
      groupedVerses[book]![chapter] ??= [];
      groupedVerses[book]![chapter]!.add(verse);
    }

    // Organize books into categories (Old Testament, Gospels, Rest of New Testament)
    Map<String, List<String>> bookCategories = {
      'OT': [],
      'Gospels': ['Matthew', 'Mark', 'Luke', 'John'],
      'NT': [],
    };

    for (var book in groupedVerses.keys) {
      if (bookCategories['Gospels']!.contains(book)) continue;
      if (book == 'Acts' || 
          book == 'Romans' || 
          book.contains('Corinthians') || 
          book.contains('Timothy') ||
          book.contains('Peter') ||
          book.contains('John') ||
          book == 'Revelation') {
        bookCategories['NT']!.add(book);
      } else {
        bookCategories['OT']!.add(book);
      }
    }

    // Create chapter lists for each category
    Map<String, List<Map<String, dynamic>>> categoryChapters = {};
    for (var category in bookCategories.keys) {
      categoryChapters[category] = [];
      for (var book in bookCategories[category]!) {
        var chapters = groupedVerses[book]!.keys.toList();
        for (var chapter in chapters) {
          categoryChapters[category]!.add({
            'book': book,
            'chapter': chapter,
          });
        }
      }
    }

    // Calculate chapters needed per category per day
    int totalDays = 365;
    Map<String, int> chaptersPerCategory = {
      'OT': 2,
      'Gospels': 1,
      'NT': 1,
    };

    // Create daily readings
    for (int day = 0; day < totalDays; day++) {
      final date = startDate.add(Duration(days: day));
      List<String> passages = [];

      // Add chapters from each category
      categoryChapters.forEach((category, chapters) {
        int chaptersNeeded = chaptersPerCategory[category] ?? 0;
        int startIndex = (day * chaptersNeeded) % chapters.length;
        
        for (int i = 0; i < chaptersNeeded; i++) {
          int index = (startIndex + i) % chapters.length;
          var chapter = chapters[index];
          passages.add('${chapter['book']} ${chapter['chapter']}');
        }
      });

      if (passages.isEmpty) {
        passages = ['Reading plan completed!'];
      }

      plan.add(
        BibleReading(
          date: date,
          passages: passages,
        ),
      );
    }

    return plan;
  }
}
