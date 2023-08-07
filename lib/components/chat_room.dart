import 'dart:math';

import 'package:dual_screen/dual_screen.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Moyubie/components/chat.dart';
import 'package:Moyubie/controller/message.dart';
import 'package:Moyubie/data/color.dart';
import 'package:Moyubie/repository/chat_room.dart' as repo;
import 'package:Moyubie/controller/chat_room.dart' as comp;
import 'package:uuid/uuid.dart';
import 'package:Moyubie/firebase_hack.dart';
import 'package:flutter/services.dart';

import '../controller/settings.dart';
import '../data/tips.dart';
import '../repository/chat_room.dart';

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<comp.ChatRoomController>(builder: (controller) {
      final selectedIndex = controller.currentRoomIndex.value.value;
      var panePriority = TwoPanePriority.both;
      if (widget.type == ChatRoomType.phone) {
        panePriority =
            selectedIndex == -1 ? TwoPanePriority.start : TwoPanePriority.end;
      }
      return TwoPane(
        paneProportion: 0.3,
        panePriority: panePriority,
        startPane: ListPane(
          selectedIndex: selectedIndex,
          onSelect: _selectRoom,
          type: widget.type,
        ),
        endPane: DetailsPane(
          selectedIndex: selectedIndex,
          onClose: selectedIndex == -1 ? null : () => _selectRoom(-1),
          type: widget.type,
        ),
      );
    });
  }

  void _selectRoom(int index) {
    final comp.ChatRoomController chatRoomController = Get.find();
    chatRoomController.setCurrentRoom(index);
    if (index >= 0) {
      final room = chatRoomController.getCurrentRoom();
      chatRoomController.currentChatRoomUuid(room!.uuid);
      MessageController controllerMessage = Get.find();
      controllerMessage.loadAllMessages(room);
    }
  }
}

class ListPane extends StatelessWidget {
  final ValueChanged<int> onSelect;
  final int selectedIndex;
  final _scrollController = ScrollController();
  Rx<PersistentBottomSheetController?> pctl = Rx(null);
  final ChatRoomType type;

  ListPane({
    super.key,
    required this.onSelect,
    required this.selectedIndex,
    required this.type,
  });

  Widget wrapSaveArea(Scaffold scaffold) {
    if (type != ChatRoomType.tablet) {
      return SafeArea(
        child: scaffold,
      );
    }
    return scaffold;
  }

