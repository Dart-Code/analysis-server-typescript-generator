import 'dart:async';
import 'dart:io';

import 'package:analysis_server_typescript_generator/api_spec.dart';
import 'package:analysis_server_typescript_generator/typescript_generator.dart';

final _specUris = [
  Uri.parse(
      'https://github.com/dart-lang/sdk/raw/master/pkg/analysis_server/tool/spec/spec_input.html'),
  Uri.parse(
      'https://github.com/dart-lang/sdk/raw/master/pkg/analyzer_plugin/tool/spec/common_types_spec.html')
];
final _files = [
  "/Users/danny/Dev/Google/sdk/pkg/analysis_server/tool/spec/spec_input.html",
  "/Users/danny/Dev/Google/sdk/pkg/analyzer_plugin/tool/spec/common_types_spec.html",
];
final _outputFile = new File("output/analysis_server_types.ts");

Future main() async {
  final types = new TypeScriptGenerator();

  if (true) {
    await Future.forEach(_specUris, (Uri specUri) async {
      final spec = await ApiSpec.download(specUri);
      types.definitions.addAll(spec.getTypes());
    });
  } else {
    _files.forEach((file) {
      final spec = ApiSpec.fromFile(file);
      types.definitions.addAll(spec.getTypes());
    });
  }

  await types.writeTo(_outputFile);
}
