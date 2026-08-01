/// A browser-native player for a reviewer, or nothing at all.
///
/// MED-03 and MED-04 left voice and video without playback because adding a
/// player meant adding a plugin to every app. That reasoning does not reach
/// admin_web: it only ever runs in a browser, and a browser already plays MP3
/// and MP4. Nothing here ships to a student or a teacher.
///
/// The conditional export is what keeps the widget tests honest. They run on the
/// VM, where there is no DOM, so they resolve the stub and see the same
/// metadata fallback a reviewer saw before this existed.
library;

export 'media_element_view_stub.dart'
    if (dart.library.js_interop) 'media_element_view_web.dart';
