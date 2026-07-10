import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glowing_button.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameController = TextEditingController();
  final List<String> _selectedUids = [];
  bool _loading = false;

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final myUid = AuthService().currentUser?.uid ?? '';
    if (myUid.isEmpty) return;

    setState(() => _loading = true);

    try {
      final participants = [myUid, ..._selectedUids];
      final chatService = ChatService();
      final groupId = await chatService.createGroup(myUid, name, _selectedUids);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إنشاء المجموعة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('مجموعة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                opacity: 0.04,
                blur: 15,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceBright,
                      child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'اكتب اسم المجموعة هنا...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'اختر الأعضاء',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').limit(15).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final u = docs[index];
                        if (u.id == myUid) return const SizedBox.shrink();
                        final data = u.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'مستخدم';
                        final isSelected = _selectedUids.contains(u.id);

                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(name),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : AppColors.outline,
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedUids.remove(u.id);
                              } else {
                                _selectedUids.add(u.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              GlowingButton(
                text: 'إنشاء المجموعة',
                loading: _loading,
                onPressed: _createGroup,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}