import 'dart:async';

import 'package:moyubie/repository/chat_room.dart';
import 'package:moyubie/repository/message.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class MessageController extends GetxController {
  final messageList = <Message>[].obs;
  final uuid = const Uuid();

  void loadAllMessages(String chatRoomUuid) async {
    messageList.value =
        await ChatRoomRepository().getMessagesByChatRoomUUid(chatRoomUuid);
  }

  void addMessage(
      String chatRoomUuid, Message input, String ai_question) async {
    // Add user intput to message list
    await ChatRoomRepository().addMessage(chatRoomUuid, input);

    final messages =
        await ChatRoomRepository().getMessagesByChatRoomUUid(chatRoomUuid);

    if (!input.ask_ai) {
      final messages =
          await ChatRoomRepository().getMessagesByChatRoomUUid(chatRoomUuid);
      messageList.value = messages;
      return;
    }

    // If this message is a question for AI, then send request to AI service.
    final completer = Completer();

    // wait for all the state emit
    try {
      MessageRepository().postMessage(
          chatRoomUuid, //
          "",
          ai_question,
          AIConversationContext(), //
          (Message res) {
        messageList.value = [...messages, res];
      }, //
          (Message res) {
        messageList.value = [...messages, res];
      }, //
          (Message res) async {
        // if streaming is done ,load all the message
        ChatRoomRepository().addMessage(chatRoomUuid, res);
        final messages =
            await ChatRoomRepository().getMessagesByChatRoomUUid(chatRoomUuid);
        messageList.value = messages;
        completer.complete();
      });
    } catch (e) {
      messageList.value = [
        ...messages,
        Message(
            uuid: uuid.v4(),
            message: e.toString(),
            userName: "bot",
            createTime: DateTime.now(),
            source: MessageSource.bot)
      ];
      completer.complete();
    }
    await completer.future;
  }
}
