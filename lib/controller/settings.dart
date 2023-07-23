import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moyubie/repository/chat_room.dart';
import 'package:moyubie/utils/package.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final isObscure = true.obs;

  final openAiKey = "".obs;
  final openAiKeyTmp = "".obs;

  final serverlessCmd = "".obs;
  final serverlessCmdTmp = "".obs;

  // final glmBaseUrl = "".obs;

  final openAiBaseUrl = "https://api.openai-proxy.com".obs;

  final themeMode = ThemeMode.system.obs;

  final gptModel = "gpt-3.5-turbo".obs;
  final gptModelTmp = "gpt-3.5-turbo".obs;

  final locale = const Locale('zh').obs;

  final useStream = true.obs;

  final useWebSearch = false.obs;

  final llm = "Echo".obs;
  final llmTmp = "Echo".obs;

  final version = "1.0.0".obs;

  static SettingsController get to => Get.find();

  @override
  void onInit() async {
    await getThemeModeFromPreferences();
    await getLocaleFromPreferences();
    await getOpenAiBaseUrlFromPreferences();
    await getOpenAiKeyFromPreferences();
    await getServerlessCmdFromPreferences();
    await getGptModelFromPreferences();
    await getUseStreamFromPreferences();
    await initAppVersion();
    saveTmpOption();
    super.onInit();
  }

  initAppVersion() async {
    version.value = await getAppVersion();
  }

  // void setGlmBaseUrl(String baseUrl) {
  //   glmBaseUrl.value = baseUrl;
  //   GetStorage _box = GetStorage();
  //   _box.write('glmBaseUrl', baseUrl);
  // }

  // getGlmBaseUrlFromPreferences() async {
  //   GetStorage _box = GetStorage();
  //   String baseUrl = _box.read('glmBaseUrl') ?? "https://api.openai-proxy.com";
  //   setGlmBaseUrl(baseUrl);
  // }

  void saveTmpOption() {
    GetStorage _box = GetStorage();
    llm.value = llmTmp.value;
    gptModel.value = gptModelTmp.value;
    _box.write('gptModel', gptModel.value);
    openAiKey.value = openAiKeyTmp.value;
    _box.write('openAiKey', openAiKey.value);
    serverlessCmd.value = serverlessCmdTmp.value;
    _box.write('serverlessCmd', serverlessCmd.value);
    updateServerlessCmdToRepo(serverlessCmd.value);
    if (llm.value == "OpenAI") {
      OpenAI.apiKey = GetStorage().read('openAiKey') ?? "sk-xx";
      OpenAI.baseUrl =
          GetStorage().read('openAiBaseUrl') ?? "https://api.openai.com";
    }
  }

  updateServerlessCmdToRepo(String cmd) {
    cmd = cmd.replaceFirst(" -p", " -p ");
    final options = cmd.split(" ");
    var nextOpts = List.from(options);
    nextOpts.removeAt(0);
    nextOpts.add("");
    String user = "";
    String host = "";
    int port = 0;
    String password = "";

    for (int i = 0; i < options.length; i += 1) {
      final opt = options[i];
      final nextOpt = nextOpts[i];
      switch (opt) {
        case "-u":
        case "--user":
          user = nextOpt.replaceAll("'", "");
          user = user.replaceAll('"', "");
          user = user.replaceAll("'", "");
          break;
        case "-h":
        case "--host":
          host = nextOpt;
          break;
        case "-P":
        case "--port":
          port = int.parse(nextOpt);
          break;
        case "-p":
        case "--password":
          password = nextOpt;
          break;
        default:
      }
    }
    ChatRoomRepository().updateRemoteDBConfig(host, port, user, password);
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
    serverlessCmdTmp.value = text;
  }

  getServerlessCmdFromPreferences() async {
    GetStorage _box = GetStorage();
    String cmd = _box.read('serverlessCmd') ?? "";
    setServerlessCmd(cmd);
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

  void setLlm(String text) {
    llmTmp.value = text;
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
}
