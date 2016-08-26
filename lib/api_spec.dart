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

  void buildClasses(List<ClassDefinition> classes) {
    _apiDoc.querySelectorAll("request")
      ..forEach((r) => classes.add(_createRequestClass(r)))
      ..forEach((r) => classes.add(_createResponseClass(r)));
  }

  ClassDefinition _createRequestClass(Element method) {
    final name = method.parent.attributes["name"] +
        _titleCase(method.attributes["method"]) +
        "Request";
    final doc = _getDocs(method);

    final def = new ClassDefinition(name, doc);
    def.properties.addAll(
        method.querySelectorAll("params field").map(_getPropertyDefinition));
    return def;
  }

  ClassDefinition _createResponseClass(Element method) {
    final name = method.parent.attributes["name"] +
        _titleCase(method.attributes["method"]) +
        "Response";
    final doc = _getDocs(method);

    return new ClassDefinition(name, doc);
  }

  PropertyDefinition _getPropertyDefinition(Element field) {
    return new PropertyDefinition(
        _getType(_getChild(field)),
        field.attributes["name"],
        field.attributes["optional"] == "true",
        _getDocs(field));
  }
}

String _getTypeScriptTypeName(String dartType) {
  const types = const {
    "String": "string",
    "int": "number",
    "long": "number",
    "bool": "boolean",
  };

  return types[dartType] ?? dartType;
}

String _getType(Element field) {
  switch (field.localName) {
    case 'ref':
      return _getTypeScriptTypeName(field.text);
    case 'list':
      return '${_getType(_getChild(field))}[]';
    case 'map':
      return '{ [key: string]: ${_getType(_getChild(_getChild(field, "value")))}; }';
    case 'union':
      return _getChildren(field).map(_getType).join("|");
    default:
      throw 'Unknown ${field.parent.outerHtml}';
  }
}

String _titleCase(String str) =>
    str.substring(0, 1).toUpperCase() + str.substring(1);

String _getDocs(Element element) =>
    _getChildren(element, 'p').map((p) => p.text).join("\r\n");

Iterable<Element> _getChildren(Element element, [String tag]) =>
    element.children.where((c) =>
        c.nodeType != Node.TEXT_NODE && (tag == null || c.localName == tag));

Element _getChild(Element element, [String tag]) => _getChildren(element).first;
