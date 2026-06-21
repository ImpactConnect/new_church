import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/bible/bible_version.dart';

final bibleVersionServiceProvider = Provider((ref) => BibleVersionService());

class BibleVersionService {
  // Metadata to map API data to our internal schema
  static const List<Map<String, dynamic>> _booksMetadata = [
    {'name': 'Genesis', 'chapters': 50, 'id': 'gen'},
    {'name': 'Exodus', 'chapters': 40, 'id': 'exo'},
    {'name': 'Leviticus', 'chapters': 27, 'id': 'lev'},
    {'name': 'Numbers', 'chapters': 36, 'id': 'num'},
    {'name': 'Deuteronomy', 'chapters': 34, 'id': 'deu'},
    {'name': 'Joshua', 'chapters': 24, 'id': 'jos'},
    {'name': 'Judges', 'chapters': 21, 'id': 'jdg'},
    {'name': 'Ruth', 'chapters': 4, 'id': 'rut'},
    {'name': '1 Samuel', 'chapters': 31, 'id': '1sa'},
    {'name': '2 Samuel', 'chapters': 24, 'id': '2sa'},
    {'name': '1 Kings', 'chapters': 22, 'id': '1ki'},
    {'name': '2 Kings', 'chapters': 25, 'id': '2ki'},
    {'name': '1 Chronicles', 'chapters': 29, 'id': '1ch'},
    {'name': '2 Chronicles', 'chapters': 36, 'id': '2ch'},
    {'name': 'Ezra', 'chapters': 10, 'id': 'ezr'},
    {'name': 'Nehemiah', 'chapters': 13, 'id': 'neh'},
    {'name': 'Esther', 'chapters': 10, 'id': 'est'},
    {'name': 'Job', 'chapters': 42, 'id': 'job'},
    {'name': 'Psalms', 'chapters': 150, 'id': 'psa'},
    {'name': 'Proverbs', 'chapters': 31, 'id': 'pro'},
    {'name': 'Ecclesiastes', 'chapters': 12, 'id': 'ecc'},
    {'name': 'Song of Solomon', 'chapters': 8, 'id': 'sng'},
    {'name': 'Isaiah', 'chapters': 66, 'id': 'isa'},
    {'name': 'Jeremiah', 'chapters': 52, 'id': 'jer'},
    {'name': 'Lamentations', 'chapters': 5, 'id': 'lam'},
    {'name': 'Ezekiel', 'chapters': 48, 'id': 'ezk'},
    {'name': 'Daniel', 'chapters': 12, 'id': 'dan'},
    {'name': 'Hosea', 'chapters': 14, 'id': 'hos'},
    {'name': 'Joel', 'chapters': 3, 'id': 'jol'},
    {'name': 'Amos', 'chapters': 9, 'id': 'amo'},
    {'name': 'Obadiah', 'chapters': 1, 'id': 'oba'},
    {'name': 'Jonah', 'chapters': 4, 'id': 'jon'},
    {'name': 'Micah', 'chapters': 7, 'id': 'mic'},
    {'name': 'Nahum', 'chapters': 3, 'id': 'nam'},
    {'name': 'Habakkuk', 'chapters': 3, 'id': 'hab'},
    {'name': 'Zephaniah', 'chapters': 3, 'id': 'zep'},
    {'name': 'Haggai', 'chapters': 2, 'id': 'hag'},
    {'name': 'Zechariah', 'chapters': 14, 'id': 'zac'},
    {'name': 'Malachi', 'chapters': 4, 'id': 'mal'},
    {'name': 'Matthew', 'chapters': 28, 'id': 'mat'},
    {'name': 'Mark', 'chapters': 16, 'id': 'mrk'},
    {'name': 'Luke', 'chapters': 24, 'id': 'luk'},
    {'name': 'John', 'chapters': 21, 'id': 'jhn'},
    {'name': 'Acts', 'chapters': 28, 'id': 'act'},
    {'name': 'Romans', 'chapters': 16, 'id': 'rom'},
    {'name': '1 Corinthians', 'chapters': 16, 'id': '1co'},
    {'name': '2 Corinthians', 'chapters': 13, 'id': '2co'},
    {'name': 'Galatians', 'chapters': 6, 'id': 'gal'},
    {'name': 'Ephesians', 'chapters': 6, 'id': 'eph'},
    {'name': 'Philippians', 'chapters': 4, 'id': 'php'},
    {'name': 'Colossians', 'chapters': 4, 'id': 'col'},
    {'name': '1 Thessalonians', 'chapters': 5, 'id': '1th'},
    {'name': '2 Thessalonians', 'chapters': 3, 'id': '2th'},
    {'name': '1 Timothy', 'chapters': 6, 'id': '1ti'},
    {'name': '2 Timothy', 'chapters': 4, 'id': '2ti'},
    {'name': 'Titus', 'chapters': 3, 'id': 'tit'},
    {'name': 'Philemon', 'chapters': 1, 'id': 'phm'},
    {'name': 'Hebrews', 'chapters': 13, 'id': 'heb'},
    {'name': 'James', 'chapters': 5, 'id': 'jas'},
    {'name': '1 Peter', 'chapters': 5, 'id': '1pe'},
    {'name': '2 Peter', 'chapters': 3, 'id': '2pe'},
    {'name': '1 John', 'chapters': 5, 'id': '1jn'},
    {'name': '2 John', 'chapters': 1, 'id': '2jn'},
    {'name': '3 John', 'chapters': 1, 'id': '3jn'},
    {'name': 'Jude', 'chapters': 1, 'id': 'jud'},
    {'name': 'Revelation', 'chapters': 22, 'id': 'rev'},
  ];

