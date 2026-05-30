// Web implementation — uses browser download API
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> downloadImageOnWeb(List<int> bytes, String filename) async {
  final uint8List = Uint8List.fromList(bytes);
  final jsUint8Array = uint8List.toJS;

  final blob = web.Blob(
    [jsUint8Array].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );

  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

// Stub so native-conditional import compiles
Future<void> shareImageOnNative(
  List<int> imageBytes,
  String counterTitle,
  String subject,
) async {
  // No-op on web — this path is never called
}
