import 'package:flutter/foundation.dart';
import 'package:moyubie/data/llm.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../repository/chat_room.dart';

class ChatGlM extends LLM {
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
    // var messageToBeSend = messages.removeLast();
    // var prompt = messageToBeSend.message;
    // var history = messages.length >= 2 ? collectHistory(messages) : [];
    // var body = {'query': prompt, 'history': history.isEmpty ? [] : history};
    // var glmBaseUrl = GetStorage().read("glmBaseUrl") ?? "";
    // if (glmBaseUrl.isEmpty) {
    //   errorCallback(Message(
    //     uuid: uuid.v4(),
    //     userName: userName,
    //     createTime: DateTime.now(),
    //     message: "glm baseUrl is empty,please set you glmBaseUrl first",
    //     source: MessageSource.bot,
    //   ));
    //   return;
    // }
    // final request = http.Request("POST", Uri.parse(glmBaseUrl));
    // request.headers.addAll({'Content-Type': 'application/json'});
    // final requestBody = json.encode(body);
    // request.body = requestBody;
    // try {
    //   final response = await request.send();
    //   /**  chunk like this
    //  *  event: delta
    //  *   data: {"delta": "j", "response": "j", "finished": false}
    //  */
    //   await for (final chunk in response.stream.transform(utf8.decoder)) {
    //     String data = chunk.split('\n').firstWhere(
    //         (element) => element.startsWith("data:"),
    //         orElse: () => 'No matching data');
    //     if (!data.startsWith("data:")) {
    //       continue;
    //     }
    //     final jsonData = jsonDecode(data.split("data:")[1].trim());
    //     if (jsonData["finished"]) {
    //       onSuccess(Message(
    //           uuid: uuid.v4(),
    //           userName: userName,
    //           createTime: DateTime.now(),
    //           message: jsonData["response"],
    //           source: MessageSource.bot));
    //     } else {
    //       onResponse(Message(
    //           uuid: uuid.v4(),
    //           userName: userName,
    //           createTime: DateTime.now(),
    //           message: jsonData["response"],
    //           source: MessageSource.bot));
    //     }
    //   }
    // } catch (e) {
    //   errorCallback(Message(
    //     uuid: uuid.v4(),
    //     userName: userName,
    //     createTime: DateTime.now(),
    //     message: e.toString(),
    //     source: MessageSource.bot,
    //   ));
    // }
  }
}

List<List<String>> collectHistory(List<Message> list) {
  List<List<String>> result = [];
  for (int i = list.length - 1; i >= 0; i -= 2) {
    //只添加最近的会话
    if (i - 1 > 0) {
      result.insert(0, [list[i - 1].message, list[i].message]);
    }
    if (result.length > 3) {
      //放太多轮次也没啥意思
      break;
    }
  }
  return result;
}
