import 'dart:io';

import 'package:dual_screen/dual_screen.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moyubie/components/chat_room.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/ai_recommend.dart';

enum _NewsSource { HackerNews }

class _News {
  _NewsSource source;
  int id;
  String title;
  String content;
  String url;

  _News(this.source, this.id, this.url, this.title, this.content);

  Map<String, dynamic> convertToJsonForRecommend() {
    return {
      "id": id,
      "title": title,
      "score_and_creator": content,
    };
  }
}

class _TestData {
  static final hackerNews = [
    _News(
        _NewsSource.HackerNews,
        36799548,
        "https://anytype.io/?hn",
        "Anytype – open-source, local-first, P2P Notion alternative",
        "104 scores by TTTZ"),
    _News(
        _NewsSource.HackerNews,
        36799776,
        "https://github.com/bartobri/no-more-secrets",
        "No-more-secrets: recreate the decryption effect seen in the 1992 movie Sneakers",
        "66 scores by tambourine_man"),
    _News(
        _NewsSource.HackerNews,
        36795173,
        "https://www.dignitymemorial.com/obituaries/las-vegas-nv/kevin-mitnick-11371668",
        "Kevin Mitnick has died",
        "2937 scores by thirtyseven"),
    _News(
        _NewsSource.HackerNews,
        36800041,
        "https://www.projectaria.com/datasets/adt/",
        "Project Aria 'Digital Twin' Dataset by Meta",
        "20 scores by socratic1"),
    _News(
        _NewsSource.HackerNews,
        36798593,
        "https://github.com/docusealco/docuseal",
        "Docuseal: Open-source DocuSign alternative. Create, fill, sign digital documents",
        "161 scores by thunderbong"),
    _News(
        _NewsSource.HackerNews,
        36798774,
        "https://github.com/Swordfish90/cool-retro-term",
        "Cool Retro Terminal",
        "86 scores by qazpot"),
    _News(
        _NewsSource.HackerNews,
        36800151,
        "https://www.jefftk.com/p/accidentally-load-bearing",
        "Accidentally Load Bearing",
        "11 scores by jamessun"),
    _News(
        _NewsSource.HackerNews,
        36798157,
        "https://developer.mozilla.org/en-US/play",
        "MDN Playground",
        "127 scores by weinzierl"),
    _News(
        _NewsSource.HackerNews,
        36799283,
        "https://up.codes/careers",
        "UpCodes (YC S17) is hiring a Growth Marketer to make construction efficient",
        "1 scores by Old_Thrashbarg"),
    _News(
        _NewsSource.HackerNews,
        36798864,
        "https://github.com/Fadi002/unshackle",
        "Unshackle: A tool to bypass windows password logins",
        "42 scores by AdvDebug"),
    _News(
        _NewsSource.HackerNews,
        36798842,
        "https://www.pathsensitive.com/2018/02/the-practice-is-not-performance-why.html",
        "Why project-based learning fails (2018)",
        "33 scores by jger15"),
    _News(
        _NewsSource.HackerNews,
        36799628,
        "https://giannirosato.com/blog/post/jpegli-xyb/",
        "XYB JPEG: Perceptual Color Encoding Tested",
        "15 scores by computerbuster"),
    _News(
        _NewsSource.HackerNews,
        36798997,
        "https://projects.osmocom.org/projects/foss-ims-client/wiki/Wiki",
        "Open Source IMS Client",
        "16 scores by McDyver"),
    _News(
        _NewsSource.HackerNews,
        36799073,
        "https://viterbischool.usc.edu/news/2023/07/teaching-robots-to-teach-other-robots/",
        "AI That Teaches Other AI",
        "13 scores by geox"),
    _News(
        _NewsSource.HackerNews,
        36778309,
        "https://en.wikipedia.org/wiki/Glossary_of_Japanese_words_of_Portuguese_origin",
        "Japanese words of Portuguese origin",
        "181 scores by lermontov"),
    _News(
        _NewsSource.HackerNews,
        36798092,
        "https://dolphin-emu.org/blog/2023/07/20/what-happened-to-dolphin-on-steam/",
        "What Happened to Dolphin on Steam?",
        "116 scores by panic"),
    _News(
        _NewsSource.HackerNews,
        36791936,
        "https://daily.jstor.org/delts-dont-lie/",
        "Delts Don’t Lie",
        "48 scores by fnubbly"),
    _News(
        _NewsSource.HackerNews,
        36798051,
        "https://chromium.googlesource.com/chromiumos/docs/+/HEAD/development_basics.md#programming-languages-and-style",
        "ChromiumOS Developer Guide, Programming languages and style",
        "48 scores by pjmlp"),
    _News(_NewsSource.HackerNews, 36799221, "https://taylor.town/secret-sauce",
        "Spoil Your Secret Sauce", "9 scores by surprisetalk"),
    _News(_NewsSource.HackerNews, 36798826, "https://pdfdiffer.com/",
        "Show HN: PDF Differ", "20 scores by m4rc1e"),
    _News(_NewsSource.HackerNews, 36798854, "https://sive.rs/pnt",
        "The past is not true", "85 scores by swah"),
    _News(
        _NewsSource.HackerNews,
        36790301,
        "https://stanforddaily.com/2023/07/19/stanford-president-resigns-over-manipulated-research-will-retract-at-least-3-papers/",
        "Stanford president resigns over manipulated research, will retract 3 papers",
        "1339 scores by dralley"),
    _News(
        _NewsSource.HackerNews,
        36768334,
        "https://github.com/InderdeepBajwa/gitid",
        "Use multiple Git SSH identities on a single computer",
        "43 scores by inderdeepbajwa"),
    _News(
        _NewsSource.HackerNews,
        36799235,
        "https://www.bloomberg.com/news/articles/2023-07-19/wall-street-shrinks-ranks-by-21-000-amid-deals-trading-slump",
        "Wall Street Shrinks Headcount by 21,000 as Dealmaking and Trading Slump",
        "37 scores by haltingproblem"),
    _News(
        _NewsSource.HackerNews,
        36794756,
        "https://www.youtube.com/watch?v=6-3BFXpBcjc",
        "The Danger of Popcorn Polymer: Incident at the TPC Group Chemical Plant [video]",
        "172 scores by oatmeal1"),
    _News(
        _NewsSource.HackerNews,
        36794430,
        "https://www.infoq.com/news/2023/07/linkedin-protocol-buffers-restli/",
        "LinkedIn adopts protocol buffers and reduces latency up to 60%",
        "164 scores by ijidak"),
    _News(
        _NewsSource.HackerNews,
        36799700,
        "https://www.theguardian.com/us-news/2023/jul/20/toxic-flame-retardants-human-breast-milk",
        "Flame retardant found in US breast milk",
        "12 scores by geox"),
    _News(
        _NewsSource.HackerNews,
        36798850,
        "https://www.washingtonpost.com/wellness/2023/07/19/hearing-loss-hearing-aids-dementia-study/",
        "Hearing aids may cut risk of cognitive decline by nearly half",
        "48 scores by maxutility"),
    _News(
        _NewsSource.HackerNews,
        36799600,
        "https://www.nytimes.com/2023/07/19/business/google-artificial-intelligence-news-articles.html",
        "Google Tests A.I. Tool That Is Able to Write News Articles",
        "12 scores by asnyder"),
    _News(
        _NewsSource.HackerNews,
        36771331,
        "https://www.infoq.com/news/2023/07/yelp-corrupted-cassandra-rebuild/",
        "Yelp rebuilds corrupted Cassandra cluster using its data streaming architecture",
        "83 scores by rgancarz"),
    _News(
        _NewsSource.HackerNews,
        36800196,
        "https://www.theregister.com/2023/07/20/cerebras_condor_galaxy_supercomputer/",
        "Cerebras's Condor Galaxy AI supercomputer takes flight carrying 36 exaFLOPS",
        "4 scores by rntn"),
    _News(
        _NewsSource.HackerNews,
        36799059,
        "https://asia.nikkei.com/Business/Tech/Semiconductors/TSMC-delays-U.S.-chip-plant-start-to-2025-due-to-labor-shortages",
        "TSMC delays U.S. chip plant start to 2025 due to labor shortages",
        "66 scores by ironyman"),
    _News(
        _NewsSource.HackerNews,
        36797079,
        "https://github.com/Maknee/minigpt4.cpp",
        "Minigpt4 Inference on CPU",
        "89 scores by maknee"),
    _News(
        _NewsSource.HackerNews,
        36771114,
        "https://www.oreilly.com/radar/teaching-programming-in-the-age-of-chatgpt/",
        "Teaching Programming in the Age of ChatGPT",
        "135 scores by headalgorithm"),
    _News(
        _NewsSource.HackerNews,
        36780999,
        "https://phys.org/news/2023-07-tidal-disruption-event-chinese-astronomers.html",
        "New tidal disruption event discovered by Chinese astronomers",
        "23 scores by wglb"),
    _News(
        _NewsSource.HackerNews,
        36796422,
        "https://github.com/mbnuqw/sidebery",
        "Sidebery – A Firefox extension for managing tabs and bookmarks in sidebar",
        "146 scores by BafS"),
    _News(
        _NewsSource.HackerNews,
        36797178,
        "https://lists.freebsd.org/archives/freebsd-announce/2023-July/000076.html",
        "In Memoriam: Hans Petter William Sirevåg Selasky",
        "100 scores by stargrave"),
    _News(
        _NewsSource.HackerNews,
        36798395,
        "https://en.wikipedia.org/wiki/Vacuum_airship",
        "Vacuum airship",
        "61 scores by guerrilla"),
    _News(
        _NewsSource.HackerNews,
        36777096,
        "https://bigthink.com/the-past/kunga-first-hybrid-animal/",
        "Kunga: Ancient Mesopotamians created the world’s first hybrid animal",
        "34 scores by diodorus"),
    _News(
        _NewsSource.HackerNews,
        36797231,
        "https://arstechnica.com/science/2023/07/new-slow-repeating-radio-source-we-have-no-idea-what-it-is/",
        "Something in space has been lighting up every 20 minutes since 1988",
        "120 scores by Brajeshwar"),
    _News(
        _NewsSource.HackerNews,
        36782638,
        "https://www.transportation.gov/pnt/what-radio-spectrum",
        "What Is Radio Spectrum?",
        "46 scores by ZunarJ5"),
    _News(
        _NewsSource.HackerNews,
        36800009,
        "https://arstechnica.com/information-technology/2023/07/ars-on-aws-01/",
        "Behind the scenes: How we host Ars Technica, part 1",
        "4 scores by pseudolus"),
    _News(
        _NewsSource.HackerNews,
        36799461,
        "https://shkspr.mobi/blog/2023/07/keeping-a-side-project-alive-with-t-shirts-and-cash/",
        "Keeping a side project alive with t-shirts and cash",
        "8 scores by edent"),
    _News(
        _NewsSource.HackerNews,
        36793022,
        "https://www.sharbonline.com/fun-stuff/card-games/complex-hearts/",
        "Complex Hearts",
        "21 scores by pcwalton"),
    _News(
        _NewsSource.HackerNews,
        36782201,
        "https://jazz-library.com/articles/comping/",
        "Jazz Comping (2021)",
        "111 scores by RickHull"),
    _News(
        _NewsSource.HackerNews,
        36798408,
        "https://hothardware.com/news/intel-14thgen-core-k-cpu-spec-leak",
        "Intel's 14th Gen Core K-Series CPU Specs Break Cover with Speeds Up to 6GHz",
        "25 scores by rbanffy"),
    _News(
        _NewsSource.HackerNews,
        36796685,
        "https://acl2023-retrieval-lm.github.io/",
        "ACL 2023 Tutorial: Retrieval-Based Language Models and Applications",
        "17 scores by TalktoCrystal"),
    _News(
        _NewsSource.HackerNews,
        36798496,
        "https://blog.google/technology/safety-security/googles-ai-red-team-the-ethical-hackers-making-ai-safer/",
        "Google Introduces AI Red Team",
        "5 scores by bhattmayurshiv"),
    _News(
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

  static List<_Promoted> getPromoted() {
    return simplePrompted.mapMany((e) {
      _News? item = hackerNews.firstWhereOrNull((element) {
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
  _News news;
  String reason;

  _Promoted(this.news, this.reason);
}

class NewsWindow extends StatefulWidget {
  ChatRoomType ty;

  NewsWindow({super.key, required this.ty});

  @override
  State<NewsWindow> createState() => _NewsWindowState();
}

class _NewsWindowState extends State<NewsWindow> {
  static bool webViewSupported() {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  String? _openedLink;
  String? _err;
  List<_News> _news = _TestData.hackerNews.toList();
  List<_Promoted> _promoted_news = [];
  List<_Promoted> _all_promoted = [];

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
          startPane: Column(
            children: [
              Container(
                  child: SearchBar(
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
                      onPressed: () {
                        fillSearchResult();
                      },
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ))
                ],
              )),
              Expanded(
                child: EasyRefresh(
                  controller: _rfrctl,
                  header: ClassicHeader(
                    triggerOffset: context.height / 5,
                    dragText: "Drag down to ask AI pick some news for you!",
                    armedText: "Release to let AI pick your favorite!",
                    processingText: "AI is picking news for you...",
                    readyText: "Here we go!",
                    processedText: "Done!",
                    failedText: "Oops...",
                  ),
                  onRefresh: () => promoteNews(_news),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    children: [
                      ...(_search.text.isEmpty ? _all_promoted : _promoted_news)
                          .map((e) => _PromotedCard(e)),
                      ..._news.map((e) =>
                          _NewsCard(e, on_enter: (news) => {setUrl(news.url)}))
                    ],
                  ),
                ),
              ),
            ],
          ),
          endPane: contentForWeb(),
          panePriority: panePriority,
        ));
  }

  bool get useInlineWebView => _webctl != null;

  AppBar appbar({enableGoBack = false}) {
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
    var progress = _web_load_progress > 0
        ? PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: _web_load_progress.toDouble() / 100.0,
            ))
        : null;
    return AppBar(
        leading: goBack,
        title: const Text("News"),
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
    return const Center(child: Text("The URL will be open at external browser."));
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

  promoteNews(List<_News> cnd) async {
    await Future.delayed(const Duration(seconds: 1));
    const promotedList = _TestData.simplePrompted;
    var promotedFull = <_Promoted>[];
    var newNews = cnd.where((element) {
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

  fillSearchResult() async {
    var newNews = _TestData.hackerNews.where((news) => news.title.contains(_search.text)).toList();
    setState(() {
      _promoted_news = [];
      _news = newNews;
    });
  }
}

class _NewsCard extends StatelessWidget {
  final _News _news;
  final void Function(_News)? on_enter;

  const _NewsCard(this._news, {this.on_enter});

  @override
  Widget build(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => {},
          onTapUp: (details) => {on_enter?.call(_news)},
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

  const _PromotedCard(this._promoted);

  @override
  Widget build(BuildContext context) {
    var th = Theme.of(context);
    return Card(
        clipBehavior: Clip.antiAlias,
        color: th.primaryColor,
        child: InkWell(
          onTap: () => {},
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                isThreeLine: true,
                leading: const Icon(
                  Icons.star,
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
