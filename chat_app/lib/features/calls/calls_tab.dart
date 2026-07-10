import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUser?.uid ?? '';

    Stream<QuerySnapshot> getCallStream() {
      try {
        return FirebaseFirestore.instance
            .collection('calls')
            .where('callerId', isEqualTo: myUid)
            .snapshots();
      } catch (_) {
        // Return a mock stream of QuerySnapshot for demo mode!
        final mockDocs = [
          MockQueryDocumentSnapshot('call_mock_1', {
            'callerId': myUid,
            'calleeId': 'other_user_1',
            'type': 'video',
            'status': 'accepted',
            'createdAt': Timestamp.now(),
          }),
          MockQueryDocumentSnapshot('call_mock_2', {
            'callerId': 'other_user_2',
            'calleeId': myUid,
            'type': 'voice',
            'status': 'declined',
            'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          }),
        ];
        return Stream.value(MockQuerySnapshot(mockDocs));
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: getCallStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_missed_outlined, size: 64, color: AppColors.outline.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد مكالمات بعد',
                  style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        final callDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: callDocs.length,
          itemBuilder: (context, index) {
            final data = callDocs[index].data() as Map<String, dynamic>;
            final isVideo = data['type'] == 'video';
            final status = data['status'];
            final otherUid = data['calleeId'] == myUid ? data['callerId'] : data['calleeId'];
            final timestamp = (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now();

            IconData callIcon;
            Color iconColor;
            if (status == 'declined' || status == 'ended') {
              callIcon = Icons.call_received;
              iconColor = Colors.grey;
            } else if (status == 'ringing') {
              callIcon = Icons.call_made;
              iconColor = AppColors.primary;
            } else {
              callIcon = Icons.call_made;
              iconColor = AppColors.tertiary;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassContainer(
                opacity: 0.03,
                blur: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.surfaceBright,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherUid,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(callIcon, size: 14, color: iconColor),
                                const SizedBox(width: 6),
                                Text(
                                  intl.DateFormat('MM/dd HH:mm').format(timestamp),
                                  style: const TextStyle(fontSize: 12, color: AppColors.outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(isVideo ? Icons.videocam_outlined : Icons.phone_outlined),
                        color: AppColors.primary,
                        onPressed: () {
                          // بدء مكالمة جديدة
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
