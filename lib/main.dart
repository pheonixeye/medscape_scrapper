// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
// import 'dart:io';

import 'package:chaleno/chaleno.dart';
import 'package:console_bars/console_bars.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:starter_template/models/med_article.dart';
import 'package:uuid/uuid.dart';

// final _url = Platform.environment["BASE_POCKETBASE_URL"]!;

final _medscapeUrl = "https://www.medscape.com/index/list_13470_";
final _url = "https://server-proklinik.fly.dev/";
final _pb = PocketBase(_url);

// final String _medscapeUrl = Platform.environment["MEDSCAPE_URL"]!;

Future<dynamic> main(final context) async {
  final deleteBar = FillingBar(
    desc: "Deleting Old Articles",
    total: 100,
    time: true,
    fill: '*',
    percentage: true,
  );
  final currentArticles =
      await _pb.collection("medscape").getFullList(batch: 100);
  for (var article in currentArticles) {
    await _pb.collection("medscape").delete(article.id);
    deleteBar.increment();
  }

  final scrappingBar = FillingBar(
    desc: "Scrapping Articles",
    total: 100,
    time: true,
    percentage: true,
  );

  List<Result> _results = [];
  for (var i = 0; i < 5; i++) {
    final String _medUrl = "$_medscapeUrl$i";
    await Chaleno().load(_medUrl).then((p) {
      for (var i = 1; i < 21; i++) {
        final res = p?.querySelector("#archives > ul > li:nth-child($i)");
        if (res != null) {
          _results.add(res);
          scrappingBar.increment();
        }
      }
    });
  }
  // print("${_results.map((e) => e.html).toList()}");
  final _articles = _results.map((e) {
    final url = e.querySelector("a")?.href;
    final title = e.querySelector(".title")?.innerHTML;
    final teaser = e.querySelector("span")?.text;
    final from = e.querySelector(".byline")?.text;

    return MedArticle(
        id: const Uuid().v4(),
        title: title ?? "",
        teaser: teaser ?? "",
        url: url ?? "",
        from: from ?? "");
  }).toList();

  final uploadingBar = FillingBar(
    desc: "Uploading Articles",
    total: 100,
    time: true,
    fill: '↑',
    percentage: true,
  );
  for (final article in _articles) {
    await _pb.collection("medscape").create(body: article.toJson());
    uploadingBar.increment();
  }
}
