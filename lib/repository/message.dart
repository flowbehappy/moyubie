import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:moyubie/data/glm.dart';
import 'package:moyubie/data/llm.dart';
import 'package:get_storage/get_storage.dart';

import '../data/echo.dart';
import 'chat_room.dart';

class MessageRepository {
  static final MessageRepository _instance = MessageRepository._internal();

  factory MessageRepository() {
    return _instance;
  }

  MessageRepository._internal() {
    init();
  }

  void postMessage(
      String chatRoomUuid,
      String userName,
      String question,
      AIConversationContext convContext,
      ValueChanged<Message> onResponse,
      ValueChanged<Message> onError,
      ValueChanged<Message> onSuccess) async {
    // List<Message> messages =
    // await ChatRoomRepository().getMessagesByChatRoomUUid(chatRoomUuid);
    _getResponseFromGpt(chatRoomUuid, userName, question, convContext,
        onResponse, onError, onSuccess);
  }

  void init() {
    OpenAI.apiKey = GetStorage().read('openAiKey') ?? "sk-xx";
    OpenAI.baseUrl =
        GetStorage().read('openAiBaseUrl') ?? "https://api.openai.com";
  }

  void _getResponseFromGpt(
      String chatRoomUuid,
      String userName,
      String question,
      AIConversationContext convContext,
      ValueChanged<Message> onResponse,
      ValueChanged<Message> errorCallback,
      ValueChanged<Message> onSuccess) async {
    String llm = SettingsController.to.llm.value;

    switch (llm.toUpperCase()) {
      case "OPENAI":
        ChatGpt().getResponse(chatRoomUuid, userName, question, convContext,
            onResponse, errorCallback, onSuccess);
        break;
      case "CHATGLM":
        ChatGlM().getResponse(chatRoomUuid, userName, question, convContext,
            onResponse, errorCallback, onSuccess);
        break;
      case "ECHO":
        EchoGPT().getResponse(chatRoomUuid, userName, question, convContext,
            onResponse, errorCallback, onSuccess);
        break;
      default:
        ChatGpt().getResponse(chatRoomUuid, userName, question, convContext,
            onResponse, errorCallback, onSuccess);
    }
  }

  deleteMessage(String chatRoomUuid, String messageUuid) {
    ChatRoomRepository().deleteMessage(chatRoomUuid, messageUuid);
  }
}
