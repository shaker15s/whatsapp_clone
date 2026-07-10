import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }
  
  final Uuid _uuid = const Uuid();

  Future<String> uploadImage(File file, String chatId) async {
    if (_storage == null) {
      // Offline mode: return local file path or mock unsplash url
      return file.path;
    }
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage!.ref().child('chats/$chatId/images/$fileName');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return file.path;
    }
  }

  Future<String> uploadAudio(File file, String chatId) async {
    if (_storage == null) {
      // Offline mode: return local path
      return file.path;
    }
    try {
      final fileName = '${_uuid.v4()}.m4a';
      final ref = _storage!.ref().child('chats/$chatId/audio/$fileName');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return file.path;
    }
  }

  Future<String> uploadProfilePic(File file, String uid) async {
    if (_storage == null) {
      return file.path;
    }
    try {
      final ref = _storage!.ref().child('profile_pics/$uid.jpg');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return file.path;
    }
  }
}
