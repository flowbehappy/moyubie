import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:moyubie/components/chat.dart';
import 'package:moyubie/repository/chat_room.dart' as repo;
import 'package:moyubie/controller/chat_room.dart' as comp;
import 'package:uuid/uuid.dart';

enum ChatRoomType {
  tablet,
  phone,
}

class ChatRoom extends StatefulWidget {
  const ChatRoom({
    super.key,
    required this.restorationId,
    required this.type,
  });

  final String restorationId;
  final ChatRoomType type;

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  @override
  Widget build(BuildContext context) {
    return GetX<comp.ChatRoomController>(builder: (controller) {
      var panePriority = TwoPanePriority.both;
      if (widget.type == ChatRoomType.phone) {
        panePriority = controller.currentRoomIndex.value.value == -1
            ? TwoPanePriority.start
            : TwoPanePriority.end;
      }
      return TwoPane(
        paneProportion: 0.3,
        panePriority: panePriority,
        startPane: ListPane(
          selectedIndex: controller.currentRoomIndex.value.value,
          onSelect: _selectRoom,
        ),
        endPane: DetailsPane(
          selectedIndex: controller.currentRoomIndex.value.value,
          onClose: widget.type == ChatRoomType.phone
              ? () {
                  _selectRoom(-1);
                }
              : null,
        ),
      );
    });
  }

  void _selectRoom(int index) {
    final comp.ChatRoomController chatRoomController = Get.find();
    chatRoomController.setCurrentRoomIndex(index);
  }
}

class ListPane extends StatelessWidget {
  final ValueChanged<int> onSelect;
  final int selectedIndex;
  final _scrollController = ScrollController();

  ListPane({
    super.key,
    required this.onSelect,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GetX<comp.ChatRoomController>(builder: (controller) {
      return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text("Chat Room"),
            actions: const [NewChatButton()]),
        body: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            restorationId: 'list_demo_list_view',
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: controller.roomList
                .asMap()
                .map((index, room) {
                  return MapEntry(
                      index,
                      ListTile(
                        onTap: () {
                          onSelect(index);
                        },
                        selected: selectedIndex == index,
                        leading: ExcludeSemantics(
                          child: CircleAvatar(child: Text('$index')),
                        ),
                        title: Text(
                          'chat room $index',
                        ),
                      ));
                })
                .values
                .toList(),
          ),
        ),
      );
    });
  }
}

class DetailsPane extends StatelessWidget {
  final VoidCallback? onClose;
  final int selectedIndex;

  const DetailsPane({
    super.key,
    required this.selectedIndex,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onClose == null
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        title: Text(
          selectedIndex == -1 ? "" : "Chat Room $selectedIndex",
        ),
      ),
      body: const ChatWindow(),
    );
  }
}

class NewChatButton extends StatelessWidget {
  const NewChatButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Text>(
      padding: const EdgeInsets.only(right: 32),
      icon: const Icon(Icons.add),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Align(
                alignment: Alignment(-1.2, 0),
                child: Text("New Chat Room"),
              ),
              onTap: _addNewChatRoom,
            ),
          ),
          const PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.group_add),
              title: Align(
                alignment: Alignment(-1.2, 0),
                child: Text("Join Chat Room"),
              ),
            ),
          ),
        ];
      },
    );
  }

  _addNewChatRoom() {
    final comp.ChatRoomController chatRoomController = Get.find();
    const uuid = Uuid();
    var createTime = DateTime.now();
    repo.ChatRoom chatRoom = repo.ChatRoom(
        uuid: uuid.v4(),
        name: "New Chat Room",
        createTime: createTime,
        connectionToken: "");
    chatRoomController.addChatRoom(chatRoom);
  }
}
