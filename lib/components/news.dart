import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dual_screen/dual_screen.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moyubie/components/chat_room.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../utils/ai_recommend.dart';

mixin BgTaskIndicatorExt<T extends StatefulWidget> on State<T> {
  int? _max;
  int? _current;
  String? _task_text;

  bool get bgTaskRunning => _current != null;

  Widget indct() {
    if (_current == null) {
      throw Exception("the progress isn't running!");
    }
    if (_max == null) {
      return CircularProgressIndicator();
    }
    return LinearProgressIndicator(value: (_current as double) / _max!);
  }

  Widget prog() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.only(bottom: 4), child: indct()),
      if (_task_text != null) Text(_task_text!)
    ]);
  }

  Future<R> runTask<R>(Future<R> Function(void Function(int) setProgress) fut,
      {max, taskName}) async {
    setState(() {
      this._current = 0;
      if (max != null) {
        this._max = max;
      }
      if (taskName != null) {
        this._task_text = taskName;
      }
    });

    return await fut((x) {
      setState(() {
        if (x < 0 || (_max != null && x > _max!)) {
          this._current = null;
          this._max = null;
          return;
        }
        this._current = x;
      });
    });
  }

  Future<R> runOneShotTask<R>(Future<R> fut, {taskName}) async {
    return runTask((setProgress) async {
      final res = await fut;
      setProgress(-1);
      return res;
    }, taskName: taskName);
  }
}

enum _NewsSource { HackerNews }

class News {
  _NewsSource source;
  int id;
  String title;
  String content;
  String url;

  News(this.source, this.id, this.url, this.title, this.content);

  Map<String, dynamic> convertToJsonForRecommend() {
    return {
      "id": id,
      "title": title,
      "score_and_creator": content,
    };
  }
}

class NewsService {
  List<News> _cached = [];
  final _concurrency = 8;

  Future<void> refreshTopNews(int limit) async {
    var topStories = 'https://hacker-news.firebaseio.com/v0/topstories.json';
    var uri = Uri.parse(topStories);
    var response = await http.get(
      uri,
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      var topStoriesId = json.decode(response.body) as List<dynamic>;
      var news = <News>[];
      var futs = <Future>[];
      for (var id in topStoriesId) {
        if (futs.length > _concurrency) {
          final res = await Future.any(
              futs.indexed.map((p) => p.$2.then((value) => (p.$1, value))));
          futs.removeAt(res.$1);
          final newsJson = res.$2;
          if (newsJson == null || newsJson['url'] == null) {
            continue;
          }
          news.add(News(
              _NewsSource.HackerNews,
              newsJson['id'],
              newsJson['url'],
              newsJson['title'],
              "${newsJson["score"]} scores by ${newsJson["by"]}"));
        }
        if (news.length >= limit) {
          if (futs.isEmpty) {
            break;
          }
          continue;
        }

        futs.add(() async {
          var url = 'https://hacker-news.firebaseio.com/v0/item/$id.json';
          var uri = Uri.parse(url);
          var response = await http.get(
            uri,
            headers: {"Content-Type": "application/json"},
          );
          if (response.statusCode == 200) {
            var newsJson = json.decode(response.body);
            return newsJson;
          }
        }());
      }
      _cached = news;
    } else {
      throw Exception('Failed to load top news');
    }
  }

  Future<List<News>> cachedOrFetchTopNews(int limit) async {
    if (_cached.length < limit) {
      await refreshTopNews(limit);
    }
    return _cached;
  }
}