  @override
  Widget build(BuildContext context) {
    return wrapSaveArea(
      Scaffold(
        appBar: type == ChatRoomType.tablet
            ? null
            : AppBar(
                systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarBrightness: Theme.of(context).brightness),
                backgroundColor: Theme.of(context).colorScheme.background,
                toolbarHeight: 0,
              ),
        primary: false,
        floatingActionButton: type == ChatRoomType.tablet
            ? null
            : Obx(() => NewChatButton(
                  pctl: pctl,
                )),
        body: GetX<comp.ChatRoomController>(builder: (roomCtrl) {
          return EasyRefresh(
            refreshOnStart: true,
            onRefresh: () => roomCtrl.loadChatRooms(),
            child: ListView(
              restorationId: 'chat_room_list_view',
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: roomCtrl.roomList
                  .asMap()
                  .map((index, room) {
                    fmt(Message m) {
                      final pfx = m.source == MessageSource.bot
                          ? "bot#${m.userName}"
                          : m.source == MessageSource.user
                              ? m.userName
                              : "<SYS>";
                      return "$pfx: ${m.message}";
                    }

                    final colorSeed = room.createTime.millisecondsSinceEpoch;
                    final avatarColor = getColor(colorSeed);
                    return MapEntry(
                        index,
                        ListTile(
                          isThreeLine: false,
                          subtitle: room.firstMessage != null
                              ? Text(
                                  fmt(room.firstMessage!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () {
                            onSelect(index);
                          },
                          selected: selectedIndex == index,
                          leading: ExcludeSemantics(
                            child: CircleAvatar(
                                backgroundColor: avatarColor,
                                foregroundColor: Colors.white,
                                child: Text(room.name[0])),
                          ),
                          title: Text(
                            room.name,
                            style: const TextStyle(
                              // fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ));
                  })
                  .values
                  .toList(),
            ),
          );
        }),
      ),
    );
  }
}

class DetailsPane extends StatelessWidget {
  final VoidCallback? onClose;
  final int selectedIndex;
  final ChatRoomType type;

  const DetailsPane({
    super.key,
    required this.selectedIndex,
    this.onClose,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final String tip = tips[Random().nextInt(tips.length)];
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: type == ChatRoomType.tablet
            ? null
            : AppBar(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                toolbarHeight: 40,
                automaticallyImplyLeading: false,
                leading: onClose == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close), onPressed: onClose),
                title: GetX<comp.ChatRoomController>(builder: (controller) {
                  return Text(
                    _currentRoomName(controller),
                  );
                }),
                actions: [
                  if (selectedIndex != -1)
                    ChatDetailButton(
                      type: type,
                      selectedIndex: selectedIndex,
                    )
                ],
              ),
        body: selectedIndex == -1
            ? Center(
                child: Text(
                  "Moyu tips: $tip",
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
              )
            : const ChatWindow(),
      ),
    );
  }

  String _currentRoomName(comp.ChatRoomController controller) {
    var idx = controller.currentRoomIndex.value.value;
    if (idx == -1) {
      return "";
    }
    return controller.roomList[idx].name;
  }
}

class _ChatRoomActions extends StatelessWidget {
  const _ChatRoomActions();

  final uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Column(children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text("New Chat Room"),
          onTap: () {
            _addNewChatRoom();
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.group_add),
          title: const Text("Join Chat Room"),
          onTap: () {
            _joinChatRoom(context);
          },
        ),
      ]),
    );
  }

  static _addNewChatRoom() async {
    final comp.ChatRoomController chatRoomController = Get.find();
    final SettingsController settingsController = Get.find();
    final createTime = DateTime.now().toUtc();
    repo.ChatRoom chatRoom = repo.ChatRoom(
      uuid: const Uuid().v1(),
      name: "New Chat Room",
      createTime: createTime,
      connectionToken: repo.ChatRoomRepository.myTiDBConn.toToken(),
      role: repo.Role.host,
    );
    chatRoomController.addChatRoom(chatRoom);
    FirebaseAnalytics.instance.logEvent(name: "chat_room_add");

    final MessageController messageController = Get.find();
    messageController.messageList.value = [];
  }

  static _joinChatRoom(BuildContext context) {
    final theme = Theme.of(context);
    final dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          var connToken = "";
          return AlertDialog(
            content: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the connection token';
                }
                return null;
              },
              style: dialogTextStyle,
              decoration: InputDecoration(
                labelText: "Connection Token",
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                filled: true,
              ),
              autovalidateMode: AutovalidateMode.always,
              onChanged: (value) {
                connToken = value;
              },
            ),
            actions: [
              _DialogButton(
                text: "Join",
                onPressed: () => _handleConnToken(context, connToken),
              ),
              _DialogButton(
                text: "Cancel",
                onPressed: () {},
              ),
            ],
          );
        });
  }

  static _handleConnToken(BuildContext context, String token) {
    final comp.ChatRoomController chatRoomController = Get.find();
    chatRoomController.joinChatRoom(context, token);
  }
}

class NewChatButton extends StatelessWidget {
  Rx<PersistentBottomSheetController?> pctl;
  bool _opened;

  NewChatButton({super.key, required this.pctl}) : _opened = pctl.value != null;

  @override
  Widget build(BuildContext context) {
    final ctl = Scaffold.of(context);
    return FloatingActionButton(
      backgroundColor: Theme.of(context).primaryColor,
      onPressed: _opened
          ? () {
              pctl.value!.close();
            }
          : () {
              pctl.value =
                  ctl.showBottomSheet((context) => const _ChatRoomActions());
              pctl.value!.closed.then((value) => pctl.value = null);
            },
      child: _opened ? const Icon(Icons.close) : const Icon(Icons.add),
    );
  }
}

