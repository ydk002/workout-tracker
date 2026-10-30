import 'dart:convert';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadJsonFile(String content, String filename) {
  final bytes = utf8.encode(content);
  final jsArray = [bytes.toJS].toJS;
  final blob = web.Blob(jsArray, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