class _TestData {
  static final hackerNews = [
    News(
        _NewsSource.HackerNews,
        36799548,
        "https://anytype.io/?hn",
        "Anytype – open-source, local-first, P2P Notion alternative",
        "104 scores by TTTZ"),
    News(
        _NewsSource.HackerNews,
        36799776,
        "https://github.com/bartobri/no-more-secrets",
        "No-more-secrets: recreate the decryption effect seen in the 1992 movie Sneakers",
        "66 scores by tambourine_man"),
    News(
        _NewsSource.HackerNews,
        36795173,
        "https://www.dignitymemorial.com/obituaries/las-vegas-nv/kevin-mitnick-11371668",
        "Kevin Mitnick has died",
        "2937 scores by thirtyseven"),
    News(
        _NewsSource.HackerNews,
        36800041,
        "https://www.projectaria.com/datasets/adt/",
        "Project Aria 'Digital Twin' Dataset by Meta",
        "20 scores by socratic1"),
    News(
        _NewsSource.HackerNews,
        36798593,
        "https://github.com/docusealco/docuseal",
        "Docuseal: Open-source DocuSign alternative. Create, fill, sign digital documents",
        "161 scores by thunderbong"),
    News(
        _NewsSource.HackerNews,
        36798774,
        "https://github.com/Swordfish90/cool-retro-term",
        "Cool Retro Terminal",
        "86 scores by qazpot"),
    News(
        _NewsSource.HackerNews,
        36800151,
        "https://www.jefftk.com/p/accidentally-load-bearing",
        "Accidentally Load Bearing",
        "11 scores by jamessun"),
    News(
        _NewsSource.HackerNews,
        36798157,
        "https://developer.mozilla.org/en-US/play",
        "MDN Playground",
        "127 scores by weinzierl"),
    News(
        _NewsSource.HackerNews,
        36799283,
        "https://up.codes/careers",
        "UpCodes (YC S17) is hiring a Growth Marketer to make construction efficient",
        "1 scores by Old_Thrashbarg"),
    News(
        _NewsSource.HackerNews,
        36798864,
        "https://github.com/Fadi002/unshackle",
        "Unshackle: A tool to bypass windows password logins",
        "42 scores by AdvDebug"),
    News(
        _NewsSource.HackerNews,
        36798842,
        "https://www.pathsensitive.com/2018/02/the-practice-is-not-performance-why.html",
        "Why project-based learning fails (2018)",
        "33 scores by jger15"),
    News(
        _NewsSource.HackerNews,
        36799628,
        "https://giannirosato.com/blog/post/jpegli-xyb/",
        "XYB JPEG: Perceptual Color Encoding Tested",
        "15 scores by computerbuster"),
    News(
        _NewsSource.HackerNews,
        36798997,
        "https://projects.osmocom.org/projects/foss-ims-client/wiki/Wiki",
        "Open Source IMS Client",
        "16 scores by McDyver"),
    News(
        _NewsSource.HackerNews,
        36799073,
        "https://viterbischool.usc.edu/news/2023/07/teaching-robots-to-teach-other-robots/",
        "AI That Teaches Other AI",
        "13 scores by geox"),
    News(
        _NewsSource.HackerNews,
        36778309,
        "https://en.wikipedia.org/wiki/Glossary_of_Japanese_words_of_Portuguese_origin",
        "Japanese words of Portuguese origin",
        "181 scores by lermontov"),
    News(
        _NewsSource.HackerNews,
        36798092,
        "https://dolphin-emu.org/blog/2023/07/20/what-happened-to-dolphin-on-steam/",
        "What Happened to Dolphin on Steam?",
        "116 scores by panic"),
    News(
        _NewsSource.HackerNews,
        36791936,
        "https://daily.jstor.org/delts-dont-lie/",
        "Delts Don’t Lie",
        "48 scores by fnubbly"),
    News(
        _NewsSource.HackerNews,
        36798051,
        "https://chromium.googlesource.com/chromiumos/docs/+/HEAD/development_basics.md#programming-languages-and-style",
        "ChromiumOS Developer Guide, Programming languages and style",
        "48 scores by pjmlp"),
    News(_NewsSource.HackerNews, 36799221, "https://taylor.town/secret-sauce",
        "Spoil Your Secret Sauce", "9 scores by surprisetalk"),
    News(_NewsSource.HackerNews, 36798826, "https://pdfdiffer.com/",
        "Show HN: PDF Differ", "20 scores by m4rc1e"),
    News(_NewsSource.HackerNews, 36798854, "https://sive.rs/pnt",
        "The past is not true", "85 scores by swah"),
    News(
        _NewsSource.HackerNews,
        36790301,
        "https://stanforddaily.com/2023/07/19/stanford-president-resigns-over-manipulated-research-will-retract-at-least-3-papers/",
        "Stanford president resigns over manipulated research, will retract 3 papers",
        "1339 scores by dralley"),
    News(
        _NewsSource.HackerNews,
        36768334,
        "https://github.com/InderdeepBajwa/gitid",
        "Use multiple Git SSH identities on a single computer",
        "43 scores by inderdeepbajwa"),
    News(
        _NewsSource.HackerNews,
        36799235,
        "https://www.bloomberg.com/news/articles/2023-07-19/wall-street-shrinks-ranks-by-21-000-amid-deals-trading-slump",
        "Wall Street Shrinks Headcount by 21,000 as Dealmaking and Trading Slump",
        "37 scores by haltingproblem"),
    News(
        _NewsSource.HackerNews,
        36794756,
        "https://www.youtube.com/watch?v=6-3BFXpBcjc",
        "The Danger of Popcorn Polymer: Incident at the TPC Group Chemical Plant [video]",
        "172 scores by oatmeal1"),
    News(
        _NewsSource.HackerNews,
        36794430,
        "https://www.infoq.com/news/2023/07/linkedin-protocol-buffers-restli/",
        "LinkedIn adopts protocol buffers and reduces latency up to 60%",
        "164 scores by ijidak"),
    News(
        _NewsSource.HackerNews,
        36799700,
        "https://www.theguardian.com/us-news/2023/jul/20/toxic-flame-retardants-human-breast-milk",
        "Flame retardant found in US breast milk",
        "12 scores by geox"),
    News(
        _NewsSource.HackerNews,
        36798850,
        "https://www.washingtonpost.com/wellness/2023/07/19/hearing-loss-hearing-aids-dementia-study/",
        "Hearing aids may cut risk of cognitive decline by nearly half",
        "48 scores by maxutility"),
    News(
        _NewsSource.HackerNews,
        36799600,
        "https://www.nytimes.com/2023/07/19/business/google-artificial-intelligence-news-articles.html",
        "Google Tests A.I. Tool That Is Able to Write News Articles",
        "12 scores by asnyder"),
    News(
        _NewsSource.HackerNews,
        36771331,
        "https://www.infoq.com/news/2023/07/yelp-corrupted-cassandra-rebuild/",
        "Yelp rebuilds corrupted Cassandra cluster using its data streaming architecture",
        "83 scores by rgancarz"),
    News(
        _NewsSource.HackerNews,
        36800196,
        "https://www.theregister.com/2023/07/20/cerebras_condor_galaxy_supercomputer/",
        "Cerebras's Condor Galaxy AI supercomputer takes flight carrying 36 exaFLOPS",
        "4 scores by rntn"),
    News(
        _NewsSource.HackerNews,
        36799059,
        "https://asia.nikkei.com/Business/Tech/Semiconductors/TSMC-delays-U.S.-chip-plant-start-to-2025-due-to-labor-shortages",
        "TSMC delays U.S. chip plant start to 2025 due to labor shortages",
        "66 scores by ironyman"),
    News(
        _NewsSource.HackerNews,
        36797079,
        "https://github.com/Maknee/minigpt4.cpp",
        "Minigpt4 Inference on CPU",
        "89 scores by maknee"),
    News(
        _NewsSource.HackerNews,
        36771114,
        "https://www.oreilly.com/radar/teaching-programming-in-the-age-of-chatgpt/",
        "Teaching Programming in the Age of ChatGPT",
        "135 scores by headalgorithm"),
    News(
        _NewsSource.HackerNews,
        36780999,
        "https://phys.org/news/2023-07-tidal-disruption-event-chinese-astronomers.html",
        "New tidal disruption event discovered by Chinese astronomers",
        "23 scores by wglb"),
    News(
        _NewsSource.HackerNews,
        36796422,
        "https://github.com/mbnuqw/sidebery",
        "Sidebery – A Firefox extension for managing tabs and bookmarks in sidebar",
        "146 scores by BafS"),
    News(
        _NewsSource.HackerNews,
        36797178,
        "https://lists.freebsd.org/archives/freebsd-announce/2023-July/000076.html",
        "In Memoriam: Hans Petter William Sirevåg Selasky",
        "100 scores by stargrave"),
    News(
        _NewsSource.HackerNews,
        36798395,
        "https://en.wikipedia.org/wiki/Vacuum_airship",
        "Vacuum airship",
        "61 scores by guerrilla"),
    News(
        _NewsSource.HackerNews,
        36777096,
        "https://bigthink.com/the-past/kunga-first-hybrid-animal/",
        "Kunga: Ancient Mesopotamians created the world’s first hybrid animal",
        "34 scores by diodorus"),
    News(
        _NewsSource.HackerNews,
        36797231,
        "https://arstechnica.com/science/2023/07/new-slow-repeating-radio-source-we-have-no-idea-what-it-is/",
        "Something in space has been lighting up every 20 minutes since 1988",
        "120 scores by Brajeshwar"),
    News(
        _NewsSource.HackerNews,
        36782638,
        "https://www.transportation.gov/pnt/what-radio-spectrum",
        "What Is Radio Spectrum?",
        "46 scores by ZunarJ5"),
    News(
        _NewsSource.HackerNews,
        36800009,
        "https://arstechnica.com/information-technology/2023/07/ars-on-aws-01/",
        "Behind the scenes: How we host Ars Technica, part 1",
        "4 scores by pseudolus"),
    News(
        _NewsSource.HackerNews,
        36799461,
        "https://shkspr.mobi/blog/2023/07/keeping-a-side-project-alive-with-t-shirts-and-cash/",
        "Keeping a side project alive with t-shirts and cash",
        "8 scores by edent"),
    News(
        _NewsSource.HackerNews,
        36793022,
        "https://www.sharbonline.com/fun-stuff/card-games/complex-hearts/",
        "Complex Hearts",
        "21 scores by pcwalton"),
    News(
        _NewsSource.HackerNews,
        36782201,
        "https://jazz-library.com/articles/comping/",
        "Jazz Comping (2021)",
        "111 scores by RickHull"),
    News(
        _NewsSource.HackerNews,
        36798408,
        "https://hothardware.com/news/intel-14thgen-core-k-cpu-spec-leak",
        "Intel's 14th Gen Core K-Series CPU Specs Break Cover with Speeds Up to 6GHz",
        "25 scores by rbanffy"),
    News(
        _NewsSource.HackerNews,
        36796685,
        "https://acl2023-retrieval-lm.github.io/",
        "ACL 2023 Tutorial: Retrieval-Based Language Models and Applications",
        "17 scores by TalktoCrystal"),
    News(
        _NewsSource.HackerNews,
        36798496,
        "https://blog.google/technology/safety-security/googles-ai-red-team-the-ethical-hackers-making-ai-safer/",
        "Google Introduces AI Red Team",
        "5 scores by bhattmayurshiv"),
    News(
        _NewsSource.HackerNews,
        36798863,
        "https://www.theguardian.com/technology/2023/jul/20/tiktok-is-the-most-popular-news-source-for-12-to-15-year-olds-says-ofcom",
        "TikTok is the most popular news source for 12 to 15-year-olds",
        "16 scores by firstSpeaker")
  ];

