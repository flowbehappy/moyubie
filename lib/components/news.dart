import 'package:flutter/material.dart';

enum _NewsSource { HackerNews }

class _News {
  _NewsSource source;
  String title;
  String content;

  _News(this.source, this.title, this.content);
}

class _TestData {
  static final hackerNews = [
    _News(
        _NewsSource.HackerNews,
        "Bookwyrm – the federated social network for reading books",
        "126 points by susanthenerd"),
    _News(
        _NewsSource.HackerNews,
        "NeetoCal, a calendly alternative, is a commodity and is priced accordingly",
        "64 points by jasim"),
    _News(
        _NewsSource.HackerNews,
        "Advanced Python Mastery – A Course by David Beazley",
        "74 points by a_bonobo"),
    _News(_NewsSource.HackerNews, "Tachyons – A CSS Toolkit",
        "12 points by impoppy"),
    _News(
        _NewsSource.HackerNews,
        "Kangaroo tendons could rebuild human knees better, stronger",
        "39 points by geox"),
    _News(
        _NewsSource.HackerNews,
        "The global fight for critical minerals is costly and damaging",
        "32 points by headalgorithm"),
    _News(
        _NewsSource.HackerNews,
        "Senators to Propose Ban on U.S. Lawmakers, Executive Branch Members Owning Stock",
        "116 points by mfiguiere"),
    _News(
        _NewsSource.HackerNews,
        "ASUS agrees to manufacture and sell Intel’s NUC products",
        "424 points by mepian"),
    _News(_NewsSource.HackerNews, "Netscape and Sun announce JavaScript (1995)",
        "222 points by damethos"),
    _News(
        _NewsSource.HackerNews,
        "Lazygit: Simple terminal UI for Git commands",
        "135 points by thunderbong")
  ];

  static const hackerNewsIcon =
      ImageIcon(AssetImage("hackernews_icon.jpeg"), color: Colors.transparent);
}

class NewsWindow extends StatefulWidget {
  const NewsWindow({super.key});

  @override
  State<NewsWindow> createState() => _NewsWindowState();
}

class _NewsWindowState extends State<NewsWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("News")),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          children: _TestData.hackerNews.map((e) => _NewsCard(e)).toList()),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final _News _news;

  const _NewsCard(this._news);

  @override
  Widget build(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
        onTap: () => {},
        child: ListTile(
          leading: _TestData.hackerNewsIcon,
          title: Text(_news.title),
          subtitle: Text(_news.content),
      ),
    ));
  }
}
