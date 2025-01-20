import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
final geminiProvider = Provider<Gemini>((ref) => Gemini.instance);
final openAIProvider = Provider<OpenAI>((ref) => OpenAI.instance.build(
    token: dotenv.env['OPEN_AI_KEY'],
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
    enableLog: true
));