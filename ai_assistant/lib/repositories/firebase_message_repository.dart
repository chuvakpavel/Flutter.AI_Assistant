import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:medicine_assistant/repositories/base_message_repository.dart';

import '../general_providers.dart';

final messagesRepositoryProvider = Provider<FirebaseMessageRepository>((ref) => FirebaseMessageRepository(ref));

class FirebaseMessageRepository implements BaseMessageRepository {
  final Ref _ref;

  const FirebaseMessageRepository(this._ref);
  @override
  Future<void> add(ChatMessage message, String chatName) async {
    try {
      await _ref
          .read(firebaseFirestoreProvider)
          .collection(chatName)
          .add(message.toJson());
    } on FirebaseException catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> deleteAll(String chatName) async {
    try {
      final colRef = _ref.read(firebaseFirestoreProvider)
          .collection(chatName);

      final querySnapshot = await colRef.get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        colRef.doc(doc.id).delete();
      }

    } on FirebaseException catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<List<ChatMessage>> getAll(String chatName) async {
    final snap = await _ref.read(firebaseFirestoreProvider)
        .collection(chatName)
        .get();
    return snap.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();
  }

}