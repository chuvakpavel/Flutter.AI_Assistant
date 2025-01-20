import 'package:dash_chat_2/dash_chat_2.dart';

abstract class BaseMessageRepository {
  Future<List<ChatMessage>> getAll(String chatName);
  Future<void> add(ChatMessage message, String chatName);
  Future<void> deleteAll(String chatName);
}