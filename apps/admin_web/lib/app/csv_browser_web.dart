import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String?> pickCsvFile() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.csv,text/csv,text/plain';
  final done = Completer<String?>();
  input.onchange = (web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      done.complete(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      done.complete(null);
      return;
    }
    file.text().toDart.then((text) {
      done.complete(text.toDart);
    }).catchError((Object _) {
      done.complete(null);
    });
  }.toJS;
  input.oncancel = (web.Event _) {
    if (!done.isCompleted) done.complete(null);
  }.toJS;
  input.click();
  return done.future;
}

void downloadCsvFile({
  required String filename,
  required String contents,
}) {
  final parts = <web.BlobPart>[contents.toJS].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
