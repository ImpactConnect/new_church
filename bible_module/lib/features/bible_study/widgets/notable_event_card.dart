import 'package:flutter/material.dart';
import '../models/bible_study_models.dart';

class NotableEventCard extends StatelessWidget {
  final NotableEvent event;
  final bool isExpanded;
  final VoidCallback? onTap;

  const NotableEventCard({
    super.key,
    required this.event,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF7B61FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🎬',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.eventTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.reference,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF7B61FF).withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              
              if (isExpanded) ...[
                const SizedBox(height: 16),
                
                // Participants
                if (event.participants.isNotEmpty) ...[
                  _SectionLabel('Participants'),
                  const SizedBox(height: 6),
                  Text(
                    event.participants,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Narrative
                _SectionLabel('What Happened'),
                const SizedBox(height: 6),
                Text(
                  event.narrative,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
                
                // Context
                if (event.context.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionLabel('Context'),
                  const SizedBox(height: 6),
                  Text(
                    event.context,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                
                // Significance
                if (event.significance.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionLabel('Why It Matters'),
                  const SizedBox(height: 6),
                  Text(
                    event.significance,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
                
                // Lessons
                if (event.lessons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'Lessons',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...event.lessons.map((lesson) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF7B61FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lesson,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
      ),
    );
  }
}
