import 'package:flutter/material.dart';
import '../../data/models/linked_content_reference.dart';
import 'package:church_mobile/features/notes/presentation/widgets/add_to_note_dialog.dart' as real;
import 'package:church_mobile/features/notes/data/models/linked_content_reference.dart' as real_model;

/// Wrapper dialog that routes the request to the real standalone AddToNoteDialog
class AddToNoteDialog extends StatelessWidget {
  final String formattedContent;
  final LinkedContentReference linkedContentReference;
  final String suggestedTitle;

  const AddToNoteDialog({
    super.key,
    required this.formattedContent,
    required this.linkedContentReference,
    required this.suggestedTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Map the old LinkedContentReference to the new one safely
    real_model.LinkedContentReference realRef;
    try {
      final typeName = linkedContentReference.type.toString().split('.').last;
      real_model.LinkedContentType realType;
      if (typeName == 'verse') {
        realType = real_model.LinkedContentType.verse;
      } else if (typeName == 'chat') {
        realType = real_model.LinkedContentType.chat;
      } else if (typeName == 'exegesis') {
        realType = real_model.LinkedContentType.exegesis;
      } else {
        realType = real_model.LinkedContentType.verse; // fallback
      }

      realRef = real_model.LinkedContentReference(
        id: linkedContentReference.id,
        type: realType,
        sourceId: linkedContentReference.sourceId,
        sourceReference: linkedContentReference.sourceReference,
        linkedAt: linkedContentReference.linkedAt,
        metadata: linkedContentReference.metadata != null
            ? Map<String, dynamic>.from(linkedContentReference.metadata)
            : {},
      );
    } catch (_) {
      // Fallback reference if parsing fails
      realRef = real_model.LinkedContentReference(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: real_model.LinkedContentType.verse,
        sourceId: 'unknown',
        sourceReference: suggestedTitle,
        linkedAt: DateTime.now(),
        metadata: {},
      );
    }

    return real.AddToNoteDialog(
      formattedContent: formattedContent,
      linkedContentReference: realRef,
      suggestedTitle: suggestedTitle,
    );
  }
}
