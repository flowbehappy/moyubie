import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:uuid/uuid.dart';

import '../repository/chat_room.dart';

abstract class LLM {
  getResponse(
      String chatRoomUuid,
      String userName,
      String question,
      AIConversationContext convContext,
      ValueChanged<Message> onResponse,
      ValueChanged<Message> errorCallback,
      ValueChanged<Message> onSuccess);
}

class ChatGpt extends LLM {
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
    List<OpenAIChatCompletionChoiceMessageModel> openAIMessages = [];

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
      // messages.first.message = await fetchAndParse(messages.first.message);
    }

    openAIMessages.insert(
      0,
      OpenAIChatCompletionChoiceMessageModel(
        content: question,
        role: OpenAIChatMessageRole.user,
      ),
    );
    var message = Message(
        uuid: uuid.v1(),
        message: "",
        userName: userName,
        createTime: DateTime.now().toUtc(),
        source: MessageSource.bot);
    if (SettingsController.to.useStream.value) {
      Stream<OpenAIStreamChatCompletionModel> chatStream = OpenAI.instance.chat
          .createStream(model: currentModel, messages: openAIMessages);
      chatStream.listen(
        (chatStreamEvent) async {
          if (chatStreamEvent.choices.first.delta.content != null) {
            message.message =
                message.message + chatStreamEvent.choices.first.delta.content!;

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
