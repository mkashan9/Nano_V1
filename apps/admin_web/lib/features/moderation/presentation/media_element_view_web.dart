import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// A view type may only be registered once per name, and the registry has no
/// way to unregister. Keying on the URL means selecting the same asset twice
/// reuses one registration, and a re-signed URL for the same file makes a new
/// one — which is correct, because the element has to be rebuilt with the new
/// link anyway.
final _viewTypes = <String, String>{};
var _next = 0;

Widget? mediaElementView({required String url, required bool isVideo}) {
  final key = '${isVideo ? 'video' : 'audio'}:$url';
  final viewType = _viewTypes.putIfAbsent(key, () {
    final name = 'nano-media-${_next++}';
    ui_web.platformViewRegistry.registerViewFactory(
      name,
      (int _) => isVideo ? _video(url) : _audio(url),
    );
    return name;
  });

  return HtmlElementView(viewType: viewType);
}

web.HTMLVideoElement _video(String url) => web.HTMLVideoElement()
  ..src = url
  ..controls = true
  // A reaction clip is silent by design (MED-04), but a reviewer should still
  // be the one who decides to make noise.
  ..autoplay = false
  // Loop, because a three-second clip is hard to judge once and this is the
  // screen where judging it is the whole job.
  ..loop = true
  ..style.width = '100%'
  ..style.height = '100%'
  ..style.objectFit = 'contain';

web.HTMLAudioElement _audio(String url) => web.HTMLAudioElement()
  ..src = url
  ..controls = true
  ..autoplay = false
  ..style.width = '100%';
