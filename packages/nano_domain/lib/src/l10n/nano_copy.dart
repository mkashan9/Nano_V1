import '../companion/companion_mode.dart';
import '../game/game_assets.dart';
import '../media/generated_asset.dart';
import '../teacher/teacher_attendance.dart';
import '../teacher/teacher_marks_grid.dart';
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
  String get gamesEmpty =>
      isUrdu ? 'ابھی کوئی کھیل دستیاب نہیں۔' : 'No games available yet.';
  String get gamesLoadError =>
      isUrdu ? 'کھیل لوڈ نہیں ہو سکے۔' : 'Could not load games.';
  String get gamesComingSoonPlay => isUrdu
      ? 'کھیلنا اگلے ماڈیول میں آئے گا۔'
      : 'Play opens in a later module.';
  String get gamesPlay => isUrdu ? 'کھیلیں' : 'Play';
  String get gamesClose => isUrdu ? 'بند کریں' : 'Close';
  String get gamesHostIntro => isUrdu
      ? 'محفوظ میزبان میں کھیلیں۔ اسکور کی تصدیق بعد میں ہو گی۔'
      : 'Play in the secure host. Score verification comes later.';
  String get gamesStartError =>
      isUrdu ? 'کھیل شروع نہیں ہو سکا۔' : 'Could not start the game.';
  String get gamesFlutterDeferred => isUrdu
      ? 'یہ کھیل فلیٹر میزبان میں بعد میں آئے گا۔'
      : 'This game opens in a later Flutter host.';
  String get gamesHttpsDeferred => isUrdu
      ? 'ریموٹ ویب کھیل ابھی رجسٹرڈ نہیں۔'
      : 'Remote web games are not registered yet.';
  String get gamesResultPendingVerify => isUrdu
      ? 'نتیجہ موصول ہو گیا۔ تصدیق بعد میں ہو گی۔'
      : 'Result received. Verification comes later.';
  String get gamesBridgeRejected => isUrdu
      ? 'غیر محفوظ پیغام نظرانداز کیا گیا۔'
      : 'Unsafe game message was ignored.';
  String get gamesSave => isUrdu ? 'محفوظ کریں' : 'Save';
  String get gamesUpdate => isUrdu ? 'اپ ڈیٹ' : 'Update';
  String get gamesFreeSpace => isUrdu ? 'جگہ خالی کریں' : 'Free space';
  String get gamesReady => isUrdu ? 'کھیلنے کے لیے تیار' : 'Ready to play';
  String get gamesNotOnDevice =>
      isUrdu ? 'اس آلے پر نہیں' : 'Not on this device';
  String get gamesUpdateAvailable =>
      isUrdu ? 'نیا ورژن دستیاب' : 'Update available';
  String get gamesStorageFailed =>
      isUrdu ? 'محفوظ نہیں ہو سکا۔' : 'Could not save this game.';
  String gamesStorageUsed(int bytes) {
    final kb = (bytes / 1024).round();
    return isUrdu ? 'محفوظ: $kb KB' : 'Saved: $kb KB';
  }
  String gamesInstallStatusLabel(GameLocalInstallStatus status) =>
      switch (status) {
        GameLocalInstallStatus.ready => gamesReady,
        GameLocalInstallStatus.notOnDevice => gamesNotOnDevice,
        GameLocalInstallStatus.updateAvailable => gamesUpdateAvailable,
        GameLocalInstallStatus.failed => gamesStorageFailed,
      };
  String gamesCategoryLabel(String category) => switch (category) {
        'challenge' => isUrdu ? 'چیلنج' : 'Challenge',
        'world' => isUrdu ? 'دنیا' : 'World',
        _ => isUrdu ? 'مشق' : 'Practice',
      };
  String get flex => isUrdu ? 'فلیکس' : 'Flex';
  String get communities => isUrdu ? 'کمیونٹیز' : 'Communities';
  String get me => isUrdu ? 'میں' : 'Me';
  String get profile => isUrdu ? 'پروفائل' : 'Profile';

  String get dashboard => isUrdu ? 'ڈیش بورڈ' : 'Dashboard';
  String get classes => isUrdu ? 'کلاسز' : 'Classes';
  String get attendance => isUrdu ? 'حاضری' : 'Attendance';
  String get marks => isUrdu ? 'نمبر' : 'Marks';
  String get classroom => isUrdu ? 'کلاس روم' : 'Classroom';
  String get feedback => isUrdu ? 'رائے' : 'Feedback';

  String get overview => isUrdu ? 'جائزہ' : 'Overview';
  String get students => isUrdu ? 'طلبہ' : 'Students';
  String get teachers => isUrdu ? 'اساتذہ' : 'Teachers';
  String get assignments => isUrdu ? 'تفویضات' : 'Assignments';
  String get reports => isUrdu ? 'رپورٹس' : 'Reports';
  String get settings => isUrdu ? 'ترتیبات' : 'Settings';
  String get schoolMetricLearners => isUrdu ? 'طلبہ' : 'Learners';
  String get schoolMetricTeachers => isUrdu ? 'اساتذہ' : 'Teachers';
  String get schoolMetricStaff => isUrdu ? 'عملہ' : 'Staff';
  String get schoolMetricClasses => isUrdu ? 'کلاسز' : 'Classes';
  String get schoolSetupTitle => isUrdu ? 'سیٹ اپ' : 'Setup progress';
  String schoolSetupProgress(int done, int total) => isUrdu
      ? '$done / $total مکمل'
      : '$done of $total complete';
  String get schoolSetupAdmin => isUrdu ? 'اسکول ایڈمن' : 'School admin assigned';
  String get schoolSetupBranding =>
      isUrdu ? 'برانڈنگ تیار' : 'Branding ready';
  String get schoolSetupContact =>
      isUrdu ? 'رابطہ تفصیل' : 'Contact details';
  String get schoolSetupYear =>
      isUrdu ? 'تعلیمی سال' : 'Academic year';
  String get schoolBrandingTitle =>
      isUrdu ? 'اسکول برانڈنگ' : 'School branding';
  String get schoolBrandingSubtitle => isUrdu
      ? 'نام، رنگ، رابطہ — کوڈ اور حیثیت یہاں نہیں بدلتے۔'
      : 'Name, colors, and contact — code and status stay elsewhere.';
  String get schoolDisplayName => isUrdu ? 'ظاہری نام' : 'Display name';
  String get schoolAcademicYear => isUrdu ? 'تعلیمی سال' : 'Academic year';
  String get schoolPrimaryColor =>
      isUrdu ? 'بنیادی رنگ' : 'Primary color';
  String get schoolSecondaryColor =>
      isUrdu ? 'ثانوی رنگ' : 'Secondary color';
  String get schoolAddress => isUrdu ? 'پتہ' : 'Address';
  String get schoolContactEmail =>
      isUrdu ? 'رابطہ ای میل' : 'Contact email';
  String get schoolContactPhone =>
      isUrdu ? 'رابطہ فون' : 'Contact phone';
  String get schoolLogoUrl => isUrdu ? 'لوگو لنک' : 'Logo URL';
  String get schoolSaveBranding =>
      isUrdu ? 'برانڈنگ محفوظ' : 'Save branding';
  String get schoolMarkSetupComplete =>
      isUrdu ? 'سیٹ اپ مکمل' : 'Mark setup complete';
  String get schoolBrandingSaved =>
      isUrdu ? 'برانڈنگ محفوظ ہو گئی' : 'Branding saved';
  String get schoolSettingsBrandingTab => isUrdu ? 'برانڈنگ' : 'Branding';
  String get schoolSettingsPoliciesTab => isUrdu ? 'پالیسیاں' : 'Policies';
  String get policiesPageTitle =>
      isUrdu ? 'نمبر اور نتائج کی پالیسیاں' : 'Marks and result policies';
  String get policiesPageSubtitle => isUrdu
      ? 'حاضری موڈ، پاس فیصد، رپورٹ کارڈ، اور نتیجہ ادوار۔'
      : 'Attendance mode, passing percent, report cards, and result periods.';
  String get policiesAttendanceLabel =>
      isUrdu ? 'حاضری موڈ' : 'Attendance mode';
  String get policiesAttendanceDaily => isUrdu ? 'روزانہ' : 'Daily';
  String get policiesAttendanceSession => isUrdu ? 'سیشن' : 'Session';
  String get policiesPassingLabel =>
      isUrdu ? 'پاس فیصد' : 'Passing percent';
  String get policiesReportFormatLabel =>
      isUrdu ? 'رپورٹ کارڈ فارمیٹ' : 'Report card format';
  String get policiesFormatPercent => isUrdu ? 'فیصد' : 'Percent';
  String get policiesFormatGrade => isUrdu ? 'گریڈ' : 'Grade';
  String get policiesFormatBoth => isUrdu ? 'دونوں' : 'Both';
  String get policiesAllowBonusLabel =>
      isUrdu ? 'بونس نمبر اجازت' : 'Allow bonus marks';
  String get policiesGradeBandsTitle =>
      isUrdu ? 'گریڈ بینڈز' : 'Grade bands';
  String get policiesSaveAction => isUrdu ? 'محفوظ' : 'Save policy';
  String get policiesSaved =>
      isUrdu ? 'پالیسی محفوظ ہو گئی۔' : 'Policy saved.';
  String get policiesPeriodsTitle =>
      isUrdu ? 'نتیجہ ادوار' : 'Result periods';
  String get policiesPeriodsEmpty =>
      isUrdu ? 'ابھی کوئی دور نہیں۔' : 'No result periods yet.';
  String get policiesCreatePeriodTitle =>
      isUrdu ? 'نیا نتیجہ دور' : 'Create result period';
  String get policiesCreatePeriodAction => isUrdu ? 'نیا دور' : 'Add period';
  String get policiesPeriodNameLabel => isUrdu ? 'نام' : 'Period name';
  String get policiesClosePeriodTitle =>
      isUrdu ? 'دور بند کریں' : 'Close period';
  String get policiesClosePeriodAction => isUrdu ? 'بند' : 'Close';
  String get policiesReasonLabel => isUrdu ? 'وجہ' : 'Reason';
  String get policiesConfirmAction => isUrdu ? 'تصدیق' : 'Confirm';
  String get teacherDashboardTitle =>
      isUrdu ? 'ڈیش بورڈ' : 'Dashboard';
  String teacherDashboardGreeting(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return isUrdu ? 'خوش آمدید' : 'Welcome';
    }
    return isUrdu ? 'خوش آمدید، $trimmed' : 'Welcome, $trimmed';
  }

  String teacherDashboardSchool(String name, String code) =>
      isUrdu ? '$name ($code)' : '$name ($code)';
  String get teacherDashboardAssignments =>
      isUrdu ? 'فعال تفویضات' : 'Active assignments';
  String get teacherDashboardPending =>
      isUrdu ? 'زیر التوا' : 'Pending';
  String get teacherDashboardPendingTitle =>
      isUrdu ? 'آنے والے کام' : 'Coming workflows';
  String get teacherDashboardPendingAttendance =>
      isUrdu ? 'حاضری' : 'Attendance';
  String get teacherDashboardPendingDrafts =>
      isUrdu ? 'مسودہ تشخیص' : 'Draft assessments';
  String get teacherDashboardPendingMarks =>
      isUrdu ? 'غیر شائع نمبر' : 'Unpublished marks';
  String get teacherDashboardPendingClassroom =>
      isUrdu ? 'کلاس روم' : 'Classroom';
  String get teacherDashboardScopeTitle =>
      isUrdu ? 'میری تفویضات' : 'My assignments';
  String get teacherDashboardScopeEmpty => isUrdu
      ? 'ابھی کوئی فعال تفویض نہیں۔'
      : 'No active assignments yet.';
  String get teacherDashboardOpenClasses =>
      isUrdu ? 'کلاسز' : 'Open classes';
  String get teacherClassesTitle => isUrdu ? 'میری کلاسز' : 'My classes';
  String get teacherClassesSubtitle => isUrdu
      ? 'صرف آپ کی فعال تفویضات۔'
      : 'Only your active assignment scopes.';
  String get teacherClassesEmpty => isUrdu
      ? 'ابھی کوئی فعال تفویض نہیں۔'
      : 'No active assignments yet.';
  String get teacherClassesBack => isUrdu ? 'واپس' : 'Back';
  String teacherClassesRosterCount(int count) =>
      isUrdu ? '$count طلبہ' : '$count students';
  String get teacherClassesRosterEmpty => isUrdu
      ? 'اس کلاس میں ابھی کوئی طالب علم نہیں۔'
      : 'No enrolled students in this class yet.';
  String get teacherClassesRosterDenied => isUrdu
      ? 'یہ تفویض آپ کے دائرے میں نہیں۔'
      : 'This assignment is not in your active scope.';
  String get teacherClassesStudentFallback =>
      isUrdu ? 'طالب علم' : 'Student';
  String get teacherAttendanceTitle => isUrdu ? 'حاضری' : 'Attendance';
  String get teacherAttendanceSubtitle => isUrdu
      ? 'تفویض اور تاریخ چنیں، حاضری جمع کرائیں۔'
      : 'Pick an assignment and date, then submit the grid.';
  String get teacherAttendanceNoAssignments => isUrdu
      ? 'حاضری کے لیے کوئی فعال تفویض نہیں۔'
      : 'No active assignments for attendance.';
  String get teacherAttendanceAssignmentLabel =>
      isUrdu ? 'تفویض' : 'Assignment';
  String get teacherAttendanceDateLabel => isUrdu ? 'تاریخ' : 'Date';
  String get teacherAttendanceMarkAllPresent =>
      isUrdu ? 'سب حاضر' : 'Mark all present';
  String get teacherAttendanceSubmit => isUrdu ? 'جمع کرائیں' : 'Submit';
  String get teacherAttendanceAlreadySubmitted =>
      isUrdu ? 'جمع ہو چکی' : 'Already submitted';
  String get teacherAttendanceSubmitted =>
      isUrdu ? 'حاضری جمع ہو گئی۔' : 'Attendance submitted.';
  String get teacherAttendanceSubmitFailed => isUrdu
      ? 'حاضری جمع نہیں ہو سکی۔'
      : 'Could not submit attendance.';
  String get teacherAttendanceRosterEmpty => isUrdu
      ? 'اس کلاس میں ابھی کوئی طالب علم نہیں۔'
      : 'No enrolled students in this class yet.';
  String get teacherAttendanceImportTitle =>
      isUrdu ? 'Excel / CSV درآمد' : 'Excel / CSV import';
  String get teacherAttendanceImportSubtitle => isUrdu
      ? 'مستحکم طالب علم شناخت استعمال کریں — نام اکیلے کافی نہیں۔'
      : 'Use stable student IDs — names alone are not enough.';
  String get teacherAttendanceImportCsvLabel =>
      isUrdu ? 'CSV مواد' : 'CSV content';
  String get teacherAttendanceLoadTemplate =>
      isUrdu ? 'سانچہ لوڈ' : 'Load template';
  String get teacherAttendanceCopyCsv => isUrdu ? 'کاپی' : 'Copy CSV';
  String get teacherAttendancePreviewImport =>
      isUrdu ? 'پیش منظر' : 'Preview import';
  String get teacherAttendanceCommitImport =>
      isUrdu ? 'درآمد محفوظ' : 'Commit import';
  String teacherAttendanceImportPreviewSummary(int ok, int fail) => isUrdu
      ? '$ok درست، $fail غلط'
      : '$ok ok, $fail failed';
  String get teacherAttendanceImportCommitted =>
      isUrdu ? 'درآمد جمع ہو گئی۔' : 'Import committed.';
  String get teacherAttendanceImportFailed => isUrdu
      ? 'درآمد ناکام۔'
      : 'Import failed.';
  String teacherAttendanceImportRowError(int row, String error) =>
      isUrdu ? 'قطار $row: $error' : 'Row $row: $error';
  String get teacherAttendanceCorrectTitle =>
      isUrdu ? 'تصحیح' : 'Correction';
  String get teacherAttendanceCorrectSubtitle => isUrdu
      ? 'جمع شدہ حاضری بدلیں — وجہ لازم ہے؛ پرانی قدر محفوظ رہتی ہے۔'
      : 'Change submitted marks with a reason — prior values are kept.';
  String get teacherAttendanceCorrectReasonLabel =>
      isUrdu ? 'تصحیح کی وجہ' : 'Correction reason';
  String get teacherAttendanceApplyCorrection =>
      isUrdu ? 'تصحیح محفوظ' : 'Apply correction';
  String get teacherAttendanceCorrected =>
      isUrdu ? 'تصحیح محفوظ ہو گئی۔' : 'Correction saved.';
  String get teacherAttendanceCorrectFailed => isUrdu
      ? 'تصحیح ناکام۔'
      : 'Could not apply correction.';
  String get teacherAttendanceHistoryTitle =>
      isUrdu ? 'تصحیح کی تاریخ' : 'Correction history';
  String get teacherAttendanceHistoryEmpty => isUrdu
      ? 'ابھی کوئی تصحیح نہیں۔'
      : 'No corrections yet.';
  String teacherAttendanceHistoryLine({
    required String name,
    required String previous,
    required String next,
    required String reason,
  }) =>
      isUrdu
          ? '$name: $previous → $next ($reason)'
          : '$name: $previous → $next ($reason)';
  String get teacherMarksTitle => isUrdu ? 'نمبر' : 'Marks';
  String get teacherClassroomTitle => isUrdu ? 'کلاس روم' : 'Classroom';
  String get teacherClassroomSubtitle => isUrdu
      ? 'تفویض چنیں اور کلاس کے اعلانات لکھیں۔'
      : 'Pick an assignment and write class announcements.';
  String get teacherClassroomNoAssignments => isUrdu
      ? 'اعلانات کے لیے کوئی فعال تفویض نہیں۔'
      : 'No active assignments for announcements.';
  String get teacherClassroomAssignmentLabel =>
      isUrdu ? 'تفویض' : 'Assignment';
  String get teacherClassroomCreateTitle =>
      isUrdu ? 'نیا اعلان' : 'New announcement';
  String get teacherClassroomEditTitle =>
      isUrdu ? 'اعلان ترمیم' : 'Edit announcement';
  String get teacherClassroomTitleLabel => isUrdu ? 'عنوان' : 'Title';
  String get teacherClassroomBodyLabel => isUrdu ? 'متن' : 'Body';
  String get teacherClassroomBodyEmpty => isUrdu ? '(خالی)' : '(empty)';
  String get teacherClassroomPublishNow =>
      isUrdu ? 'ابھی شائع کریں' : 'Publish now';
  String get teacherClassroomSaveDraft =>
      isUrdu ? 'مسودہ محفوظ' : 'Save draft';
  String get teacherClassroomUpdateDraft =>
      isUrdu ? 'مسودہ اپ ڈیٹ' : 'Update draft';
  String get teacherClassroomCancelEdit => isUrdu ? 'منسوخ' : 'Cancel';
  String get teacherClassroomSaved =>
      isUrdu ? 'اعلان محفوظ ہو گیا۔' : 'Announcement saved.';
  String get teacherClassroomSaveFailed => isUrdu
      ? 'اعلان محفوظ نہیں ہو سکا۔'
      : 'Could not save announcement.';
  String get teacherClassroomListTitle =>
      isUrdu ? 'اعلانات' : 'Announcements';
  String get teacherClassroomListEmpty => isUrdu
      ? 'ابھی کوئی اعلان نہیں۔'
      : 'No announcements yet.';
  String get teacherClassroomEditAction => isUrdu ? 'ترمیم' : 'Edit';
  String teacherClassroomListSubtitle(String status, String body) =>
      '$status · $body';
  String get teacherClassroomAttachmentsTitle =>
      isUrdu ? 'منسلکات' : 'Attachments';
  String get teacherClassroomAttachmentsSubtitle => isUrdu
      ? 'مسودہ اعلان پر لنک شامل کریں۔'
      : 'Add https links to this draft announcement.';
  String get teacherClassroomAttachmentTitleLabel =>
      isUrdu ? 'لنک عنوان' : 'Link title';
  String get teacherClassroomAttachmentUrlLabel =>
      isUrdu ? 'URL' : 'URL';
  String get teacherClassroomAddLink => isUrdu ? 'لنک شامل' : 'Add link';
  String get teacherClassroomRemoveAttachment =>
      isUrdu ? 'ہٹائیں' : 'Remove';
  String get teacherClassroomAttachmentsEmpty => isUrdu
      ? 'ابھی کوئی منسلکہ نہیں۔'
      : 'No attachments yet.';
  String get teacherClassroomAttachmentAdded =>
      isUrdu ? 'منسلکہ شامل ہو گیا۔' : 'Attachment added.';
  String get teacherClassroomAttachmentRemoved =>
      isUrdu ? 'منسلکہ ہٹا دیا گیا۔' : 'Attachment removed.';
  String get teacherClassroomAttachmentFailed => isUrdu
      ? 'منسلکہ ناکام۔'
      : 'Could not update attachment.';
  String teacherClassroomAttachmentCount(int count) => isUrdu
      ? '$count منسلکات'
      : '$count attachment${count == 1 ? '' : 's'}';
  String get teacherClassroomScheduleLabel =>
      isUrdu ? 'شیڈول اشاعت' : 'Schedule publish';
  String get teacherClassroomExpiryLabel =>
      isUrdu ? 'میعاد ختم' : 'Expires on';
  String get teacherClassroomClearSchedule =>
      isUrdu ? 'شیڈول صاف' : 'Clear schedule';
  String get teacherClassroomClearExpiry =>
      isUrdu ? 'میعاد صاف' : 'Clear expiry';
  String get teacherClassroomRequiresAck =>
      isUrdu ? 'تسلیم درکار' : 'Require acknowledgement';
  String teacherClassroomAckSummary(int ack, int roster) => isUrdu
      ? '$ack/$roster تسلیم'
      : '$ack/$roster acknowledged';
  String get teacherMarksSubtitle => isUrdu
      ? 'تفویض چنیں، مسودہ تشخیص بنائیں، اور نمبر درج کریں۔'
      : 'Pick an assignment, create draft assessments, and enter marks.';
  String get teacherMarksNoAssignments => isUrdu
      ? 'تشخیص کے لیے کوئی فعال تفویض نہیں۔'
      : 'No active assignments for assessments.';
  String get teacherMarksAssignmentLabel =>
      isUrdu ? 'تفویض' : 'Assignment';
  String get teacherMarksCreateTitle =>
      isUrdu ? 'نیا مسودہ' : 'New draft assessment';
  String get teacherMarksEditTitle =>
      isUrdu ? 'مسودہ ترمیم' : 'Edit draft assessment';
  String get teacherMarksCategoryLabel =>
      isUrdu ? 'قسم' : 'Category';
  String get teacherMarksNameLabel => isUrdu ? 'نام' : 'Name';
  String get teacherMarksDateLabel => isUrdu ? 'تاریخ' : 'Date';
  String get teacherMarksTotalLabel =>
      isUrdu ? 'کل نمبر' : 'Total marks';
  String get teacherMarksWeightLabel =>
      isUrdu ? 'وزن (اختیاری)' : 'Weight (optional)';
  String get teacherMarksDescriptionLabel =>
      isUrdu ? 'تفصیل' : 'Description';
  String get teacherMarksSaveDraft =>
      isUrdu ? 'مسودہ محفوظ' : 'Save draft';
  String get teacherMarksUpdateDraft =>
      isUrdu ? 'مسودہ اپڈیٹ' : 'Update draft';
  String get teacherMarksCancelEdit => isUrdu ? 'منسوخ' : 'Cancel';
  String get teacherMarksSaved =>
      isUrdu ? 'مسودہ محفوظ ہو گیا۔' : 'Draft assessment saved.';
  String get teacherMarksSaveFailed => isUrdu
      ? 'مسودہ محفوظ نہیں ہو سکا۔'
      : 'Could not save assessment draft.';
  String get teacherMarksListTitle =>
      isUrdu ? 'تشخیصات' : 'Assessments';
  String get teacherMarksListEmpty => isUrdu
      ? 'ابھی کوئی تشخیص نہیں۔'
      : 'No assessments yet.';
  String get teacherMarksEditAction => isUrdu ? 'ترمیم' : 'Edit';
  String get teacherMarksEnterAction =>
      isUrdu ? 'نمبر درج' : 'Enter marks';
  String get teacherMarksGridTitle =>
      isUrdu ? 'نمبر گرڈ' : 'Marks grid';
  String get teacherMarksGridSubtitle => isUrdu
      ? 'مسودہ تشخیص کے لیے نمبر محفوظ کریں — اشاعت بعد میں۔'
      : 'Save draft marks for this assessment — publish comes later.';
  String get teacherMarksSaveGrid =>
      isUrdu ? 'نمبر محفوظ' : 'Save marks';
  String get teacherMarksCloseGrid =>
      isUrdu ? 'گرڈ بند' : 'Close grid';
  String get teacherMarksImportTitle =>
      isUrdu ? 'Excel / CSV درآمد' : 'Excel / CSV import';
  String get teacherMarksImportSubtitle => isUrdu
      ? 'مستحکم طالب علم شناخت استعمال کریں — نام اکیلے کافی نہیں۔'
      : 'Use stable student IDs — names alone are not enough.';
  String get teacherMarksImportCsvLabel =>
      isUrdu ? 'CSV مواد' : 'CSV content';
  String get teacherMarksLoadTemplate =>
      isUrdu ? 'سانچہ لوڈ' : 'Load template';
  String get teacherMarksCopyCsv => isUrdu ? 'کاپی' : 'Copy CSV';
  String get teacherMarksPreviewImport =>
      isUrdu ? 'پیش منظر' : 'Preview import';
  String get teacherMarksCommitImport =>
      isUrdu ? 'درآمد محفوظ' : 'Commit import';
  String teacherMarksImportPreviewSummary(int ok, int fail) => isUrdu
      ? '$ok درست، $fail غلط'
      : '$ok ok, $fail failed';
  String get teacherMarksImportCommitted =>
      isUrdu ? 'درآمد جمع ہو گئی۔' : 'Import committed.';
  String get teacherMarksImportFailed => isUrdu
      ? 'درآمد ناکام۔'
      : 'Import failed.';
  String teacherMarksImportRowError(int row, String error) =>
      isUrdu ? 'قطار $row: $error' : 'Row $row: $error';
  String get teacherMarksGridSaved =>
      isUrdu ? 'نمبر محفوظ ہو گئے۔' : 'Marks saved.';
  String get teacherMarksGridSaveFailed => isUrdu
      ? 'نمبر محفوظ نہیں ہو سکے۔'
      : 'Could not save marks.';
  String get teacherMarksGridEmpty => isUrdu
      ? 'اس کلاس میں ابھی کوئی طالب علم نہیں۔'
      : 'No enrolled students in this class yet.';
  String get teacherMarksObtainedLabel =>
      isUrdu ? 'حاصل' : 'Obtained';
  String get teacherMarksRemarksLabel =>
      isUrdu ? 'نوٹ' : 'Remarks';
  String teacherMarksEntryStatusLabel(MarksEntryStatus status) {
    if (isUrdu) {
      return switch (status) {
        MarksEntryStatus.scored => 'نمبر',
        MarksEntryStatus.absent => 'غیر حاضر',
        MarksEntryStatus.exempt => 'مستثنی',
        MarksEntryStatus.notSubmitted => 'جمع نہیں',
      };
    }
    return switch (status) {
      MarksEntryStatus.scored => 'Scored',
      MarksEntryStatus.absent => 'Absent',
      MarksEntryStatus.exempt => 'Exempt',
      MarksEntryStatus.notSubmitted => 'Not submitted',
    };
  }

  String get teacherMarksPublishAction =>
      isUrdu ? 'شائع کریں' : 'Publish marks';
  String get teacherMarksPublished =>
      isUrdu ? 'تشخیص شائع ہو گئی۔' : 'Assessment published.';
  String get teacherMarksPublishFailed => isUrdu
      ? 'شائع نہیں ہو سکی۔'
      : 'Could not publish assessment.';
  String get teacherMarksOpenAction => isUrdu ? 'کھولیں' : 'Open marks';
  String get teacherMarksCorrectTitle =>
      isUrdu ? 'تصحیح' : 'Correction';
  String get teacherMarksCorrectSubtitle => isUrdu
      ? 'شائع شدہ نمبر بدلیں — وجہ لازم ہے؛ پرانی قدر محفوظ رہتی ہے۔'
      : 'Change published marks with a reason — prior values are kept.';
  String get teacherMarksCorrectReasonLabel =>
      isUrdu ? 'تصحیح کی وجہ' : 'Correction reason';
  String get teacherMarksApplyCorrection =>
      isUrdu ? 'تصحیح محفوظ' : 'Apply correction';
  String get teacherMarksCorrected =>
      isUrdu ? 'تصحیح محفوظ ہو گئی۔' : 'Correction saved.';
  String get teacherMarksCorrectFailed => isUrdu
      ? 'تصحیح ناکام۔'
      : 'Could not apply correction.';
  String get teacherMarksHistoryTitle =>
      isUrdu ? 'تصحیح کی تاریخ' : 'Correction history';
  String get teacherMarksHistoryEmpty => isUrdu
      ? 'ابھی کوئی تصحیح نہیں۔'
      : 'No corrections yet.';
  String teacherMarksHistoryLine({
    required String name,
    required String previous,
    required String next,
    required String reason,
  }) =>
      isUrdu
          ? '$name: $previous → $next ($reason)'
          : '$name: $previous → $next ($reason)';
  String teacherMarksStatusValueLabel(
    MarksEntryStatus status, [
    double? obtained,
  ]) {
    final base = teacherMarksEntryStatusLabel(status);
    if (status == MarksEntryStatus.scored && obtained != null) {
      return '$base $obtained';
    }
    return base;
  }

  String get teacherMarksSummaryTitle =>
      isUrdu ? 'نتائج کا خلاصہ' : 'Result summary';
  String get teacherMarksSummarySubtitle => isUrdu
      ? 'شائع شدہ تشخیص کی کلاسی کارکردگی۔'
      : 'Class performance for this published assessment.';
  String teacherMarksSummaryAverage(double value) =>
      isUrdu ? 'اوسط $value%' : 'Average $value%';
  String teacherMarksSummaryPassRate(double? value) => value == null
      ? (isUrdu ? 'پاس شرح —' : 'Pass rate —')
      : (isUrdu ? 'پاس شرح $value%' : 'Pass rate $value%');
  String teacherMarksSummaryScored(int scored, int roster) => isUrdu
      ? 'نمبر والے $scored / $roster'
      : 'Scored $scored / $roster';
  String teacherMarksSummaryGrades(String line) =>
      isUrdu ? 'درجات: $line' : 'Grades: $line';
  String teacherMarksSummaryStudentLine({
    required String name,
    required String detail,
  }) =>
      '$name · $detail';

  String teacherMarksListSubtitle(
    String category,
    String date,
    double total,
    String status,
  ) =>
      isUrdu
          ? '$category · $date · $total · $status'
          : '$category · $date · $total · $status';
  String teacherAttendanceStatusLabel(AttendanceEntryStatus status) {
    if (isUrdu) {
      return switch (status) {
        AttendanceEntryStatus.present => 'حاضر',
        AttendanceEntryStatus.absent => 'غیر حاضر',
        AttendanceEntryStatus.late => 'دیر',
        AttendanceEntryStatus.leave => 'چھٹی',
        AttendanceEntryStatus.excused => 'معاف',
      };
    }
    return switch (status) {
      AttendanceEntryStatus.present => 'Present',
      AttendanceEntryStatus.absent => 'Absent',
      AttendanceEntryStatus.late => 'Late',
      AttendanceEntryStatus.leave => 'Leave',
      AttendanceEntryStatus.excused => 'Excused',
    };
  }

  String get reportsPageTitle => isUrdu ? 'رپورٹس' : 'Reports';
  String get reportsPageSubtitle => isUrdu
      ? 'اسکول کے محفوظ خلاصے — طالب علم کے ذاتی رابطے نہیں۔'
      : 'Privacy-safe school summaries — no learner contact details.';
  String reportsGeneratedAt(String iso) =>
      isUrdu ? 'تیار: $iso' : 'Generated: $iso';
  String get reportsLearners => isUrdu ? 'طلبہ' : 'Learners';
  String get reportsTeachers => isUrdu ? 'اساتذہ' : 'Teachers';
  String get reportsClasses => isUrdu ? 'کلاسز' : 'Classes';
  String get reportsSubjects => isUrdu ? 'مضامین' : 'Subjects';
  String get reportsCoverageTitle =>
      isUrdu ? 'تفویض کوریج' : 'Assignment coverage';
  String get reportsActiveAssignments =>
      isUrdu ? 'فعال تفویضات' : 'Active assignments';
  String get reportsUncovered =>
      isUrdu ? 'بغیر استاد مضامین' : 'Uncovered subjects';
  String get reportsTeachersAssigned =>
      isUrdu ? 'تفویض شدہ اساتذہ' : 'Teachers with assignments';
  String get reportsCoverageGapHint => isUrdu
      ? 'کچھ کلاس مضامین ابھی بغیر استاد ہیں۔'
      : 'Some class subjects still need a teacher.';
  String get reportsEnrollmentTitle => isUrdu ? 'اندراج' : 'Enrollment';
  String get reportsStudentsWithClass =>
      isUrdu ? 'کلاس والے طلبہ' : 'Students with class';
  String get reportsStudentsWithoutClass =>
      isUrdu ? 'بغیر کلاس طلبہ' : 'Students without class';
  String get reportsResultsTitle =>
      isUrdu ? 'نتائج پالیسی' : 'Results policy';
  String get reportsOpenPeriods => isUrdu ? 'کھلے ادوار' : 'Open periods';
  String get reportsClosedPeriods => isUrdu ? 'بند ادوار' : 'Closed periods';
  String get reportsPassingPercent => isUrdu ? 'پاس فیصد' : 'Passing percent';
  String get reportsAttendanceMode =>
      isUrdu ? 'حاضری موڈ' : 'Attendance mode';
  String get reportsWorkloadTitle =>
      isUrdu ? 'استاد ورکلوڈ' : 'Teacher workload';
  String get reportsWorkloadEmpty =>
      isUrdu ? 'ابھی کوئی استاد نہیں۔' : 'No teachers yet.';
  String reportsWorkloadValue(int count) =>
      isUrdu ? '$count فعال' : '$count active';
  String get schoolEditBranding =>
      isUrdu ? 'برانڈنگ تبدیل' : 'Edit branding';
  String get schoolYearMissing =>
      isUrdu ? 'تعلیمی سال نہیں' : 'No academic year yet';
  String get classesPageTitle => isUrdu ? 'کلاسز' : 'Classes';
  String get classesPageSubtitle => isUrdu
      ? 'گریڈ، کلاس، سیکشن اور مضامین — محفوظ محفوظ کریں، حذف نہ کریں۔'
      : 'Grades, classes, sections, and subjects — archive instead of delete.';
  String get classesEmpty =>
      isUrdu ? 'ابھی کوئی گریڈ یا کلاس نہیں۔' : 'No grades or classes yet.';
  String get classesLoadError =>
      isUrdu ? 'ساخت لوڈ نہیں ہو سکی۔' : 'Could not load academic structure.';
  String get classesCreateGradeTitle =>
      isUrdu ? 'نیا گریڈ' : 'Add grade';
  String get classesCreateClassTitle =>
      isUrdu ? 'نئی کلاس' : 'Add class';
  String get classesCreateSectionTitle =>
      isUrdu ? 'نیا سیکشن' : 'Add section';
  String get classesCreateSubjectTitle =>
      isUrdu ? 'نیا مضمون' : 'Add subject';
  String get classesAssignSubjectTitle =>
      isUrdu ? 'مضمون تفویض' : 'Assign subject';
  String get classesCreateAction => isUrdu ? 'بنائیں' : 'Create';
  String get classesAssignAction => isUrdu ? 'تفویض' : 'Assign';
  String get classesArchiveAction => isUrdu ? 'محفوظ' : 'Archive';
  String get classesGradeNameLabel => isUrdu ? 'گریڈ نام' : 'Grade name';
  String get classesClassNameLabel => isUrdu ? 'کلاس نام' : 'Class name';
  String get classesSectionNameLabel =>
      isUrdu ? 'سیکشن نام' : 'Section name';
  String get classesSubjectNameLabel =>
      isUrdu ? 'مضمون نام' : 'Subject name';
  String get classesSubjectCodeLabel =>
      isUrdu ? 'مضمون کوڈ' : 'Subject code';
  String get classesNeedGradeFirst =>
      isUrdu ? 'پہلے گریڈ بنائیں۔' : 'Create a grade first.';
  String get classesNeedSubjectFirst =>
      isUrdu ? 'پہلے مضمون بنائیں۔' : 'Create a subject first.';
  String get classesMappingIssuesTitle =>
      isUrdu ? 'نقشہ مسائل' : 'Mapping issues';
  String classesMissingSubjects(String className) => isUrdu
      ? '$className میں کوئی فعال مضمون نہیں۔'
      : '$className has no active subjects.';
  String get classesGradesHeading => isUrdu ? 'گریڈز' : 'Grades';
  String get classesClassesHeading => isUrdu ? 'کلاسز' : 'Classes';
  String get classesSubjectsHeading => isUrdu ? 'مضامین' : 'Subjects';
  String get teachersPageTitle => isUrdu ? 'اساتذہ' : 'Teachers';
  String get teachersPageSubtitle => isUrdu
      ? 'فہرست، نیا استاد، معطل، CSV درآمد۔'
      : 'List, create, suspend, and CSV import teachers.';
  String get teachersEmpty =>
      isUrdu ? 'ابھی کوئی استاد نہیں۔' : 'No teachers yet.';
  String get teachersCreateTitle => isUrdu ? 'نیا استاد' : 'Add teacher';
  String get teachersCreateAction => isUrdu ? 'بنائیں' : 'Create';
  String get teachersNameLabel => isUrdu ? 'نام' : 'Display name';
  String get teachersEmailLabel => isUrdu ? 'ای میل' : 'Email';
  String get teachersSearchHint =>
      isUrdu ? 'نام یا ای میل' : 'Search name or email';
  String get teachersSuspendTitle => isUrdu ? 'معطل' : 'Suspend';
  String get teachersRestoreTitle => isUrdu ? 'بحال' : 'Restore';
  String get teachersReasonLabel => isUrdu ? 'وجہ' : 'Reason';
  String get teachersConfirmAction => isUrdu ? 'تصدیق' : 'Confirm';
  String get teachersTempPasswordTitle =>
      isUrdu ? 'عارضی پاس ورڈ' : 'Temporary password';
  String get teachersCopyPassword =>
      isUrdu ? 'کاپی کریں' : 'Copy password';
  String get teachersImportTitle =>
      isUrdu ? 'CSV درآمد' : 'CSV import';
  String get teachersImportSubtitle => isUrdu
      ? 'کالم: display_name,email — سانچہ ڈاؤن لوڈ کریں یا فائل چنیں، پھر پیش منظر۔'
      : 'Columns: display_name,email — download the template or choose a CSV, then Preview.';
  String get teachersPreviewImport => isUrdu ? 'پیش منظر' : 'Preview';
  String get teachersCommitImport => isUrdu ? 'محفوظ درآمد' : 'Commit import';
  String get teachersLoadTemplate =>
      isUrdu ? 'سانچہ پیسٹ کریں' : 'Paste template';
  String get teachersDownloadTemplate =>
      isUrdu ? 'سانچہ ڈاؤن لوڈ' : 'Download template';
  String get teachersChooseCsv =>
      isUrdu ? 'CSV فائل چنیں' : 'Choose CSV file';
  String teachersImportPreviewSummary(int ok, int fail) => isUrdu
      ? '$ok ٹھیک، $fail ناکام'
      : '$ok ready, $fail failed';
  String get studentsPageTitle => isUrdu ? 'طلبہ' : 'Students';
  String get studentsPageSubtitle => isUrdu
      ? 'فہرست، نیا طالب علم، معطل، CSV درآمد، کلاس اندراج۔'
      : 'List, create, suspend, CSV import, and class enrollment.';
  String get studentsEmpty =>
      isUrdu ? 'ابھی کوئی طالب علم نہیں۔' : 'No students yet.';
  String get studentsCreateTitle => isUrdu ? 'نیا طالب علم' : 'Add student';
  String get studentsCreateAction => isUrdu ? 'بنائیں' : 'Create';
  String get studentsNameLabel => isUrdu ? 'نام' : 'Display name';
  String get studentsEmailLabel => isUrdu ? 'ای میل' : 'Email';
  String get studentsSearchHint =>
      isUrdu ? 'نام، ای میل یا کلاس' : 'Search name, email, or class';
  String get studentsSuspendTitle => isUrdu ? 'معطل' : 'Suspend';
  String get studentsRestoreTitle => isUrdu ? 'بحال' : 'Restore';
  String get studentsReasonLabel => isUrdu ? 'وجہ' : 'Reason';
  String get studentsConfirmAction => isUrdu ? 'تصدیق' : 'Confirm';
  String get studentsTempPasswordTitle =>
      isUrdu ? 'عارضی پاس ورڈ' : 'Temporary password';
  String get studentsCopyPassword =>
      isUrdu ? 'کاپی کریں' : 'Copy password';
  String get studentsImportTitle =>
      isUrdu ? 'CSV درآمد' : 'CSV import';
  String get studentsImportSubtitle => isUrdu
      ? 'کالم: display_name,email,class_name — فائل چنیں یا پیش منظر دبائیں؛ صرف صفر ناکامی پر محفوظ درآمد چالو ہوگا۔ class_name فعال کلاس سے میل کھانا چاہیے۔'
      : 'Columns: display_name,email,class_name — Choose CSV or tap Preview; Commit enables only when every row passes. class_name must match an active class.';
  String get studentsPreviewImport => isUrdu ? 'پیش منظر' : 'Preview';
  String get studentsCommitImport => isUrdu ? 'محفوظ درآمد' : 'Commit import';
  String get studentsLoadTemplate =>
      isUrdu ? 'سانچہ پیسٹ کریں' : 'Paste template';
  String get studentsDownloadTemplate =>
      isUrdu ? 'سانچہ ڈاؤن لوڈ' : 'Download template';
  String get studentsChooseCsv =>
      isUrdu ? 'CSV فائل چنیں' : 'Choose CSV file';
  String studentsImportPreviewSummary(int ok, int fail) => isUrdu
      ? '$ok ٹھیک، $fail ناکام'
      : '$ok ready, $fail failed';
  String get assignmentsPageTitle => isUrdu ? 'تفویضات' : 'Assignments';
  String get assignmentsPageSubtitle => isUrdu
      ? 'استاد کو کلاس، سیکشن، مضمون تفویض کریں؛ کوریج اور ورکلوڈ دیکھیں۔'
      : 'Assign teachers to class/section/subject; review coverage and workload.';
  String get assignmentsEmpty =>
      isUrdu ? 'ابھی کوئی تفویض نہیں۔' : 'No assignments yet.';
  String get assignmentsCreateTitle =>
      isUrdu ? 'نئی تفویض' : 'Assign teacher';
  String get assignmentsCreateAction => isUrdu ? 'تفویض' : 'Assign';
  String get assignmentsTeacherLabel => isUrdu ? 'استاد' : 'Teacher';
  String get assignmentsClassLabel => isUrdu ? 'کلاس' : 'Class';
  String get assignmentsSubjectLabel => isUrdu ? 'مضمون' : 'Subject';
  String get assignmentsSectionLabel =>
      isUrdu ? 'سیکشن (اختیاری)' : 'Section (optional)';
  String get assignmentsSectionNone =>
      isUrdu ? 'پوری کلاس' : 'Whole class';
  String get assignmentsEndTitle => isUrdu ? 'تفویض ختم' : 'End assignment';
  String get assignmentsEndAction => isUrdu ? 'ختم' : 'End';
  String get assignmentsReplaceTitle =>
      isUrdu ? 'استاد تبدیل' : 'Replace teacher';
  String get assignmentsReplaceAction => isUrdu ? 'تبدیل' : 'Replace';
  String get assignmentsReasonLabel => isUrdu ? 'وجہ' : 'Reason';
  String get assignmentsConfirmAction => isUrdu ? 'تصدیق' : 'Confirm';
  String get assignmentsNeedAnotherTeacher => isUrdu
      ? 'تبدیلی کے لیے دوسرا استاد درکار ہے۔'
      : 'Need another teacher to replace.';
  String get assignmentsListTitle =>
      isUrdu ? 'تفویض فہرست' : 'Assignment list';
  String get assignmentsWorkloadTitle => isUrdu ? 'ورکلوڈ' : 'Workload';
  String assignmentsWorkloadValue(int count) =>
      isUrdu ? '$count فعال' : '$count active';
  String get assignmentsUncoveredTitle =>
      isUrdu ? 'بغیر استاد مضامین' : 'Uncovered subjects';
  String get assignmentsConflictsTitle =>
      isUrdu ? 'مشترکہ تفویضات' : 'Co-assignments';
  String get assignmentsActiveCount => isUrdu ? 'فعال' : 'Active';
  String get assignmentsUncoveredCount => isUrdu ? 'کھلے' : 'Uncovered';
  String get assignmentsConflictCount => isUrdu ? 'مشترکہ' : 'Shared';
  String get platform => isUrdu ? 'پلیٹ فارم' : 'Platform';
  String get platformDashboardTitle =>
      isUrdu ? 'پلیٹ فارم ڈیش بورڈ' : 'Platform dashboard';
  String get platformDashboardSubtitle => isUrdu
      ? 'محفوظ خلاصے — ذاتی رابطے یہاں نہیں دکھتے۔'
      : 'Safe operational summaries — personal contact details stay off this screen.';
  String get platformMetricSchools => isUrdu ? 'اسکول' : 'Schools';
  String get platformMetricActiveSchools =>
      isUrdu ? 'فعال اسکول' : 'Active schools';
  String get platformMetricLearners => isUrdu ? 'طلبہ' : 'Learners';
  String get platformMetricStaff => isUrdu ? 'عملہ' : 'Staff';
  String get platformMetricSuspended =>
      isUrdu ? 'معطل پروفائلز' : 'Suspended profiles';
  String get platformMetricIncidents =>
      isUrdu ? 'کھلے واقعات' : 'Open incidents';
  String get platformShortcutsTitle => isUrdu ? 'مختصر راستے' : 'Shortcuts';
  String get platformSchoolsTitle =>
      isUrdu ? 'اسکول ڈائریکٹری' : 'School directory';
  String get platformSchoolSearchHint =>
      isUrdu ? 'نام یا کوڈ سے تلاش' : 'Search by name or code';
  String get platformSchoolsEmpty =>
      isUrdu ? 'کوئی اسکول نہیں ملا۔' : 'No schools matched.';
  String get platformAuditTitle =>
      isUrdu ? 'حالیہ آڈٹ' : 'Recent audit';
  String get platformAuditEmpty =>
      isUrdu ? 'ابھی کوئی آڈٹ نہیں۔' : 'No recent audit events.';
  String get schools => isUrdu ? 'اسکول' : 'Schools';
  String get schoolsPageTitle => isUrdu ? 'اسکول انتظام' : 'Schools';
  String get schoolsPageSubtitle => isUrdu
      ? 'نیا اسکول بنائیں، حیثیت بدلیں، پہلا ایڈمن تفویض کریں۔'
      : 'Create schools, change status with a reason, and assign the first admin.';
  String get schoolsCreateTitle => isUrdu ? 'نیا اسکول' : 'Create school';
  String get schoolsCreateAction => isUrdu ? 'بنائیں' : 'Create';
  String get schoolsCodeLabel => isUrdu ? 'کوڈ' : 'Code';
  String get schoolsNameLabel => isUrdu ? 'نام' : 'Name';
  String get schoolsStatusTitle => isUrdu ? 'حیثیت بدلیں' : 'Change status';
  String get schoolsStatusAction => isUrdu ? 'حیثیت' : 'Status';
  String get schoolsSaveStatusAction => isUrdu ? 'محفوظ کریں' : 'Save status';
  String get schoolsReasonLabel => isUrdu ? 'وجہ' : 'Reason';
  String get schoolsAssignAdminTitle =>
      isUrdu ? 'پہلا ایڈمن' : 'Assign first admin';
  String get schoolsAssignAdminAction => isUrdu ? 'ایڈمن' : 'Assign admin';
  String get schoolsAdminUserIdLabel =>
      isUrdu ? 'صارف شناخت' : 'User id';
  String get schoolsHasAdmin => isUrdu ? 'ایڈمن موجود' : 'Has admin';
  String get schoolsNeedsAdmin => isUrdu ? 'ایڈمن درکار' : 'Needs admin';
  String get cancelLabel => isUrdu ? 'منسوخ' : 'Cancel';
  String get users => isUrdu ? 'صارفین' : 'Users';
  String get usersPageTitle => isUrdu ? 'صارف کنٹرول' : 'Users';
  String get usersPageSubtitle => isUrdu
      ? 'تلاش، معطل/بحال، ایڈمن تبدیل، سیشن منسوخ — وجہ لازمی۔'
      : 'Search, suspend/restore, replace admin, revoke sessions — reason required.';
  String get usersSearchHint =>
      isUrdu ? 'نام یا شناخت تلاش' : 'Search by name or id';
  String get usersEmpty => isUrdu ? 'کوئی صارف نہیں ملا۔' : 'No users matched.';
  String get usersReasonLabel => isUrdu ? 'وجہ' : 'Reason';
  String get usersConfirmAction => isUrdu ? 'تصدیق' : 'Confirm';
  String get usersSuspendTitle => isUrdu ? 'صارف معطل کریں' : 'Suspend user';
  String get usersRestoreTitle => isUrdu ? 'صارف بحال کریں' : 'Restore user';
  String get usersSuspendAction => isUrdu ? 'معطل' : 'Suspend';
  String get usersRestoreAction => isUrdu ? 'بحال' : 'Restore';
  String get usersRevokeSessionsTitle =>
      isUrdu ? 'سیشن منسوخ کریں' : 'Revoke sessions';
  String get usersRevokeAction => isUrdu ? 'سیشن' : 'Revoke';
  String usersRevokedCount(int count) => isUrdu
      ? '$count سیشن منسوخ'
      : '$count session(s) revoked';
  String usersSessionsLabel(int count) =>
      isUrdu ? '$count فعال سیشن' : '$count active sessions';
  String get usersReplaceAdminTitle =>
      isUrdu ? 'اسکول ایڈمن تبدیل' : 'Replace school admin';
  String get usersReplaceAdminAction => isUrdu ? 'تبدیل' : 'Replace admin';
  String get usersNewAdminIdLabel =>
      isUrdu ? 'نیا ایڈمن شناخت' : 'New admin user id';
  String get content => isUrdu ? 'مواد' : 'Content';
  String get moderation => isUrdu ? 'نگرانی' : 'Moderation';
  String get analytics => isUrdu ? 'تجزیات' : 'Analytics';
  String get analyticsPageTitle =>
      isUrdu ? 'پلیٹ فارم تجزیات' : 'Platform analytics';
  String get analyticsPageSubtitle => isUrdu
      ? 'محفوظ مجموعی اعداد — کوئی ذاتی رابطہ یا نمبر نہیں۔'
      : 'Safe aggregates only — no personal contact or marks.';
  String get analyticsHealthTitle =>
      isUrdu ? 'صحت' : 'Platform health';
  String get analyticsCatalogTitle =>
      isUrdu ? 'کیٹلاگ' : 'Catalog readiness';
  String get analyticsActivityTitle =>
      isUrdu ? '۷ دن کی سرگرمی' : 'Last 7 days';
  String get analyticsActionsTitle =>
      isUrdu ? 'آڈٹ اعمال' : 'Audit actions (7d)';
  String get analyticsActionsEmpty =>
      isUrdu ? 'ابھی کوئی آڈٹ نہیں۔' : 'No audit events yet.';
  String get analyticsActiveSchools =>
      isUrdu ? 'فعال اسکول' : 'Active schools';
  String get analyticsSuspendedSchools =>
      isUrdu ? 'معطل اسکول' : 'Suspended schools';
  String get analyticsActiveLearners =>
      isUrdu ? 'فعال طلبہ' : 'Active learners';
  String get analyticsIndependentLearners =>
      isUrdu ? 'آزاد طلبہ' : 'Independent learners';
  String get analyticsOpenIncidents =>
      isUrdu ? 'کھلے واقعات' : 'Open incidents';
  String get analyticsAssetsReview =>
      isUrdu ? 'جائزہ باقی' : 'Assets to review';
  String get analyticsPublishedSubjects =>
      isUrdu ? 'شائع مضامین' : 'Published subjects';
  String get analyticsPublishedTopics =>
      isUrdu ? 'شائع موضوعات' : 'Published topics';
  String get analyticsLiveGames => isUrdu ? 'لائیو گیمز' : 'Live games';
  String get analyticsLiveNotifications =>
      isUrdu ? 'لائیو اطلاعات' : 'Live templates';
  String get analyticsTopicCompletions =>
      isUrdu ? 'مکمل موضوعات' : 'Topic completions';
  String get analyticsXpAwards => isUrdu ? 'ایکس پی' : 'XP awards';
  String get analyticsQuizPasses =>
      isUrdu ? 'کوئز پاس' : 'Quiz passes';
  String get analyticsAuditEvents =>
      isUrdu ? 'آڈٹ واقعات' : 'Audit events';
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
  String get streakWelcomeBack => isUrdu
      ? 'خوش آمدید۔ آرام سیکھنے کا حصہ ہے — نیا سلسلہ تب شروع ہوگا جب آپ تیار ہوں۔'
      : 'Welcome back. Rest is part of learning — a new streak starts when you are ready.';
  String get notificationsLabel => isUrdu ? 'اطلاعات' : 'Notifications';
  String get missionXpAvailable => isUrdu ? 'دستیاب XP' : 'XP to earn';
  String percentDone(int percent) =>
      isUrdu ? '$percent% مکمل' : '$percent% done';
  String get profileTitle => isUrdu ? 'پروفائل' : 'Profile';
  String get progressLabel => isUrdu ? 'پیش رفت' : 'Progress';
  String get topicsCompleted => isUrdu ? 'مکمل ٹاپکس' : 'Topics completed';
  String get nextUpLabel => isUrdu ? 'اگلا مرحلہ' : 'Next up';
  String get achievementsLabel => isUrdu ? 'اعزازات' : 'Achievements';
  String get featuredAchievementsLabel =>
      isUrdu ? 'نمایاں اعزازات' : 'Featured';
  String get shareAchievementLabel => isUrdu ? 'شیئر کریں' : 'Share';
  String get shareScoreLabel => isUrdu ? 'سکور شیئر کریں' : 'Share score';
  String get shareCopiedSnack =>
      isUrdu ? 'شیئر متن کاپی ہو گیا' : 'Share text copied';
  String get pinAchievementLabel => isUrdu ? 'نمایاں کریں' : 'Feature';
  String get unpinAchievementLabel =>
      isUrdu ? 'نمایاں ہٹائیں' : 'Unfeature';
  String get featuredLimitHint => isUrdu
      ? 'زیادہ سے زیادہ تین اعزازات نمایاں کر سکتے ہیں۔'
      : 'You can feature up to three achievements.';
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
  String get flexSubtitle => isUrdu
      ? 'حاضری، نمبر، اور کلاس روم — صرف اسکول والے طلبہ۔'
      : 'Attendance, marks, and classroom — for school-linked students.';
  String get flexAttendanceTitle => isUrdu ? 'حاضری' : 'Attendance';
  String get flexAttendanceSubtitle => isUrdu
      ? 'آپ کے دن اور خلاصہ۔'
      : 'Your days and summaries.';
  String get studentAttendanceSubtitle => isUrdu
      ? 'صرف آپ کی جمع شدہ حاضری۔'
      : 'Only your submitted attendance.';
  String get studentAttendanceEmpty => isUrdu
      ? 'اس مہینے کوئی ریکارڈ نہیں۔'
      : 'No attendance recorded this month.';
  String studentAttendanceCounts(int present, int absent, int late) => isUrdu
      ? 'حاضر $present · غیر حاضر $absent · دیر $late'
      : 'Present $present · Absent $absent · Late $late';
  String get flexMarksTitle => isUrdu ? 'نمبر' : 'Marks';
  String get flexMarksSubtitle => isUrdu
      ? 'شائع شدہ نتائج۔'
      : 'Published results.';
  String get studentMarksSubtitle => isUrdu
      ? 'صرف آپ کے شائع شدہ نمبر۔'
      : 'Only your published marks.';
  String get studentMarksEmpty => isUrdu
      ? 'اس مہینے کوئی نتیجہ نہیں۔'
      : 'No published results this month.';
  String studentMarksCounts(int scored, int absent) => isUrdu
      ? 'نمبر $scored · غیر حاضر $absent'
      : 'Scored $scored · Absent $absent';
  String get studentMarksCorrectedBadge =>
      isUrdu ? 'درست شدہ' : 'Corrected';
  String get flexClassroomTitle => isUrdu ? 'کلاس روم' : 'Classroom';
  String get flexClassroomSubtitle => isUrdu
      ? 'اعلانات اور وسائل۔'
      : 'Announcements and materials.';
  String get studentClassroomSubtitle => isUrdu
      ? 'آپ کی کلاس کے شائع شدہ اعلانات۔'
      : 'Published announcements for your class.';
  String get studentClassroomEmpty => isUrdu
      ? 'ابھی کوئی اعلان نہیں۔'
      : 'No classroom announcements yet.';
  String studentClassroomPendingAck(int count) => isUrdu
      ? '$count تسلیم باقی'
      : '$count to acknowledge';
  String get studentClassroomNeedsAck =>
      isUrdu ? 'تسلیم درکار' : 'Needs acknowledgement';
  String get studentClassroomAcknowledged =>
      isUrdu ? 'تسلیم شدہ' : 'Acknowledged';
  String get studentClassroomExpired => isUrdu ? 'میعاد ختم' : 'Expired';
  String get studentClassroomAckAction =>
      isUrdu ? 'تسلیم کریں' : 'Acknowledge';
  String get studentClassroomAckDone =>
      isUrdu ? 'تسلیم ہو گیا۔' : 'Acknowledged.';
  String get studentClassroomAckFailed => isUrdu
      ? 'تسلیم ناکام۔'
      : 'Could not acknowledge.';
  String get flexSectionComingSoon => isUrdu
      ? 'یہ حصہ اگلے ماڈیول میں آئے گا۔'
      : 'This section arrives in a later module.';
  String get flexIndependentBlocked => isUrdu
      ? 'آزاد طلبہ فلیکس نہیں دیکھ سکتے۔'
      : 'Independent students never see Flex.';
  String flexOpenTasks(int count) =>
      isUrdu ? '$count کام باقی ہیں' : '$count tasks open';
  String flexSectionOpen(int count) => isUrdu
      ? '$count کھلے'
      : '$count open';
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
  String get learningCatalogTitle =>
      isUrdu ? 'کیٹلاگ' : 'Catalog';
  String get gamification => isUrdu ? 'گیمیفیکیشن' : 'Gamification';
  String get gameAdmin => isUrdu ? 'گیمز' : 'Games';
  String get notificationAdminSearchHint =>
      isUrdu ? 'ٹیمپلیٹ تلاش' : 'Search templates';
  String get notificationAdminNew =>
      isUrdu ? 'نیا ٹیمپلیٹ' : 'New template';
  String get notificationAdminPublish => isUrdu ? 'شائع کریں' : 'Publish';
  String get notificationAdminDisable => isUrdu ? 'بند کریں' : 'Disable';
  String get notificationAdminReason => isUrdu ? 'وجہ' : 'Reason';
  String get notificationAdminStatus => isUrdu ? 'حیثیت' : 'Status';
  String get notificationAdminChannel => isUrdu ? 'چینل' : 'Channel';
  String get notificationAdminDeepLink =>
      isUrdu ? 'ڈیپ لنک' : 'Deep link';
  String get notificationAdminEmptyDetail => isUrdu
      ? 'تفصیل دیکھنے کے لیے ٹیمپلیٹ منتخب کریں۔'
      : 'Select a template to see details.';
  String get gameAdminSearchHint =>
      isUrdu ? 'گیم تلاش' : 'Search games';
  String get gameAdminNew => isUrdu ? 'نیا گیم' : 'New game';
  String get gameAdminPublish => isUrdu ? 'شائع کریں' : 'Publish';
  String get gameAdminDisable => isUrdu ? 'بند کریں' : 'Disable';
  String get gameAdminReason => isUrdu ? 'وجہ' : 'Reason';
  String get gameAdminStatus => isUrdu ? 'حیثیت' : 'Status';
  String get gameAdminEntry => isUrdu ? 'انٹری' : 'Entry';
  String get gameAdminEmptyDetail => isUrdu
      ? 'تفصیل دیکھنے کے لیے گیم منتخب کریں۔'
      : 'Select a game to see details.';
  String get gamificationPageTitle =>
      isUrdu ? 'گیمیفیکیشن انتظام' : 'Gamification';
  String get gamificationPageSubtitle => isUrdu
      ? 'پالیسی، سطحیں، کامیابیاں، مشن، دستی ایڈجسٹ۔'
      : 'Policy, levels, achievements, missions, and manual adjust.';
  String get gamificationPolicyTab => isUrdu ? 'پالیسی' : 'Policy';
  String get gamificationLevelsTab => isUrdu ? 'سطحیں' : 'Levels';
  String get gamificationCatalogTab => isUrdu ? 'کیٹلاگ' : 'Catalog';
  String get gamificationAdjustTab => isUrdu ? 'ایڈجسٹ' : 'Adjust';
  String get gamificationDailyCap =>
      isUrdu ? 'روزانہ حد' : 'Daily XP cap';
  String get gamificationSaveCap =>
      isUrdu ? 'حد محفوظ کریں' : 'Save cap';
  String get gamificationAwardRules =>
      isUrdu ? 'ایوارڈ قواعد' : 'Award rules';
  String get gamificationEditAward => isUrdu ? 'تبدیل' : 'Edit';
  String get gamificationSaveAward => isUrdu ? 'محفوظ' : 'Save';
  String get gamificationLevelStep =>
      isUrdu ? 'سطح کا قدم' : 'Level step';
  String get gamificationXpPerLevel =>
      isUrdu ? 'فی سطح ایکس پی' : 'XP per level';
  String get gamificationSaveLevels =>
      isUrdu ? 'سطحیں محفوظ کریں' : 'Save levels';
  String get gamificationLevel => isUrdu ? 'سطح' : 'Level';
  String gamificationMoreLevels(int count) =>
      isUrdu ? '+$count مزید سطحیں' : '+$count more levels';
  String get gamificationAchievements =>
      isUrdu ? 'کامیابیاں' : 'Achievements';
  String get gamificationMissions => isUrdu ? 'مشن' : 'Missions';
  String get gamificationAdjustTitle =>
      isUrdu ? 'دستی ایکس پی' : 'Manual XP adjust';
  String get gamificationUserId => isUrdu ? 'صارف شناخت' : 'User id';
  String get gamificationAmount => isUrdu ? 'رقم' : 'Amount';
  String get gamificationReason => isUrdu ? 'وجہ' : 'Reason';
  String get gamificationSubmitAdjust =>
      isUrdu ? 'ایڈجسٹ کریں' : 'Apply adjustment';
  String gamificationAdjusted(int amount) => isUrdu
      ? '$amount ایکس پی محفوظ'
      : '$amount XP recorded';
  String get authoringSearchHint =>
      isUrdu ? 'مضمون تلاش' : 'Search subjects';
  String get authoringNewSubject =>
      isUrdu ? 'نیا مضمون' : 'New subject';
  String get authoringNewTopic =>
      isUrdu ? 'نیا موضوع' : 'New topic';
  String get authoringPublishSubject =>
      isUrdu ? 'مضمون شائع کریں' : 'Publish subject';
  String get authoringArchiveSubject =>
      isUrdu ? 'مضمون محفوظ کریں' : 'Archive subject';
  String get authoringPublishTopic =>
      isUrdu ? 'موضوع شائع کریں' : 'Publish topic';
  String get authoringArchiveTopic =>
      isUrdu ? 'موضوع محفوظ کریں' : 'Archive topic';
  String get authoringTopicsTitle => isUrdu ? 'موضوعات' : 'Topics';
  String get authoringNoTopics =>
      isUrdu ? 'ابھی کوئی موضوع نہیں۔' : 'No topics yet.';
  String get authoringEmptyDetail => isUrdu
      ? 'تفصیل کے لیے ایک مضمون منتخب کریں۔'
      : 'Select a subject to review details.';
  String get authoringVersionId => isUrdu ? 'ورژن شناخت' : 'Version id';
  String get authoringPreviewTitle =>
      isUrdu ? 'پیش نظارہ' : 'Preview';
  String get authoringJuniorPreview =>
      isUrdu ? 'جونیئر پیش نظارہ' : 'Junior preview';
  String get authoringSeniorPreview =>
      isUrdu ? 'سینئر پیش نظارہ' : 'Senior preview';
  String get authoringSharedVersion =>
      isUrdu ? 'مشترکہ ورژن' : 'Shared version';
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
  String get assetReviewCoverageTitle =>
      isUrdu ? 'ساتھی کی کمی' : 'Companion gaps';
  String get assetReviewCoverageComplete => isUrdu
      ? 'ہر جشن کے کلپ منظور ہو چکے ہیں۔'
      : 'Every celebration clip is approved.';
  String get assetReviewCoverageBody => isUrdu
      ? 'یہ سلاٹ ابھی منظور شدہ آرٹ کے بغیر ہیں۔ بچہ بندل پوز دیکھے گا جب تک آپ فیصلہ نہ کریں۔'
      : 'These slots have no approved art yet. A learner sees the bundled pose until you decide.';
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
        'feedback' => feedback,
        'overview' => overview,
        'students' => students,
        'teachers' => teachers,
        'assignments' => assignments,
        'reports' => reports,
        'settings' => settings,
        'platform' => platform,
        'schools' => schools,
        'users' => users,
        'content' => content,
        'gamification' => gamification,
        'gameAdmin' => gameAdmin,
        'notifications' => notificationsLabel,
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
