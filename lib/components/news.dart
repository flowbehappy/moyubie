import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:dual_screen/dual_screen.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:Moyubie/components/chat_room.dart';
import 'package:Moyubie/controller/settings.dart';
import 'package:Moyubie/repository/tags.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

import '../utils/ai_recommend.dart';

part 'news.g.dart';

@JsonSerializable()
class PromotedRecord {
  DateTime at;
  List<Promoted> records;

  PromotedRecord(this.at, this.records);

  factory PromotedRecord.fromJson(Map<String, dynamic> json) =>
      _$PromotedRecordFromJson(json);

  Map<String, dynamic> toJson() => _$PromotedRecordToJson(this);
}

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
      return const CircularProgressIndicator();
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
      this._task_text = taskName ?? "";
    });

    return await fut((x) {
      if (mounted) {
        setState(() {
          if (x < 0 || (_max != null && x > _max!)) {
            this._current = null;
            this._max = null;
            return;
          }
          this._current = x;
        });
      }
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

@JsonSerializable()
class News {
  _NewsSource source;
  int id;
  String title;
  String content;
  String url;

  News(this.source, this.id, this.url, this.title, this.content);

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);

  Map<String, dynamic> toJson() => _$NewsToJson(this);

  Map<String, dynamic> convertToJsonForRecommend() {
    return {
      "id": id,
      "title": title,
      "score_and_creator": content,
    };
  }
}

class AIFetchingTask {
  DateTime startedAt = DateTime.now();
  List<News> source;

  AIFetchingTask({required this.source});
}

class NewsController extends GetxController {
  final RxMap<String, AIFetchingTask> _pendingTasks = RxMap(HashMap());

  final RxList<News> _$cached = <News>[].obs;
  final RxList<PromotedRecord> _$record = <PromotedRecord>[].obs;
  final RxString _$aiKey;
  final RxString _$aiModel;
  final RxString _$err = "".obs;

  final _repo = Get.find<TagsRepository>();

  bool _inited = false;
  bool _loading = false;

  NewsController(this._$aiKey, this._$aiModel) {
    prefetch();
  }

  AIContext get _ai_ctx =>
      AIContext(api_key: _$aiKey.value, model: _$aiModel.value);

  int lastTab = 0;
  final _concurrency = 12;
  final _limit = 32;
  final _topStoriesId = Queue();
  final Map<int, News> _newsCache = HashMap(); // TODO： use LRU cache.

  Future<void> init() async {
    if (_inited) {
      return;
    }
    final items = await _repo.fetchPromoted();
    _$record.value = items.toList();
    _inited = true;
  }

  Future<void> savePromoted(PromotedRecord rec) async {
    _$record.add(rec);
    await _repo.savePromoted(rec);
  }

  List<PromotedRecord> get promoted {
    final l = _$record.toList(growable: false);
    // DESC ORDER.
    l.sort((a, b) => b.at.compareTo(a.at));
    return l;
  }

  Future<UserProfile> getUserTags() async {
    return UserProfile(
        tags: await Get.find<TagsRepository>().fetchMostPopularTags(5));
  }

  Future<void> prefetch() async {
    await pullTopNewsList(false);
    await prefetchNews(_limit);
  }

  Future<void> prefetchNews(int limit) async {
    var stories = _topStoriesId.take(limit);
    for (var id in stories) {
      if (_newsCache.containsKey(id)) {
        continue;
      }
      var news = await getNewsById(id);
      if (news != null) {
        _newsCache[id] = news;
      }
    }
  }

  Future<List<dynamic>> getTopNewsList(int limit) async {
    if (_topStoriesId.isEmpty) {
      await pullTopNewsList(false);
    }

    var res = <dynamic>[].obs;
    for (var i = 0; i < limit && _topStoriesId.isNotEmpty; i++) {
      res.add(_topStoriesId.removeFirst());
    }

    if (_topStoriesId.length < limit * 3) {
      pullTopNewsList(false);
    }

    log("Get top news list: $res", name: "NewsController");
    return res;
  }

  Future<void> pullTopNewsList(bool clear) async {
    if (clear) {
      _topStoriesId.clear();
    }
    var topStories = 'https://hacker-news.firebaseio.com/v0/topstories.json';
    var uri = Uri.parse(topStories);
    var response = await http.get(
      uri,
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      var topStoriesId = json.decode(response.body) as List<dynamic>;
      log("Pull top news list: $topStoriesId", name: "NewsController");
      _topStoriesId.addAll(topStoriesId);
    } else {
      throw Exception('Failed to pull top news list');
    }
  }

  Future<void> refreshTopNewsOptimized(int firstScreenLimit) async {
    await refreshTopNews(firstScreenLimit);
    refreshTopNews(_limit - firstScreenLimit, append: true);
  }

  Future<void> refreshTopNews(int limit, {bool append = false}) async {
    var news_list = <News>[];
    var futs = ListQueue();

    var topStoriesId = await getTopNewsList(limit);
    for (var id in topStoriesId) {
      var cachedNews = _newsCache[id];
      if (cachedNews != null) {
        news_list.add(cachedNews);
        continue;
      }

      if (futs.length > _concurrency) {
        final news = await futs.removeFirst();
        if (news != null) {
          news_list.add(news);
        }
      }

      futs.add(() async {
        return await getNewsById(id);
      }());
    }

    for (var fut in futs) {
      final news = await fut;
      if (news != null) {
        news_list.add(news);
      }
    }

    if (append) {
      _$cached.value = [..._$cached, ...news_list];
    } else {
      _$cached.value = news_list;
    }

    prefetchNews(_limit);
  }

  Future<News?> getNewsById(int id) async {
    var url = 'https://hacker-news.firebaseio.com/v0/item/$id.json';
    var uri = Uri.parse(url);
    var response = await http.get(
      uri,
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      var newsJson = json.decode(response.body);
      if (newsJson == null || newsJson['url'] == null) {
        return null;
      }
      var id = newsJson['id'];
      log("Get news by id: $id", name: "NewsController");
      return News(
          _NewsSource.HackerNews,
          newsJson['id'],
          newsJson['url'],
          newsJson['title'],
          "${newsJson["score"]} scores by ${newsJson["by"]}");
    } else {
      // log("Failed to get news by id: $id", name: "NewsController");
      return null;
    }
  }

  Future<List<News>> cachedOrFetchTopNews(int firstScreenLimit) async {
    if (_$cached.length < firstScreenLimit && !_loading) {
      _loading = true;
      try {
        await refreshTopNewsOptimized(firstScreenLimit);
      } finally {
        _loading = false;
      }
    }
    return _$cached;
  }

  Future<PromotedRecord> recommendNews(List<News> news,
      {UserProfile? profile}) async {
    final id = const Uuid().v4();
    _pendingTasks[id] = AIFetchingTask(source: news);
    try {
      final currentPromoted =
          this.promoted.mapMany((e) => e.records.map((e) => e.news.id)).toSet();
      final userProfile = profile ?? await getUserTags();
      final promotedList = await NewsPromoter(_ai_ctx).promoteNews(
          userProfile,
          news
              .where((element) => !currentPromoted.contains(element.id))
              .map((e) => e.convertToJsonForRecommend())
              .toList(growable: false));
      var promotedFull = news.mapMany((element) {
        var recommend =
            promotedList.firstWhereOrNull((rec) => rec.id == element.id);
        if (recommend != null) {
          return [Promoted(element, recommend.reason)];
        }
        return <Promoted>[];
      }).toList(growable: false);
      final promoted = PromotedRecord(DateTime.now(), promotedFull);
      await savePromoted(promoted);
      return promoted;
    } catch (e) {
      if (e is RequestFailedException) {
        _$err.value = e.message;
      } else {
        _$err.value = e.toString();
      }
      rethrow;
    } finally {
      _pendingTasks.remove(id);
    }
  }

  void dismissError() {
    _$err.value = "";
  }

  List<AIFetchingTask> pendingTasks() {
    return _pendingTasks.values.toList(growable: false);
  }
}

@JsonSerializable()
class Promoted {
  News news;
  String reason;

  Promoted(this.news, this.reason);

  factory Promoted.fromJson(Map<String, dynamic> json) =>
      _$PromotedFromJson(json);

  Map<String, dynamic> toJson() => _$PromotedToJson(this);
}

class NewsWindow extends StatefulWidget {
  ChatRoomType ty;

  NewsWindow({super.key, required this.ty});

  @override
  State<NewsWindow> createState() => _NewsWindowState();
}

class _NewsWindowState extends State<NewsWindow>
    with BgTaskIndicatorExt<NewsWindow>, TickerProviderStateMixin {
  static bool webViewSupported() {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  String? _opened_link;
  String? _err;

  bool _calledPromote = false;
  final _firstScreenNewsLimit =
      12; // TODO: get the limit according to screen height.

  _NewsWindowState();

  late NewsController _srv;
  late List<Key> _tab_key;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();

  AIContext get _ai_ctx {
    final settings = Get.find<SettingsController>();
    return AIContext(
        api_key: settings.openAiKey.value, model: settings.gptModel.value);
  }

  final WebViewController? _webctl =
      webViewSupported() ? WebViewController() : null;
  final EasyRefreshController _rfrctl = EasyRefreshController();
  late final TabController _tabctl;
  int _web_load_progress = 0;

  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _tabctl.removeListener(onTabChanged);
    super.dispose();
  }

  @override
  void initState() {
    _tab_key = Iterable.generate(2, (i) => GlobalKey()).toList();
    _srv = Get.find<NewsController>();
    _srv.init();
    _webctl?.setNavigationDelegate(NavigationDelegate(onProgress: (i) {
      if (mounted && _opened_link != null) {
        setState(() {
          _web_load_progress = i;
        });
      }
    }));
    _tabctl = TabController(initialIndex: _srv.lastTab, length: 2, vsync: this);
    _tabctl.addListener(onTabChanged);
    onTabChanged(force: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var panePriority =
        (_opened_link == null ? TwoPanePriority.start : TwoPanePriority.end);
    return TwoPane(
      paneProportion: 0.3,
      startPane: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
            appBar: appbar(),
            body: TabBarView(controller: _tabctl, children: [
              bgTaskRunning
                  ? prog()
                  : EasyRefresh(
                      key: _tab_key[0],
                      controller: _rfrctl,
                      header: refreshHeader,
                      onRefresh: () async {
                        FirebaseAnalytics.instance
                            .logEvent(name: "refresh_news");
                        await refreshNews(_firstScreenNewsLimit);
                      },
                      child: Obx(
                        () => ListView(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          children: [
                            ..._srv._$cached.map((e) => _NewsCard(e,
                                onEnter: (news) => {setUrl(news.url)}))
                          ],
                        ),
                      )),
              bgTaskRunning
                  ? prog()
                  : EasyRefresh(
                      key: _tab_key[1],
                      controller: _rfrctl,
                      header: aiPromoteHeader,
                      onRefresh: () async {
                        try {
                          FirebaseAnalytics.instance
                              .logEvent(name: "promote_news");
                          await promoteNews();
                        } catch (e, stack) {
                          if (kDebugMode) {
                            stack.printError(
                                info: "promote_news::error::stacktrace");
                          }
                          maybeShowBannerForError();
                          return IndicatorResult.fail;
                        }
                      },
                      child: Obx(
                        () => _srv.pendingTasks().isEmpty &&
                                _srv._$record.isEmpty
                            ? ListView(children: const [
                                ListTile(
                                    title: Text(
                                      "Yet nothing here.",
                                    ),
                                    subtitle: Text(
                                        "Drag down to let AI select some news for you.")),
                              ])
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                children: [
                                  if (_srv._pendingTasks.isNotEmpty &&
                                      !_calledPromote)
                                    _PendingCard(_srv.pendingTasks()),
                                  ..._srv.promoted.map((e) => _PromotedGroup(
                                      record: e,
                                      onEnter: (promoted) =>
                                          {setUrl(promoted.news.url)})),
                                ],
                              ),
                      )),
            ])),
      ),
      endPane: contentForWeb(),
      panePriority: panePriority,
    );
  }

  @override
  void deactivate() {
    _calledPromote = false;
    super.deactivate();
  }

  bool get agiAccessible => _ai_ctx.api_key.isNotEmpty;

  Header get refreshHeader => const ClassicHeader(
      dragText: "Drag down to fetch some news!",
      armedText: "Release to fetch some news!",
      processingText: "We are gathering news for you...",
      readyText: "Here we go!",
      processedText: "Done!",
      failedText: "Oops...",
      textStyle: TextStyle(overflow: TextOverflow.ellipsis));

  Header get aiPromoteHeader => agiAccessible
      ? const ClassicHeader(
          dragText: "Drag down to ask AI pick some news for you!",
          armedText: "Release to let AI pick your favorite!",
          processingText: "AI is picking news for you...",
          readyText: "Here we go!",
          processedText: "Done!",
          failedText: "Oops...",
          textStyle: TextStyle(overflow: TextOverflow.ellipsis))
      : ClassicHeader(
          triggerOffset: context.height,
          dragText: "AI isn't accessible, try to config the API key?",
          armedText: "Amazing! You did this. But nothing will happen.",
          processingText: "I have told you...",
          readyText: "Nothing will happen.",
          processedText: "Ya see?",
          failedText: "Oops...",
          textStyle: const TextStyle(overflow: TextOverflow.ellipsis),
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
                FirebaseAnalytics.instance.logEvent(
                    name: "search_news", parameters: {"query": _search.text});
                await refreshNews(_firstScreenNewsLimit);
              },
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              ))
        ],
      );

  AppBar browserAppBar() {
    final goBack = IconButton(
      icon: const Icon(Icons.close),
      onPressed: () {
        setState(() {
          _opened_link = null;
          _err = null;
        });
        _webctl?.loadHtmlString("<html></html>");
      },
    );
    final bottom = PreferredSize(
        preferredSize: const Size.fromHeight(4.0),
        child: LinearProgressIndicator(
          value: _web_load_progress.toDouble() / 100.0,
        ));
    final actions = [
      IconButton(
          onPressed: () => {
                launchUrl(
                    Uri.parse(
                      _opened_link!,
                    ),
                    mode: LaunchMode.externalApplication)
              },
          icon: const Icon(Icons.open_in_browser))
    ];
    return AppBar(
        leading: goBack,
        toolbarHeight: 40,
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 70, 70, 70),
        actions: actions,
        bottom: bottom);
  }

  AppBar appbar() {
    var bottom = TabBar(
      tabs: const <Widget>[
        Tab(icon: Icon(Icons.newspaper)),
        Tab(icon: Icon(Icons.recommend)),
      ],
      controller: _tabctl,
    );
    return AppBar(
        title: const Text("News"),
        toolbarHeight: 40,
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 70, 70, 70),
        bottom: bottom);
  }

  Widget contentForWeb() {
    if (useInlineWebView) {
      return Scaffold(
          appBar: browserAppBar(), body: WebViewWidget(controller: _webctl!));
    }
    if (_err != null) {
      return Center(
          child: Container(
              color: Colors.red,
              child: Text("Error: $_err",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))));
    }
    return Center(
        child: Container(
      width: 480,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "WebView not supported in this platform. The URL will be opened in external browser.",
              style: Theme.of(context).textTheme.titleMedium),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
              initialValue: _opened_link ?? "",
              readOnly: true,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                  onPressed: () {
                    setState(() {
                      _opened_link = null;
                      _err = null;
                    });
                  },
                  child: Text(
                    "GO BACK",
                    style: Theme.of(context).textTheme.labelMedium,
                  )),
            ],
          )
        ],
      ),
    ));
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

  void maybeShowBannerForError() {
    final mgr = _scaffoldKey;
    if (_scaffoldKey.currentWidget == null) {
      return;
    }
    if (_srv._$err.isEmpty) {
      mgr.currentState?.clearMaterialBanners();
      return;
    }
    final banner = MaterialBanner(
        leading: const Icon(Icons.error, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: Text(
          _srv._$err.value,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _srv.dismissError();
              maybeShowBannerForError();
            },
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
          )
        ],
        shadowColor: Theme.of(context).shadowColor,
        backgroundColor: Theme.of(context).colorScheme.error);
    mgr.currentState?.showMaterialBanner(banner);
  }

  setUrl(String link) async {
    try {
      openUrl(link);
      setState(() {
        _opened_link = link;
      });
    } catch (e) {
      setState(() {
        _err = e.toString();
      });
    }
  }

  Future<void> promoteNews() async {
    _calledPromote = true;
    await _srv.recommendNews(_srv._$cached);
    maybeShowBannerForError();
  }

  Future<void> refreshNews(int firstScreenLimit) async {
    await _srv.refreshTopNewsOptimized(firstScreenLimit);
    maybeShowBannerForError();
  }

  void onTabChanged({bool force = false}) async {
    if (!_tabctl.indexIsChanging && !force) {
      return;
    }
    _srv.lastTab = _tabctl.index;
    if (_tabctl.index == 0 && !bgTaskRunning) {
      runOneShotTask(() async {
        await _srv.cachedOrFetchTopNews(_firstScreenNewsLimit);
      }());
      return;
    }
  }
}

