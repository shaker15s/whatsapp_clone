import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

/// A simple mock document for offline mode
class _MockStatusDoc {
  final String id;
  final Map<String, dynamic> _data;
  _MockStatusDoc(this.id, this._data);
  
  Map<String, dynamic> data() => _data;
  bool get exists => true;
}

/// A simple mock snapshot for offline mode
class _MockStatusSnapshot {
  final List<_MockStatusDoc> _docs;
  _MockStatusSnapshot(this._docs);
  
  List<_MockStatusDoc> get docs => _docs;
  int get size => _docs.length;
  bool get isEmpty => _docs.isEmpty;
}

class StatusTab extends StatefulWidget {
  const StatusTab({super.key});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  final ChatService _chatService = ChatService();

  /// Build a status stream: in mock mode, fall back to built-in mocks;
  /// in real mode, fetch from Firestore `status` collection ordered by time.
  Stream<dynamic> _getStatusStream() {
    final db = FirebaseFirestore.instance;
    try {
      return db.collection('status').orderBy('createdAt', descending: true).snapshots();
    } catch (_) {
      // Fallback mock stream
      final mockDocs = [
        _MockStatusDoc('status_mock_1', {
          'uid': 'other_user_1',
          'name': 'سارة أحمد',
          'statusText': 'يوم جميل في الحديقة 🌸',
          'createdAt': Timestamp.now(),
        }),
        _MockStatusDoc('status_mock_2', {
          'uid': 'other_user_2',
          'name': 'كريم علي',
          'statusText': 'قهوة الصباح ☕',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
        }),
      ];
      return Stream.value(_MockStatusSnapshot(mockDocs));
    }
  }

  void _openPostStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, color: AppColors.primary),
              title: const Text('حالة نصية'),
              onTap: () {
                Navigator.pop(ctx);
                _showTextStatusDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.primary),
              title: const Text('حالة صورة'),
              onTap: () {
                Navigator.pop(ctx);
                _showImageStatusDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTextStatusDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('إضافة حالة نصية'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(hintText: 'ماذا يدور في ذهنك؟'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              await _postTextStatus(text);
            },
            child: const Text('نشر'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageStatusDialog() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    if (mounted) {
      await _postImageStatus(file);
    }
  }

  Future<void> _postTextStatus(String text) async {
    final myUid = AuthService().currentUser?.uid;
    if (myUid == null) return;
    try {
      await FirebaseFirestore.instance.collection('status').add({
        'uid': myUid,
        'type': 'text',
        'statusText': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر الحالة ✅'), duration: Duration(seconds: 2)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل نشر الحالة')),
        );
      }
    }
  }

  Future<void> _postImageStatus(File file) async {
    final myUid = AuthService().currentUser?.uid;
    if (myUid == null) return;
    try {
      // Upload image to Storage
      final photoUrl = await _chatService.uploadImage(file, 'statuses');
      await FirebaseFirestore.instance.collection('status').add({
        'uid': myUid,
        'type': 'image',
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر الحالة ✅'), duration: Duration(seconds: 2)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل نشر الحالة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          StreamBuilder<dynamic>(
            stream: _getStatusStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final docs = snapshot.data?.docs ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My status card
                    GlassContainer(
                      opacity: 0.04,
                      blur: 12,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _openPostStatusSheet,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.surfaceBright,
                                    child: Icon(Icons.person, color: Colors.white, size: 28),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'حالتي',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'إضافة تحديث لحالتك',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.outline.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'آخر التحديثات',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (docs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'لا توجد حالات حديثة.',
                            style: TextStyle(color: AppColors.outline.withValues(alpha: 0.7)),
                          ),
                        ),
                      )
                    else
                      ...docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? data['uid'] ?? 'مستخدم';
                        final type = data['type'] ?? 'text';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassContainer(
                            opacity: 0.03,
                            blur: 10,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                // View status detail (simple placeholder)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('حالة $name'), duration: const Duration(seconds: 1)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.tertiary, width: 2),
                                      ),
                                      child: const CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.surfaceBright,
                                        child: Icon(Icons.person, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          if (type == 'image' && data['photoUrl'] != null)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                data['photoUrl'],
                                                width: double.infinity,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image_not_supported, size: 48),
                                              ),
                                            )
                                          else
                                            Text(
                                              data['statusText'] ?? 'تحديث حالة',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _timeAgo(data['createdAt']),
                                            style: TextStyle(fontSize: 12, color: AppColors.outline.withValues(alpha: 0.7)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),

          // FAB to add status
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _openPostStatusSheet,
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
              label: const Text('إضافة حالة', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic createdAt) {
    try {
      final ts = createdAt is Timestamp ? createdAt.toDate() : DateTime.parse(createdAt.toString());
      final diff = DateTime.now().difference(ts);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
      return 'منذ ${diff.inDays} يوم';
    } catch (_) {
      return 'منذ قليل';
    }
  }
}