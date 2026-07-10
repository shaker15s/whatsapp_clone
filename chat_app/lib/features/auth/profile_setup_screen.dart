import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/glowing_button.dart';
import '../../shared/widgets/glass_container.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  
  File? _imageFile;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال اسمك');
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _storageService.uploadProfilePic(_imageFile!, user.uid);
      }

      await _authService.createUserProfile(
        uid: user.uid,
        name: name,
        phoneNumber: user.phoneNumber ?? '',
        profilePicUrl: photoUrl,
      );

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'حدث خطأ أثناء حفظ الملف الشخصي. يرجى المحاولة مرة أخرى.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
                const Text(
                  'إعداد الملف الشخصي',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'يرجى إدخال اسمك وصورتك الشخصية ليعرفها أصدقاؤك عند محادثتك.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 45),
                
                // منتقي الصورة الشخصية
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 62,
                            backgroundColor: Colors.black.withValues(alpha: 0.3),
                            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                            child: _imageFile == null
                                ? const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  opacity: 0.04,
                  blur: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اسم العرض (مطلوب)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'اكتب اسمك هنا...',
                          fillColor: Colors.black.withValues(alpha: 0.2),
                          filled: true,
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 50),
                GlowingButton(
                  text: 'حفظ ودخول التطبيق',
                  loading: _loading,
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
