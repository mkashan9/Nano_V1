import 'nano_app_locale.dart';

/// Foundation UI copy for English and Urdu.
/// Feature modules should prefer keys here (or later ARB) over hardcoded English.
class NanoCopy {
  const NanoCopy(this.locale);

  final NanoAppLocale locale;

  bool get isUrdu => locale == NanoAppLocale.ur;

  String get appName => 'Nano';

  String get languageEnglish => isUrdu ? 'انگریزی' : 'English';
  String get languageUrdu => isUrdu ? 'اردو' : 'Urdu';

  String greeting(String name) =>
      isUrdu ? 'سلام $name' : 'Hi $name';

  String get subjects => isUrdu ? 'مضامین' : 'Subjects';
  String get continueLearning => isUrdu ? 'جاری رکھیں' : 'Continue';
  String get todaysMission =>
      isUrdu ? 'آج کا مشن' : "Today's Mission";
  String get buildingFuture =>
      isUrdu ? 'میں اپنا مستقبل بنا رہا/رہی ہوں۔' : "I'm building my future.";

  String get home => isUrdu ? 'گھر' : 'Home';
  String get learning => isUrdu ? 'سیکھنا' : 'Learning';
  String get play => isUrdu ? 'کھیلیں' : 'Play';
  String get games => isUrdu ? 'گیمز' : 'Games';
  String get flex => isUrdu ? 'فلیکس' : 'Flex';
  String get communities => isUrdu ? 'کمیونٹیز' : 'Communities';
  String get me => isUrdu ? 'میں' : 'Me';
  String get profile => isUrdu ? 'پروفائل' : 'Profile';

  String get dashboard => isUrdu ? 'ڈیش بورڈ' : 'Dashboard';
  String get classes => isUrdu ? 'کلاسز' : 'Classes';
  String get attendance => isUrdu ? 'حاضری' : 'Attendance';
  String get marks => isUrdu ? 'نمبر' : 'Marks';
  String get classroom => isUrdu ? 'کلاس روم' : 'Classroom';

  String get overview => isUrdu ? 'جائزہ' : 'Overview';
  String get students => isUrdu ? 'طلبہ' : 'Students';
  String get teachers => isUrdu ? 'اساتذہ' : 'Teachers';
  String get reports => isUrdu ? 'رپورٹس' : 'Reports';
  String get settings => isUrdu ? 'ترتیبات' : 'Settings';
  String get platform => isUrdu ? 'پلیٹ فارم' : 'Platform';
  String get schools => isUrdu ? 'اسکول' : 'Schools';
  String get content => isUrdu ? 'مواد' : 'Content';
  String get moderation => isUrdu ? 'نگرانی' : 'Moderation';
  String get analytics => isUrdu ? 'تجزیات' : 'Analytics';
  String get audit => isUrdu ? 'آڈٹ' : 'Audit';

  String get loading => isUrdu ? 'لوڈ ہو رہا ہے' : 'Loading';
  String get emptyTitle => isUrdu ? 'ابھی کچھ نہیں' : 'Nothing here yet';
  String get emptyMessage =>
      isUrdu ? 'جلد دوبارہ چیک کریں۔' : 'Check back soon.';
  String get errorTitle =>
      isUrdu ? 'کچھ غلط ہو گیا' : 'Something went wrong';
  String get errorMessage =>
      isUrdu ? 'براہِ کرم دوبارہ کوشش کریں۔' : 'Please try again.';
  String get tryAgain => isUrdu ? 'دوبارہ کوشش' : 'Try again';
  String get offlineBanner => isUrdu
      ? 'آپ آف لائن ہیں۔ دوبارہ جڑنے پر ہم وقت کریں گے۔'
      : 'You are offline. Changes will sync when you reconnect.';
  String get conflictMessage => isUrdu
      ? 'ایک نئی محفوظ شدہ ورژن موجود ہے۔ دوبارہ کوشش کریں یا اپنی مسودہ مسترد کریں۔'
      : 'A newer saved version exists. Try again or discard your draft.';
  String get pendingChanges =>
      isUrdu ? 'زیرِ التوا تبدیلیاں' : 'Pending changes';
  String get lastUpdated => isUrdu ? 'آخری تازہ کاری' : 'Last updated';
  String get maintenanceTitle =>
      isUrdu ? 'مرمت جاری ہے' : 'Under maintenance';
  String get maintenanceMessage => isUrdu
      ? 'Nano عارضی طور پر دستیاب نہیں۔ جلد کوشش کریں۔'
      : 'Nano is temporarily unavailable while we finish updates. Try again soon.';

