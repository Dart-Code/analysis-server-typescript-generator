import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiSpec {
  final String _spec;

  ApiSpec._(this._spec);

  static Future<ApiSpec> download(Uri specUri) async {
    final resp = await http.get(specUri);
    return new ApiSpec._(resp.body);
  }
}

