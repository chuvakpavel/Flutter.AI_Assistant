import 'dart:io';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/message_controller.dart';
import '../widgets/components/custom_exception_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  final user = ChatUser(
    id: '1',
    firstName: 'user',
    lastName: 'user',
  );

  XFile? _selectedImg;
  bool _inputDisabled = false;
  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesControllerProvider);
    final selectedChat = ref.watch(selectedChatProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(messagesControllerProvider.notifier).deleteAll();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 15),
            child: DropdownButton(
              value: selectedChat,
              onChanged: (Chats? newValue) {
                if (newValue != null) {
                  ref.read(selectedChatProvider.notifier).updateSelectedType(newValue);
                }
              },
              items: Chats.values.map((Chats chat) {
                return DropdownMenuItem<Chats>(
                  value: chat,
                  child: Text(chat.name),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: messagesState.when(
        data: (messages) {
          return Column(
            children: [
              Expanded(
                child: DashChat(
                  currentUser: user,
                  inputOptions: InputOptions(
                    inputDisabled: _inputDisabled,
                    sendOnEnter:  true,
                    leading: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: () => _selectImg(),
                      ),
                    ],
                  ),
                  onSend: (message) async {
                    setState(() {_inputDisabled = true;});
                    message.text = message.text.trim();
                    if(message.text.isEmpty) return;
                    final selectedImg = _selectedImg;
                    if(_selectedImg != null) setState(() {_selectedImg = null;});

                    await ref
                        .read(messagesControllerProvider.notifier)
                        .add(message, image: selectedImg);

                    await ref
                        .read(messagesControllerProvider.notifier)
                        .getAnswer(selectedChat);

                    setState(() {
                      _inputDisabled = false;
                    });
                  },
                  messages: messages,
                ),
              ),
              if (_selectedImg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImg!.path),
                            fit: BoxFit.cover,
                            height: 100,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: _removeImg,
                          child: const Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => CustomExceptionWidget(
          message: error.toString(),
          function: () => ref.read(messagesControllerProvider.notifier).getAll(),
        ),
      ),
    );
  }

  void _selectImg() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image != null) {
      setState(() {
        _selectedImg = image;
      });
    }
  }

  void _removeImg(){
    setState(() {
      _selectedImg = null;
    });
  }

}