import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../general_providers.dart';

final imagesRepositoryProvider = Provider<ImagesRepository>((ref) => ImagesRepository(ref));

abstract class BaseImagesRepository {
  Future<String> add(String chatName, {required XFile image});
  Future<void> deleteAll(String chatName);
}

class ImagesRepository implements BaseImagesRepository {
  final Ref _ref;

  const ImagesRepository(this._ref);

  @override
  Future<String> add(String chatName, {required XFile image}) async {
    try {
      Reference referenceImageToUpload = _ref
          .read(firebaseStorageProvider)
          .ref()
          .child('images')
          .child(chatName)
          .child(image.name);

      await referenceImageToUpload.putFile(File(image.path));

      return await referenceImageToUpload.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> deleteAll(String chatName) async {
    try {
      final listResult = await _ref
          .read(firebaseStorageProvider)
          .ref()
          .child('images')
          .child(chatName)
          .listAll();
      for (var fileRef in listResult.items) {
        await fileRef.delete();
      }
    } on FirebaseException catch (e) {
      throw Exception(e);
    }
  }
}