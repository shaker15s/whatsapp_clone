import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String _lastSeen = 'everyone';
  String _profilePhoto = 'everyone';

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        children: [
          const Text(
            'من يمكنه رؤية آخر ظهور لي',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.03,
            blur: 10,
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('الجميع', style: TextStyle(color: Colors.white)),
                  value: 'everyone',
                  groupValue: _lastSeen,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _lastSeen = val!),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                RadioListTile<String>(
                  title: const Text('جهات اتصالي', style: TextStyle(color: Colors.white)),
                  value: 'contacts',
                  groupValue: _lastSeen,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _lastSeen = val!),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                RadioListTile<String>(
                  title: const Text('لا أحد', style: TextStyle(color: Colors.white)),
                  value: 'nobody',
                  groupValue: _lastSeen,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _lastSeen = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'من يمكنه رؤية صورتي الشخصية',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.03,
            blur: 10,
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('الجميع', style: TextStyle(color: Colors.white)),
                  value: 'everyone',
                  groupValue: _profilePhoto,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _profilePhoto = val!),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                RadioListTile<String>(
                  title: const Text('جهات اتصالي', style: TextStyle(color: Colors.white)),
                  value: 'contacts',
                  groupValue: _profilePhoto,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _profilePhoto = val!),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                RadioListTile<String>(
                  title: const Text('لا أحد', style: TextStyle(color: Colors.white)),
                  value: 'nobody',
                  groupValue: _profilePhoto,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _profilePhoto = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
