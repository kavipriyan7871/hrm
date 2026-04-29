import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ChatStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadFile({
    required File file,
    required String groupId,
    required String type, // 'image', 'video', 'file', 'audio'
  }) async {
    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      String folder = 'chat_media/$groupId/$type';

      Reference ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("UPLOAD ERROR => $e");
      return null;
    }
  }
}


