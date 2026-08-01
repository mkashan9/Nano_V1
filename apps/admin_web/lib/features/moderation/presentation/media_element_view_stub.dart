import 'package:flutter/widgets.dart';

/// No DOM, so no player. Returning null rather than an empty box is what lets
/// the caller fall back to describing the file instead of showing a blank
/// rectangle a reviewer would mistake for a broken one.
Widget? mediaElementView({required String url, required bool isVideo}) => null;