  static const hackerNewsIcon =
      // ImageIcon(AssetImage("hackernews_icon.jpeg"), color: Colors.transparent);
      Icon(Icons.newspaper);

  static const simplePrompted = [
    Recommend(36799548,
        "Anytype是一个开源的、本地优先的、P2P的Notion替代品。它提供了类似Notion的功能，但是数据存储在本地，而不是云端。这样可以增加数据的安全性和隐私保护。对于关注数据安全和隐私的用户来说，Anytype是一个很好的选择。"),
    Recommend(36795173,
        "Kevin Mitnick是一位著名的黑客，据称他已经去世了。Kevin Mitnick以他的黑客技术和社会工程学见长，并因此被FBI通缉。他的离世无疑对黑客界产生了一定的影响，所以对关注黑客技术和网络安全的用户来说，这是一个可能感兴趣的新闻。"),
    Recommend(36791434,
        "Twenty.com是一个开源的CRM系统，它提供了一个集成的客户关系管理解决方案。对于需要管理客户关系的企业或个人来说，Twenty.com是一个很好的选择。它的开源性质还意味着用户可以根据自己的需求进行定制和扩展。"),
    Recommend(36790301,
        "斯坦福大学校长因操纵研究数据的行为辞职，并将撤销其发表的三篇论文。这件事引发了一场关于研究诚信和学术道德的讨论。对于关注科研诚信和学术道德的用户来说，这是一个可能感兴趣的新闻。"),
    Recommend(36794430,
        "LinkedIn采用了Google开源的协议缓冲区（Protocol Buffers），并将延迟降低了高达60%。这意味着用户可以更快地访问LinkedIn的服务。对于经常使用LinkedIn的用户来说，这是一个可能感兴趣的新闻。")
  ];

