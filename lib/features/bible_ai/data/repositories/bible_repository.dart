import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bible/bible_book.dart';
import '../models/bible/bible_version.dart';

/// Abstract interface for the Bible data source.
abstract class BibleRepository {
  Future<List<BibleBook>> getBooks(BibleVersion version);
  Future<BibleBook?> getBook(String bookId, BibleVersion version);
}

/// Local JSON implementation — reads from bundled assets/json/*.json files.
class LocalJsonBibleRepository implements BibleRepository {
  final Map<BibleVersion, List<BibleBook>> _cache = {};

  @override
  Future<List<BibleBook>> getBooks(BibleVersion version) async {
    if (_cache.containsKey(version)) return _cache[version]!;
    final books = await _loadFromAsset(version);
    _cache[version] = books;
    return books;
  }

  @override
  Future<BibleBook?> getBook(String bookId, BibleVersion version) async {
    final books = await getBooks(version);
    try {
      return books.firstWhere((b) => b.id.toLowerCase() == bookId.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<List<BibleBook>> _loadFromAsset(BibleVersion version) async {
    final raw = await rootBundle.loadString(version.assetPath);
    final List<dynamic> json = jsonDecode(raw);
    return json.map((b) => BibleBook.fromJson(Map<String, dynamic>.from(b))).toList();
  }
}
