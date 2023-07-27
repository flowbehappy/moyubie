import 'package:moyubie/repository/chat_room.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChatRoomController extends GetxController {
  final roomList = <ChatRoom>[].obs;

  final currentChatRoomUuid = "".obs;
  final currentRoomIndex = IntegerWrapper(-1).obs;
  final uuid = const Uuid();

  static ChatRoomController get to => Get.find();
  @override
  void onInit() async {
    roomList.value = await ChatRoomRepository().getChatRooms();
    super.onInit();
  }

  ChatRoom getCurrentRoom() {
    return roomList[currentRoomIndex.value.value];
  }

  void setCurrentRoom(int index) async {
    currentRoomIndex.value = IntegerWrapper(index);
    if (index > 0) {
      currentChatRoomUuid.value = roomList[index].uuid;
    }
    update();
  }

  void deleteChatRoom(ChatRoom room) async {
    await ChatRoomRepository().deleteChatRoom(room);
    roomList.value = await ChatRoomRepository().getChatRooms();
    update();
  }

  void renameChatRoom(String newName) async {
    var chatRoom = roomList[currentRoomIndex.value.value];
    chatRoom.name = newName;
    await ChatRoomRepository().updateChatRoom(chatRoom);
    roomList.value = await ChatRoomRepository().getChatRooms();
    update();
  }

  void addChatRoom(ChatRoom chatRoom) async {
    await ChatRoomRepository().addChatRoom(chatRoom);
    roomList.value = await ChatRoomRepository().getChatRooms();
    currentRoomIndex.value = IntegerWrapper(roomList.length - 1);
    currentChatRoomUuid.value = chatRoom.uuid;
    update();
  }

  _popDialog(BuildContext context, String content) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void joinChatRoom(BuildContext context, String connToken) async {
    final (exists, joinRoom) =
        await ChatRoomRepository().joinChatRoom(connToken);
    if (exists) {
      if (context.mounted) {
        _popDialog(context, "Chat room already exists!");
      }
      return;
    }

    if (joinRoom == null) {
      if (context.mounted) {
        _popDialog(context, "Illegal chat room connection token!");
      }
      return;
    }

    var message = Message(
        uuid: uuid.v1(),
        message: "[New user joined!]",
        userName: "New chater",
        createTime: DateTime.now().toUtc(),
        source: MessageSource.user);

    await ChatRoomRepository().addMessage(joinRoom, message);

    roomList.add(joinRoom);
    currentRoomIndex.value = IntegerWrapper(roomList.length - 1);
    currentChatRoomUuid.value = joinRoom.uuid;
    update();
  }

  void loadChatRooms() async {
    var remoteRooms = await ChatRoomRepository().getChatRoomsRemote();
    await ChatRoomRepository().upsertLocalChatRooms(remoteRooms);
    roomList.value = await ChatRoomRepository().getChatRooms();
    update();
  }

  void reset() {
    currentRoomIndex.value = IntegerWrapper(-1);
    currentChatRoomUuid.value = "";
    roomList.clear();
    update();
  }
}

class IntegerWrapper {
  final int _value;
  IntegerWrapper(this._value);
  int get value {
    return _value;
  }
}
