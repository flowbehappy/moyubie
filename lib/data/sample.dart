import 'package:uuid/uuid.dart';

import '../repository/chat_room.dart';

var uuid = const Uuid();

List<Message> sampleMessages(String nickname)  {
  final messages = List<String>.from([
    "Hi, $nickname! Welcome to this chat room!",
    "You can create your own chat room, and invite others to join.",
    "Have fun!",
  ]);

  return messages.map((e) => Message(
    uuid: uuid.v1(),
    userName: 'User',
    createTime: DateTime.now().toUtc(),
    message: e,
    source: MessageSource.sys,
    ask_ai: false,
  )).toList();
}