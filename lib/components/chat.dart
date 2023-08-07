import 'package:Moyubie/data/tips.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Moyubie/components/markdown.dart';
import 'package:Moyubie/controller/chat_room.dart';
import 'package:Moyubie/controller/message.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Moyubie/firebase_hack.dart';
import 'package:get/get.dart';
import 'package:Moyubie/controller/settings.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../data/sample.dart';
import '../repository/chat_room.dart';

class ChatWindow extends StatefulWidget {
  const ChatWindow({super.key});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late Timer _timer;
  bool textIsEmpty = true;

  final uuid = const Uuid();

  @override
  void initState() {
    _startPollingRemote();
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GetX<MessageController>(
            builder: (controller) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToNewMessage();
              });
              List<Message> list = controller.messageList;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                controller: _scrollController,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return _buildMessageCard(list[index]);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
          if (!isKeyboardVisible || !textIsEmpty) {
            return const SizedBox.shrink();
          }
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 8),
                child: ActionChip(
                  onPressed: () {
                    _controller.text = "@ai ";
                    _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length));
                    setState(() {
                      textIsEmpty = false;
                    });
                  },
                  label: const Text(
                    "@ai",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Form(
            key: _formKey, // 将 GlobalKey 赋值给 Form 组件的 key 属性
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: _handleKeyEvent,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: const TextStyle(fontSize: 16),
                      controller: _controller,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: "@ai talk to AI",
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
                      onChanged: (value) => setState(() {
                        textIsEmpty = value.isEmpty;
                      }),
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
                        backgroundColor: const Color.fromARGB(255, 250, 94, 83),
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
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  void _sendMessage() {
    var message = _controller.text;
    if (message.isEmpty) {
      return;
    }

    FirebaseAnalytics.instance.logEvent(name: "msg_send");

    final MessageController messageController = Get.find();
    final ChatRoomController chatRoomController = Get.find();
    final nickname = Get.find<SettingsController>().nickname.value;
    final room = chatRoomController.getCurrentRoom();
    if (room == null) {
      return;
    }
    var first_letters =
        message.substring(0, min(3, message.length)).toLowerCase();
    var ask_ai = first_letters == "@ai";
    String ai_question = "";
    if (ask_ai) {
      ai_question = message.substring(3).trimLeft();

      FirebaseAnalytics.instance.logEvent(name: "msg_ask_ai");
    }
    final newMessage = Message(
      uuid: uuid.v1(),
      userName: nickname,
      createTime: DateTime.now().toUtc(),
      message: message,
      source: MessageSource.user,
      ask_ai: ask_ai,
    );
    messageController.addMessage(room, newMessage, ai_question);
    room.firstMessage = newMessage;
    _formKey.currentState!.reset();
    _controller.text = "";
  }

  Widget _buildMessageCard(Message message) {
    IconData icon = FontAwesomeIcons.question;
    String name = "?";
    String timeStr = message.createTime.toLocal().toString().substring(0, 19);
    Color? bgColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherBackgroundColor = isDark
        ? const Color.fromARGB(255, 92, 89, 89)
        : const Color.fromARGB(255, 255, 255, 255);
    final otherFontColor = isDark
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color.fromARGB(255, 0, 0, 0);
    const myBackgroundColor = Color.fromARGB(255, 156, 225, 111);
    const myFontColor = Color.fromARGB(255, 0, 0, 0);
    SettingsController settingsController = Get.find();
    final isMyMessage = message.source ==
        MessageSource.user &&
        message.userName == settingsController.nickname.value;
    bgColor = isMyMessage ? myBackgroundColor : otherBackgroundColor;
    final fontColor = isMyMessage ? myFontColor : otherFontColor;

    switch (message.source) {
      case MessageSource.user:
        icon = FontAwesomeIcons.fish;
        name = message.userName;
        break;
      case MessageSource.bot:
        icon = FontAwesomeIcons.robot;
        name = "Bot#${message.userName}";
        break;
      case MessageSource.sys:
        icon = FontAwesomeIcons.medal;
        name = "Moyubie";
        break;
      default:
    }

    final nameBox = TextSpan(
      text: name,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    );

    final timeBox = TextSpan(
      text: timeStr,
      style: const TextStyle(
        fontSize: 10,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
          child: CircleAvatar(child: FaIcon(icon, size: 16)),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                  TextSpan(children: [nameBox, TextSpan(text: " "), timeBox])),
              Card(
                margin: EdgeInsets.only(top: 4, bottom: 8),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2))),
                color: bgColor,
                child: wrapMarkDown(message.source, message.message, fontColor)
              )
            ],
          ),
        )
      ],
    );
  }

  Widget wrapMarkDown(MessageSource src, String message, Color fontColor) {
    if (src == MessageSource.bot) {
      return Markdown(text: message);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SelectableText(
        message,
        style: TextStyle(
          color: fontColor,
          fontSize: 16,
          textBaseline: TextBaseline.alphabetic,
        ),
      ),
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

  var polling = false;

  void _startPollingRemote() {
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (Timer timer) {
        if (polling) {
          return;
        }
        print("polling remote messages");
        polling = true;
        _loadMessagesRemote();
        polling = false;
      },
    );
  }

  void _loadMessagesRemote() async {
    final ChatRoomController chatRoomController = Get.find();
    final room = chatRoomController.getCurrentRoom();
    if (room == null) {
      return;
    }
    final MessageController messageController = Get.find();
    messageController.upsertRemoteMessages(room);
  }
}