class ChatDetailButton extends StatefulWidget {
  const ChatDetailButton(
      {super.key, required this.type, required this.selectedIndex});
  final ChatRoomType type;
  final int selectedIndex;

  @override
  State<ChatDetailButton> createState() => _ChatDetailButtonState();
}

class _ChatDetailButtonState extends State<ChatDetailButton>
    with RestorationMixin {
  late RestorableRouteFuture<String> _alertCreateDialogRoute;
  late RestorableRouteFuture<String> _alertJoinDialogRoute;
  late RestorableRouteFuture<String> _alertDismissDialogRoute;
  late RestorableRouteFuture<String> _alertRenameDialogRoute;
  late RestorableRouteFuture<String> _alertShareDialogRoute;

  @override
  String get restorationId => 'confirm_dialog';

  @override
  void initState() {
    super.initState();
    _alertCreateDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertCreateRoute);
      },
    );
    _alertJoinDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertJoinRoute);
      },
    );
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
    _alertShareDialogRoute = RestorableRouteFuture<String>(
      onPresent: (navigator, arguments) {
        return navigator.restorablePush(_alertShareRoute);
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(
      _alertCreateDialogRoute,
      'alert_create_dialog_route',
    );
    registerForRestoration(
      _alertJoinDialogRoute,
      'alert_join_dialog_route',
    );
    registerForRestoration(
      _alertDismissDialogRoute,
      'alert_dismiss_dialog_route',
    );
    registerForRestoration(
      _alertRenameDialogRoute,
      'alert_rename_dialog_route',
    );
    registerForRestoration(
      _alertShareDialogRoute,
      'alert_share_dialog_route',
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAddJoin =
        widget.type == ChatRoomType.tablet;
    final showRoomActions = widget.selectedIndex != -1;
    List<PopupMenuEntry<Text>> popMenuItems = [];
    if (showAddJoin) {
      popMenuItems = [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.add),
            title: const Align(
              alignment: Alignment(-1.2, 0),
              child: Text("Create Room"),
            ),
            onTap: () {
              Navigator.pop(context);
              _alertCreateDialogRoute.present();
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.group_add),
            title: const Align(
              alignment: Alignment(-1.2, 0),
              child: Text("Join Room"),
            ),
            onTap: () {
              Navigator.pop(context);
              _alertJoinDialogRoute.present();
            },
          ),
        ),
      ];
    }
    if (showRoomActions) {
      popMenuItems.addAll([
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
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.share),
            title: const Align(
              alignment: Alignment(-1.2, 0),
              child: Text("Share Room"),
            ),
            onTap: () async {
              Navigator.pop(context);
              _alertShareDialogRoute.present();
            },
          ),
        ),
      ]);
    }

    return PopupMenuButton<Text>(
      padding: const EdgeInsets.only(right: 32),
      icon: const Icon(Icons.more_horiz),
      itemBuilder: (context) {
        return popMenuItems;
      },
    );
  }

  static _addNewChatRoom(BuildContext context, String roomName) async {
    if (roomName.isEmpty) {
      _showInSnackBar(context, "Room name cannot be empty");
      return;
    }
    final comp.ChatRoomController chatRoomController = Get.find();
    final createTime = DateTime.now().toUtc();
    repo.ChatRoom chatRoom = repo.ChatRoom(
      uuid: const Uuid().v1(),
      name: roomName,
      createTime: createTime,
      connectionToken: repo.ChatRoomRepository.myTiDBConn.toToken(),
      role: repo.Role.host,
    );
    chatRoomController.addChatRoom(chatRoom);
    FirebaseAnalytics.instance.logEvent(name: "chat_room_add");

    final MessageController messageController = Get.find();
    messageController.messageList.value = [];
  }

  static _joinChatRoom(BuildContext context, String token) {
    final comp.ChatRoomController chatRoomController = Get.find();
    chatRoomController.joinChatRoom(context, token);
  }

  static _deleteChatRoom() {
    final comp.ChatRoomController chatRoomController = Get.find();
    final MessageController messageController = Get.find();
    messageController.messageList.value = [];
    final room = chatRoomController.getCurrentRoom();
    if (room == null) {
      return;
    }
    chatRoomController
        .deleteChatRoom(room)
        .then((value) => chatRoomController.setCurrentRoom(-1));
    FirebaseAnalytics.instance.logEvent(name: "chat_room_delete");
  }

  static _renameChatRoom(String newName) {
    if (newName.isEmpty) {
      return;
    }
    final comp.ChatRoomController chatRoomController = Get.find();
    chatRoomController.renameChatRoom(newName);
    FirebaseAnalytics.instance.logEvent(name: "chat_room_rename");
  }

  static String _getCurrentRoomConnectionToken() {
    final comp.ChatRoomController chatRoomController = Get.find();
    final room = chatRoomController.getCurrentRoom();
    final token = room!.getCurrentConnectToken();
    return token;
  }

  static void _showInSnackBar(BuildContext context, String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value,
        ),
      ),
    );
  }

  static Route<String> _alertCreateRoute(
    BuildContext buildCtx,
    Object? arguments,
  ) {
    final theme = Theme.of(buildCtx);
    final dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);
    final editCtrl = TextEditingController();
    editCtrl.text = "New Chat Room";
    editCtrl.selection =
        TextSelection(baseOffset: 0, extentOffset: editCtrl.text.length);
    var roomName = editCtrl.text;

    return DialogRoute<String>(
      context: buildCtx,
      builder: (context) {
        return AlertDialog(
          content: TextFormField(
            controller: editCtrl,
            style: dialogTextStyle,
            decoration: InputDecoration(
              labelText: "Chat Room Name",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              filled: true,
            ),
            maxLines: 1,
            onChanged: (value) {
              roomName = value;
            },
          ),
          actions: [
            _DialogButton(
              text: "Create",
              onPressed: () => _addNewChatRoom(context, roomName),
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

  static Route<String> _alertJoinRoute(
    BuildContext buildCtx,
    Object? arguments,
  ) {
    final theme = Theme.of(buildCtx);
    final dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);
    var connToken = "";

    return DialogRoute<String>(
      context: buildCtx,
      builder: (context) {
        return AlertDialog(
          content: TextFormField(
            style: dialogTextStyle,
            decoration: InputDecoration(
              labelText: "Connection Token",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              filled: true,
            ),
            maxLines: 1,
            onChanged: (value) {
              connToken = value;
            },
          ),
          actions: [
            _DialogButton(
              text: "Join",
              onPressed: () => _joinChatRoom(context, connToken),
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

  static Route<String> _alertDismissRoute(
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
          actions: const [
            _DialogButton(
              text: "Dismiss",
              onPressed: _deleteChatRoom,
            ),
            _DialogButton(
              text: "Cancel",
            ),
          ],
        );
      },
    );
  }

  static Route<String> _alertRenameRoute(
    BuildContext buildCtx,
    Object? arguments,
  ) {
    final theme = Theme.of(buildCtx);
    final dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);
    final comp.ChatRoomController chatRoomController = Get.find();
    final initVal = chatRoomController.getCurrentRoom()?.name;
    var newName = initVal?? "";

    return DialogRoute<String>(
      context: buildCtx,
      builder: (context) {
        return AlertDialog(
          content: TextFormField(
            initialValue: newName,
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

  static Route<String> _alertShareRoute(
    BuildContext buildCtx,
    Object? arguments,
  ) {
    final theme = Theme.of(buildCtx);
    final dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);

    return DialogRoute<String>(
      context: buildCtx,
      builder: (context) {
        final connToken = _getCurrentRoomConnectionToken();
        return AlertDialog(
          content: Text(
            connToken,
            style: dialogTextStyle,
          ),
          actions: [
            _DialogButton(
              text: "Copy!",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: connToken));
                _showInSnackBar(buildCtx, "Copied to clipboard!");
              },
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
        Navigator.pop(context);
      },
      child: Text(text),
    );
  }
}
