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
    _apiDoc.querySelectorAll("request").forEach((r) {
      final req = _createRequestClass(r);
      if (req != null) classes.add(req);
      final resp = _createResponseClass(r);
      if (resp != null) classes.add(resp);
    });
    classes.addAll(
        _apiDoc.querySelectorAll("notification").map(_createNotificationClass));
    classes.addAll(_apiDoc.querySelectorAll("type").map(_createTypeClass));
  }

  ClassDefinition _createRequestClass(Element method) => _createClass(
      method,
      _titleCase(method.parent.attributes["name"]) +
          _titleCase(method.attributes["method"]) +
          "Request",
      "params");

  ClassDefinition _createResponseClass(Element method) => _createClass(
      method,
      _titleCase(method.parent.attributes["name"]) +
          _titleCase(method.attributes["method"]) +
          "Response",
      "result");

  ClassDefinition _createNotificationClass(Element event) => _createClass(
      event,
      _titleCase(event.parent.attributes["name"]) +
          _titleCase(event.attributes["event"]) +
          "Notification",
      "params");

  ClassDefinition _createTypeClass(Element type) =>
      _createClass(type, _titleCase(type.attributes["name"]), "object");

  ClassDefinition _createClass(Element method, String name, String type) {
    final doc = _getDocs(method);
    final properties = method.querySelectorAll("$type field");

    if (properties.length == 0) return null;

    final def = new ClassDefinition(name, doc);
    def.properties.addAll(properties.map(_getPropertyDefinition));
    return def;
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
    _getChildren(element, 'p').map((p) => p.text.trim()).join("\r\n\r\n");

Iterable<Element> _getChildren(Element element, [String tag]) =>
    element.children.where((c) =>
        c.nodeType != Node.TEXT_NODE && (tag == null || c.localName == tag));

Element _getChild(Element element, [String tag]) =>
    _getChildren(element, tag).first;
