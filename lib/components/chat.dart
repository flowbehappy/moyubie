import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyubie/components/markdown.dart';
import 'package:moyubie/components/prompts.dart';
import 'package:moyubie/controller/conversation.dart';
import 'package:moyubie/controller/message.dart';
import 'package:moyubie/controller/prompt.dart';
import 'package:moyubie/repository/conversation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class ChatWindow extends StatefulWidget {
  const ChatWindow({super.key});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // 定义一个 GlobalKey
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: GetX<MessageController>(
              builder: (controller) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToNewMessage();
                });
                if (controller.messageList.isNotEmpty) {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: controller.messageList.length,
                    itemBuilder: (context, index) {
                      return _buildMessageCard(controller.messageList[index]);
                    },
                  );
                } else {
                  return GetX<PromptController>(builder: ((controller) {
                    if (controller.prompts.isEmpty) {
                      return const Center(
                        child: Center(child: Text("正在加载prompts...")),
                      );
                    } else if (controller.prompts.isNotEmpty) {
                      return PromptsView(controller.prompts, (value) {
                        _controller.text = value;
                      });
                    } else {
                      return const Center(child: Text("加载prompts列表失败，请检查网络"));
                    }
                  }));
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey, // 将 GlobalKey 赋值给 Form 组件的 key 属性
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: _handleKeyEvent,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: const TextStyle(fontSize: 13),
                      controller: _controller,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: "inputPrompt".tr,
                        hintText: "inputPromptTips".tr,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        _sendMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Conversation _newConversation(String name, String description) {
    var conversation = Conversation(
      name: name,
      description: description,
      uuid: uuid.v4(),
    );
    return conversation;
  }

  void _sendMessage() {
    final message = _controller.text;
    final MessageController messageController = Get.find();
    final ConversationController conversationController = Get.find();
    if (message.isNotEmpty) {
      var conversationUuid =
          conversationController.currentConversationUuid.value;
      if (conversationUuid.isEmpty) {
        // new conversation
        //message 的前10个字符，如果message不够10个字符，则全部
        var conversation = _newConversation(
            message.substring(0, message.length > 20 ? 20 : message.length),
            message);
        conversationUuid = conversation.uuid;
        conversationController.setCurrentConversationUuid(conversationUuid);
        conversationController.addConversation(conversation);
      }
      final newMessage = Message(
        conversationId: conversationUuid,
        role: Role.user,
        text: message,
      );
      messageController.addMessage(newMessage);
      _formKey.currentState!.reset();
    }
  }

  Widget _buildMessageCard(Message message) {
    IconData icon = FontAwesomeIcons.question;
    String name = "?";
    Color? color;
    Widget? text_box;
    switch (message.role) {
      case Role.user:
        icon = FontAwesomeIcons.fish;
        name = "User";
        color = Colors.blue[100];
        text_box = Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(
            message.text,
          ),
        );
        break;
      case Role.assistant:
      case Role.system:
        icon = FontAwesomeIcons.robot;
        name = message.role == Role.assistant ? "assistant" : "assistant";
        text_box = Markdown(text: message.text);
        break;
      default:
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              width: 10,
            ),
            FaIcon(icon),
            const SizedBox(
              width: 5,
            ),
            Text(name),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                color: color,
                margin: const EdgeInsets.all(8),
                child: text_box,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleKeyEvent(RawKeyEvent value) {
    if ((value.isKeyPressed(LogicalKeyboardKey.enter) &&
            value.isControlPressed) ||
        (value.isKeyPressed(LogicalKeyboardKey.enter) && value.isMetaPressed)) {
      _sendMessage();
    }
  }

  void _scrollToNewMessage() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }
}
