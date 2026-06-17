import 'package:cloud_firestore/cloud_firestore.dart';

class Devotional {
  Devotional({
    required this.id,
    required this.topic,
    required this.date,
    required this.bibleVerse,
    required this.bibleVerseText,
    required this.content,
    required this.prayerPoints,
    required this.author,
    required this.createdAt,
  });

  factory Devotional.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Devotional(
      id: doc.id,
      topic: data['topic'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      bibleVerse: data['bibleVerse'] ?? '',
      bibleVerseText: data['bibleVerseText'] ?? '',
      content: data['content'] ?? '',
      prayerPoints: List<String>.from(data['prayerPoints'] ?? []),
      author: data['author'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : (data['date'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String topic;
  final DateTime date;
  final String bibleVerse;
  final String bibleVerseText;
  final String content;
  final List<String> prayerPoints;
  final String author;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'topic': topic,
      'date': Timestamp.fromDate(date),
      'bibleVerse': bibleVerse,
      'bibleVerseText': bibleVerseText,
      'content': content,
      'prayerPoints': prayerPoints,
      'author': author,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
