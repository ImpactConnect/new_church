import 'package:flutter/material.dart';
import 'package:church_mobile/models/testimony.dart';
import 'package:church_mobile/widgets/testimony_details_dialog.dart';
import 'package:church_mobile/utils/date_formatter.dart';

class TestimonyCard extends StatelessWidget {
  final Testimony testimony;

  const TestimonyCard({
    Key? key,
    required this.testimony,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TestimonyDetailsDialog(testimony: testimony),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: testimony.imageUrl != null
                        ? NetworkImage(testimony.imageUrl!)
                        : null,
                    child: testimony.imageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimony.testifier,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormatter.formatDate(testimony.dateShared),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                testimony.testimony,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
