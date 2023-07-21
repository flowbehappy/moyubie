import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:moyubie/utils/bingSearch.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';

import '../repository/chat_room.dart';

abstract class LLM {
  getResponse(String chatRoomUuid, String userName,
      List<Message> messages, ValueChanged<Message> onResponse,
      ValueChanged<Message> errorCallback, ValueChanged<Message> onSuccess);
}

class ChatGpt extends LLM {
  final uuid = const Uuid();

  @override
  getResponse(
      String chatRoomUuid,
      String userName,
      List<Message> messages,
      ValueChanged<Message> onResponse,
      ValueChanged<Message> errorCallback,
      ValueChanged<Message> onSuccess) async {
    List<OpenAIChatCompletionChoiceMessageModel> openAIMessages = [];
    //将messages反转
    messages = messages.reversed.toList();

    // 将messages里面的每条消息的内容取出来拼接在一起
    String content = "";
    String currentModel = SettingsController.to.gptModel.value;
    int maxTokenLength = 1800;
    switch (currentModel) {
      case "gpt-3.5-turbo":
        maxTokenLength = 1800;
        break;
      case "gpt-3.5-turbo-16k":
        maxTokenLength = 10000;
        break;
      default:
        maxTokenLength = 1800;
        break;
    }
    bool useWebSearch = SettingsController.to.useWebSearch.value;
    if (useWebSearch) {
      messages.first.message = await fetchAndParse(messages.first.message);
    }
    for (Message message in messages) {
      content = content + message.message;
      if (content.length < maxTokenLength || openAIMessages.isEmpty) {
        // 插入到 openAIMessages 第一个位置
        openAIMessages.insert(
          0,
          OpenAIChatCompletionChoiceMessageModel(
            content: message.message,
            role: OpenAIChatMessageRole.user,
          ),
        );
      }
    }
    var message = Message(
        uuid: uuid.v4(),
        message: "",
        userName: userName,
        createTime: DateTime.now(),
        source: MessageSource.bot);
    if (SettingsController.to.useStream.value) {
      Stream<OpenAIStreamChatCompletionModel> chatStream = OpenAI.instance.chat
          .createStream(model: currentModel, messages: openAIMessages);
      chatStream.listen(
        (chatStreamEvent) async {
          if (chatStreamEvent.choices.first.delta.content != null) {
            message.message =
                message.message + chatStreamEvent.choices.first.delta.content!;
            try {
              var hasVibration = await Vibration.hasVibrator();
              if (hasVibration != null && hasVibration) {
                Vibration.vibrate(duration: 50, amplitude: 128);
              }
            } catch (e) {
              // ignore
            }

            onResponse(message);
          }
        },
        onError: (error) {
          message.message = error.message;
          errorCallback(message);
        },
        onDone: () {
          onSuccess(message);
        },
      );
    } else {
      try {
        var response = await OpenAI.instance.chat.create(
          model: currentModel,
          messages: openAIMessages,
        );
        message.message = response.choices.first.message.content;
        onSuccess(message);
      } catch (e) {
        message.message = e.toString();
        errorCallback(message);
      }
    }
  }
}
