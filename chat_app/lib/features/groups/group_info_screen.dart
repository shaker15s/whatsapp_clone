import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class GroupInfoScreen extends StatelessWidget {
  final String groupId;

  const GroupInfoScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('معلومات المجموعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('المجموعة غير موجودة'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final groupName = data['groupName'] ?? 'مجموعة';
          final participants = List<String>.from(data['participants'] ?? []);
          final admins = List<String>.from(data['admins'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 53,
                          backgroundColor: AppColors.surfaceBright,
                          child: Icon(Icons.groups, size: 55, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        groupName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مجموعة • ${participants.length} أعضاء',
                        style: const TextStyle(color: AppColors.outline, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // خيارات المجموعة
                GlassContainer(
                  opacity: 0.03,
                  blur: 10,
                  child: ListTile(
                    leading: const Icon(Icons.link, color: AppColors.primary),
                    title: const Text('رابط الدعوة للمجموعة', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('مشاركة رابط الدعوة أو نسخه', style: TextStyle(color: AppColors.outline, fontSize: 12)),
                    onTap: () => context.push('/group/$groupId/invite'),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'الأعضاء في هذه المجموعة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final uid = participants[index];
                    final isAdmin = admins.contains(uid);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GlassContainer(
                        opacity: 0.02,
                        blur: 5,
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(uid.length > 10 ? 'مستخدم Lumina' : uid),
                          trailing: isAdmin
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('أدمن', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
