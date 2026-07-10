import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  String _fontSize = 'medium';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getString('chat_font_size') ?? 'medium';
    });
  }

  Future<void> _setFontSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_font_size', size);
    setState(() => _fontSize = size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إعدادات الدردشة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        children: [
          const Text(
            'حجم خط المحادثة',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.03,
            blur: 10,
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('صغير', style: TextStyle(color: Colors.white)),
                  value: 'small',
                  groupValue: _fontSize,
                  activeColor: AppColors.primary,
                  onChanged: (val) => _setFontSize(val!),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                RadioListTile<String>(
                  title: const Text('متوسط (افتراضي)', style: TextStyle(color: Colors.white)),
                  value: 'medium',
                  groupValue: _fontSize,
                  activeColor: AppColors.primary,
                  onChanged: (val) => _setFontSize(val!),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                RadioListTile<String>(
                  title: const Text('كبير', style: TextStyle(color: Colors.white)),
                  value: 'large',
                  groupValue: _fontSize,
                  activeColor: AppColors.primary,
                  onChanged: (val) => _setFontSize(val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'خلفية الدردشة',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.03,
            blur: 10,
            child: ListTile(
              leading: const Icon(Icons.wallpaper, color: Colors.white),
              title: const Text('تغيير خلفية الشات الرئيسية', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_left, color: AppColors.outline),
              onTap: () {
                // فتح معرض الخلفيات
              },
            ),
          ),
        ],
      ),
    );
  }
}
