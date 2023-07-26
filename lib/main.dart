import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:moyubie/components/news.dart';
import 'package:moyubie/controller/message.dart';
import 'package:moyubie/controller/prompt.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:moyubie/components/setting.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moyubie/configs/translations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform;
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'components/chat_room.dart';
import 'controller/chat_room.dart';

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    // Change default factory on the web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  String path = join(await getDatabasesPath(), 'moyubie.db');
  await deleteDatabase(path);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget menu() {
    return GetX<ChatRoomController>(builder: (controller) {
      if (controller.currentRoomIndex.value.value >= 0) {
        return const SizedBox();
      }
      return Container(
        color: const Color.fromARGB(255, 250, 94, 83),
        child: const TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.all(5.0),
          indicatorColor: Color.fromARGB(255, 250, 94, 83),
          tabs: [
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
    final ChatRoomType type = ChatRoomType.phone;
    final settingsCtl = SettingsController();
    Get.put(settingsCtl);
    Get.put(MessageController());
    Get.put(PromptController());
    Get.put(ChatRoomController());
    Get.put(NewsController(settingsCtl.openAiKey, settingsCtl.gptModel));
    final newsWinKey = GlobalKey();
    return MaterialApp(
      theme: FlexThemeData.light(scheme: FlexScheme.ebonyClay),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.ebonyClay),
      themeMode: ThemeMode.system,
      // locale: const Locale('zh'),
      // translations: MyTranslations(),
      builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          bottomNavigationBar: menu(),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ChatRoom(restorationId: "chat_room", type: type),
              NewsWindow(ty: type, key: newsWinKey,),
              const SettingPage(),
            ],
          ),
        ),
      ),
    );
  }
}
