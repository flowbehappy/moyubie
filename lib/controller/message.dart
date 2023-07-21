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

  void addMessage(String chatRoomUuid, Message message) async {
    await ChatRoomRepository().addMessage(chatRoomUuid, message);
    final messages =
        await ChatRoomRepository().getMessagesByChatRoomUUid(chatRoomUuid);
    messageList.value = messages;
    // wait for all the state emit
    final completer = Completer();
    try {
      MessageRepository().postMessage(chatRoomUuid, "", message,
          (Message message) {
        messageList.value = [...messages, message];
      }, (Message message) {
        messageList.value = [...messages, message];
      }, (Message message) async {
        // if streaming is done ,load all the message
        ChatRoomRepository().addMessage(chatRoomUuid, message);
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
