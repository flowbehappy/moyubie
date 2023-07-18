import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:moyubie/controller/conversation.dart';
import 'package:moyubie/controller/message.dart';
import 'package:moyubie/controller/prompt.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:moyubie/components/chat.dart';
import 'package:moyubie/components/setting.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:moyubie/pages/unknown.dart';
import 'package:moyubie/route.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moyubie/configs/translations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Change default factory on the web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   Get.put(SettingsController());
  //   Get.put(ConversationController());
  //   Get.put(MessageController());
  //   Get.put(PromptController());
  //   return GetMaterialApp(
  //     initialRoute: '/',
  //     getPages: routes,
  //     unknownRoute:
  //         GetPage(name: '/not_found', page: () => const UnknownRoutePage()),
  //     theme: FlexThemeData.light(scheme: FlexScheme.ebonyClay),
  //     darkTheme: FlexThemeData.dark(scheme: FlexScheme.ebonyClay),
  //     themeMode: ThemeMode.system,
  //     locale: const Locale('zh'),
  //     translations: MyTranslations(),
  //     builder: EasyLoading.init(),
  //     debugShowCheckedModeBanner: false,
  //   );
  // }

  Widget menu() {
    return Container(
      color: const Color.fromARGB(255, 159, 70, 70),
      child: const TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(5.0),
        indicatorColor: Color.fromARGB(255, 221, 80, 80),
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
  }

  @override
  Widget build(BuildContext context) {
    Get.put(SettingsController());
    Get.put(ConversationController());
    Get.put(MessageController());
    Get.put(PromptController());
    return MaterialApp(
      theme: FlexThemeData.light(scheme: FlexScheme.ebonyClay),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.ebonyClay),
      themeMode: ThemeMode.system,
      locale: const Locale('zh'),
      // translations: MyTranslations(),
      builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          bottomNavigationBar: menu(),
          body: TabBarView(
            children: [
              Container(child: ChatWindow()),
              Container(child: ChatWindow()),
              Container(child: SettingPage()),
            ],
          ),
        ),
      ),
    );
  }
}
