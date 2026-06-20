import 'package:equatable/equatable.dart';

enum LinkedContentType { verse, sermon, note, exegesis }

/// A reference to linked source content (e.g. a Bible verse) embedded in a note.
class LinkedContentReference extends Equatable {
  final String id;
  final LinkedContentType type;
  final String sourceId;
  final String sourceReference;
  final DateTime linkedAt;
  final Map<String, dynamic> metadata;

  const LinkedContentReference({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.sourceReference,
    required this.linkedAt,
    required this.metadata,
  });

  @override
  List<Object?> get props => [id];
}
