import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:Moyubie/controller/settings.dart';
import 'package:Moyubie/repository/chat_room.dart';
import 'package:Moyubie/repository/message.dart';
import 'package:get/get.dart';
import 'package:Moyubie/utils/tag_collector.dart';
import 'package:uuid/uuid.dart';

class MessageController extends GetxController {
  final messageList = <Message>[].obs;
  final uuid = const Uuid();

  void loadAllMessages(ChatRoom room) async {
    final msgList = await ChatRoomRepository().getMessagesByChatRoomUUid(room);
    messageList.value = msgList;
    final messageListRemote = await ChatRoomRepository()
        .getNewMessagesByChatRoomUuidRemote(
            room, msgList.lastOrNull?.createTime);

    ChatRoomRepository().addMessageLocal(room, messageListRemote);
    messageList.value = [...msgList, ...messageListRemote];

    update();
  }

  void upsertRemoteMessages(ChatRoom room) async {
    final lastMsgTime = messageList.lastOrNull?.createTime;
    final newMessages = await ChatRoomRepository()
        .getNewMessagesByChatRoomUuidRemote(room, lastMsgTime);
    for (var item in newMessages) {
      if (lastMsgTime == null ||
          lastMsgTime.microsecondsSinceEpoch <
              item.createTime.microsecondsSinceEpoch) {
        messageList.add(item);
      }
    }
    if (newMessages.isNotEmpty) {
      update();
    }
    ChatRoomRepository().addMessageLocal(room, newMessages);
  }

  void addMessage(ChatRoom room, Message input, String ai_question) async {
    // Add user input to message list
    await ChatRoomRepository().addMessage(room, [input]);

    final chatRoomUuid = room.uuid;

    final messages = await ChatRoomRepository().getMessagesByChatRoomUUid(room);
    if (!input.ask_ai) {
      messageList.value = messages;
      return;
    }
    Get.find<TagCollector>().accept(input.message);

    // If this message is a question for AI, then send request to AI service.
    final completer = Completer();

    // wait for all the state emit
    try {
      MessageRepository().postMessage(
          chatRoomUuid, //
          input.userName,
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
        ChatRoomRepository().addMessage(room, [res]);
        final messages =
            await ChatRoomRepository().getMessagesByChatRoomUUid(room);
        messageList.value = messages;
        completer.complete();
      });
    } catch (e) {
      messageList.value = [
        ...messages,
        Message(
            uuid: uuid.v1(),
            message: e.toString(),
            userName: input.userName,
            createTime: DateTime.now(),
            source: MessageSource.bot)
      ];
      completer.complete();
    }
    await completer.future;
    update();
  }
}