  static final prof = UserProfile(tags: ["旅游", "文学", "生活", "娱乐"]);

  static List<_Promoted> getPromoted() {
    return simplePrompted.mapMany((e) {
      News? item = hackerNews.firstWhereOrNull((element) {
        return element.id == e.id;
      });
      if (item == null) {
        return <_Promoted>[];
      }
      return [_Promoted(item, e.reason)];
    }).toList();
  }
}

class _Promoted {
  News news;
  String reason;

  _Promoted(this.news, this.reason);
}

class NewsWindow extends StatefulWidget {
  ChatRoomType ty;

  NewsWindow({super.key, required this.ty});

  @override
  State<NewsWindow> createState() => _NewsWindowState();
}

class _NewsWindowState extends State<NewsWindow>
    with BgTaskIndicatorExt<NewsWindow> {
  static bool webViewSupported() {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  String? _openedLink;
  String? _err;
  List<News> _news = [];
  List<_Promoted> _promoted_news = [];
  List<_Promoted> _all_promoted = [];

  AIContext get _ai_ctx {
    final settings = Get.find<SettingsController>();
    return AIContext(
        api_key: settings.openAiKey.value, model: settings.gptModel.value);
  }

  final WebViewController? _webctl =
      webViewSupported() ? WebViewController() : null;
  final EasyRefreshController _rfrctl = EasyRefreshController();
  int _web_load_progress = 0;

  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    _webctl?.setNavigationDelegate(NavigationDelegate(onProgress: (i) {
      setState(() {
        _web_load_progress = i;
      });
    }));
    runOneShotTask(() async {
      final news = await Get.find<NewsService>().cachedOrFetchTopNews(20);
      setState(() {
        _news = news;
      });
    }(), taskName: "Fetching hacker news for you...");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var panePriority = widget.ty == ChatRoomType.tablet
        ? TwoPanePriority.both
        : (_openedLink == null ? TwoPanePriority.start : TwoPanePriority.end);
    return Scaffold(
        appBar: appbar(enableGoBack: panePriority == TwoPanePriority.end),
        body: TwoPane(
          paneProportion: 0.3,
          startPane: bgTaskRunning
              ? Center(child: prog())
              : EasyRefresh(
                  controller: _rfrctl,
                  header: easyRefreshHeader,
                  onRefresh: () async {
                    await FirebaseAnalytics.instance
                        .logEvent(name: "refresh_news");
                    agiAccessible
                        ? promoteNews()
                        : Future.delayed(Duration(seconds: 3));
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    children: [
                      ...(_search.text.isEmpty ? _all_promoted : _promoted_news)
                          .map((e) => _PromotedCard(e,
                              onEnter: (promoted) =>
                                  {setUrl(promoted.news.url)})),
                      ..._news
                          .where((n) =>
                              !_all_promoted.any((p) => p.news.id == n.id))
                          .map((e) => _NewsCard(e,
                              onEnter: (news) => {setUrl(news.url)}))
                    ],
                  ),
                ),
          endPane: contentForWeb(),
          panePriority: panePriority,
        ));
  }

  bool get agiAccessible => !_ai_ctx.api_key.isEmpty;

  Header get easyRefreshHeader => agiAccessible
      ? ClassicHeader(
          triggerOffset: context.height / 5,
          dragText: "Drag down to ask AI pick some news for you!",
          armedText: "Release to let AI pick your favorite!",
          processingText: "AI is picking news for you...",
          readyText: "Here we go!",
          processedText: "Done!",
          failedText: "Oops...",
        )
      : ClassicHeader(
          triggerOffset: context.height,
          dragText: "AI isn't accessible, try to config the API key?",
          armedText: "Amazing! You did this. But nothing will happen.",
          processingText: "I have told you...",
          readyText: "Nothing will happen.",
          processedText: "Ya see?",
          failedText: "Oops...",
          pullIconBuilder: (ctx, state, offs) => const Icon(Icons.block),
        );

  bool get useInlineWebView => _webctl != null;

  Widget searchBar() => SearchBar(
        shape: const MaterialStatePropertyAll(RoundedRectangleBorder()),
        backgroundColor:
            MaterialStatePropertyAll(Theme.of(context).primaryColor),
        controller: _search,
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0)),
        textStyle:
            const MaterialStatePropertyAll(TextStyle(color: Colors.white)),
        trailing: [
          IconButton(
              onPressed: () async {
                await FirebaseAnalytics.instance.logEvent(
                    name: "search_news", parameters: {"query": _search.text});
                fillSearchResult();
              },
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              ))
        ],
      );

  AppBar appbar({
    enableGoBack = false,
    enableRefresh = true,
  }) {
    IconButton? goBack;
    if (enableGoBack) {
      goBack = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _openedLink = null;
            _err = null;
          });
          _webctl?.loadHtmlString("<html></html>");
        },
      );
    }
    var actions = useInlineWebView && _openedLink != null
        ? [
            IconButton(
                onPressed: () => {
                      launchUrl(
                          Uri.parse(
                            _openedLink!,
                          ),
                          mode: LaunchMode.externalApplication)
                    },
                icon: const Icon(Icons.open_in_browser))
          ]
        : <Widget>[];
    if (enableRefresh) {
      actions.add(IconButton(
          onPressed: () {
            fillSearchResult();
          },
          icon: Icon(Icons.refresh)));
    }
    var progress = _web_load_progress > 0
        ? PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: _web_load_progress.toDouble() / 100.0,
            ))
        : null;
    return AppBar(
        title: const Text("News"),
        leading: goBack,
        toolbarHeight: 40,
        foregroundColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 70, 70, 70),
        actions: actions,
        bottom: progress);
  }

  Widget contentForWeb() {
    if (useInlineWebView) {
      return WebViewWidget(controller: _webctl!);
    }
    if (_err != null) {
      return Center(
          child: Container(
              color: Colors.red,
              child: Text("Error: $_err",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))));
    }
    return const Center(
        child: Text("The URL will be open at external browser."));
  }

  Future<void> openUrl(String link) async {
    var url = Uri.parse(link);
    if (useInlineWebView) {
      _webctl!.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _webctl!.loadRequest(url);
      return;
    }
    if (!await launchUrl(url)) {
      throw Exception("failed to launch the message");
    }
  }

  setUrl(String link) async {
    try {
      openUrl(link);
      setState(() {
        _openedLink = link;
      });
    } catch (e) {
      setState(() {
        _err = e.toString();
      });
    }
  }

  Future<void> promoteNews() async {
    final promotedList = await NewsPromoter(_ai_ctx).promotNews(
        _TestData.prof,
        _news
            .map((e) => e.convertToJsonForRecommend())
            .toList(growable: false));
    var promotedFull = <_Promoted>[];
    var newNews = _news.where((element) {
      var recommend =
          promotedList.firstWhereOrNull((rec) => rec.id == element.id);
      if (recommend != null) {
        promotedFull.add(_Promoted(element, recommend.reason));
      }
      return recommend == null;
    }).toList(growable: false);
    setState(() {
      _all_promoted = [...promotedFull, ..._all_promoted];
      _promoted_news = promotedFull;
      _news = newNews;
    });
  }

  Future<void> fillSearchResult() async {
    final srv = Get.find<NewsService>();
    var topNews = await runOneShotTask(() async {
      await srv.refreshTopNews(20);
      return srv._cached;
    }(), taskName: "Refreshing the top news...");
    var newNews =
        topNews.where((news) => news.title.contains(_search.text)).toList();
    setState(() {
      _promoted_news = [];
      _news = newNews;
    });
  }
}

class _NewsCard extends StatelessWidget {
  final News _news;
  final void Function(News)? onEnter;

  const _NewsCard(this._news, {this.onEnter});

  @override
  Widget build(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => {},
          onTapUp: (details) => {onEnter?.call(_news)},
          child: ListTile(
            leading: _TestData.hackerNewsIcon,
            title: Text(_news.title),
            subtitle: Text(_news.content),
          ),
        ));
  }
}

class _PromotedCard extends StatelessWidget {
  final _Promoted _promoted;
  final void Function(_Promoted)? onEnter;

  const _PromotedCard(this._promoted, {this.onEnter});

  @override
  Widget build(BuildContext context) {
    var th = Theme.of(context);
    return Card(
        clipBehavior: Clip.antiAlias,
        color: th.primaryColor,
        child: InkWell(
          onTap: () => {},
          onTapUp: (details) => {onEnter?.call(_promoted)},
          child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                isThreeLine: true,
                leading: const Icon(
                  Icons.recommend,
                  color: Colors.white,
                ),
                title: Text(
                  _promoted.news.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _promoted.reason,
                  style: const TextStyle(
                      color: Colors.white, fontStyle: FontStyle.italic),
                ),
              )),
        ));
  }
}
