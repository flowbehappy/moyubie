import 'dart:math';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Moyubie/repository/chat_room.dart';
import 'package:Moyubie/utils/package.dart';
import 'package:Moyubie/utils/tidb.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final isObscure = true.obs;
  final isTiDBCmdObscure = true.obs;

  bool isLLMReady = false;

  final openAiKey = "".obs;
  final openAiKeyTmp = "".obs;

  final serverlessCmd = "".obs;
  final serverlessCmdTmp = "".obs;

  final nickname = "".obs;
  final nicknameTmp = "".obs;

  final openAiBaseUrl = "https://api.openai-proxy.com".obs;

  final themeMode = ThemeMode.system.obs;

  final gptModel = "gpt-3.5-turbo".obs;
  final gptModelTmp = "gpt-3.5-turbo".obs;

  final locale = const Locale('zh').obs;

  final useStream = true.obs;

  final useWebSearch = false.obs;

  final llm = "Echo".obs;
  final llmTmp = "Echo".obs;

  final version = "1.1.0".obs;

  static SettingsController get to => Get.find();

  bool get getIsLLMReady {
    return isLLMReady;
  }

  @override
  void onInit() async {
    await getThemeModeFromPreferences();
    await getLocaleFromPreferences();
    await getOpenAiBaseUrlFromPreferences();
    await getOpenAiKeyFromPreferences();
    await getServerlessCmdFromPreferences();
    await getNicknameFromPreferences();
    await getLLMFromPreferences();
    await getGptModelFromPreferences();
    await getUseStreamFromPreferences();
    await initAppVersion();
    saveTmpOption();
    super.onInit();
  }

  initAppVersion() async {
    version.value = await getAppVersion();
  }

  Future<String?> validateLLM() async {
    if (llm.value == "OpenAI") {
      if (openAiKey.value.length <= 10) {
        return "Invalid OpenAI key: ${openAiKey.value}";
      }

      try {
        OpenAI.apiKey = GetStorage().read('openAiKey') ?? "sk-xx";
        OpenAI.baseUrl =
            GetStorage().read('openAiBaseUrl') ?? "https://api.openai.com";
      } catch (e) {
        return "Cannot connect to OpenAI, error: ${e.toString()}";
      }
    }

    return null;
  }

  void saveTmpOption({BuildContext? context}) async {
    GetStorage _box = GetStorage();
    llm.value = llmTmp.value;
    _box.write('llm', llm.value);
    gptModel.value = gptModelTmp.value;
    _box.write('gptModel', gptModel.value);
    openAiKey.value = openAiKeyTmp.value;
    _box.write('openAiKey', openAiKey.value);
    serverlessCmd.value = serverlessCmdTmp.value;
    _box.write('serverlessCmd', serverlessCmd.value);
    nickname.value = nicknameTmp.value;
    _box.write('nickname', nickname.value);

    bool hasLLM = openAiKey.value.isNotEmpty && llm.value != "Echo";
    if (hasLLM) {
      var res = await validateLLM();
      if (res != null) {
        isLLMReady = false;
        if (context != null && context.mounted) {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Done!'),
              content: Text("AI Service validate failed:\n$res"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      } else {
        isLLMReady = true;
      }
    }

    var res = updateTiDBCmdToRepo(serverlessCmd.value);
    res ??= await ChatRoomRepository.myTiDBConn.validateRemoteDB();

    String popMsg;
    switch (res) {
      case null:
        {
          popMsg = "Settings saved.";
          break;
        }
      case "Empty":
        {
          ChatRoomRepository.myTiDBConn.clearConnect();
          popMsg =
              "Warn: Chat messages are only saved to local if you don't specify TiDB Serverless connection.";
          break;
        }
      default:
        {
          ChatRoomRepository.myTiDBConn.clearConnect();
          popMsg = "Connect to TiDB Serverless failed:\n$res.";
        }
    }

    if (context != null && context.mounted) {
      _showInSnackBar(context, popMsg);
    }
  }

  // Return true if we find host is not empty.
  String? updateTiDBCmdToRepo(String cmd) {
    if (cmd.isEmpty) return "Empty";

    var (host, port, user, password, _, _) = parseTiDBConnectionToken(cmd);
    if (port == 0) {
      return user;
    }
    ChatRoomRepository().updateRemoteDBConfig(host, port, user, password);

    if (user.isEmpty || host.isEmpty || port == 0 || password.isEmpty) {
      return "Illegal format";
    }

    return null;
  }

  void setOpenAiKey(String text) {
    openAiKeyTmp.value = text;
  }

  getOpenAiKeyFromPreferences() async {
    GetStorage _box = GetStorage();
    String key = _box.read('openAiKey') ?? "";
    setOpenAiKey(key);
  }

  void setServerlessCmd(String text) {
    serverlessCmdTmp.value = text.trim();
  }

  getServerlessCmdFromPreferences() async {
    GetStorage _box = GetStorage();
    String cmd = _box.read('serverlessCmd') ?? "";
    setServerlessCmd(cmd);
  }

  String generateRandomNickname() {
    var random = Random();
    var index = random.nextInt(999999);
    final indexStr = index.toString().padLeft(6, '0');
    return "Moyu-$indexStr";
  }

  getNicknameFromPreferences() async {
    GetStorage _box = GetStorage();
    var name = _box.read('nickname');
    if (name == null || name.isEmpty) {
      name = generateRandomNickname();
    }
    setNickname(name);
  }

  void setOpenAiBaseUrl(String baseUrl) {
    openAiBaseUrl.value = baseUrl;
    update();
    GetStorage _box = GetStorage();
    _box.write('openAiBaseUrl', baseUrl);
  }

  getOpenAiBaseUrlFromPreferences() async {
    GetStorage _box = GetStorage();
    String baseUrl =
        _box.read('openAiBaseUrl') ?? "https://api.openai-proxy.com";
    setOpenAiBaseUrl(baseUrl);
  }

  void setLlm(String text) {
    llmTmp.value = text;
  }

  getLLMFromPreferences() async {
    GetStorage _box = GetStorage();
    String llm = _box.read('llm') ?? "Echo";
    setLlm(llm);
  }

  void setGptModel(String text) {
    gptModelTmp.value = text;
  }

  getGptModelFromPreferences() async {
    GetStorage _box = GetStorage();
    String model = _box.read('gptModel') ?? "gpt-3.5-turbo";
    setGptModel(model);
  }

  void setThemeMode(ThemeMode model) async {
    Get.changeThemeMode(model);
    themeMode.value = model;
    GetStorage _box = GetStorage();
    _box.write('theme', model.toString().split('.')[1]);
  }

  getThemeModeFromPreferences() async {
    ThemeMode themeMode;
    GetStorage _box = GetStorage();
    String themeText = _box.read('theme') ?? 'system';
    try {
      themeMode =
          ThemeMode.values.firstWhere((e) => describeEnum(e) == themeText);
    } catch (e) {
      themeMode = ThemeMode.system;
    }
    setThemeMode(themeMode);
  }

  void switchLocale() {
    locale.value =
        _parseLocale(locale.value.languageCode == 'en' ? 'zh' : 'en');
  }

  Locale _parseLocale(String locale) {
    switch (locale) {
      case 'en':
        return const Locale('en');
      case 'zh':
        return const Locale('zh');
      default:
        throw Exception('system locale');
    }
  }

  void setUseStream(bool value) {
    useStream.value = value;
    GetStorage _box = GetStorage();
    _box.write('useStream', value);
  }

  getUseStreamFromPreferences() async {
    GetStorage _box = GetStorage();
    bool useStream = _box.read('useStream') ?? true;
    setUseStream(useStream);
  }

  void setUseWebSearch(bool value) {
    useWebSearch.value = value;
    GetStorage _box = GetStorage();
    _box.write('useWebSearch', value);
  }

  void getUseWebSearchFromPreferences() async {
    GetStorage _box = GetStorage();
    bool useWebSearch = _box.read('useWebSearch') ?? false;
    setUseWebSearch(useWebSearch);
  }

  void setLocale(Locale lol) {
    Get.updateLocale(lol);
    locale.value = lol;
    GetStorage _box = GetStorage();
    _box.write('locale', lol.languageCode);
  }

  getLocaleFromPreferences() async {
    Locale locale;
    GetStorage _box = GetStorage();
    String localeText = _box.read('locale') ?? 'zh';
    try {
      locale = _parseLocale(localeText);
    } catch (e) {
      locale = Get.deviceLocale!;
    }
    setLocale(locale);
  }

  void _showInSnackBar(BuildContext context, String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value,
        ),
      ),
    );
  }

  void setNickname(String text) {
    nicknameTmp.value = text.trim();
  }
}
