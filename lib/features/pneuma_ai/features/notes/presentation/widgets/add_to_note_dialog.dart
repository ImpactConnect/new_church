import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_mobile/features/notes/presentation/widgets/add_to_note_dialog.dart' as real;
import 'package:church_mobile/features/notes/data/models/linked_content_reference.dart' as real_model;

/// Wrapper dialog that routes the request to the real standalone AddToNoteDialog
class AddToNoteDialog extends ConsumerWidget {
  final String formattedContent;
  final dynamic linkedContentReference;
  final String? suggestedTitle;

  const AddToNoteDialog({
    super.key,
    required this.formattedContent,
    this.linkedContentReference,
    this.suggestedTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Map the incoming dynamic reference (which could be the old or pneuma_ai one)
    // to the real LinkedContentReference type required by the Standalone Notes feature
    real_model.LinkedContentReference realRef;
    if (linkedContentReference != null) {
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
          id: linkedContentReference.id.toString(),
          type: realType,
          sourceId: linkedContentReference.sourceId.toString(),
          sourceReference: linkedContentReference.sourceReference.toString(),
          linkedAt: linkedContentReference.linkedAt as DateTime,
          metadata: linkedContentReference.metadata != null
              ? Map<String, dynamic>.from(linkedContentReference.metadata as Map)
              : {},
        );
      } catch (_) {
        // Fallback reference if parsing fails
        realRef = real_model.LinkedContentReference(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: real_model.LinkedContentType.verse,
          sourceId: 'unknown',
          sourceReference: suggestedTitle ?? 'Linked Content',
          linkedAt: DateTime.now(),
          metadata: {},
        );
      }
    } else {
      realRef = real_model.LinkedContentReference(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: real_model.LinkedContentType.verse,
        sourceId: 'unknown',
        sourceReference: suggestedTitle ?? 'Linked Content',
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
