import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUser?.uid ?? '';

    Stream<QuerySnapshot> getStatusStream() {
      try {
        return FirebaseFirestore.instance
            .collection('status')
            .orderBy('createdAt', descending: true)
            .snapshots();
      } catch (_) {
        // Return a mock stream of QuerySnapshot for demo mode!
        final mockDocs = [
          MockQueryDocumentSnapshot('status_mock_1', {
            'uid': 'other_user_1',
            'userName': 'سارة أحمد',
            'statusText': 'يوم جميل في الحديقة 🌸',
            'createdAt': Timestamp.now(),
          }),
          MockQueryDocumentSnapshot('status_mock_2', {
            'uid': 'other_user_2',
            'userName': 'كريم علي',
            'statusText': 'قهوة الصباح ☕',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
          }),
        ];
        return Stream.value(MockQuerySnapshot(mockDocs));
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: getStatusStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final statusDocs = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الحالات الخاصة بي
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: GlassContainer(
                    opacity: 0.04,
                    blur: 15,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                                  style: TextStyle(fontSize: 13, color: AppColors.outline.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const Text(
                  'آخر التحديثات',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                if (statusDocs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(
                        'لا توجد حالات حديثة حاليًا.',
                        style: TextStyle(color: AppColors.outline.withOpacity(0.7)),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: statusDocs.length,
                    itemBuilder: (context, index) {
                      final data = statusDocs[index].data() as Map<String, dynamic>;
                      final senderName = data['name'] ?? 'مستخدم Lumina';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassContainer(
                          opacity: 0.03,
                          blur: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                        senderName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'منذ قليل',
                                        style: TextStyle(fontSize: 12, color: AppColors.outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
