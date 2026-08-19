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
    this.churchGroups = const [],
    this.role,
    this.gender,
    this.profession,
    this.residentAddress,
    this.memberStatus,
    this.username,
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

    // Parse marital status from string — handle both enum name and display string
    MaritalStatus? parseMaritalStatus(dynamic value) {
      if (value == null) return null;
      final str = value.toString().toLowerCase().trim();
      return MaritalStatus.values.cast<MaritalStatus?>().firstWhere(
        (e) => e?.name == str,
        orElse: () => null,
      );
    }

    // Compute display name from name OR firstName + lastName
    String displayName = (data['name'] as String?)?.trim() ?? '';
    if (displayName.isEmpty) {
      final fn = (data['firstName'] as String?)?.trim() ?? '';
      final ln = (data['lastName'] as String?)?.trim() ?? '';
      displayName = '$fn $ln'.trim();
    }
    if (displayName.isEmpty) displayName = 'Unnamed Member';

    // Parse church groups or departmentIds
    List<String> groups = [];
    if (data['churchGroups'] != null) {
      groups = List<String>.from(data['churchGroups']);
    } else if (data['departmentIds'] != null) {
      groups = List<String>.from(data['departmentIds']);
    } else if (data['churchGroup'] != null && data['churchGroup'].toString().isNotEmpty) {
      groups = [data['churchGroup'].toString()];
    }

    return Member(
      id: id,
      name: displayName,
      imageUrl: data['profileImageUrl'] ?? data['photoUrl'] ?? data['imageUrl'],
      occupation: data['profession'] ?? data['occupation'],
      maritalStatus: parseMaritalStatus(data['maritalStatus']),
      spouseName: data['spouseName'],
      birthDate: parseDate(data['dob']) ?? parseDate(data['dateOfBirth']) ?? parseDate(data['birthDate']),
      weddingDate: parseDate(data['weddingDate']),
      phoneNumber: data['phone'] ?? data['phoneNumber'],
      email: data['email'],
      address: data['residentAddress'] ?? data['address'],
      churchGroups: groups,
      role: data['roleId'] ?? data['role'],
      gender: data['gender'],
      profession: data['profession'] ?? data['occupation'],
      residentAddress: data['residentAddress'] ?? data['address'],
      memberStatus: data['memberStatus'],
      username: data['username'],
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
  final List<String> churchGroups;
  final String? role;
  final String? gender;
  final String? profession;
  final String? residentAddress;
  final String? memberStatus;
  final String? username;

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
      'churchGroups': churchGroups,
      'role': role,
      'gender': gender,
    };
  }
}
