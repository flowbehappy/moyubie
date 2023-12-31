import 'package:Moyubie/data/color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:Moyubie/components/news.dart';
import 'package:Moyubie/controller/message.dart';
import 'package:Moyubie/controller/prompt.dart';
import 'package:Moyubie/controller/settings.dart';
import 'package:Moyubie/components/setting.dart';
import 'package:Moyubie/repository/tags.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Moyubie/utils/tag_collector.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:path/path.dart';
import 'firebase_options.dart';

import 'components/chat_room.dart';
import 'controller/chat_room.dart';

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && !Platform.isWindows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (kIsWeb) {
    // Change default factory on the web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // String path = join(await getDatabasesPath(), 'moyubie.db');
  // await deleteDatabase(path);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static bool prefetched = false;

  Widget menu(BuildContext context, ChatRoomType type) {
    return GetX<ChatRoomController>(builder: (controller) {
      if (controller.currentRoomIndex.value.value >= 0 &&
          type == ChatRoomType.phone) {
        return const SizedBox();
      }
      return Container(
        color: Theme.of(context).primaryColor,
        child: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(5.0),
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(
              text: "Chat",
              icon: Icon(Icons.chat),
            ),
            Tab(
              text: "News",
              icon: Icon(Icons.newspaper),
            ),
            Tab(
              text: "Settings",
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    final ChatRoomType type =
        shortestSide < 600 ? ChatRoomType.phone : ChatRoomType.tablet;
    final settingsCtl = SettingsController();
    final tagsRepo = TagsRepository();
    Get.put(settingsCtl);
    Get.put(MessageController());
    Get.put(PromptController());
    Get.put(ChatRoomController());
    Get.put(tagsRepo);
    Get.put(NewsController(
        settingsCtl.openAiKey, settingsCtl.gptModel, !prefetched));
    Get.put(TagCollector.create(repo: tagsRepo, sctl: settingsCtl));
    prefetched = true;
    final newsWinKey = GlobalKey();
    return MaterialApp(
      theme: FlexThemeData.light(
        colors: moyubieSchemeData.light,
        scheme: FlexScheme.ebonyClay,
      ),
      darkTheme: FlexThemeData.dark(
        colors: moyubieSchemeData.dark,
        scheme: FlexScheme.ebonyClay,
      ),
      themeMode: ThemeMode.system,
      // locale: const Locale('zh'),
      // translations: MyTranslations(),
      builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Builder(builder: (context) {
          return Scaffold(
            appBar: type == ChatRoomType.phone ? null : AppBar(
              title: const Text("Moyubie"),
              actions: [
                GetX<ChatRoomController>(builder: (controller) {
                  return ChatDetailButton(type: type,
                      selectedIndex: controller.currentRoomIndex.value.value);
                }),
              ],
            ),
            bottomNavigationBar: menu(context, type),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ChatRoom(restorationId: "chat_room", type: type),
                NewsWindow(
                  ty: type,
                  key: newsWinKey,
                ),
                const SettingPage(),
              ],
            ),
          );
        }),
      ),
    );
  }
}
