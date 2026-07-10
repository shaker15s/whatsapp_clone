import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

class ContactsSelectScreen extends StatelessWidget {
  const ContactsSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUser?.uid ?? '';
    final chatService = ChatService();

    Stream<QuerySnapshot> getUsersStream() {
      try {
        return FirebaseFirestore.instance.collection('users').snapshots();
      } catch (_) {
        final mockDocs = [
          MockQueryDocumentSnapshot('other_user_1', {
            'name': 'سارة أحمد',
            'about': 'الحياة جميلة 💚',
            'uid': 'other_user_1',
          }),
          MockQueryDocumentSnapshot('other_user_2', {
            'name': 'كريم علي',
            'about': 'مشغول دائماً ☕',
            'uid': 'other_user_2',
          }),
        ];
        return Stream.value(MockQuerySnapshot(mockDocs));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('جهات الاتصال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمون مسجلون بعد.'));
          }

          final userDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final u = userDocs[index];
              if (u.id == myUid) return const SizedBox.shrink();
              final data = u.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'مستخدم Lumina';
              final about = data['about'] ?? 'تواصل بوضوح وأناقة';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GlassContainer(
                  opacity: 0.03,
                  blur: 10,
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(name),
                    subtitle: Text(about, style: const TextStyle(fontSize: 12, color: AppColors.outline), maxLines: 1),
                    onTap: () async {
                      final chatId = await chatService.getOrCreateChat(myUid, u.id);
                      if (context.mounted) {
                        context.pushReplacement(
                          '/chat/$chatId',
                          extra: {
                            'myUid': myUid,
                            'otherUid': u.id,
                          },
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
