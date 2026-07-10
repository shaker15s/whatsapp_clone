import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../core/services/auth_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String _lastSeen = 'everyone';
  String _profilePhoto = 'everyone';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _lastSeen = (data['lastSeenPrivacy'] ?? 'everyone') as String;
          _profilePhoto = (data['profilePhotoPrivacy'] ?? 'everyone') as String;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updatePrivacy(String field, String value) async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    // Optimistic local update
    setState(() {
      if (field == 'lastSeen') _lastSeen = value;
      if (field == 'profilePhoto') _profilePhoto = value;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        field: value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الإعداد: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الخصوصية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              children: [
                const Text(
                  'من يمكنه رؤية آخر ظهور لي',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                _PrivacyRadioGroup<String>(
                  value: _lastSeen,
                  options: const [
                    _RadioOption('الجميع', 'everyone'),
                    _RadioOption('جهات اتصالي', 'contacts'),
                    _RadioOption('لا أحد', 'nobody'),
                  ],
                  onChanged: (val) => _updatePrivacy('lastSeenPrivacy', val!),
                ),
                const SizedBox(height: 24),
                const Text(
                  'من يمكنه رؤية صورتي الشخصية',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                _PrivacyRadioGroup<String>(
                  value: _profilePhoto,
                  options: const [
                    _RadioOption('الجميع', 'everyone'),
                    _RadioOption('جهات اتصالي', 'contacts'),
                    _RadioOption('لا أحد', 'nobody'),
                  ],
                  onChanged: (val) => _updatePrivacy('profilePhotoPrivacy', val!),
                ),
              ],
            ),
    );
  }
}

class _RadioOption {
  final String label;
  final String value;
  const _RadioOption(this.label, this.value);
}

class _PrivacyRadioGroup<T> extends StatelessWidget {
  final T value;
  final List<_RadioOption> options;
  final ValueChanged<T?> onChanged;

  const _PrivacyRadioGroup({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.03,
      blur: 10,
      child: Column(
        children: options.map((opt) {
          return RadioListTile<T>(
            title: Text(opt.label, style: const TextStyle(color: Colors.white)),
            value: opt.value as T,
            groupValue: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          );
        }).toList(),
      ),
    );
  }
}
