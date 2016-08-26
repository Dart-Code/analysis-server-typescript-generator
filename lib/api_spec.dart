import 'dart:async';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import 'definitions.dart';

class ApiSpec {
  final Document _apiDoc;

  ApiSpec._(String spec) : _apiDoc = parse(spec);

  static Future<ApiSpec> download(Uri specUri) async {
    final resp = await http.get(specUri);
    return new ApiSpec._(resp.body);
  }

  buildClasses(List<ClassDefinition> classes) {
    _apiDoc.querySelectorAll("request")
      ..forEach((r) => classes.add(_createRequestClass(r)))
      ..forEach((r) => classes.add(_createResponseClass(r)));
  }

  _createRequestClass(Element method) {
    final name = method.parent.attributes["name"] +
        _titleCase(method.attributes["method"]) +
        "Request";
    final doc = _getDocs(method);

    return new ClassDefinition(name, doc);
  }

  _createResponseClass(Element method) {
    final name = method.parent.attributes["name"] +
        _titleCase(method.attributes["method"]) +
        "Response";
    final doc = _getDocs(method);

    return new ClassDefinition(name, doc);
  }

  String _titleCase(String str) =>
      str.substring(0, 1).toUpperCase() + str.substring(1);

  String _getDocs(Element element) => element.children
      .where((c) => c.localName == "p")
      .map((p) => p.text)
      .join("\r\n");
}
