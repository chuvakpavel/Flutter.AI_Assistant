import 'package:chat_gpt_sdk/chat_gpt_sdk.dart' as gpt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicine_assistant/general_providers.dart';
import 'package:medicine_assistant/repositories/firebase_image_repository.dart';
import 'package:medicine_assistant/repositories/firebase_message_repository.dart';
import 'package:medicine_assistant/services/api_service.dart';

enum Chats {gemini, openAI}

final selectedChatProvider = StateNotifierProvider<SelectedChatNotifier, Chats>(
        (ref) => SelectedChatNotifier(ref));

class SelectedChatNotifier extends StateNotifier<Chats> {
  final Ref _ref;
  SelectedChatNotifier(this._ref) : super(Chats.gemini);

  void updateSelectedType(Chats newChat) {
    if (state != newChat) {
      state = newChat;

      _ref.read(messagesControllerProvider.notifier).getAll();
    }
  }
}


final messagesExceptionProvider = StateProvider<Exception?>((_) => null);

final messagesControllerProvider = StateNotifierProvider<MessageController, AsyncValue<List<ChatMessage>>>(
        (ref) => MessageController(ref));

class MessageController extends StateNotifier<AsyncValue<List<ChatMessage>>>{

  final Ref _ref;

  MessageController(this._ref) : super(const AsyncValue.data([])){
    getAll();
  }

  final assistant = ChatUser(
    id: '2',
    firstName: 'AI',
    lastName: 'Assistant',
  );

  List<List<String>> history = [];

  Future<void> add(ChatMessage message, {XFile? image}) async {
    try {
      String chatName = _ref.read(selectedChatProvider).name;
      if(image != null) {
        final imageUrl = await _ref.read(imagesRepositoryProvider).add(chatName, image: image);
        message.medias = [
          ChatMedia(
              url: imageUrl,
              fileName: image.name,
              type: MediaType.image
          )
        ];
      }
      await _save(message);
      state = AsyncValue.data([message, ...state.value!]);
    } on FirebaseException catch (e, st) {
      state = AsyncValue.error(e, st);
      throw Exception(e);
    }
  }

  Future<void> deleteAll() async {
    try {
      String chatName = _ref.read(selectedChatProvider).name;
      await _ref.read(messagesRepositoryProvider).deleteAll(chatName);
      await _ref.read(imagesRepositoryProvider).deleteAll(chatName);
      state = const AsyncValue.data([]);
    } on FirebaseException catch (e, st) {
      state = AsyncValue.error(e, st);
      throw Exception(e);
    }
  }

  Future<void> getAll() async {
    try {
      state = const AsyncValue.loading();
      String chatName = _ref.read(selectedChatProvider).name;
      final messages = await _ref.read(messagesRepositoryProvider).getAll(chatName);
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> getAnswer(Chats chat) async {
    _addAssistantTypingMessage();
    switch (chat) {
      case Chats.gemini: _getAnswerGemini();
      case Chats.openAI: _getAnswerGPT();
    }
  }

  Future<void> _getAnswerGPT() async {
    try {
      final history = state.value!.map((message){
        return message.customProperties?['isTyping'] != true ? {
          "role": message.user.firstName == 'user' ? 'user' : 'assistant',
          "content": [
            {
              "type": "text",
              "text": message.text
            },
            if(message.medias != null && message.medias!.isNotEmpty)
              {
                "type": "image_url",
                "image_url": {"url": message.medias!.first.url}
              }
          ],
        } : null;
      }).whereType<Map<String, dynamic>>().toList();

      final request = gpt.ChatCompleteText(
        model: gpt.Gpt4OChatModel(),
        maxToken: 200,
        temperature: 0.0,
        messages: history.reversed.toList(),
      );

      String answer = '';
      _ref.read(openAIProvider).onChatCompletionSSE(request: request).listen((res) {
        answer += res.choices!.first.message!.content;
        state.value!.first = _createAssistantAnswer(answer);
        state = AsyncValue.data(state.value!);
      }).onDone((){
        _save(state.value!.first);
      });

    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _getAnswerGemini() async {
    try {
      final history = await Future.wait(state.value!.map((message) async {
        return [
          if(message.customProperties?['isTyping'] != true)
            Content(
              parts: [
                if (message.medias != null && message.medias!.isNotEmpty)
                  Part.bytes((await ApiService.get(uri: message.medias!.first.url)).bodyBytes),
                Part.text(message.text),
              ],
              role: message.user.firstName == 'user' ? 'user' : 'model',
            )
        ];
      }));
      String answer = '';
      _ref.read(geminiProvider).streamChat(
        history.reversed.expand((innerList) => innerList).toList()
      ).listen((res) {
        answer += (res.content!.parts!.first as TextPart).text;
        state.value!.first = _createAssistantAnswer(answer);
        state = AsyncValue.data(state.value!);
      }).onDone((){
        _save(state.value!.first);
      });

    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  ChatMessage _createAssistantAnswer(String answer, { Map<String, dynamic>? customProperties }){
    return ChatMessage(
      user: assistant,
      createdAt: DateTime.now(),
      text: answer,
      customProperties: customProperties,
    );
  }

  void _addAssistantTypingMessage(){
    final message = _createAssistantAnswer(
        'Assistant is typing...',
        customProperties: {'isTyping': true}
    );
    state = AsyncValue.data([message, ...state.value!]);
  }


  Future<void> _save(ChatMessage message) async {
    try {
      String chatName = _ref.read(selectedChatProvider).name;
      await _ref.read(messagesRepositoryProvider).add(message, chatName);
    } on FirebaseException catch (e, st) {
      state = AsyncValue.error(e, st);
      throw Exception(e);
    }
  }

}