import 'package:flutter/material.dart';
import '../exegesis/models/exegesis_final_model.dart';

/// Stub Deep Exegesis screen — navigated to from ChapterScreen's "Deep Exegesis" action.
/// Pre-fills book, chapter, and verse from the selected verse reference.
class NewExegesisScreen extends StatelessWidget {
  final VerseRef? prefillVerseRef;
  final String? prefillVerseText;

  const NewExegesisScreen({
    super.key,
    this.prefillVerseRef,
    this.prefillVerseText,
  });

  @override
  Widget build(BuildContext context) {
    final ref = prefillVerseRef;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Exegesis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories_rounded, size: 72, color: Colors.indigo),
            const SizedBox(height: 24),
            const Text(
              'Deep Exegesis',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (ref != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ref.referenceString,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (prefillVerseText != null)
                Text(
                  '"$prefillVerseText"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Full deep exegesis with 14-layer analysis will be available here.\n'
              'This feature is part of the ILLUMINE Bible AI Engine and will be '
              'wired to the AI service in the next integration phase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
