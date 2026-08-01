import '../companion/companion_mode.dart';
import '../media/generated_asset.dart';
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
  String get saveFailed => isUrdu
      ? 'محفوظ نہیں ہو سکا۔ اپنا انٹرنیٹ دیکھیں اور دوبارہ کوشش کریں۔'
      : "Couldn't save. Check your connection and try again.";
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

  String get catalogTitle => isUrdu ? 'سیکھنے کا مواد' : 'Learning';
  String get catalogSearchHint =>
      isUrdu ? 'مضمون یا ٹاپک تلاش کریں' : 'Search subjects and topics';
  String get catalogNoResults =>
      isUrdu ? 'کوئی نتیجہ نہیں ملا۔' : 'No matches found.';
  String get catalogEmpty => isUrdu
      ? 'ابھی آپ کے لیے کوئی مضمون تیار نہیں۔'
      : 'No subjects are ready for you yet.';
  String topicCount(int count) =>
      isUrdu ? '$count ٹاپکس' : '$count topics';
  String topicsDone(int done, int total) =>
      isUrdu ? '$total میں سے $done مکمل' : '$done of $total done';
  String minutesLabel(int minutes) =>
      isUrdu ? '$minutes منٹ' : '$minutes min';
  String get objectivesLabel => isUrdu ? 'آپ کیا سیکھیں گے' : "What you'll learn";
  String get resourcesLabel => isUrdu ? 'اضافی مواد' : 'Extra material';
  String get lockedLabel => isUrdu ? 'بند' : 'Locked';
  String lockedBecause(String prerequisites) => isUrdu
      ? 'پہلے $prerequisites مکمل کریں'
      : 'Finish $prerequisites first';
  String get completedLabel => isUrdu ? 'مکمل' : 'Completed';
  String get startLabel => isUrdu ? 'شروع کریں' : 'Start';
  String get resumeLabel => isUrdu ? 'جاری رکھیں' : 'Resume';
  String get reviewLabel => isUrdu ? 'دوبارہ دیکھیں' : 'Review';
  String get playLabel => isUrdu ? 'چلائیں' : 'Play';
  String get pauseLabel => isUrdu ? 'روکیں' : 'Pause';
  String get markCompleteLabel => isUrdu ? 'مکمل کریں' : 'Mark complete';
  String keepWatchingHint(int seconds) => isUrdu
      ? 'مکمل کرنے کے لیے مزید $seconds سیکنڈ دیکھیں'
      : 'Watch $seconds more seconds to finish';
  String get watchedLabel => isUrdu ? 'دیکھا گیا' : 'Watched';
  String get progressTitle => isUrdu ? 'آپ کی پیش رفت' : 'Your progress';
  String get recommendedTitle => isUrdu ? 'اگلا کام' : 'Up next';
  String get reasonResume =>
      isUrdu ? 'یہ ادھورا رہ گیا تھا' : 'You left this unfinished';
  String get reasonReviewQuiz =>
      isUrdu ? 'اس کوئز کا دوبارہ جائزہ لیں' : 'Worth another look';
  String get reasonNextInSubject =>
      isUrdu ? 'اس مضمون کا اگلا موضوع' : 'Next in this subject';
  String get reasonNewSubject =>
      isUrdu ? 'کچھ نیا شروع کریں' : 'Start something new';
  String get strongestLabel => isUrdu ? 'سب سے مضبوط' : 'Going well';
  String get focusLabel => isUrdu ? 'توجہ دیں' : 'Worth some time';
  String get allCaughtUp =>
      isUrdu ? 'سب کچھ مکمل ہو گیا۔ شاباش!' : 'Everything is finished. Well done.';
  String get nothingStartedYet =>
      isUrdu ? 'ابھی کچھ شروع نہیں کیا۔' : 'Nothing started yet.';
  String lockedCount(int count) =>
      isUrdu ? '$count ابھی بند ہیں' : '$count still locked';
  String watchedMinutes(int minutes) =>
      isUrdu ? '$minutes منٹ دیکھے' : '$minutes minutes watched';
  String get checkpointStretchTitle =>
      isUrdu ? 'ذرا سستا لیں' : 'Quick break';
  String get checkpointRecallTitle =>
      isUrdu ? 'ایک لمحہ سوچیں' : 'Think back';
  String get checkpointReadyTitle =>
      isUrdu ? 'آگے بڑھیں؟' : 'Ready to continue?';
  String get keepWatchingLabel => isUrdu ? 'دیکھنا جاری رکھیں' : 'Keep watching';
  String get takeABreakLabel => isUrdu ? 'وقفہ لیں' : 'Take a break';
  String get creditPausedNotice => isUrdu
      ? 'یہاں سے پیش رفت رکی ہے۔ جواب دے کر آگے بڑھیں۔'
      : 'Progress is paused here until you answer.';
  String get noSkipAheadNotice => isUrdu
      ? 'اس ویڈیو میں آگے نہیں چھوڑ سکتے۔'
      : "You can't skip ahead in this video.";
  String get questionBankTitle =>
      isUrdu ? 'سوالات کا ذخیرہ' : 'Question bank';
  String get topicQuizzesTitle =>
      isUrdu ? 'موضوع کے کوئز' : 'Topic quizzes';
  String get newQuizLabel => isUrdu ? 'نیا کوئز' : 'New quiz';
  String get publishQuizLabel => isUrdu ? 'کوئز شائع کریں' : 'Publish quiz';
  String get retireQuizLabel => isUrdu ? 'کوئز ریٹائر کریں' : 'Retire quiz';
  String get quizItemsLabel => isUrdu ? 'ترتیب والے سوالات' : 'Ordered questions';
  String get passPercentLabel => isUrdu ? 'پاسنگ فیصد' : 'Pass percent';
  String get fixedOrderLabel =>
      isUrdu ? 'ترتیب محفوظ ہے' : 'Order is preserved';
  String quizItemNumber(int n) => isUrdu ? 'سوال $n' : 'Question $n';
  String get takeQuizLabel => isUrdu ? 'کوئز لیں' : 'Take quiz';
  String get quizNextLabel => isUrdu ? 'اگلا' : 'Next';
  String get quizFinishLabel => isUrdu ? 'ختم کریں' : 'Finish';
  String get quizDoneTitle => isUrdu ? 'آپ نے کوئز مکمل کیا!' : 'You finished the quiz!';
  String get quizScoreLaterNotice => isUrdu
      ? 'اسکور بعد میں محفوظ ہوگا — ابھی صرف مشق ہے۔'
      : 'Your score will be saved later — this is practice for now.';
  String get quizDoneButtonLabel => isUrdu ? 'واپس' : 'Done';
  String get quizPassedLabel => isUrdu ? 'کامیاب' : 'Passed';
  String get quizFailedLabel => isUrdu ? 'دوبارہ کوشش' : 'Try again';
  String quizServerScore(double percent) => isUrdu
      ? 'اسکور: ${percent.toStringAsFixed(0)}٪'
      : 'Score: ${percent.toStringAsFixed(0)}%';
  String get quizScoreFromServerNotice => isUrdu
      ? 'یہ اسکور سرور نے محفوظ کیا ہے۔'
      : 'This score was saved by the server.';
  String get quizUnavailableLabel =>
      isUrdu ? 'اس ٹاپک کا کوئز ابھی نہیں ہے۔' : 'No quiz for this topic yet.';
  String quizProgressLabel(int current, int total) => isUrdu
      ? 'سوال $current از $total'
      : 'Question $current of $total';
  String get quizReviewLabel => isUrdu ? 'جائزہ' : 'Review';
  String get quizPreviousLabel => isUrdu ? 'پچھلا' : 'Previous';
  String get quizSubmitReviewLabel =>
      isUrdu ? 'جائزہ کے بعد ختم کریں' : 'Review & finish';
  String get quizUnansweredLabel =>
      isUrdu ? 'جواب نہیں دیا' : 'Unanswered';
  String get quizAnsweredLabel => isUrdu ? 'جواب دے دیا' : 'Answered';
  String get quizNavigatorLabel =>
      isUrdu ? 'سوال نیویگیٹر' : 'Question navigator';
  String quizAnsweredCount(int answered, int total) => isUrdu
      ? '$answered از $total جواب'
      : '$answered of $total answered';
  String get quizResultsTitle => isUrdu ? 'آپ کے نتائج' : 'Your results';
  String get quizReviewAnswersTitle =>
      isUrdu ? 'آپ کے جوابات' : 'What you answered';
  String get quizYourAnswerLabel => isUrdu ? 'آپ کا جواب' : 'Your answer';
  String get quizWhyLabel => isUrdu ? 'وجہ' : 'Why';
  String get quizJuniorReviewIntro => isUrdu
      ? 'آئیے ان کو مل کر دیکھیں۔'
      : 'Let us look at these together.';
  String quizCorrectCountLabel(int correct, int total) => isUrdu
      ? '$total میں سے $correct درست'
      : '$correct of $total correct';
  String quizPassMarkLabel(double percent) => isUrdu
      ? 'پاسنگ نمبر: ${percent.toStringAsFixed(0)}٪'
      : 'Pass mark: ${percent.toStringAsFixed(0)}%';
  String quizAttemptNumberLabel(int attempt) =>
      isUrdu ? 'کوشش $attempt' : 'Attempt $attempt';
  String get quizRetakeLabel => isUrdu ? 'کوئز دوبارہ لیں' : 'Retake quiz';
  String quizRetakesLeftLabel(int remaining) => isUrdu
      ? '$remaining مواقع باقی'
      : '$remaining ${remaining == 1 ? 'try' : 'tries'} left';
  String get quizNoRetakesLeftLabel =>
      isUrdu ? 'مزید مواقع نہیں' : 'No tries left';
  String get quizUnlimitedRetakesLabel => isUrdu
      ? 'آپ جب چاہیں دوبارہ کوشش کر سکتے ہیں۔'
      : 'You can try again whenever you like.';
  String get newQuestionLabel => isUrdu ? 'نیا سوال' : 'New question';
  String get publishQuestionLabel => isUrdu ? 'شائع کریں' : 'Publish';
  String get retireQuestionLabel => isUrdu ? 'ریٹائر کریں' : 'Retire';
  String get draftStatusLabel => isUrdu ? 'مسودہ' : 'Draft';
  String get publishedStatusLabel => isUrdu ? 'شائع شدہ' : 'Published';
  String get retiredStatusLabel => isUrdu ? 'ریٹائرڈ' : 'Retired';
  String get duplicateWarning => isUrdu
      ? 'ایسا ہی سوال پہلے سے موجود ہے۔'
      : 'A similar question already exists.';
  String get juniorPreviewLabel => isUrdu ? 'جونیئر پیش نظارہ' : 'Junior preview';
  String get seniorPreviewLabel => isUrdu ? 'سینئر پیش نظارہ' : 'Senior preview';
  String get correctOptionLabel => isUrdu ? 'درست جواب' : 'Correct answer';
  String get stemLabel => isUrdu ? 'سوال' : 'Question';
  String get optionsLabel => isUrdu ? 'اختیارات' : 'Options';
  String get difficultyLabel => isUrdu ? 'مشکل' : 'Difficulty';
  String get provenanceLabel => isUrdu ? 'ماخذ' : 'Provenance';
  String get explanationLabel => isUrdu ? 'وضاحت' : 'Explanation';
  String get versionIdLabel => isUrdu ? 'ورژن شناخت' : 'Version id';
  String questionStatusLabel(String status) => switch (status) {
        'published' => publishedStatusLabel,
        'retired' => retiredStatusLabel,
        _ => draftStatusLabel,
      };
  String get noCaptionsLabel =>
      isUrdu ? 'اس ویڈیو کے کیپشنز نہیں ہیں۔' : 'This video has no captions.';
  String get videoUnavailable => isUrdu
      ? 'ویڈیو ابھی دستیاب نہیں۔'
      : 'The video is not available yet.';
  String get nextUpTitle => isUrdu ? 'اگلا کریں' : 'Do this next';
  String get topicDetailTitle => isUrdu ? 'ٹاپک' : 'Topic';
  String get topicGateFailed => isUrdu
      ? 'یہ ٹاپک ابھی کھولا نہیں جا سکتا۔'
      : "This topic can't be opened yet.";
  String get topicSaveFailed => isUrdu
      ? 'پیشرفت محفوظ نہیں ہو سکی۔ دوبارہ کوشش کریں۔'
      : "Couldn't save progress. Try again.";
  String get estimatedTimeLabel => isUrdu ? 'تخمینی وقت' : 'Estimated time';
  String percentComplete(int percent) =>
      isUrdu ? '$percent٪ مکمل' : '$percent% complete';
  String get unlockTitle => isUrdu ? 'کیسے کھلے گا' : 'How to unlock';
  String resumeFrom(int seconds) {
    final minutes = (seconds / 60).floor();
    final rem = seconds % 60;
    if (minutes == 0) {
      return isUrdu ? '$rem سیکنڈ سے جاری' : 'Resume from ${rem}s';
    }
    return isUrdu
        ? '$minutes منٹ $rem سیکنڈ سے جاری'
        : 'Resume from ${minutes}m ${rem}s';
  }

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

  /// Mode names label the same companion in a different role, so they read as
  /// "$companionName the explorer" rather than as a different character.
  String companionModeLabel(CompanionMode mode) => switch (mode) {
        CompanionMode.guide => isUrdu ? 'رہنما' : 'Guide',
        CompanionMode.explorer => isUrdu ? 'کھوجی' : 'Explorer',
        CompanionMode.quizCoach => isUrdu ? 'کوئز کوچ' : 'Quiz coach',
        CompanionMode.builder => isUrdu ? 'کاریگر' : 'Builder',
        CompanionMode.celebration => isUrdu ? 'جشن' : 'Celebration',
      };

  String companionModeBadge(String companionName, CompanionMode mode) =>
      '$companionName · ${companionModeLabel(mode)}';

  String get companionDismissLabel => isUrdu ? 'بند کریں' : 'Dismiss';

  /// MED-03. A control, not a promise: it appears only when a recording of the
  /// line on screen exists.
  String get companionListenLabel => isUrdu ? 'سنیں' : 'Listen';

  /// MED-04. Also a control rather than a promise: it appears only when an
  /// approved clip exists for this exact reaction and motion is welcome.
  String get companionPlayClipLabel => isUrdu ? 'ویڈیو چلائیں' : 'Play clip';

  /// MED-05. The superadmin publication surface. These are English-first
  /// administration words; the Urdu is provided because the shell can be read in
  /// Urdu, not because a learner ever sees them.
  String get assetReviewTitle => isUrdu ? 'میڈیا کا جائزہ' : 'Media review';
  String get assetReviewQueueEmptyTitle =>
      isUrdu ? 'جائزے کے لیے کچھ نہیں' : 'Nothing to review';
  String get assetReviewQueueEmptyBody => isUrdu
      ? 'ہر تیار شدہ اثاثہ فیصلہ پا چکا ہے۔'
      : 'Every generated asset has been decided.';
  String get assetApproveLabel => isUrdu ? 'منظور کریں' : 'Approve';
  String get assetRejectLabel => isUrdu ? 'مسترد کریں' : 'Reject';
  String get assetReturnToQueueLabel =>
      isUrdu ? 'قطار میں واپس' : 'Return to queue';
  String get assetRejectReasonLabel => isUrdu ? 'وجہ' : 'Reason';
  String get assetRejectReasonHint => isUrdu
      ? 'اگلی کوشش بہتر بنانے کے لیے وجہ لکھیں'
      : 'Say what to fix, so the next attempt is better';
  String get assetReviewHistoryLabel => isUrdu ? 'فیصلوں کی تاریخ' : 'Decisions';
  String get assetPreviewLabel => isUrdu ? 'پیش منظر' : 'Preview';
  String get assetPromptLabel => isUrdu ? 'ہدایت' : 'Prompt';
  String get assetPreviewUnavailable => isUrdu
      ? 'اس اثاثے کی فائل ابھی موجود نہیں'
      : 'This asset has no file yet';
  String get assetNotDecidable => isUrdu
      ? 'صرف تیار اثاثہ منظور ہو سکتا ہے'
      : 'Only a ready asset can be approved';

  String assetModerationLabel(GeneratedAssetModeration moderation) =>
      switch (moderation) {
        GeneratedAssetModeration.unreviewed =>
          isUrdu ? 'زیرِ جائزہ' : 'Unreviewed',
        GeneratedAssetModeration.approved => isUrdu ? 'شائع شدہ' : 'Published',
        GeneratedAssetModeration.rejected => isUrdu ? 'مسترد' : 'Rejected',
      };

  String assetReviewCount(int reviewed, int unchanged) {
    if (reviewed == 0) {
      return isUrdu
          ? 'پہلے ہی یہی فیصلہ نافذ تھا'
          : 'That decision was already in force';
    }
    if (unchanged == 0) {
      return isUrdu ? '$reviewed پر فیصلہ ہوا' : 'Decided $reviewed';
    }
    return isUrdu
        ? '$reviewed پر فیصلہ ہوا، $unchanged پہلے سے ویسے ہی تھے'
        : 'Decided $reviewed, $unchanged already were';
  }

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
