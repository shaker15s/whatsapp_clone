import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageType;
  final Map<String, int> unreadCount;
  final List<String> archivedBy;
  final List<String> pinnedBy;
  final String type; // direct | group
  final String? groupName;
  final String? groupPhotoUrl;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageTime,
    this.lastMessageType = 'text',
    required this.unreadCount,
    required this.archivedBy,
    required this.pinnedBy,
    required this.type,
    this.groupName,
    this.groupPhotoUrl,
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // تحويل unreadCount بأمان
    final rawUnread = data['unreadCount'] as Map<dynamic, dynamic>? ?? {};
    final Map<String, int> unread = {};
    rawUnread.forEach((k, v) {
      unread[k.toString()] = (v is num) ? v.toInt() : 0;
    });

    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] is Timestamp)
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageType: data['lastMessageType'] ?? 'text',
      unreadCount: unread,
      archivedBy: List<String>.from(data['archivedBy'] ?? []),
      pinnedBy: List<String>.from(data['pinnedBy'] ?? []),
      type: data['type'] ?? 'direct',
      groupName: data['groupName'],
      groupPhotoUrl: data['groupPhotoUrl'],
    );
  }

  static String buildChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
