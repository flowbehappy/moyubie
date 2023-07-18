import 'package:flutter/foundation.dart';
import 'package:moyubie/data/llm.dart';
import 'package:moyubie/repository/conversation.dart';

class ChatIF extends LLM {
  @override
  getResponse(
      List<Message> messages,
      ValueChanged<Message> onResponse,
      ValueChanged<Message> errorCallback,
      ValueChanged<Message> onSuccess) async {
    // TODO: implement getResponse
    throw UnimplementedError();
  }
}
