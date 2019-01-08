import 'dart:async';
import 'dart:io';

import 'definitions.dart';

final _header = '''
// This file was code-generated from the Analysis Server API doc
// and should not be hand-edited!
// https://github.com/Dart-Code/analysis-server-typescript-generator

"use strict";

''';

class TypeScriptGenerator {
  final definitions = new List<Definition>();

  Future writeTo(File file) async {
    final output = new StringBuffer(_header);

    definitions.forEach((c) => _writeDefinition(output, c));

    await file.parent.create(recursive: true);
    await file.writeAsString(output.toString());
  }

  void _writeDefinition(StringBuffer output, Definition def) {
    output.writeln(_formatDoc(def.doc));
    if (def is InterfaceDefinition)
      _writeInterface(output, def);
    else if (def is EnumDefinition)
      _writeEnum(output, def);
    else if (def is TypeAliasDefinition)
      _writeTypeAlias(output, def);
    else
      throw new ArgumentError('Unknown type ${def.runtimeType}');
    output.writeln();
  }

  void _writeInterface(StringBuffer output, InterfaceDefinition def) {
    output.write(
        'export interface ${def.name} ${def.parent != null ? "extends ${def.parent} " : ""}{');
    def.properties.forEach((p) => _writeProperty(output, p));
    // Match Formatted typescript by having empty space for empty interfaces.
    if (def.properties.length == 0) output.write(' ');
    output.writeln('}');
  }

  void _writeProperty(StringBuffer output, PropertyDefinition prop) {
    final indent = _getIndent(1);
    output.writeln();
    output.writeln(_formatDoc(prop.doc, indent: indent));
    output.writeln(
        '$indent${prop.name}${prop.isOptional ? "?" : ""}: ${prop.value != null ? '"${prop.value}"' : prop.type};');
  }

  void _writeEnum(StringBuffer output, EnumDefinition def) {
    output.writeln('export type ${def.name} =');
    final indent = _getIndent(1);
    final values = def.values.map((v) => '"$v"').join('\r\n$indent| ');
    output.writeln('$indent$values;');
  }

  void _writeTypeAlias(StringBuffer output, TypeAliasDefinition def) {
    output.writeln('export type ${def.name} = ${def.type};');
  }

  String _formatDoc(String doc, {String indent: ""}) {
    final lines = doc.trim().split('\n').map((l) => l.trim());
    return '$indent/**\r\n' +
        lines.map((l) => '$indent * $l').join('\r\n') +
        '\r\n$indent */';
  }

  String _getIndent(int level) => '\t' * level;
}
