abstract final class NanoBreakpoints {
  static const double smallPhone = 360;
  static const double largePhone = 430;
  static const double tablet = 768;
  static const double narrowWeb = 1024;
  static const double desktop = 1280;
  static const double wideDesktop = 1440;

  static bool isPhone(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < narrowWeb;
  static bool isDesktop(double width) => width >= narrowWeb;
}
