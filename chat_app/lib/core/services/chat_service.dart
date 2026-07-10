import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

// Mock implementations of Firestore objects to support running without Firebase config
class MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  MockDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(Object field) => _data?[field];

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  bool get exists => _data != null;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockQueryDocumentSnapshot extends MockDocumentSnapshot implements QueryDocumentSnapshot {
  MockQueryDocumentSnapshot(super.id, super.data);

  @override
  Map<String, dynamic> data() => super.data() ?? {};
}

class MockQuerySnapshot implements QuerySnapshot {
  @override
  final List<QueryDocumentSnapshot> docs;

  MockQuerySnapshot(this.docs);

  @override
  List<DocumentChange> get docChanges => [];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  int get size => docs.length;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ChatService {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseDatabase? get _rtdb {
    try {
      return FirebaseDatabase.instance;
    } catch (_) {
      return null;
    }
  }

  // Local/Offline state representation
  static final List<Map<String, dynamic>> _mockChats = [
    {
      'id': 'chat_1',
      'participants': ['mock_uid_123', 'other_user_1'],
      'lastMessage': 'أهلاً بك في Lumina Emerald! 👋',
      'lastMessageTime': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))),
      'lastMessageType': 'text',
      'unreadCount': {'mock_uid_123': 1, 'other_user_1': 0},
      'archivedBy': [],
      'pinnedBy': [],
      'type': 'direct',
    },
    {
      'id': 'chat_2',
      'participants': ['mock_uid_123', 'other_user_2'],
      'lastMessage': '📷 صورة',
      'lastMessageTime': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'lastMessageType': 'image',
      'unreadCount': {'mock_uid_123': 0, 'other_user_2': 0},
      'archivedBy': [],
      'pinnedBy': [],
      'type': 'direct',
    }
  ];

  static final Map<String, List<Map<String, dynamic>>> _mockMessages = {
    'chat_1': [
      {
        'id': 'msg_1_1',
        'senderId': 'other_user_1',
        'type': 'text',
        'content': 'مرحباً، كيف حالك؟ هذا هو تصميم Lumina Emerald الأنيق.',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 10))),
        'status': 'read',
        'reactions': {},
        'isStarredBy': [],
        'isDeleted': false,
      },
      {
        'id': 'msg_1_2',
        'senderId': 'other_user_1',
        'type': 'text',
        'content': 'أهلاً بك في Lumina Emerald! 👋',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))),
        'status': 'delivered',
        'reactions': {},
        'isStarredBy': [],
        'isDeleted': false,
      }
    ],
    'chat_2': [
      {
        'id': 'msg_2_1',
        'senderId': 'mock_uid_123',
        'type': 'text',
        'content': 'مرحباً، أرسلت لك هذه الصورة الرائعة.',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2, minutes: 5))),
        'status': 'read',
        'reactions': {},
        'isStarredBy': [],
        'isDeleted': false,
      },
      {
        'id': 'msg_2_2',
        'senderId': 'mock_uid_123',
        'type': 'image',
        'content': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'status': 'read',
        'reactions': {},
        'isStarredBy': [],
        'isDeleted': false,
      }
    ]
  };

  // StreamControllers to trigger UI updates for mock streams
  static final StreamController<List<Map<String, dynamic>>> _chatsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  static final Map<String, StreamController<List<Map<String, dynamic>>>> _messageControllers = {};
  static final Map<String, bool> _typingStates = {};
  static final Map<String, StreamController<bool>> _typingControllers = {};

  /// الحصول على شات أو إنشائه
  Future<String> getOrCreateChat(String myUid, String otherUid) async {
    if (_db == null) {
      final ids = [myUid, otherUid]..sort();
      final chatId = '${ids[0]}_${ids[1]}';
      
      final exists = _mockChats.any((c) => c['id'] == chatId);
      if (!exists) {
        final newChat = {
          'id': chatId,
          'participants': [myUid, otherUid],
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
          'lastMessageType': 'text',
          'unreadCount': {myUid: 0, otherUid: 0},
          'archivedBy': [],
          'pinnedBy': [],
          'type': 'direct',
        };
        _mockChats.add(newChat);
        _mockMessages[chatId] = [];
        _chatsController.add(List.from(_mockChats));
      }
      return chatId;
    }

    // بناء معرّف فريد دائمًا بغض النظر عن البادئ
    final ids = [myUid, otherUid]..sort();
    final chatId = '${ids[0]}_${ids[1]}';
    
    final chatRef = _db!.collection('chats').doc(chatId);
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
      });
    }
    return chatId;
  }

  /// التسمع للشاتات الخاصة بالمستخدم
  Stream<QuerySnapshot> watchMyChats(String uid) {
    if (_db == null) {
      // Return local stream converted to QuerySnapshot
      return _chatsController.stream.map((chatsList) {
        final userChats = chatsList.where((c) => (c['participants'] as List).contains(uid)).toList();
        final docs = userChats.map((c) => MockQueryDocumentSnapshot(c['id'], c)).toList();
        return MockQuerySnapshot(docs);
      }).asBroadcastStream(onListen: (sub) {
        _chatsController.add(List.from(_mockChats));
      });
    }
    return _db!
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots();
  }

  /// التسمع للرسائل
  Stream<QuerySnapshot> watchMessages(String chatId) {
    if (_db == null) {
      if (!_messageControllers.containsKey(chatId)) {
        _messageControllers[chatId] = StreamController<List<Map<String, dynamic>>>.broadcast();
      }
      return _messageControllers[chatId]!.stream.map((messagesList) {
        // Reverse to match descending timeline
        final reversed = messagesList.reversed.toList();
        final docs = reversed.map((m) => MockQueryDocumentSnapshot(m['id'], m)).toList();
        return MockQuerySnapshot(docs);
      }).asBroadcastStream(onListen: (sub) {
        _messageControllers[chatId]!.add(List.from(_mockMessages[chatId] ?? []));
      });
    }
    return _db!
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

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

    if (_db == null) {
      final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      final newMsg = {
        'id': msgId,
        'senderId': senderId,
        'type': type,
        'content': content,
        'timestamp': Timestamp.now(),
        'status': 'sent',
        'reactions': {},
        'isStarredBy': [],
        'isDeleted': false,
        if (replyTo != null) 'replyTo': replyTo,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      };

      if (!_mockMessages.containsKey(chatId)) {
        _mockMessages[chatId] = [];
      }
      _mockMessages[chatId]!.add(newMsg);

      // Update Chat List info
      final chatIndex = _mockChats.indexWhere((c) => c['id'] == chatId);
      if (chatIndex != -1) {
        final chat = _mockChats[chatIndex];
        chat['lastMessage'] = previewText;
        chat['lastMessageTime'] = Timestamp.now();
        chat['lastMessageType'] = type;
        
        final participants = List<String>.from(chat['participants'] ?? []);
        final currentUnread = Map<String, dynamic>.from(chat['unreadCount'] ?? {});
        for (final p in participants) {
          if (p != senderId) {
            currentUnread[p] = (currentUnread[p] ?? 0) + 1;
          }
        }
        chat['unreadCount'] = currentUnread;
        _mockChats[chatIndex] = chat;
      }

      // Notify Listeners
      _chatsController.add(List.from(_mockChats));
      if (_messageControllers.containsKey(chatId)) {
        _messageControllers[chatId]!.add(List.from(_mockMessages[chatId]!));
      }

      // Trigger automatic AI Response if sending message to AI Assistant
      if (chatId.contains('other_user_1') || chatId.contains('other_user_2')) {
        _simulateTypingAndResponse(chatId, senderId);
      }
      return;
    }

    final chatRef = _db!.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final messageData = {
      'id': messageRef.id,
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

    // حفظ الرسالة
    await messageRef.set(messageData);

    final doc = await chatRef.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final participants = List<String>.from(data['participants'] ?? []);
    final currentUnread = Map<String, dynamic>.from(data['unreadCount'] ?? {});

    for (final p in participants) {
      if (p != senderId) {
        currentUnread[p] = (currentUnread[p] ?? 0) + 1;
      }
    }

    await chatRef.update({
      'lastMessage': previewText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageType': type,
      'unreadCount': currentUnread,
    });
  }

  // Local AI/Bot response simulation for offline testing
  void _simulateTypingAndResponse(String chatId, String senderId) {
    final otherUid = chatId.replaceFirst(senderId, '').replaceFirst('_', '');
    setTyping(chatId, otherUid, true);

    Future.delayed(const Duration(seconds: 2), () {
      setTyping(chatId, otherUid, false);
      final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      final botMsg = {
        'id': msgId,
        'senderId': otherUid,
        'type': 'text',
        'content': 'مرحباً! أنا هنا متصل حالياً للرد عليك. تصميم الزمردة جميل، أليس كذلك؟ 💚',
        'timestamp': Timestamp.now(),
        'status': 'read',
        'reactions': {},
        'isStarredBy': [],
        'isDeleted': false,
      };

      _mockMessages[chatId]!.add(botMsg);
      final chatIndex = _mockChats.indexWhere((c) => c['id'] == chatId);
      if (chatIndex != -1) {
        final chat = _mockChats[chatIndex];
        chat['lastMessage'] = botMsg['content'];
        chat['lastMessageTime'] = Timestamp.now();
        chat['lastMessageType'] = 'text';
        _mockChats[chatIndex] = chat;
      }

      _chatsController.add(List.from(_mockChats));
      if (_messageControllers.containsKey(chatId)) {
        _messageControllers[chatId]!.add(List.from(_mockMessages[chatId]!));
      }
    });
  }

  /// تحديث حالة القراءة للمحادثة
  Future<void> markChatAsRead(String chatId, String myUid) async {
    if (_db == null) {
      final chatIndex = _mockChats.indexWhere((c) => c['id'] == chatId);
      if (chatIndex != -1) {
        final chat = _mockChats[chatIndex];
        final unreadCount = Map<String, dynamic>.from(chat['unreadCount'] ?? {});
        unreadCount[myUid] = 0;
        chat['unreadCount'] = unreadCount;
        _mockChats[chatIndex] = chat;
        _chatsController.add(List.from(_mockChats));
      }

      if (_mockMessages.containsKey(chatId)) {
        for (var msg in _mockMessages[chatId]!) {
          if (msg['senderId'] != myUid && msg['status'] != 'read') {
            msg['status'] = 'read';
          }
        }
        if (_messageControllers.containsKey(chatId)) {
          _messageControllers[chatId]!.add(List.from(_mockMessages[chatId]!));
        }
      }
      return;
    }

    final chatRef = _db!.collection('chats').doc(chatId);
    
    // تصفير العداد للمستخدم الحالي
    await _db!.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final unreadCount = Map<String, dynamic>.from(data['unreadCount'] ?? {});
      unreadCount[myUid] = 0;
      transaction.update(chatRef, {'unreadCount': unreadCount});
    });

    // تحديث كل الرسائل غير المقروءة من الطرف الآخر لتصبح read
    final unreadMessages = await chatRef
        .collection('messages')
        .where('senderId', isNotEqualTo: myUid)
        .where('status', isNotEqualTo: 'read')
        .get();

    final batch = _db!.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
  }

  /// إرسال تفاعل (Reaction)
  Future<void> toggleReaction(String chatId, String messageId, String myUid, String emoji) async {
    if (_db == null) {
      if (_mockMessages.containsKey(chatId)) {
        final msgIndex = _mockMessages[chatId]!.indexWhere((m) => m['id'] == messageId);
        if (msgIndex != -1) {
          final msg = _mockMessages[chatId]![msgIndex];
          final reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});
          if (reactions[myUid] == emoji) {
            reactions.remove(myUid);
          } else {
            reactions[myUid] = emoji;
          }
          msg['reactions'] = reactions;
          _mockMessages[chatId]![msgIndex] = msg;
          
          if (_messageControllers.containsKey(chatId)) {
            _messageControllers[chatId]!.add(List.from(_mockMessages[chatId]!));
          }
        }
      }
      return;
    }

    final msgRef = _db!.collection('chats').doc(chatId).collection('messages').doc(messageId);
    
    await _db!.runTransaction((transaction) async {
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

  /// أرشفة الشات أو إلغاء الأرشفة
  Future<void> toggleArchiveChat(String chatId, String myUid, bool archive) async {
    if (_db == null) {
      final chatIndex = _mockChats.indexWhere((c) => c['id'] == chatId);
      if (chatIndex != -1) {
        final chat = _mockChats[chatIndex];
        final archivedBy = List<String>.from(chat['archivedBy'] ?? []);
        if (archive) {
          if (!archivedBy.contains(myUid)) archivedBy.add(myUid);
        } else {
          archivedBy.remove(myUid);
        }
        chat['archivedBy'] = archivedBy;
        _mockChats[chatIndex] = chat;
        _chatsController.add(List.from(_mockChats));
      }
      return;
    }

    final chatRef = _db!.collection('chats').doc(chatId);
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

  /// وضع نجمة على رسالة
  Future<void> toggleStarMessage(String chatId, String messageId, String myUid, bool star) async {
    if (_db == null) {
      if (_mockMessages.containsKey(chatId)) {
        final msgIndex = _mockMessages[chatId]!.indexWhere((m) => m['id'] == messageId);
        if (msgIndex != -1) {
          final msg = _mockMessages[chatId]![msgIndex];
          final isStarredBy = List<String>.from(msg['isStarredBy'] ?? []);
          if (star) {
            if (!isStarredBy.contains(myUid)) isStarredBy.add(myUid);
          } else {
            isStarredBy.remove(myUid);
          }
          msg['isStarredBy'] = isStarredBy;
          _mockMessages[chatId]![msgIndex] = msg;

          if (_messageControllers.containsKey(chatId)) {
            _messageControllers[chatId]!.add(List.from(_mockMessages[chatId]!));
          }
        }
      }
      return;
    }

    final msgRef = _db!.collection('chats').doc(chatId).collection('messages').doc(messageId);
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

  /// التحديث اللحظي لحالة الكتابة (Typing)
  void setTyping(String chatId, String myUid, bool isTyping) {
    if (_rtdb == null) {
      final key = '${chatId}_$myUid';
      _typingStates[key] = isTyping;
      if (_typingControllers.containsKey(key)) {
        _typingControllers[key]!.add(isTyping);
      }
      return;
    }
    _rtdb!.ref('typing/$chatId/$myUid').set(isTyping);
  }

  /// مراقبة حالة الكتابة للطرف الآخر
  Stream<dynamic> watchTyping(String chatId, String otherUid) {
    if (_rtdb == null) {
      final key = '${chatId}_$otherUid';
      if (!_typingControllers.containsKey(key)) {
        _typingControllers[key] = StreamController<bool>.broadcast();
      }
      return _typingControllers[key]!.stream.asBroadcastStream(onListen: (sub) {
        _typingControllers[key]!.add(_typingStates[key] ?? false);
      });
    }
    return _rtdb!.ref('typing/$chatId/$otherUid').onValue;
  }
}
