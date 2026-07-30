// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

final _registered = <String>{};

void registerSketchfabView(String viewType, String src) {
  if (_registered.contains(viewType)) return;
  _registered.add(viewType);
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = src
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'autoplay; fullscreen; xr-spatial-tracking'
      ..allowFullscreen = true;
    return iframe;
  });
}
