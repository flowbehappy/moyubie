import 'package:moyubie/repository/chat_room.dart';
import 'package:get/get.dart';

class ChatRoomController extends GetxController {
  final roomList = <ChatRoom>[].obs;

  final currentChatRoomUuid = "".obs;
  final currentRoomIndex = IntegerWrapper(-1).obs;

  static ChatRoomController get to => Get.find();
  @override
  void onInit() async {
    roomList.value = await ChatRoomRepository().getChatRooms();
    super.onInit();
  }

  void setCurrentRoom(int index) async {
    currentRoomIndex.value = IntegerWrapper(index);
    if (index > 0) {
      currentChatRoomUuid.value = roomList[index].uuid;
    }
    update();
  }

  void deleteChatRoom() async {
    await ChatRoomRepository().deleteChatRoom(currentChatRoomUuid.value);
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
}

class IntegerWrapper {
  final int _value;
  IntegerWrapper(this._value);
  int get value { return _value; }
}
