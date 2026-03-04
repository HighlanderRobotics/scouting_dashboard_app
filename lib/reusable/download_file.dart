import 'download_file_stub.dart'
    if (dart.library.html) 'download_file_web.dart';

Future<void> downloadFile(
  String filename,
  List<int> bytes,
  String mimeType,
) async {
  await downloadFileImpl(filename, bytes, mimeType);
}
