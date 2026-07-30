import 'package:flutter/material.dart';

abstract final class NanoRadii {
  static const double junior = 28;
  static const double senior = 20;
  static const double admin = 12;
  static const double pill = 999;
  static const double avatar = 999;
  static const double sheet = 24;

  static BorderRadius juniorCard = BorderRadius.circular(junior);
  static BorderRadius seniorCard = BorderRadius.circular(senior);
  static BorderRadius adminCard = BorderRadius.circular(admin);
}
