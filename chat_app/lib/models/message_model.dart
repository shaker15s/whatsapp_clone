import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع الرسالة
enum MessageType { text, image, audio, location, system }

/// حالة الرسالة
enum MessageStatus { sent, delivered, read }

/// نموذج بيانات الرسالة
class MessageModel {
  final String id;
  final String senderId;
  final MessageType type;
  final String content; // نص، أو رابط صورة/صوت، أو "lat,lng" للموقع
  final int? durationSeconds; // للرسايل الصوتية
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, String> reactions; // userId -> emoji
  final Map<String, dynamic>? replyTo; // {messageId, textSnippet, senderName}
  final List<String> isStarredBy; // list of userIds
  final bool isDeleted;
  final DateTime? editedAt;
  final bool isForwarded;
  final String? forwardedFrom;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.content,
    this.durationSeconds,
    required this.timestamp,
    this.status = MessageStatus.sent,
    required this.reactions,
    this.replyTo,
    required this.isStarredBy,
    this.isDeleted = false,
    this.editedAt,
    this.isForwarded = false,
    this.forwardedFrom,
  });

  /// هل الرسالة معدّلة (تظهر "تم تعديلها" تحت الوقت)
  bool get isEdited => editedAt != null;

  /// تحويل إلى Map للتخزين في Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'type': type.name,
      'content': content,
      'durationSeconds': durationSeconds,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status.name,
      'reactions': reactions,
      if (replyTo != null) 'replyTo': replyTo,
      'isStarredBy': isStarredBy,
      'isDeleted': isDeleted,
      if (editedAt != null) 'editedAt': FieldValue.serverTimestamp(),
      'isForwarded': isForwarded,
      if (forwardedFrom != null) 'forwardedFrom': forwardedFrom,
    };
  }

  /// إنشاء من DocumentSnapshot
  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw StateError('Message document does not exist: ${doc.id}');
    }

    final data = doc.data() as Map<String, dynamic>;
    return MessageModel._fromData(data, doc.id);
  }

  /// إنشاء من Map (للاستخدام مع snapshots)
  factory MessageModel.fromMap(Map<String, dynamic> data, String id) {
    return MessageModel._fromData(data, id);
  }

MessageModel._fromData(Map<String, dynamic> data, String id)
 : id = id,
 senderId = data['senderId'] as String? ?? '',
 type = _parseMessageType(data['type']),
 content = data['content'] as String? ?? '',
 durationSeconds = data['durationSeconds'] as int?,
 timestamp = _parseTimestamp(data['timestamp']),
 status = _parseMessageStatus(data['status']),
 reactions = _parseReactions(data['reactions']),
 replyTo = data['replyTo'] as Map<String, dynamic>?,
 isStarredBy = List<String>.from(data['isStarredBy'] ?? []),
 isDeleted = data['isDeleted'] as bool? ?? false,
 editedAt = data['editedAt'] is Timestamp ? (data['editedAt'] as Timestamp).toDate() : null,
 isForwarded = data['isForwarded'] as bool? ?? false,
 forwardedFrom = data['forwardedFrom'] as String?;

/// تحليل نوع الرسالة
  static MessageType _parseMessageType(dynamic value) {
    if (value == null) return MessageType.text;
    final name = value.toString();
    return MessageType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => MessageType.text,
    );
  }

  /// تحليل حالة الرسالة
  static MessageStatus _parseMessageStatus(dynamic value) {
    if (value == null) return MessageStatus.sent;
    final name = value.toString();
    return MessageStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => MessageStatus.sent,
    );
  }

  /// تحليل التفاعلات
  static Map<String, String> _parseReactions(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      final Map<String, String> result = {};
      value.forEach((k, v) {
        result[k.toString()] = v.toString();
      });
      return result;
    }
    return {};
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
  MessageModel copyWith({
    String? content,
    MessageStatus? status,
    Map<String, String>? reactions,
    List<String>? isStarredBy,
    bool? isDeleted,
    bool? isForwarded,
    bool isSystem = false,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      type: isSystem ? MessageType.system : type,
      content: content ?? this.content,
      durationSeconds: durationSeconds,
      timestamp: timestamp,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo,
      isStarredBy: isStarredBy ?? this.isStarredBy,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          senderId == other.senderId &&
          type == other.type &&
          content == other.content &&
          durationSeconds == other.durationSeconds &&
          timestamp == other.timestamp &&
          status == other.status &&
          reactions.length == other.reactions.length &&
          reactions.entries.every((e) => other.reactions[e.key] == e.value) &&
          isStarredBy.length == other.isStarredBy.length &&
          isStarredBy.every((e) => other.isStarredBy.contains(e)) &&
          isDeleted == other.isDeleted &&
          isForwarded == other.isForwarded;

  @override
  int get hashCode =>
      id.hashCode ^
      senderId.hashCode ^
      type.hashCode ^
      content.hashCode ^
      durationSeconds.hashCode ^
      timestamp.hashCode ^
      status.hashCode ^
      reactions.hashCode ^
      isStarredBy.hashCode ^
      isDeleted.hashCode ^
      isForwarded.hashCode;

  @override
  String toString() =>
      'MessageModel(id: $id, senderId: $senderId, type: ${type.name}, content: $content, status: ${status.name})';
}