  Future<String> _getLocalPath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  Future<bool> isVersionDownloaded(BibleVersion version) async {
    // KJV is always available as asset
    if (version == BibleVersion.kjv) return true;

    // Web does not support local file system storage for large JSONs
    if (kIsWeb) return false;

    final path = await _getLocalPath(
      '${version.abbreviation.toLowerCase()}.json',
    );
    return File(path).exists();
  }

  Future<void> downloadVersion(
    BibleVersion version, {
    required Function(double progress) onProgress,
  }) async {
    try {
      if (kIsWeb) throw Exception('Download not supported on Web');

      final url =
          'https://api.getbible.net/v2/${version.abbreviation.toLowerCase()}.json';

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final rawResponse = await request.close();
      
      onProgress(0.85); // Processing starting

      final responseBody = await rawResponse.transform(utf8.decoder).join();
      if (responseBody.isEmpty) throw Exception('Empty response');

      final Map<String, dynamic> jsonData = json.decode(responseBody);

      // Check format
      // getbible.net/v2/[version].json returns { ..., "books": [...] }
      if (!jsonData.containsKey('books')) {
        throw Exception('Invalid JSON format: missing "books" key');
      }

      final List<dynamic> sourceBooks = jsonData['books'];
      final List<Map<String, dynamic>> targetBooks = [];

      // Map books using metadata
      // Assumption: Source books are in standard order 1..66
      for (
        int i = 0;
        i < sourceBooks.length && i < _booksMetadata.length;
        i++
      ) {
        final sourceBook = sourceBooks[i];
        final metadata = _booksMetadata[i];
        final bookId = metadata['id'] as String;
        final bookName = metadata['name'] as String;

        // Source structure: { "chapters": [ { "verses": [ { "verse": 1, "text": "..." }, ... ] }, ... ] }
        final List<dynamic> sourceChapters = sourceBook['chapters'];
        final List<Map<String, dynamic>> targetChapters = [];

        for (int c = 0; c < sourceChapters.length; c++) {
          final sourceChapter = sourceChapters[c];
          final chapterNum = sourceChapter['chapter'] as int;

          final List<dynamic> sourceVerses = sourceChapter['verses'];
          final List<Map<String, dynamic>> targetVerses = [];

          for (final sourceVerse in sourceVerses) {
            final verseNum = sourceVerse['verse'] as int;
            final text = sourceVerse['text'] as String;

            targetVerses.add({
              'number': verseNum,
              'text': text,
              'id': '$bookId-$chapterNum-$verseNum',
            });
          }

          targetChapters.add({
            'number': chapterNum,
            'verses': targetVerses,
            'id': '$bookId-$chapterNum',
          });
        }

        targetBooks.add({
          'name': bookName,
          'id': bookId,
          'chapters': targetChapters,
        });
      }

      onProgress(0.95); // Saving

      final savePath = await _getLocalPath(
        '${version.abbreviation.toLowerCase()}.json',
      );
      final file = File(savePath);
      await file.writeAsString(json.encode(targetBooks));

      onProgress(1.0);
    } catch (e) {
      throw Exception('Failed to download ${version.name}: $e');
    }
  }

  Future<void> deleteVersion(BibleVersion version) async {
    if (version == BibleVersion.kjv) return; // Cannot delete asset version

    final path = await _getLocalPath(
      '${version.abbreviation.toLowerCase()}.json',
    );
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
