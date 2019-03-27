import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import 'definitions.dart';

Element _getChild(Element element, [String tag]) =>
    _getChildren(element, tag).firstWhere((e) => true, orElse: () => null);

Iterable<Element> _getChildren(Element element, [String tag]) =>
    element.children.where((c) =>
        c.nodeType != Node.TEXT_NODE && (tag == null || c.localName == tag));

String _getDocs(Element element) =>
    _getChildren(element, 'p').map((p) => p.text.trim()).join("\r\n\r\n");

String _getType(Element field) {
  switch (field.localName) {
    case 'ref':
      return _getTypeScriptTypeName(field.text);
    case 'list':
      return '${_getType(_getChild(field))}[]';
    case 'map':
      return '{ [key: string]: ${_getType(_getChild(_getChild(field, "value")))} | undefined; }';
    case 'union':
      return _getChildren(field).map(_getType).join(" | ");
    default:
      throw new ArgumentError('Unknown ${field.parent.outerHtml}');
  }
}

// Converts THIS_AND_THIS to ThisAndThis
String _getTypeScriptTypeName(String dartType) {
  const types = const {
    "String": "string",
    "int": "number",
    "long": "number",
    "bool": "boolean",
  };

  return types[dartType] ?? dartType;
}

String _prettyName(String str) =>
    str.split('_').map((s) => _titleCase(s.toLowerCase())).join('');

String _titleCase(String str) =>
    str.substring(0, 1).toUpperCase() + str.substring(1);

class ApiSpec {
  ApiSpec._(String spec) : _apiDoc = parse(spec);

  final Document _apiDoc;

  Iterable<Definition> getTypes() sync* {
    // Request/responses.
    yield* _apiDoc.querySelectorAll("request").map((r) sync* {
      final req = _createRequestInterface(r);
      if (req != null) yield req;
      final resp = _createResponseInterface(r);
      if (resp != null) yield resp;
    }).expand((x) => x);
    // Notifications.
    yield* _apiDoc
        .querySelectorAll("notification")
        .map(_createNotificationInterface);
    // Types.
    yield* _apiDoc.querySelectorAll("type").map((t) sync* {
      if (_getChild(t, "enum") != null)
        yield _createEnum(t);
      else if (_getChild(t, "ref") != null)
        yield _createTypeAlias(t);
      else
        yield _createTypeInterface(t);
    }).expand((x) => x);
    // Refactoring feedback.
    yield* _apiDoc.querySelectorAll("refactoring").map((r) sync* {
      final fbk = _createRefactoringFeedbackInterface(r);
      if (fbk != null) yield fbk;
    }).expand((x) => x);
  }

  EnumDefinition _createEnum(Element type) {
    final def = new EnumDefinition(type.attributes["name"], _getDocs(type));
    def.values.addAll(_getChildren(_getChild(type, "enum"), "value")
        .map((c) => _getChild(c, "code").text));
    return def;
  }

  InterfaceDefinition _createInterface(Element method, String name, String type,
      {bool allowEmpty: false, String parent}) {
    final doc = _getDocs(method);
    final properties = method.querySelectorAll("$type field");

    if (properties.length == 0 && !allowEmpty) return null;

    final def = new InterfaceDefinition(name, doc, parent: parent);
    def.properties.addAll(properties.map(_getPropertyDefinition));
    return def;
  }

  InterfaceDefinition _createNotificationInterface(Element event) =>
      _createInterface(
          event,
          _titleCase(event.parent.attributes["name"]) +
              _titleCase(event.attributes["event"]) +
              "Notification",
          "params");

  InterfaceDefinition _createRefactoringFeedbackInterface(Element type) =>
      _createInterface(
          type, _prettyName(type.attributes["kind"]) + "Feedback", "feedback",
          parent: "RefactoringFeedback");

  InterfaceDefinition _createRequestInterface(Element method) =>
      _createInterface(
          method,
          _titleCase(method.parent.attributes["name"]) +
              _titleCase(method.attributes["method"]) +
              "Request",
          "params");

  InterfaceDefinition _createResponseInterface(Element method) =>
      _createInterface(
          method,
          _titleCase(method.parent.attributes["name"]) +
              _titleCase(method.attributes["method"]) +
              "Response",
          "result");

  TypeAliasDefinition _createTypeAlias(Element type) {
    return new TypeAliasDefinition(_getType(_getChild(type, "ref")),
        type.attributes["name"], _getDocs(type));
  }

  InterfaceDefinition _createTypeInterface(Element type) =>
      _createInterface(type, _titleCase(type.attributes["name"]), "object",
          allowEmpty: true);

  PropertyDefinition _getPropertyDefinition(Element field) {
    return new PropertyDefinition(
        _getType(_getChild(field)),
        field.attributes["value"],
        field.attributes["name"],
        field.attributes["optional"] == "true",
        _getDocs(field));
  }

  static ApiSpec fromFile(String file) {
    final body = new File(file).readAsStringSync();
    return new ApiSpec._(body);
  }

  static Future<ApiSpec> fromUri(Uri specUri) async {
    final resp = await http.get(specUri);
    return new ApiSpec._(resp.body);
  }
}
