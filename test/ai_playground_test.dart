import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moyubie/utils/ai_recommend.dart';

void main() {
  // test("Collection Playground!",() async {
  //   var ctx = AIContext(api_key: Platform.environment["OAI_API"]!, model: "gpt-3.5-turbo");
  //   var coll = TagCollector(ctx);
  //   var res = await coll.messageToTags(["今天天气真好啊，来写点 Rust 吧，你能给我一点和 TiDB 相关的 Rust 库吗？"]);
  //   print(res.toString());
  //   print(res.job);
  //   print(res.language);
  //   print(res.tags);
  // });

  test("Promote Test!",() async {
    var ctx = AIContext(api_key: Platform.environment["OAI_API"]!, model: "gpt-3.5-turbo");
    var rec = NewsPromoter(ctx);
    var res = await rec.promotNews(UserProfile(tags: ["编程", "科技", "软件开发"]), 
      [{"title": "最新的 Rust 库，可以帮助大家再也没有编译错误！", "id": 1},
      {"title": "国家今日决定免除一切个人所得税征收。", "id": 2},
      {"title": "在山麓的湖泊中发现水怪！", "id": 3},

      // More different news about programming... 
      {"title": "新晋偶像团体主打高学历，人人都精通数据库调优。", "id": 4},
      {"title": "游戏 Rust 从零开始的攻略：Craft your life", "id": 5},
      {"title": "蛇果公司全新可穿戴设备，或将协助农林经济发展", "id": 6}
      ]);
    print(res.map((e) => "${e.id} => ${e.reason}").join("|||"));
  });
}