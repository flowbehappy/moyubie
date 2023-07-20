import 'package:get_storage/get_storage.dart';
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

  void setCurrentChatRoomUuid(String uuid) async {
    currentChatRoomUuid.value = uuid;
    update();
  }

  void setCurrentRoomIndex(int index) async {
    currentRoomIndex.value = IntegerWrapper(index);
    update();
  }

  void deleteChatRoom(int index) async {
    ChatRoom chatRoom = roomList[index];
    await ChatRoomRepository().deleteChatRoom(chatRoom.uuid);
    roomList.value = await ChatRoomRepository().getChatRooms();
    update();
  }

  void renameChatRoom(ChatRoom chatRoom) async {
    await ChatRoomRepository().updateChatRoom(chatRoom);
    roomList.value = await ChatRoomRepository().getChatRooms();
    update();
  }

  void addChatRoom(ChatRoom chatRoom) async {
    await ChatRoomRepository().addChatRoom(chatRoom);
    roomList.value = await ChatRoomRepository().getChatRooms();
    update();
  }
}

class IntegerWrapper {
  final int _value;
  IntegerWrapper(this._value);
  int get value { return _value; }
}
