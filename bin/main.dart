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

final _files = Platform.isWindows
    ? [
        "M:\\Coding\\Applications\\Google\\dart-sdk\\sdk\\pkg\\analysis_server\\tool\\spec\\spec_input.html",
        "M:\\Coding\\Applications\\Google\\dart-sdk\\sdk\\pkg\\analyzer_plugin\\tool\\spec\\common_types_spec.html",
      ]
    : [
        "/Users/danny/Dev/Google/sdk/pkg/analysis_server/tool/spec/spec_input.html",
        "/Users/danny/Dev/Google/sdk/pkg/analyzer_plugin/tool/spec/common_types_spec.html",
      ];
final _outputFile = new File("output/analysis_server_types.ts");

const useLiveSpecs = true;

Future main() async {
  final typesFile = new TypeScriptGenerator();

  final specs = useLiveSpecs
      ? await Future.wait(_specUris.map(ApiSpec.fromUri))
      : _files.map(ApiSpec.fromFile);

  // Write all the types
  specs.forEach((spec) => typesFile.definitions.addAll(spec.getTypes()));
  await typesFile.writeTo(_outputFile);

  print("Done!");
}
