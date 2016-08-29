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

  void buildDefinitions(List<Definition> defs) {
    // Request/responses.
    _apiDoc.querySelectorAll("request").forEach((r) {
      final req = _createRequestInterface(r);
      if (req != null) defs.add(req);
      final resp = _createResponseInterface(r);
      if (resp != null) defs.add(resp);
    });
    // Notifications.
    defs.addAll(_apiDoc
        .querySelectorAll("notification")
        .map(_createNotificationInterface));
    // Types.
    _apiDoc.querySelectorAll("type").forEach((t) {
      if (_getChild(t, "enum") != null)
        defs.add(_createEnum(t));
      else if (_getChild(t, "ref") != null)
        defs.add(_createTypeAlias(t));
      else
        defs.add(_createTypeInterface(t));
    });
    // Refactoring feedback.
    _apiDoc.querySelectorAll("refactoring").forEach((r) {
      final fbk = _createRefactoringFeedbackInterface(r);
      if (fbk != null) defs.add(fbk);
    });
  }

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

  InterfaceDefinition _createNotificationInterface(Element event) =>
      _createInterface(
          event,
          _titleCase(event.parent.attributes["name"]) +
              _titleCase(event.attributes["event"]) +
              "Notification",
          "params");

  InterfaceDefinition _createTypeInterface(Element type) =>
      _createInterface(type, _titleCase(type.attributes["name"]), "object",
          allowEmpty: true);

  EnumDefinition _createEnum(Element type) {
    final def = new EnumDefinition(type.attributes["name"], _getDocs(type));
    def.values.addAll(_getChildren(_getChild(type, "enum"), "value")
        .map((c) => _getChild(c, "code").text));
    return def;
  }

  TypeAliasDefinition _createTypeAlias(Element type) {
    return new TypeAliasDefinition(_getType(_getChild(type, "ref")),
        type.attributes["name"], _getDocs(type));
  }

  InterfaceDefinition _createRefactoringFeedbackInterface(Element type) =>
      _createInterface(
          type, _prettyName(type.attributes["kind"]) + "Feedback", "feedback",
          parent: "RefactoringFeedback");

  InterfaceDefinition _createInterface(Element method, String name, String type,
      {bool allowEmpty: false, String parent}) {
    final doc = _getDocs(method);
    final properties = method.querySelectorAll("$type field");

    if (properties.length == 0 && !allowEmpty) return null;

    final def = new InterfaceDefinition(name, doc, parent: parent);
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
      return _getChildren(field).map(_getType).join(" | ");
    default:
      throw 'Unknown ${field.parent.outerHtml}';
  }
}

String _titleCase(String str) =>
    str.substring(0, 1).toUpperCase() + str.substring(1);

// Converts THIS_AND_THIS to ThisAndThis
String _prettyName(String str) =>
    str.split('_').map((s) => _titleCase(s.toLowerCase())).join('');

String _getDocs(Element element) =>
    _getChildren(element, 'p').map((p) => p.text.trim()).join("\r\n\r\n");

Iterable<Element> _getChildren(Element element, [String tag]) =>
    element.children.where((c) =>
        c.nodeType != Node.TEXT_NODE && (tag == null || c.localName == tag));

Element _getChild(Element element, [String tag]) =>
    _getChildren(element, tag).firstWhere((e) => true, orElse: () => null);
