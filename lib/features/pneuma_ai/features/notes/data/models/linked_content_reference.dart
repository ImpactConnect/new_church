import 'package:equatable/equatable.dart';

enum LinkedContentType { chat, verse, exegesis, berean, note }

class LinkedContentReference extends Equatable {
  final String id;
  final LinkedContentType type;
  final String sourceId;
  final String sourceReference;
  final DateTime linkedAt;
  final Map<String, dynamic>? metadata;

  const LinkedContentReference({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.sourceReference,
    required this.linkedAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, type, sourceId];
}
