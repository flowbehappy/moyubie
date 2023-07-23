import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moyubie/components/chat.dart';
import 'package:moyubie/controller/message.dart';
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
    chatRoomController.setCurrentRoom(index);
    if (index >= 0) {
      String roomUuid = chatRoomController.roomList[index].uuid;
      chatRoomController.currentChatRoomUuid(roomUuid);
      MessageController controllerMessage = Get.find();
      controllerMessage.loadAllMessages(roomUuid);
    }
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
    return GetX<comp.ChatRoomController>(builder: (roomCtrl) {
      return Scaffold(
          appBar: AppBar(
              title: const Text("Chat Room"),
              foregroundColor: Colors.white,
              backgroundColor: Color.fromARGB(255, 70, 70, 70),
              toolbarHeight: 40,
              automaticallyImplyLeading: false,
              actions: const [NewChatButton()]),
          body: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              restorationId: 'chat_room_list_view',
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: roomCtrl.roomList
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
                            child: CircleAvatar(child: Text(room.name[0])),
                          ),
                          title: Text(
                            room.name,
                          ),
                        ));
                  })
                  .values
                  .toList(),
            ),
          ));
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
    return GetX<comp.ChatRoomController>(builder: (controller) {
      return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 70, 70, 70),
          toolbarHeight: 40,
          automaticallyImplyLeading: false,
          leading: onClose == null
              ? null
              : IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          title: Text(
            _currentRoomName(controller),
          ),
          actions: const [ChatDetailButton()],
        ),
        body: const ChatWindow(),
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
              onTap: () {
                _addNewChatRoom(context);
              },
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

  _addNewChatRoom(BuildContext context) {
    final comp.ChatRoomController chatRoomController = Get.find();
    const uuid = Uuid();
    var createTime = DateTime.now();
    repo.ChatRoom chatRoom = repo.ChatRoom(
        uuid: uuid.v4(),
        name: "New Chat Room",
        createTime: createTime,
        connectionToken: "");
    chatRoomController.addChatRoom(chatRoom);
    final MessageController messageController = Get.find();
    messageController.messageList.value = [];
    Navigator.pop(context);
  }
}

class ChatDetailButton extends StatefulWidget {
  const ChatDetailButton({super.key});

  @override
  State<ChatDetailButton> createState() => _ChatDetailButtonState();
}

class _ChatDetailButtonState extends State<ChatDetailButton>
    with RestorationMixin {
  late RestorableRouteFuture<String> _alertDismissDialogRoute;
  late RestorableRouteFuture<String> _alertRenameDialogRoute;

  @override
  String get restorationId => 'confirm_dialog';

  @override
  void initState() {
    super.initState();
    _alertDismissDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertDismissRoute);
      },
    );
    _alertRenameDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertRenameRoute);
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(
      _alertDismissDialogRoute,
      'alert_dismiss_dialog_route',
    );
    registerForRestoration(
      _alertRenameDialogRoute,
      'alert_rename_dialog_route',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Text>(
      padding: const EdgeInsets.only(right: 32),
      icon: const Icon(Icons.more_horiz),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.delete),
              title: const Align(
                alignment: Alignment(-1.2, 0),
                child: Text("Dismiss Room",
                    style: TextStyle(color: Colors.redAccent)),
              ),
              onTap: () {
                Navigator.pop(context);
                _alertDismissDialogRoute.present();
              },
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Align(
                alignment: Alignment(-1.2, 0),
                child: Text("Rename Room"),
              ),
              onTap: () {
                Navigator.pop(context);
                _alertRenameDialogRoute.present();
              },
            ),
          ),
        ];
      },
    );
  }

  _deleteChatRoom() {
    final comp.ChatRoomController chatRoomController = Get.find();
    final MessageController messageController = Get.find();
    messageController.messageList.value = [];
    chatRoomController.setCurrentRoom(-1);
    chatRoomController.deleteChatRoom();
  }

  _renameChatRoom(String newName) {
    if (newName.isEmpty) {
      return;
    }
    final comp.ChatRoomController chatRoomController = Get.find();
    chatRoomController.renameChatRoom(newName);
  }

  Route<String> _alertDismissRoute(
    BuildContext buildCtx,
    Object? arguments,
  ) {
    final theme = Theme.of(buildCtx);
    final dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);

    return DialogRoute<String>(
      context: buildCtx,
      builder: (context) {
        return AlertDialog(
          content: Text(
            "Do you want to dismiss this chat room?",
            style: dialogTextStyle,
          ),
          actions: [
            _DialogButton(
              text: "Dismiss",
              onPressed: _deleteChatRoom,
            ),
            const _DialogButton(
              text: "Cancel",
            ),
          ],
        );
      },
    );
  }

  Route<String> _alertRenameRoute(
    BuildContext buildCtx,
    Object? arguments,
  ) {
    final theme = Theme.of(buildCtx);
    final dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);
    var newName = "";

    return DialogRoute<String>(
      context: buildCtx,
      builder: (context) {
        return AlertDialog(
          content: TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
            style: dialogTextStyle,
            decoration: InputDecoration(
              labelText: "New Name",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              filled: true,
            ),
            autovalidateMode: AutovalidateMode.always,
            maxLines: 1,
            onChanged: (value) {
              newName = value;
            },
          ),
          actions: [
            _DialogButton(
              text: "Done",
              onPressed: () => _renameChatRoom(newName),
            ),
            _DialogButton(
              text: "Cancel",
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.text, this.onPressed});

  final String text;
  final Function? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        }
        Navigator.of(context).pop(text);
      },
      child: Text(text),
    );
  }
}