  String get onboardingWelcomeTitle =>
      isUrdu ? 'Nano میں خوش آمدید' : 'Welcome to Nano';
  String welcomeLine(String name) => isUrdu
      ? '$name، آئیے آپ کا سیکھنے کا سفر ترتیب دیں۔'
      : "$name, let's set up your learning.";
  String get onboardingExperienceTitle =>
      isUrdu ? 'آپ کس جماعت میں ہیں؟' : 'Which grade are you in?';
  String get onboardingExperienceHelp => isUrdu
      ? 'اس سے ہم صفحات کو آپ کے مطابق بناتے ہیں۔ آپ کا اسکول اسے بعد میں درست کر سکتا ہے۔'
      : 'This shapes how pages look. Your school can correct it later.';
  String get onboardingJunior => isUrdu ? 'جونیئر' : 'Junior';
  String get onboardingSenior => isUrdu ? 'سینئر' : 'Senior';
  String onboardingSchoolIntro(String schoolName) => isUrdu
      ? 'آپ $schoolName سے منسلک ہیں۔ حاضری اور نمبر Flex میں نظر آئیں گے۔'
      : 'You are linked to $schoolName. Attendance and marks appear in Flex.';
  String get onboardingIndependentIntro => isUrdu
      ? 'آپ خود سیکھ رہے ہیں: اسباق، کوئز اور گیمز آپ کے لیے تیار ہیں۔'
      : 'You are learning on your own: lessons, quizzes, and games are ready for you.';
  String get keepGoing => isUrdu ? 'جاری رکھیں' : 'Keep going';
  String get streakLabel => isUrdu ? 'دن کا سلسلہ' : 'day streak';
  String get notificationsLabel => isUrdu ? 'اطلاعات' : 'Notifications';
  String get missionXpAvailable => isUrdu ? 'دستیاب XP' : 'XP to earn';
  String percentDone(int percent) =>
      isUrdu ? '$percent% مکمل' : '$percent% done';
  String get profileTitle => isUrdu ? 'پروفائل' : 'Profile';
  String get progressLabel => isUrdu ? 'پیش رفت' : 'Progress';
  String get topicsCompleted => isUrdu ? 'مکمل ٹاپکس' : 'Topics completed';
  String get nextUpLabel => isUrdu ? 'اگلا مرحلہ' : 'Next up';
  String get achievementsLabel => isUrdu ? 'اعزازات' : 'Achievements';
  String get privacyLabel => isUrdu ? 'پرائیویسی' : 'Privacy';
  String get discoverableLabel =>
      isUrdu ? 'مجھے تلاش کیا جا سکتا ہے' : 'Let others find me';
  String get showAchievementsLabel =>
      isUrdu ? 'اعزازات دکھائیں' : 'Show my achievements';
  String get allowFriendRequestsLabel =>
      isUrdu ? 'دوستی کی درخواستیں' : 'Allow friend requests';
  String get devicesLabel => isUrdu ? 'ڈیوائسز' : 'Devices';
  String get thisDeviceLabel => isUrdu ? 'یہ ڈیوائس' : 'This device';
  String get revokeLabel => isUrdu ? 'رسائی ختم کریں' : 'Sign out device';
  String get revokedLabel => isUrdu ? 'ختم شدہ' : 'Signed out';
  String lastSeen(String label) =>
      isUrdu ? 'آخری بار $label' : 'Last active $label';
  String get settingsLabel => isUrdu ? 'سیٹنگز' : 'Settings';
  String get accessibilityLabel => isUrdu ? 'ایکسیسبیلٹی' : 'Accessibility';
  String get signOutLabel => isUrdu ? 'سائن آؤٹ' : 'Sign out';
  String get accountTypeLabel => isUrdu ? 'اکاؤنٹ' : 'Account';

