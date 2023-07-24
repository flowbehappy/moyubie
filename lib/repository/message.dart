import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:moyubie/data/glm.dart';
import 'package:moyubie/data/llm.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../data/echo.dart';
import 'chat_room.dart';

class MessageRepository {
  static final MessageRepository _instance = MessageRepository._internal();

  final uuid = const Uuid();

  factory MessageRepository() {
    return _instance;
  }

  MessageRepository._internal();

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
    _getResponseFromLLM(chatRoomUuid, userName, question, convContext,
        onResponse, onError, onSuccess);
  }

  void _getResponseFromLLM(
      String chatRoomUuid,
      String userName,
      String question,
      AIConversationContext convContext,
      ValueChanged<Message> onResponse,
      ValueChanged<Message> errorCallback,
      ValueChanged<Message> onSuccess) async {
    String llm = SettingsController.to.llm.value;

    if (llm.toUpperCase() == "ECHO") {
      EchoGPT().getResponse(chatRoomUuid, userName, question, convContext,
          onResponse, errorCallback, onSuccess);
      return;
    }

    if (!SettingsController.to.getIsLLMReady) {
      // LLM service is not ready.
      var message = Message(
          uuid: uuid.v1(),
          message:
              "AI service is not ready. Please use correct token or check your network",
          userName: userName,
          createTime: DateTime.now(),
          source: MessageSource.bot);

      errorCallback(message);
      return;
    }

    switch (llm.toUpperCase()) {
      case "OPENAI":
        ChatGpt().getResponse(chatRoomUuid, userName, question, convContext,
            onResponse, errorCallback, onSuccess);
        break;
      default:
        EchoGPT().getResponse(chatRoomUuid, userName, question, convContext,
            onResponse, errorCallback, onSuccess);
    }
  }

  deleteMessage(String chatRoomUuid, String messageUuid) {
    ChatRoomRepository().deleteMessage(chatRoomUuid, messageUuid);
  }
}
