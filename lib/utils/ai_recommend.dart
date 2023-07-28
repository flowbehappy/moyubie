import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:Moyubie/utils/log.dart';

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
    if (job.isNotEmpty) {
      res[_PromptStringsEn._job] = job;
    }
    if (language.isNotEmpty) {
      res[_PromptStringsEn._lang] = language;
    }
    if (tags.isNotEmpty) {
      res[_PromptStringsEn._interesting_fields] = tags;
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

  static const _interesting_fields_eng = "Interesting Fields";
  static const _interesting_topic_eng = "Interesting News Topics";

  static const _recommend_news = "recommend_news";
  static const _items = "items";
  static const _reason = "reason";
  static const _id = "id";

  static const get_user_info_desc = "获取用户的分析报告。";
  static const get_news_desc = "获取新闻列表。";
  static const recommend_news_desc = "将指定的新闻推荐给用户，并附带上推荐理由。";
}

class _PromptStringsEn {
  static const _interesting_topic = "Interesting News Topics";
  static const _interesting_fields = "Interesting Fields";
  static const _lang = "Language";
  static const _country = "Country";
  static const _job = "Occupation";

  static const _fn_send_report_desc =
      "Send the user information obtained from the analysis to the caller.";
  static const _fn_fetch_message_desc = "Fetch recent messages from the user.";

  static const get_user_info_desc = "Obtain the user's analysis report.";
  static const get_news_desc = "Get the list of news.";
  static const recommend_news_desc =
      "Recommend specified news articles to the user with accompanying reasons.";
}

class WithOpenAI {
  AIContext _context;

  WithOpenAI(this._context) {
    OpenAI.apiKey = this._context.api_key;
  }
}

class UserProfiler extends WithOpenAI {
  static const _sys_prompt = "你是一个用户画像服务，你通过 `fetch_message` 获得用户最近的问题。"
      "请通过这些问题（不要带上其它任何来源）猜测用户关注的领域，以及如果要推送新闻内容，什么主题的内容那样的人会感兴趣？"
      "请把这些信息发送给“send_report”函数，如果有些属性猜不出来，那么请不要带上那些东西。";
  static const _sys_prompt_en =
      "You are a user profiling service that obtains the user's recent questions through the fetch_message function. "
      "Please use these questions (without considering any other sources) to guess the user's areas of interest and the topics of news content that people with similar interests would find intriguing. "
      'Send this information to the "send_report" function. If there are certain attributes you cannot determine, please omit them from the report.';
  static const _fn_send_report = OpenAIFunctionModel(
      name: "send_report",
      description: _PromptStringsEn._fn_send_report_desc,
      parametersSchema: {
        "type": "object",
        "properties": {
          _PromptStringsEn._interesting_fields: {
            "type": "array",
            "items": {"type": "string"}
          },
          _PromptStringsEn._interesting_topic: {
            "type": "array",
            "items": {"type": "string"}
          },
          _PromptStringsEn._lang: {"type": "string"},
          _PromptStringsEn._country: {"type": "string"},
          _PromptStringsEn._job: {"type": "string"}
        },
        "required": [
          _PromptStringsEn._interesting_fields,
          _PromptStringsEn._interesting_topic
        ],
      });

  static const _fn_fetch_message = OpenAIFunctionModel(
    name: "fetch_message",
    description: _PromptStringsEn._fn_fetch_message_desc,
    parametersSchema: {
      "type": "object",
      "properties": {},
    },
  );

  UserProfiler(super._context);

  Future<UserProfile> messageToTags(List<String> msgs) async {
    final res = await OpenAI.instance.chat.create(
      model: _context.model,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system, content: _sys_prompt_en),
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
    final lang = args?[_PromptStringsEn._lang] ?? "";
    final tags = [
      ...args?[_PromptStringsEn._interesting_fields] ?? [],
      ...args?[_PromptStringsEn._interesting_topic] ?? []
    ];
    return UserProfile(
        job: args?[_PromptStringsEn._job] ?? "",
        language: lang,
        tags: tags.cast<String>());
  }
}

class NewsPromoter extends WithOpenAI {
  static const _fn_get_user_info = OpenAIFunctionModel(
      name: "get_user_info",
      description: _PromptStringsEn.get_user_info_desc,
      parametersSchema: {"type": "object", "properties": {}});
  static const _fn_get_news = OpenAIFunctionModel(
      name: "get_news",
      description: _PromptStringsEn.get_news_desc,
      parametersSchema: {"type": "object", "properties": {}});
  static const _fn_recommend_news = OpenAIFunctionModel(
      name: "recommend_news",
      description: _PromptStringsEn.recommend_news_desc,
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
      '传递推荐给 `recommend_news`，你只需要传递 id 和推荐理由，不要带上新闻的其它属性。不要使用 `get_user_info` 以外任何地方的用户信息。'
      '不要用和用户信息不相符的理由推荐，也不要推荐用户感兴趣主题以外的新闻。';
  static const _sys_prompt_en =
      "You are a news recommendation service. You obtain the user analysis report exclusively through 'get_user_info' and today's news through 'get_news'."
      "Your task is to select as many news articles as possible that users might be interested in (but not exceeding five articles), and provide corresponding reasons. "
      "Pass the recommendations to 'recommend_news'. You only need to provide the news id and the recommended reasons, without including any other properties of the news. Do not use user information from any other source besides 'get_user_info'."
      "Do not recommend news with reasons that do not match the user's preferences, and avoid recommending news outside of the user's interested topics.";

  NewsPromoter(super._context);

  Future<List<Recommend>> promoteNews(
      UserProfile userInfo, List<Map<String, dynamic>> news) async {
    final res = await OpenAI.instance.chat.create(
        model: _context.model,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system, content: _sys_prompt_en),
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
        topP: 0.08,
        presencePenalty: 1,
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
