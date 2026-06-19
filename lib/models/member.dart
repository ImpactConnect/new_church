import 'package:cloud_firestore/cloud_firestore.dart';

enum MaritalStatus {
  single,
  married,
  divorced,
  widowed;

  String toDisplayString() {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class Member {
  Member({
    required this.id,
    required this.name,
    this.imageUrl,
    this.occupation,
    this.maritalStatus,
    this.spouseName,
    this.birthDate,
    this.weddingDate,
    this.phoneNumber,
    this.email,
    this.address,
    this.churchGroup,
    this.role,
  });

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Member.fromJson(data, doc.id);
  }

  factory Member.fromJson(Map<String, dynamic> data, String id) {
    // Helper to handle both Timestamp and String dates that might come from JSON caches
    DateTime? parseDate(dynamic dateData) {
      if (dateData == null) return null;
      if (dateData is Timestamp) return dateData.toDate();
      if (dateData is String) return DateTime.tryParse(dateData);
      if (dateData is Map && dateData['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(dateData['_seconds'] * 1000);
      }
      return null;
    }

    return Member(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['photoUrl'] ?? data['imageUrl'],
      occupation: data['occupation'],
      maritalStatus: data['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere(
              (e) => e.name == data['maritalStatus'],
              orElse: () => MaritalStatus.single)
          : null,
      spouseName: data['spouseName'],
      birthDate: parseDate(data['dateOfBirth']) ?? parseDate(data['birthDate']),
      weddingDate: parseDate(data['weddingDate']),
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      address: data['address'],
      churchGroup: data['churchGroup'],
      role: data['role'],
    );
  }
  final String id;
  final String name;
  final String? imageUrl;
  final String? occupation;
  final MaritalStatus? maritalStatus;
  final String? spouseName;
  final DateTime? birthDate;
  final DateTime? weddingDate;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? churchGroup;
  final String? role;

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'occupation': occupation,
      'maritalStatus': maritalStatus?.name,
      'spouseName': spouseName,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'weddingDate':
          weddingDate != null ? Timestamp.fromDate(weddingDate!) : null,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'churchGroup': churchGroup,
      'role': role,
    };
  }
}
