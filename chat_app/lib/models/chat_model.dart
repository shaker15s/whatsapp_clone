import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع المحادثة
enum ChatType { direct, group }

/// نموذج بيانات المحادثة
class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageType;
  final Map<String, int> unreadCount;
  final List<String> archivedBy;
  final List<String> pinnedBy;
  final ChatType type;
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

  /// تحويل إلى Map للتخزين في Firestore
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : FieldValue.serverTimestamp(),
      'lastMessageType': lastMessageType,
      'unreadCount': unreadCount,
      'archivedBy': archivedBy,
      'pinnedBy': pinnedBy,
      'type': type.name,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
    };
  }

  /// إنشاء من DocumentSnapshot
  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw StateError('Chat document does not exist: ${doc.id}');
    }
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel._fromData(data, doc.id);
  }

  /// إنشاء من Map (للاستخدام مع snapshots)
  factory ChatModel.fromMap(Map<String, dynamic> data, String id) {
    return ChatModel._fromData(data, id);
  }

  ChatModel._fromData(Map<String, dynamic> data, String id)
      : id = id,
        participants = List<String>.from(data['participants'] ?? []),
        lastMessage = data['lastMessage'] as String? ?? '',
        lastMessageTime = _parseTimestamp(data['lastMessageTime']),
        lastMessageType = data['lastMessageType'] as String? ?? 'text',
        unreadCount = _parseUnreadCount(data['unreadCount']),
        archivedBy = List<String>.from(data['archivedBy'] ?? []),
        pinnedBy = List<String>.from(data['pinnedBy'] ?? []),
        type = _parseChatType(data['type']),
        groupName = data['groupName'] as String?,
        groupPhotoUrl = data['groupPhotoUrl'] as String?;

  /// تحليل عدد الرسائل غير المقروءة
  static Map<String, int> _parseUnreadCount(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      final Map<String, int> result = {};
      value.forEach((k, v) {
        result[k.toString()] = (v is num) ? v.toInt() : 0;
      });
      return result;
    }
    return {};
  }

  /// تحليل نوع المحادثة
  static ChatType _parseChatType(dynamic value) {
    if (value == null) return ChatType.direct;
    final name = value.toString();
    return ChatType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ChatType.direct,
    );
  }

  /// تحليل Timestamp من Firestore
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// إنشاء معرف محادثة فريد لمحادثة خاصة (محدد بغض النظر عن الترتيب)
  static String buildChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// نسخة معدلة من النموذج
  ChatModel copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageType,
    Map<String, int>? unreadCount,
    List<String>? archivedBy,
    List<String>? pinnedBy,
    String? groupName,
    String? groupPhotoUrl,
  }) {
    return ChatModel(
      id: id,
      participants: participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      archivedBy: archivedBy ?? this.archivedBy,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      type: type,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          participants.length == other.participants.length &&
          participants.every((e) => other.participants.contains(e)) &&
          lastMessage == other.lastMessage &&
          lastMessageTime == other.lastMessageTime &&
          lastMessageType == other.lastMessageType &&
          unreadCount.length == other.unreadCount.length &&
          unreadCount.entries.every(
              (e) => other.unreadCount[e.key] == e.value) &&
          archivedBy.length == other.archivedBy.length &&
          archivedBy.every((e) => other.archivedBy.contains(e)) &&
          pinnedBy.length == other.pinnedBy.length &&
          pinnedBy.every((e) => other.pinnedBy.contains(e)) &&
          type == other.type &&
          groupName == other.groupName &&
          groupPhotoUrl == other.groupPhotoUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      participants.hashCode ^
      lastMessage.hashCode ^
      lastMessageTime.hashCode ^
      lastMessageType.hashCode ^
      unreadCount.hashCode ^
      archivedBy.hashCode ^
      pinnedBy.hashCode ^
      type.hashCode ^
      groupName.hashCode ^
      groupPhotoUrl.hashCode;

  @override
  String toString() =>
      'ChatModel(id: $id, type: ${type.name}, participants: ${participants.length}, lastMessage: $lastMessage)';
}