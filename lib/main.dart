// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:chaleno/chaleno.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:starter_template/models/med_article.dart';
import 'package:uuid/uuid.dart';

final _url = String.fromEnvironment("BASE_POCKETBASE_URL");

final _pb = PocketBase(_url);

const String _medscapeUrl = String.fromEnvironment("MEDSCAPE_URL");

Future<dynamic> main(final context) async {
  final currentArticles =
      await _pb.collection("medscape").getFullList(batch: 100);
  for (var article in currentArticles) {
    await _pb.collection("medscape").delete(article.id);
  }

  List<Result> _results = [];
  for (var i = 0; i < 5; i++) {
    final String _medUrl = "$_medscapeUrl$i";
    await Chaleno().load(_medUrl).then((p) {
      for (var i = 1; i < 21; i++) {
        final res = p?.querySelector("#archives > ul > li:nth-child($i)");
        if (res != null) {
          _results.add(res);
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
  for (final article in _articles) {
    await _pb.collection("medscape").create(body: article.toJson());
  }
}