  String levelLabel(int level) => isUrdu ? 'لیول $level' : 'Level $level';
  String xpToNextLevel(int xp) =>
      isUrdu ? 'اگلے لیول تک $xp XP' : '$xp XP to next level';
  String get todaysPlan => isUrdu ? 'آج کا پلان' : "Today's Plan";
  String get planEmpty =>
      isUrdu ? 'آج کے لیے کچھ باقی نہیں۔' : 'Nothing planned for today.';
  String get latestUpdate => isUrdu ? 'تازہ اپڈیٹ' : 'Latest update';
  String get flexTitle => isUrdu ? 'فلیکس' : 'Flex';
  String flexOpenTasks(int count) =>
      isUrdu ? '$count کام باقی ہیں' : '$count tasks open';
  String get continueBuilding => isUrdu ? 'بناتے رہیں' : 'Continue building';
  String get sectionUnavailable =>
      isUrdu ? 'یہ حصہ ابھی لوڈ نہیں ہوا۔' : "This part didn't load.";
  String get retryLabel => isUrdu ? 'دوبارہ کوشش' : 'Try again';

  String get accessWarning => isUrdu
      ? 'آپ کی رسائی جلد ختم ہو رہی ہے۔ سیکھنا جاری رکھیں۔'
      : 'Your access is ending soon. You can keep learning for now.';

  String get onboardingSetupTitle =>
      isUrdu ? 'اپنے ساتھی کو نام دیں' : 'Name your learning guide';
  String get companionNameLabel => isUrdu ? 'ساتھی کا نام' : 'Guide name';
  String get companionNameHelp => isUrdu
      ? 'یہ نام صرف آپ دیکھتے ہیں۔ آپ اسے بعد میں بدل سکتے ہیں۔'
      : 'Only you see this name. You can change it later.';
  String get languageLabel => isUrdu ? 'زبان' : 'Language';
  String get soundLabel => isUrdu ? 'آواز' : 'Sound';
  String get captionsLabel => isUrdu ? 'کیپشنز' : 'Captions';
  String get reducedMotionLabel => isUrdu ? 'کم حرکت' : 'Reduced motion';
  String companionGreeting(String companionName) => isUrdu
      ? '$companionName آپ کے ساتھ سیکھنے کے لیے تیار ہے۔'
      : '$companionName is ready to learn with you.';

  String get onboardingReadyTitle => isUrdu ? 'سب تیار ہے' : 'You are all set';
  String get onboardingResumed =>
      isUrdu ? 'ہم نے آپ کی جگہ محفوظ رکھی' : 'We saved your place';
  String get onboardingContinue => isUrdu ? 'آگے بڑھیں' : 'Continue';
  String get onboardingBack => isUrdu ? 'واپس' : 'Back';
  String get onboardingStart => isUrdu ? 'سیکھنا شروع کریں' : 'Start learning';

  String get localePreviewTitle =>
      isUrdu ? 'زبان کا پیش منظر' : 'Locale preview';
  String get localePreviewBody => isUrdu
      ? 'اردو دائیں سے بائیں ترتیب استعمال کرتی ہے۔ انگریزی بائیں سے دائیں۔'
      : 'Urdu uses right-to-left layout. English uses left-to-right.';
  String get sampleSentence => isUrdu
      ? 'علی ریاضی کا سبق جاری رکھ سکتا ہے۔'
      : 'Ali can continue a Math lesson.';

  String navLabel(String destinationId) => switch (destinationId) {
        'home' => home,
        'learning' => learning,
        'game' => play,
        'games' => games,
        'flex' => flex,
        'communities' => communities,
        'profile' => profile,
        'dashboard' => dashboard,
        'classes' => classes,
        'attendance' => attendance,
        'marks' => marks,
        'classroom' => classroom,
        'overview' => overview,
        'students' => students,
        'teachers' => teachers,
        'reports' => reports,
        'settings' => settings,
        'platform' => platform,
        'schools' => schools,
        'content' => content,
        'moderation' => moderation,
        'analytics' => analytics,
        'audit' => audit,
        _ => destinationId,
      };

  /// Junior profile/play labels differ from senior density labels.
  String studentNavLabel(String destinationId, {required bool junior}) {
    if (destinationId == 'profile') {
      return junior ? me : profile;
    }
    if (destinationId == 'games' || destinationId == 'games') {
      return junior ? play : games;
    }
    return navLabel(destinationId);
  }
}
