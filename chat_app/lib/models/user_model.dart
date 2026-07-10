import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phoneNumber;
  final String? profilePicUrl;
  final String? fcmToken;
  final String about;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    this.profilePicUrl,
    this.fcmToken,
    required this.about,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'profilePicUrl': profilePicUrl,
      'fcmToken': fcmToken,
      'about': about,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? map['username'] ?? 'مستخدم Lumina',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      fcmToken: map['fcmToken'],
      about: map['about'] ?? 'تواصل بوضوح وأناقة',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }
}
