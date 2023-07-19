import 'package:moyubie/repository/chat_room.dart';
import 'package:moyubie/repository/conversation.dart';
import 'package:get/get.dart';

class ChatRoomController extends GetxController {
  final roomList = <ChatRoom>[].obs;

  final currentChatRoomUuid = "".obs;

  static ChatRoomController get to => Get.find();
  @override
  void onInit() async {
    roomList.value = await ChatRoomRepository().getChatRooms();
    super.onInit();
  }

  // void setCurrentChatRoomUuid(String uuid) async {
  //   currentChatRoomUuid.value = uuid;
  //   update();
  // }

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
