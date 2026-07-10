import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات المستخدم
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

  /// تحويل إلى Map للتخزين في Firestore
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

  /// إنشاء من Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      profilePicUrl: map['profilePicUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      about: map['about'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  /// إنشاء من DocumentSnapshot
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw StateError('User document does not exist: ${doc.id}');
    }
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  /// تحليل Timestamp من Firestore
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// نسخة معدلة من النموذج
  UserModel copyWith({
    String? name,
    String? phoneNumber,
    String? profilePicUrl,
    String? fcmToken,
    String? about,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      about: about ?? this.about,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          name == other.name &&
          phoneNumber == other.phoneNumber &&
          profilePicUrl == other.profilePicUrl &&
          fcmToken == other.fcmToken &&
          about == other.about &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      uid.hashCode ^
      name.hashCode ^
      phoneNumber.hashCode ^
      profilePicUrl.hashCode ^
      fcmToken.hashCode ^
      about.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber)';
}