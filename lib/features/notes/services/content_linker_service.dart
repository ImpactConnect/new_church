import 'package:uuid/uuid.dart';
import '../data/models/linked_content_reference.dart';

/// Service for formatting and linking content from different sources to notes
class ContentLinkerService {
  static const _uuid = Uuid();

  /// Formats Bible verse content for adding to a note
  /// Returns formatted string: "Book Chapter:Verse - [verse text]"
  static String formatBibleVerse({
    required String bookName,
    required int chapter,
    required int verse,
    required String verseText,
  }) {
    return '$bookName $chapter:$verse\n\n"$verseText"';
  }

  /// Creates a LinkedContentReference for a Bible verse
  static LinkedContentReference createVerseReference({
    required String verseId,
    required String bookName,
    required int chapter,
    required int verse,
  }) {
    return LinkedContentReference(
      id: _uuid.v4(),
      type: LinkedContentType.verse,
      sourceId: verseId,
      sourceReference: '$bookName $chapter:$verse',
      linkedAt: DateTime.now(),
      metadata: {
        'book': bookName,
        'chapter': chapter,
        'verse': verse,
      },
    );
  }

  /// Formats chat message content for adding to a note
  /// Returns formatted string: "[Sender] - [timestamp]: [message]"
  static String formatChatMessage({
    required String sender,
    required DateTime timestamp,
    required String message,
  }) {
    final timeStr = timestamp.toString().split('.')[0];
    return '**$sender** - $timeStr\n\n$message';
  }

  /// Creates a LinkedContentReference for a chat message
  static LinkedContentReference createChatReference({
    required String messageId,
    required String sender,
    required String messagePreview,
  }) {
    return LinkedContentReference(
      id: _uuid.v4(),
      type: LinkedContentType.chat,
      sourceId: messageId,
      sourceReference: 'Chat: $messagePreview',
      linkedAt: DateTime.now(),
      metadata: {
        'sender': sender,
        'messageId': messageId,
      },
    );
  }

  /// Formats study content for adding to a note
  /// Returns formatted string: "[Study Title]\n[Section Headers]\n[Content]"
  static String formatStudyContent({
    required String studyTitle,
    required String sectionTitle,
    required String content,
  }) {
    return '**$studyTitle**\n\n*$sectionTitle*\n\n$content';
  }

  /// Creates a LinkedContentReference for study content
  static LinkedContentReference createStudyReference({
    required String studyId,
    required String studyTitle,
    required String sectionId,
  }) {
    return LinkedContentReference(
      id: _uuid.v4(),
      type: LinkedContentType.study,
      sourceId: studyId,
      sourceReference: 'Study: $studyTitle',
      linkedAt: DateTime.now(),
      metadata: {
        'studyId': studyId,
        'sectionId': sectionId,
      },
    );
  }

  /// Formats exegesis content for adding to a note
  /// Returns formatted string: "[Verse Reference] - Exegesis\n[Analysis sections]"
  static String formatExegesisContent({
    required String verseReference,
    required String analysisType,
    required String content,
  }) {
    return '**$verseReference - Exegesis**\n\n*$analysisType*\n\n$content';
  }

  /// Creates a LinkedContentReference for exegesis content
  static LinkedContentReference createExegesisReference({
    required String exegesisId,
    required String verseReference,
    required String analysisType,
  }) {
    return LinkedContentReference(
      id: _uuid.v4(),
      type: LinkedContentType.exegesis,
      sourceId: exegesisId,
      sourceReference: 'Exegesis: $verseReference',
      linkedAt: DateTime.now(),
      metadata: {
        'exegesisId': exegesisId,
        'verseReference': verseReference,
        'analysisType': analysisType,
      },
    );
  }
}
