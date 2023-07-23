import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyubie/components/markdown.dart';
import 'package:moyubie/components/prompts.dart';
import 'package:moyubie/controller/chat_room.dart';
import 'package:moyubie/controller/message.dart';
import 'package:moyubie/controller/prompt.dart';
import 'package:moyubie/controller/chat_room.dart' as comp;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

import '../repository/chat_room.dart';

var uuid = const Uuid();

class ChatWindow extends StatefulWidget {
  const ChatWindow({super.key});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return GetX<comp.ChatRoomController>(builder: (controller) {
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
                          hintText:
                              "Send to ".tr + _currentRoomName(controller),
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
                          FocusManager.instance.primaryFocus?.unfocus();
                          _sendMessage();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 250, 94, 83),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      );
    });
  }

  String _currentRoomName(comp.ChatRoomController controller) {
    var idx = controller.currentRoomIndex.value.value;
    if (idx == -1) {
      return "";
    }
    return controller.roomList[idx].name;
  }

  void _sendMessage() {
    var message = _controller.text;
    if (message.isEmpty) {
      return;
    }
    final MessageController messageController = Get.find();
    final ChatRoomController chatRoomController = Get.find();
    var chatRoomUuid = chatRoomController.currentChatRoomUuid.value;
    var first_letters =
    message.substring(0, min(3, message.length)).toLowerCase();
    var ask_ai = first_letters == "@ai";
    String ai_question = "";
    if (ask_ai) {
      ai_question = message.substring(3).trimLeft();
    }
    final newMessage = Message(
      uuid: uuid.v4(),
      userName: 'User',
      createTime: DateTime.now(),
      message: message,
      source: MessageSource.user,
      ask_ai: ask_ai,
    );
    messageController.addMessage(chatRoomUuid, newMessage, ai_question);
    _formKey.currentState!.reset();
  }

  Widget _buildMessageCard(Message message) {
    IconData icon = FontAwesomeIcons.question;
    String name = "?";
    Color? color;
    Widget? text_box;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (message.source) {
      case MessageSource.user:
        icon = FontAwesomeIcons.fish;
        name = "User";
        color = Color.fromARGB(255, 156, 225, 111);
        text_box = Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(
            message.message,
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        );
        break;
      case MessageSource.bot:
        icon = FontAwesomeIcons.robot;
        name = "bot";
        color = isDark
            ? Color.fromARGB(255, 92, 89, 89)
            : Color.fromARGB(255, 255, 255, 255);
        text_box = Markdown(text: message.message);
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
