import 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart';

void downloadWebJson(String content, String filename) {
  downloadJsonFile(content, filename);
}
