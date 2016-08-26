import 'dart:io';

import 'package:analysis_server_typescript_generator/api_spec.dart';
import 'package:analysis_server_typescript_generator/typescript_generator.dart';

final _specUri = Uri.parse('https://github.com/dart-lang/sdk/raw/master/pkg/analysis_server/doc/api.html');
final _outputFile = new File("output/types.ts");

main() async {
  final spec = await ApiSpec.download(_specUri);
  final gen = new TypeScriptGenerator();

  await gen.writeTo(_outputFile);
}
