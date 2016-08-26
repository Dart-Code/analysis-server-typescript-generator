import 'dart:async';
import 'dart:io';

class TypeScriptGenerator {
  Future writeTo(File file) async {
    await file.parent.create(recursive: true);
    final f = file.openWrite();
    try {
      f.write("Test");
    } finally {
      f.close();
    }
  }
}
