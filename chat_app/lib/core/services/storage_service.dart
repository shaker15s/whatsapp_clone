import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;

/// خدمة التخزين - رفع الصور/الصوتيات/الأفاتار إلى Firebase Storage
class StorageService {
  /// التحقق من جاهزية Firebase
  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseStorage get _storage {
    if (!_isFirebaseReady) {
      throw StateError('Firebase غير مهيأ. شغل flutterfire configure أولاً.');
    }
    return FirebaseStorage.instance;
  }

  final Uuid _uuid = const Uuid();

  static void _log(String msg) {
    if (kDebugMode) debugPrint('[StorageService] $msg');
  }

  /// رفع صورة - ترجع URL للتنزيل
  Future<String> uploadImage(File file, String chatId) async {
    if (kIsWeb) {
      throw UnsupportedError('uploadImage with File غير مدعوم على Web. استخدم uploadImageBytes.');
    }

    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('chats/$chatId/images/$fileName');

    try {
      final task = await ref.putFile(file);
      final downloadUrl = await task.ref.getDownloadURL();
      _log('uploadImage success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('uploadImage error: $e');
      rethrow;
    }
  }

  /// رفع صورة من بايتات (للتوافق مع Web)
  Future<String> uploadImageBytes(Uint8List bytes, String chatId, {String fileName = ''}) async {
    final name = fileName.isEmpty ? '${_uuid.v4()}.jpg' : fileName;
    final ref = _storage.ref().child('chats/$chatId/images/$name');

    try {
      final task = await ref.putData(bytes);
      final downloadUrl = await task.ref.getDownloadURL();
      _log('uploadImageBytes success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('uploadImageBytes error: $e');
      rethrow;
    }
  }

  /// رفع رسالة صوتية - ترجع URL للتنزيل
  Future<String> uploadAudio(File file, String chatId) async {
    if (kIsWeb) {
      throw UnsupportedError('uploadAudio with File غير مدعوم على Web. استخدم uploadAudioBytes.');
    }

    final fileName = '${_uuid.v4()}.m4a';
    final ref = _storage.ref().child('chats/$chatId/audio/$fileName');

    try {
      final task = await ref.putFile(file);
      final downloadUrl = await task.ref.getDownloadURL();
      _log('uploadAudio success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('uploadAudio error: $e');
      rethrow;
    }
  }

  /// رفع صوتيات من بايتات (للتوافق مع Web)
  Future<String> uploadAudioBytes(Uint8List bytes, String chatId, {String fileName = ''}) async {
    final name = fileName.isEmpty ? '${_uuid.v4()}.m4a' : fileName;
    final ref = _storage.ref().child('chats/$chatId/audio/$name');

    try {
      final task = await ref.putData(bytes);
      final downloadUrl = await task.ref.getDownloadURL();
      _log('uploadAudioBytes success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('uploadAudioBytes error: $e');
      rethrow;
    }
  }

  /// رفع صورة الملف الشخصي - ترجع URL للتنزيل
  Future<String> uploadProfilePic(File file, String uid) async {
    if (kIsWeb) {
      throw UnsupportedError('uploadProfilePic with File غير مدعوم على Web. استخدم uploadProfilePicBytes.');
    }

    final ref = _storage.ref().child('profile_pics/$uid.jpg');

    try {
      final task = await ref.putFile(file);
      final downloadUrl = await task.ref.getDownloadURL();
      _log('uploadProfilePic success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('uploadProfilePic error: $e');
      rethrow;
    }
  }

  /// رفع صورة الملف الشخصي من بايتات (للتوافق مع Web)
  Future<String> uploadProfilePicBytes(Uint8List bytes, String uid) async {
    final ref = _storage.ref().child('profile_pics/$uid.jpg');

    try {
      final task = await ref.putData(bytes);
      final downloadUrl = await task.ref.getDownloadURL();
      _log('uploadProfilePicBytes success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('uploadProfilePicBytes error: $e');
      rethrow;
    }
  }

  /// حذف ملف من التخزين
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      _log('deleteFile success: $downloadUrl');
    } catch (e) {
      _log('deleteFile error: $e');
      rethrow;
    }
  }
}