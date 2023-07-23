import 'package:flutter/foundation.dart';
import 'package:moyubie/data/llm.dart';
import 'package:uuid/uuid.dart';

import '../repository/chat_room.dart';

class EchoGPT extends LLM {
  final uuid = const Uuid();

  @override
  getResponse(
      String chatRoomUuid,
      String userName,
      String question,
      AIConversationContext convContext,
      ValueChanged<Message> onResponse,
      ValueChanged<Message> errorCallback,
      ValueChanged<Message> onSuccess) async {
    var message = question;
    message = message.replaceAll('？', "！");
    message = message.replaceAll('吗', "");
    message = message.replaceAll('?', "!");
    onSuccess(Message(
        uuid: uuid.v1(),
        message: message,
        userName: userName,
        createTime: DateTime.now(),
        source: MessageSource.bot));
  }
}
