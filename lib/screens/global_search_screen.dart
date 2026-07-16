import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/sermon.dart';
import '../models/devotional.dart';
import '../models/event.dart' as app_event;
import 'sermon_screen.dart';
import 'devotional_screen.dart';
import 'event_details_screen.dart';
import 'media/video_screen.dart';
import '../../main.dart';
import '../features/notes/presentation/screens/standalone_notes_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  // We will just fetch everything and filter locally for simplicity,
  // or use basic firestore queries where possible.
  List<dynamic> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchQuery = q;
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final firestore = FirebaseFirestore.instance;
      List<dynamic> results = [];

      // 1. Sermons
      final sermonsSnap = await firestore.collection('sermons').get();
      for (var doc in sermonsSnap.docs) {
        final title = (doc.data()['title'] ?? '').toString().toLowerCase();
        if (title.contains(q)) {
          results.add({'type': 'Sermon', 'data': doc});
        }
      }

      // 2. Devotionals
      final devosSnap = await firestore.collection('devotionals').get();
      for (var doc in devosSnap.docs) {
        final title = (doc.data()['title'] ?? '').toString().toLowerCase();
        if (title.contains(q)) {
          results.add({'type': 'Devotional', 'data': doc});
        }
      }

      // 3. Events
      final eventsSnap = await firestore.collection('events').get();
      for (var doc in eventsSnap.docs) {
        final title = (doc.data()['title'] ?? '').toString().toLowerCase();
        if (title.contains(q)) {
          results.add({'type': 'Event', 'data': doc});
        }
      }

      // 4. Videos
      final videosSnap = await firestore.collection('videos').get();
      for (var doc in videosSnap.docs) {
        final title = (doc.data()['title'] ?? '').toString().toLowerCase();
        if (title.contains(q)) {
          results.add({'type': 'Video', 'data': doc});
        }
      }

      // 5. Notes (Firestore notes or local Hive?)
      // Assuming notes might be stored in 'notes' collection for the user.
      // But standalone notes are in Hive 'notes_box'. 
      // We will skip Hive notes for now to keep it simple, or we can just redirect to Notes screen for note search.

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  void _handleResultTap(Map<String, dynamic> result) {
    final type = result['type'] as String;
    final doc = result['data'] as QueryDocumentSnapshot;

    switch (type) {
      case 'Sermon':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SermonScreen(
              sermonService: MyApp.of(context).sermonService,
              audioPlayerService: MyApp.of(context).audioPlayerService,
              initialSermonId: doc.id,
            ),
          ),
        );
        break;
      case 'Devotional':
        Navigator.pushNamed(context, '/devotional');
        break;
      case 'Event':
        final event = app_event.Event.fromFirestore(doc);
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)));
        break;
      case 'Video':
        Navigator.pushNamed(context, '/videos');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search sermons, devotionals, events...',
            border: InputBorder.none,
          ),
          onChanged: (val) {
            // Optional: debounce this
          },
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchQuery.isEmpty
              ? const Center(child: Text('Enter a search term.'))
              : _searchResults.isEmpty
                  ? Center(child: Text('No results found for "$_searchQuery".'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        final type = result['type'] as String;
                        final doc = result['data'] as QueryDocumentSnapshot;
                        final title = doc.data() is Map<String, dynamic> ? (doc.data() as Map<String, dynamic>)['title'] ?? 'No Title' : 'No Title';

                        IconData icon;
                        Color color;
                        switch (type) {
                          case 'Sermon':
                            icon = Icons.headset;
                            color = Colors.orange;
                            break;
                          case 'Devotional':
                            icon = Icons.book;
                            color = Colors.purple;
                            break;
                          case 'Event':
                            icon = Icons.event;
                            color = Colors.blue;
                            break;
                          case 'Video':
                            icon = Icons.video_library;
                            color = Colors.red;
                            break;
                          default:
                            icon = Icons.article;
                            color = Colors.grey;
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(icon, color: color),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(type),
                          onTap: () => _handleResultTap(result),
                        );
                      },
                    ),
    );
  }
}
