import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyubie/components/markdown.dart';
import 'package:moyubie/controller/chat_room.dart';
import 'package:moyubie/controller/message.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';
import 'package:moyubie/controller/settings.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:math';

import '../data/names.dart';
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
                  return _buildStartRoomButton();
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
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  void _startChat() {
    final MessageController messageController = Get.find();
    final ChatRoomController chatRoomController = Get.find();
    final room = chatRoomController.getCurrentRoom();
    if (room == null) {
      return;
    }
    final name = fromRoomName(room.name);
    final String? explanation = chatRoomNames[name];
    if (explanation != null) {
      final demoMsg = Message(
        uuid: uuid.v1(),
        userName: 'User',
        createTime: DateTime.now().toUtc(),
        message: "$name: $explanation",
        source: MessageSource.sys,
        ask_ai: false,
      );
      messageController.addMessage(room, demoMsg, "");
    }
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
    _formKey.currentState!.reset();
  }

  Widget _buildStartRoomButton() {
    ChatRoomController chatRoomController = Get.find();
    final room = chatRoomController.getCurrentRoom();
    if (room == null) {
      return const SizedBox.shrink();
    }
    if (DateTime.now().toUtc().difference(room.createTime).inMinutes >= 1) {
      return const SizedBox.shrink();
    }
    return Center(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: Colors.red,
          side: const BorderSide(
            color: Colors.red,
          ),
        ),
        onPressed: _startChat,
        child: const Text("Let's chat!"),
      ),
    );
  }

  Widget _buildMessageCard(Message message) {
    IconData icon = FontAwesomeIcons.question;
    String name = "?";
    String timeStr = message.createTime.toLocal().toString().substring(0, 19);
    Color? color;
    Widget? msg_box;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (message.source) {
      case MessageSource.user:
        icon = FontAwesomeIcons.fish;
        name = message.userName;
        SettingsController settingsController = Get.find();
        if (name == settingsController.nickname.value) {
          color = const Color.fromARGB(255, 156, 225, 111);
        } else {
          color = isDark
              ? const Color.fromARGB(255, 92, 89, 89)
              : const Color.fromARGB(255, 255, 255, 255);
        }
        msg_box = Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(
            message.message,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        );
        break;
      case MessageSource.bot:
        icon = FontAwesomeIcons.robot;
        name = "Bot#${message.userName}";
        color = isDark
            ? const Color.fromARGB(255, 92, 89, 89)
            : const Color.fromARGB(255, 255, 255, 255);
        msg_box = Markdown(text: message.message);
        break;
      case MessageSource.sys:
        icon = FontAwesomeIcons.medal;
        name = "Moyubie";
        color = isDark
            ? const Color.fromARGB(255, 92, 89, 89)
            : const Color.fromARGB(255, 255, 255, 255);
        msg_box = Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(
            message.message,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        );
        break;
      default:
    }

    Widget? nameBox = Text(
      name,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    );

    Widget? timeBox = Container(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
      alignment: Alignment.bottomLeft,
      child: Text(
        timeStr,
        style: const TextStyle(
          fontSize: 10,
        ),
      ),
    );

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
            nameBox,
            const SizedBox(
              width: 5,
            ),
            timeBox,
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Card(
                color: color,
                margin: const EdgeInsets.all(8),
                child: msg_box,
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
