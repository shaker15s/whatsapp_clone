import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/glowing_button.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  double _cacheSizeMb = 0.0;
  bool _autoDownloadWifi = true;
  bool _autoDownloadMobile = false;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      double totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true).forEach((file) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        });
      }
      setState(() {
        _cacheSizeMb = totalSize / (1024 * 1024);
      });
    } catch (_) {}
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      _calculateCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح الذاكرة المؤقتة بنجاح')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('التخزين والبيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        children: [
          const Text(
            'استهلاك التخزين الحالي',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.04,
            blur: 15,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ذاكرة الكاش (المؤقتة)', style: TextStyle(fontSize: 15)),
                    Text('${_cacheSizeMb.toStringAsFixed(2)} MB', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 20),
                GlowingButton(
                  text: 'مسح الكاش والميديا الموقتة',
                  onPressed: _clearCache,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'التنزيل التلقائي للوسائط',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            opacity: 0.03,
            blur: 10,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('التنزيل التلقائي عبر Wi-Fi', style: TextStyle(color: Colors.white)),
                  activeColor: AppColors.primary,
                  value: _autoDownloadWifi,
                  onChanged: (val) => setState(() => _autoDownloadWifi = val),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                SwitchListTile(
                  title: const Text('التنزيل التلقائي عبر البيانات الخلوية', style: TextStyle(color: Colors.white)),
                  activeColor: AppColors.primary,
                  value: _autoDownloadMobile,
                  onChanged: (val) => setState(() => _autoDownloadMobile = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
