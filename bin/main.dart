import 'dart:async';
import 'dart:io';

import 'package:analysis_server_typescript_generator/api_spec.dart';
import 'package:analysis_server_typescript_generator/typescript_generator.dart';

final _specUri = Uri.parse(
    'https://github.com/dart-lang/sdk/raw/master/pkg/analysis_server/tool/spec/spec_input.html');
final _outputFile = new File("output/types.ts");

Future main() async {
  final spec = await ApiSpec.download(_specUri);
  final gen = new TypeScriptGenerator();

  spec.buildDefinitions(gen.definitions);

  await gen.writeTo(_outputFile);
}
