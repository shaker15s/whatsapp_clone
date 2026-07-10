import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio, location }
enum MessageStatus { sent, delivered, read }

class MessageModel {
  final String id;
  final String senderId;
  final MessageType type;
  final String content; // نص، أو رابط صورة/صوت، أو "lat,lng"
  final int? durationSeconds; // للرسايل الصوتية
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, String> reactions; // userId -> emoji
  final Map<String, dynamic>? replyTo; // {messageId, textSnippet, senderName}
  final List<String> isStarredBy; // list of userIds
  final bool isDeleted;

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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    };
  }

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final rawReactions = data['reactions'] as Map<dynamic, dynamic>? ?? {};
    final Map<String, String> reactionsMap = {};
    rawReactions.forEach((k, v) {
      reactionsMap[k.toString()] = v.toString();
    });

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      durationSeconds: data['durationSeconds'],
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      reactions: reactionsMap,
      replyTo: data['replyTo'] as Map<String, dynamic>?,
      isStarredBy: List<String>.from(data['isStarredBy'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
    );
  }
}
