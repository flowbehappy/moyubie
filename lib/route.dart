import 'package:get/get.dart';
import 'package:moyubie/pages/home.dart';

import 'components/setting.dart';

final routes = [
  GetPage(name: '/', page: () => MyHomePage()),
  GetPage(name: '/setting', page: () => SettingPage())
];
