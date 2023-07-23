import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:moyubie/utils/log.dart';

class Recommend {
  final int id;
  final String reason;

  const Recommend(this.id, this.reason);
}

class AIContext {
  String api_key;
  String model;

  AIContext({required this.api_key, required this.model});
}

class UserProfile {
  String job;
  String language;
  List<String> tags;

  UserProfile({this.job = "", this.language = "", this.tags = const []});

  Map<String, dynamic> toJson() {
    var res = <String, dynamic>{};
    if (!job.isEmpty) {
      res[_PromptStrings._job] = job;
    }
    if (!language.isEmpty) {
      res[_PromptStrings._lang] = language;
    }
    if (tags.isNotEmpty) {
      res[_PromptStrings._interesting_fields] = tags;
    }
    return res;
  }
}

class _PromptStrings {
  static const _interesting_topic = "感兴趣的新闻主题";
  static const _interesting_fields = "感兴趣的领域";
  static const _lang = "语言";
  static const _country = "国家";
  static const _job = "职业";

  static const _recommend_news = "recommend_news";
  static const _items = "items";
  static const _reason = "reason";
  static const _id = "id";
}

class WithOpenAI {
  AIContext _context;

  WithOpenAI(this._context) {
    OpenAI.apiKey = this._context.api_key;
  }
}

class TagCollector extends WithOpenAI {
  static const _sys_prompt = "你是一个用户画像服务，你通过 `fetch_message` 获得用户最近的问题。"
      "请通过这些问题（不要带上其它任何来源）猜测用户关注的领域，以及如果要推送新闻内容，什么主题的内容那样的人会感兴趣？"
      "请把这些信息发送给“send_report”函数，如果有些属性猜不出来，那么请不要带上那些东西。";
  static const _fn_send_report = OpenAIFunctionModel(
      name: "send_report",
      description: "发送分析得到的用户信息给调用者。",
      parametersSchema: {
        "type": "object",
        "properties": {
          _PromptStrings._interesting_fields: {
            "type": "array",
            "items": {"type": "string"}
          },
          _PromptStrings._interesting_topic: {
            "type": "array",
            "items": {"type": "string"}
          },
          _PromptStrings._lang: {"type": "string"},
          _PromptStrings._country: {"type": "string"},
          _PromptStrings._job: {"type": "string"}
        },
        "required": ["感兴趣的领域", "感兴趣的新闻主题"],
      });

  static const _fn_fetch_message = OpenAIFunctionModel(
    name: "fetch_message",
    description: "获得用户最近的消息。",
    parametersSchema: {
      "type": "object",
      "properties": {},
    },
  );

  TagCollector(super._context);

  Future<UserProfile> messageToTags(List<String> msgs) async {
    final res = await OpenAI.instance.chat.create(
      model: _context.model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system, content: _sys_prompt),
        OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.function,
            functionName: _fn_fetch_message.name,
            content: JsonEncoder().convert(msgs))
      ],
      functions: [_fn_fetch_message, _fn_send_report],
      functionCall: FunctionCall.forFunction(_fn_send_report.name),
      // Make GPT be more possible to extract some abstract concepts.
      // (When it is hard to directly use the same text in the input, LLM may try to detect newer words. Hopefully...)
      presencePenalty: 0.8,
      frequencyPenalty: 0.5,
    );
    final args = res.choices[0].message.functionCall?.arguments;
    final lang = args?[_PromptStrings._lang] ?? "";
    final tags = [
      ...args?[_PromptStrings._interesting_fields] ?? [],
      ...args?[_PromptStrings._interesting_topic] ?? []
    ];
    return UserProfile(
        job: args?[_PromptStrings._job] ?? "",
        language: lang,
        tags: tags.cast<String>());
  }
}

class NewsPromoter extends WithOpenAI {
  static const _fn_get_user_info = OpenAIFunctionModel(
      name: "get_user_info",
      description: "获取用户的分析报告。",
      parametersSchema: {"type": "object", "properties": {}});
  static const _fn_get_news = OpenAIFunctionModel(
      name: "get_news",
      description: "获取新闻列表。",
      parametersSchema: {"type": "object", "properties": {}});
  static const _fn_recommend_news = OpenAIFunctionModel(
      name: "recommend_news",
      description: "将指定的新闻推荐给用户，并附带上推荐理由。",
      parametersSchema: {
        "type": "object",
        "properties": {
          "recommend_news": {
            "type": "array",
            "maxItems": 5,
            _PromptStrings._items: {
              "properties": {
                _PromptStrings._id: {},
                _PromptStrings._reason: {"type": "string"}
              },
              "required": [_PromptStrings._id, _PromptStrings._reason]
            }
          }
        }
      });
  static const _sys_prompt =
      '你是一个新闻推荐服务。你通过且仅通过 `get_user_info` 获得用户分析报告，通过 `get_news` 获得今日新闻。'
      '你要从中选出尽可能多用户可能感兴趣的新闻（但是不要超过五条），并给出相应的理由，随后将理由翻译给用户的惯用语言，推荐理由请不要和标题过度相似。'
      '传递推荐给 `recommend_news`，你只需要传递 id 和推荐理由，不要带上新闻的其它属性。不要使用 `get_user_info` 以外任何地方的用户信息，也不要用和用户信息不相符的理由推荐。';

  NewsPromoter(super._context);

  Future<List<Recommend>> promotNews(
      UserProfile userInfo, List<Map<String, dynamic>> news) async {
    final res = await OpenAI.instance.chat.create(
        model: _context.model,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system, content: _sys_prompt),
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.function,
              functionName: _fn_get_news.name,
              content: JsonEncoder().convert(news)),
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.function,
              functionName: _fn_get_user_info.name,
              content: JsonEncoder().convert(userInfo)),
        ],
        // Make the output more predictable.
        temperature: 0,
        functionCall: FunctionCall.forFunction(_fn_recommend_news.name),
        functions: [_fn_get_news, _fn_get_user_info, _fn_recommend_news]);
    final args = res.choices[0].message.functionCall?.arguments;
    final recommends = args?[_PromptStrings._recommend_news] as List<dynamic>;
    var recs = <Recommend>[];
    for (var item in recommends) {
      try {
        var m = item as Map<String, dynamic>;
        recs.add(Recommend(m[_PromptStrings._id], m[_PromptStrings._reason]));
      } catch (e) {
        log("Error on parsing AI response...");
        log(e);
        rethrow;
      }
    }
    log(recs);
    return recs;
  }
}