class _NewsCard extends StatelessWidget {
  final Key? key;
  final News _news;
  final void Function(News)? onEnter;

  const _NewsCard(this._news, {this.onEnter, this.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        key: key,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => {},
          onTapUp: (details) => {onEnter?.call(_news)},
          child: ListTile(
            leading: const Icon(Icons.newspaper),
            title: Text(_news.title),
            subtitle: Text(_news.content),
          ),
        ));
  }
}

class _PendingCard extends StatelessWidget {
  List<AIFetchingTask> _task;

  _PendingCard(this._task);

  @override
  Widget build(BuildContext context) {
    var th = Theme.of(context);
    return Card(
        key: key,
        clipBehavior: Clip.antiAlias,
        color: th.primaryColor,
        child: Container(
            child: ListTile(
          subtitle: Container(
            child: LinearProgressIndicator(
              color: Colors.white,
              backgroundColor: th.primaryColor,
            ),
            margin: const EdgeInsets.only(top: 8),
          ),
          title: Text(
            "We are still longing for ${_task.length} response(s)...",
            style: (th.textTheme.labelLarge ?? const TextStyle())
                .merge(const TextStyle(color: Colors.white)),
          ),
        )));
  }
}

class _PromotedGroup extends StatelessWidget {
  final PromotedRecord record;
  final void Function(Promoted)? onEnter;

  const _PromotedGroup({required this.record, this.onEnter});

  @override
  Widget build(BuildContext context) {
    final ts = record.at;
    return Column(children: [
      Container(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            child: Row(
              children: [
                Text(
                  timeago.format(ts).capitalizeFirst!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Expanded(
                    child: Divider(
                  indent: 8,
                  endIndent: 8,
                  height: 30,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                )),
              ],
            ),
          )),
      ...record.records.map((e) => _PromotedCard(e, onEnter: onEnter))
    ]);
  }
}

class _PromotedCard extends StatelessWidget {
  final Key? key;
  final Promoted _promoted;
  final void Function(Promoted)? onEnter;

  const _PromotedCard(this._promoted, {this.onEnter, this.key});

  @override
  Widget build(BuildContext context) {
    var th = Theme.of(context);
    return Card(
        key: key,
        clipBehavior: Clip.antiAlias,
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
                ),
                title: Text(
                  _promoted.news.title,
                ),
                subtitle: Text(
                  _promoted.reason,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              )),
        ));
  }
}
