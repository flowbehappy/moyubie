import 'package:flutter/material.dart';
import 'package:flutter_chatgpt/controller/conversation.dart';
import 'package:flutter_chatgpt/controller/message.dart';
import 'package:flutter_chatgpt/controller/prompt.dart';
import 'package:flutter_chatgpt/controller/settings.dart';
import 'package:flutter_chatgpt/components/chat.dart';
import 'package:flutter_chatgpt/components/setting.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
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
            text: "Like",
            icon: Icon(Icons.favorite),
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
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          bottomNavigationBar: menu(),
          body: TabBarView(
            children: [
              Container(child: ChatWindow()),
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
