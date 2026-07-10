import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';

/// خدمة المحادثات - تدعم Firebase الحقيقي مع معالجة خطأ سليمة
class ChatService {
  /// التحقق من جاهزية Firebase
  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// إرجاع مثيل Firestore مع التحقق من الجاهزية
  FirebaseFirestore get _db {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. تأكد من تشغيل flutterfire configure.');
    }
    return FirebaseFirestore.instance;
  }

  /// إرجاع مثيل Realtime Database مع التحقق من الجاهزية
  FirebaseDatabase get _rtdb {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. تأكد من تشغيل flutterfire configure.');
    }
    return FirebaseDatabase.instance;
  }

  // ─── Get or Create Chat ──────────────────────────────────────────────────
  /// الحصول على شات أو إنشاؤه (محادثة مباشرة)
  Future<String> getOrCreateChat(String myUid, String otherUid) async {
    final ids = [myUid, otherUid]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final chatRef = _db.collection('chats').doc(chatId);
    final doc = await chatRef.get();

    if (!doc.exists) {
      await chatRef.set({
        'participants': [myUid, otherUid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageType': 'text',
        'unreadCount': {myUid: 0, otherUid: 0},
        'archivedBy': [],
        'pinnedBy': [],
        'type': 'direct',
      });
    }
    return chatId;
  }

  // ─── Watch My Chats ─────────────────────────────────────────────────────
  /// الاستماع للشاتات الخاصة بالمستخدم
  Stream<QuerySnapshot> watchMyChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots();
  }

  // ─── Watch Messages ─────────────────────────────────────────────────────
  /// الاستماع للرسائل في شات معين
  Stream<QuerySnapshot> watchMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ─── Send Message ───────────────────────────────────────────────────────
  /// إرسال رسالة مع دعم الرد والميديا
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String type, // text, image, audio, location
    required String content,
    Map<String, dynamic>? replyTo,
    int? durationSeconds,
  }) async {
    String previewText;
    switch (type) {
      case 'image':
        previewText = '📷 صورة';
        break;
      case 'audio':
        previewText = '🎤 رسالة صوتية';
        break;
      case 'location':
        previewText = '📍 موقع';
        break;
      default:
        previewText = content;
    }

    final chatRef = _db.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

  final messageData = {
    'id': messageRef.id,
    'chatId': chatId,
    'senderId': senderId,
    'type': type,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'reactions': {},
      'isStarredBy': [],
      'isDeleted': false,
      if (replyTo != null) 'replyTo': replyTo,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };

    // كتابة الرسالة وتحديث معلومات الشات في batch واحد لضمان الاتساق
    final batch = _db.batch();

    // 1. إضافة الرسالة
    batch.set(messageRef, messageData);

    // 2. تحديث آخر رسالة + زيادة عدادات القراءة باستخدام FieldValue.increment
    final chatDoc = await chatRef.get();
    final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
    final unreadUpdates = <String, dynamic>{};
    for (final p in participants) {
      if (p != senderId) {
        unreadUpdates['unreadCount.$p'] = FieldValue.increment(1);
      }
    }

    batch.update(chatRef, {
      'lastMessage': previewText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageType': type,
      ...unreadUpdates,
    });

    await batch.commit();
  }

  // ─── Mark Chat as Read ──────────────────────────────────────────────────
  /// تحديث حالة القراءة للمحادثة
  Future<void> markChatAsRead(String chatId, String myUid) async {
    final chatRef = _db.collection('chats').doc(chatId);

    // إعادة تعيين عداد القراءة للمستخدم الحالي
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final unreadCount = Map<String, dynamic>.from(data['unreadCount'] ?? {});
      unreadCount[myUid] = 0;
      transaction.update(chatRef, {'unreadCount': unreadCount});
    });

    // تعليم جميع الرسائل غير المقروءة بأنها مقروءة
    final unreadMessages = await chatRef
        .collection('messages')
        .where('senderId', isNotEqualTo: myUid)
        .where('status', isNotEqualTo: 'read')
        .get();

    if (unreadMessages.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    }
  }

  // ─── Toggle Reaction ────────────────────────────────────────────────────
  /// إرسال تفاعل (Reaction)
  Future<void> toggleReaction(
      String chatId, String messageId, String myUid, String emoji) async {
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc(messageId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(msgRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      if (reactions[myUid] == emoji) {
        reactions.remove(myUid); // إزالة التفاعل
      } else {
        reactions[myUid] = emoji;
      }
      transaction.update(msgRef, {'reactions': reactions});
    });
  }

  // ─── Toggle Archive ─────────────────────────────────────────────────────
  /// أرشفة الشات أو إلغاء الأرشفة
  Future<void> toggleArchiveChat(String chatId, String myUid, bool archive) async {
    final chatRef = _db.collection('chats').doc(chatId);
    if (archive) {
      await chatRef.update({
        'archivedBy': FieldValue.arrayUnion([myUid]),
      });
    } else {
      await chatRef.update({
        'archivedBy': FieldValue.arrayRemove([myUid]),
      });
    }
  }

  // ─── Toggle Star ────────────────────────────────────────────────────────
  /// وضع نجمة على رسالة
  Future<void> toggleStarMessage(
      String chatId, String messageId, String myUid, bool star) async {
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc(messageId);
    if (star) {
      await msgRef.update({
        'isStarredBy': FieldValue.arrayUnion([myUid]),
      });
    } else {
      await msgRef.update({
        'isStarredBy': FieldValue.arrayRemove([myUid]),
      });
    }
  }

  // ─── Group CRUD ────────────────────────────────────────────────────────────
  /// إنشاء مجموعة جديدة — يرجع groupId
  Future<String> createGroup(
    String creatorUid,
    String groupName,
    List<String> memberUids, {
    String? groupPhotoUrl,
  }) async {
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}_${creatorUid.hashCode}';
    final allParticipants = [creatorUid, ...memberUids];

    final chatRef = _db.collection('chats').doc(groupId);
    await chatRef.set({
      'participants': allParticipants,
      'lastMessage': 'تم إنشاء المجموعة "$groupName"',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageType': 'text',
      'unreadCount': {for (final p in allParticipants) p: (p == creatorUid ? 0 : 1)},
      'archivedBy': [],
      'pinnedBy': [],
      'type': 'group',
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl ?? '',
    });

    // رسالة نظام
    await chatRef.collection('messages').doc().set({
      'id': 'sys_${DateTime.now().millisecondsSinceEpoch}',
      'senderId': creatorUid,
      'type': 'system',
      'content': 'أنشأت المجموعة "$groupName"',
      'timestamp': Timestamp.now(),
      'status': 'read',
      'reactions': {},
      'isStarredBy': [],
      'isDeleted': false,
    });

    return groupId;
  }

  /// إضافة عضو لمجموعة
  Future<void> addGroupMember(String chatId, String memberUid) async {
    final chatRef = _db.collection('chats').doc(chatId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      if (!participants.contains(memberUid)) {
        participants.add(memberUid);
        transaction.update(chatRef, {
          'participants': participants,
          'unreadCount.$memberUid': 1,
        });
        transaction.set(chatRef.collection('messages').doc(), {
          'id': 'sys_${DateTime.now().millisecondsSinceEpoch}',
          'senderId': memberUid,
          'type': 'system',
          'content': 'انضم للمجموعة',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'read',
          'reactions': {},
          'isStarredBy': [],
          'isDeleted': false,
        });
      }
    });
  }

  /// حذف عضو من مجموعة
  Future<void> removeGroupMember(String chatId, String memberUid) async {
    final chatRef = _db.collection('chats').doc(chatId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      participants.remove(memberUid);
      transaction.update(chatRef, {'participants': participants});
    });
  }

  /// تحديث اسم أو صورة المجموعة
  Future<void> updateGroupInfo(String chatId, {String? groupName, String? groupPhotoUrl}) async {
    final updates = <String, dynamic>{};
    if (groupName != null) updates['groupName'] = groupName;
    if (groupPhotoUrl != null) updates['groupPhotoUrl'] = groupPhotoUrl;
    if (updates.isEmpty) return;

    await _db.collection('chats').doc(chatId).update(updates);
  }

  /// الاستماع لقائمة أعضاء المجموعة
  Stream<List<Map<String, dynamic>>> watchGroupMembers(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return <Map<String, dynamic>>[];
      final members = List<String>.from(data['participants'] ?? []);
      return members.map((uid) => {'uid': uid}).toList();
    });
  }

  // ─── Edit Message ──────────────────────────────────────────────────────────
  /// تعديل رسالة نصية
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'content': newContent,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Delete / Unsend Message ───────────────────────────────────────────────
  /// حذف رسالة (لنفسي = حذف من القائمة فقط، للكل = إظهار "تم حذف الرسالة")
  Future<void> deleteMessage(
    String chatId,
    String messageId,
    String myUid, {
    bool unsendForAll = false,
  }) async {
    final msgRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    if (unsendForAll) {
      await msgRef.update({
        'content': 'تم حذف هذه الرسالة',
        'isDeleted': true,
      });
    } else {
      await msgRef.delete();
    }
  }

  // ─── Forward Message ───────────────────────────────────────────────────────
  /// إعادة توجيه رسالة لمحادثة أخرى
  Future<void> forwardMessage(
    String sourceChatId,
    String messageId,
    String targetChatId,
    String myUid,
  ) async {
    final originalDoc = await _db
        .collection('chats')
        .doc(sourceChatId)
        .collection('messages')
        .doc(messageId)
        .get();
    if (!originalDoc.exists) return;

    final data = originalDoc.data() as Map<String, dynamic>;

    final targetMsgRef = _db
        .collection('chats')
        .doc(targetChatId)
        .collection('messages')
        .doc();

    String preview = (data['content'] ?? '');
    if (data['type'] == 'image') preview = '📷 صورة';
    if (data['type'] == 'audio') preview = '🎤 رسالة صوتية';
    if (data['type'] == 'location') preview = '📍 موقع';
    preview = '↩️ $preview';

await targetMsgRef.set({
  'id': targetMsgRef.id,
  'chatId': targetChatId,
  'senderId': myUid,
  'type': data['type'] ?? 'text',
  'content': data['content'] ?? '',
  if (data['durationSeconds'] != null) 'durationSeconds': data['durationSeconds'],
  'timestamp': FieldValue.serverTimestamp(),
  'status': 'sent',
  'reactions': {},
  'isStarredBy': [],
  'isDeleted': false,
  'isForwarded': true,
  'forwardedFrom': sourceChatId,
});

  await _db.collection('chats').doc(targetChatId).update({
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageType': data['type'] ?? 'text',
    });
  }

  // ─── Search Messages ───────────────────────────────────────────────────────
  /// بحث في رسائل محادثة معينة (فلترة على côté-client)
  /// ملاحظة: لنتائج أفضل في الإنتاج استخدم Algolia أو Elasticsearch
  Future<List<Map<String, dynamic>>> searchMessages(
    String chatId,
    String query,
  ) async {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return [];

    // نفحص حتى 100 رسالة من الأحدث ونفلتر عميلياً
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return (data['content'] ?? '').toString().toLowerCase().contains(normalizedQuery);
        })
        .map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        })
        .toList();
  }

  // ─── Paginated Messages ────────────────────────────────────────────────────
  /// جلب رسائل بنظام الصفحات — يرجع QuerySnapshot لكل صفحة
  Future<QuerySnapshot> getMessagesPaginated(
    String chatId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }

  // ─── Typing ─────────────────────────────────────────────────────────────
  /// التحديث اللحظي لحالة الكتابة (Typing)
  void setTyping(String chatId, String myUid, bool isTyping) {
    _rtdb.ref('typing/$chatId/$myUid').set(isTyping);
  }

  /// مراقبة حالة الكتابة للطرف الآخر
  Stream<DatabaseEvent> watchTyping(String chatId, String otherUid) {
    return _rtdb.ref('typing/$chatId/$otherUid').onValue;
  }

  // ─── Upload Image ─────────────────────────────────────────────────────
  /// رفع صورة إلى Firebase Storage
  Future<String> uploadImage(File file, String folder) async {
    final myUid = AuthService().currentUser?.uid;
    if (myUid == null) throw StateError('User not logged in');

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref().child('$folder/$myUid/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }
}