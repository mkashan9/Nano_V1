import 'package:nano_domain/nano_domain.dart';

/// PAR-02 superadmin weekly guidance package admin.
abstract class WeeklyGuidanceAdminRepository {
  Future<List<WeeklyGuidancePackage>> listPackages();

  Future<WeeklyGuidancePackage> createDraft({
    required String weekKey,
    required String titleEn,
    required String bodyEn,
  });

  Future<WeeklyGuidancePackage> attachPdf({
    required String id,
    required String pdfFileName,
  });

  Future<WeeklyGuidancePackage> setActivityTips({
    required String id,
    required List<String> tips,
  });

  Future<WeeklyGuidancePackage> publish(String id);
}

class FakeWeeklyGuidanceAdminRepository
    implements WeeklyGuidanceAdminRepository {
  FakeWeeklyGuidanceAdminRepository({
    List<WeeklyGuidancePackage>? seed,
    this.alwaysFail = false,
  }) : _packages = List.of(seed ?? const []);

  final List<WeeklyGuidancePackage> _packages;
  bool alwaysFail;
  var _seq = 0;

  @override
  Future<List<WeeklyGuidancePackage>> listPackages() async {
    if (alwaysFail) throw StateError('Packages unavailable');
    final list = [..._packages]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<WeeklyGuidancePackage> createDraft({
    required String weekKey,
    required String titleEn,
    required String bodyEn,
  }) async {
    if (alwaysFail) throw StateError('Create failed');
    _seq += 1;
    final now = DateTime.now().toUtc();
    final created = WeeklyGuidancePackage(
      id: 'wg-$_seq',
      weekKey: weekKey.trim(),
      titleEn: titleEn.trim(),
      bodyEn: bodyEn.trim(),
      status: WeeklyGuidancePackageStatus.draft,
      updatedAt: now,
    );
    _packages.insert(0, created);
    return created;
  }

  @override
  Future<WeeklyGuidancePackage> attachPdf({
    required String id,
    required String pdfFileName,
  }) async {
    if (alwaysFail) throw StateError('Attach failed');
    final index = _packages.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Package not found');
    final name = pdfFileName.trim();
    if (name.isEmpty || !name.toLowerCase().endsWith('.pdf')) {
      throw ArgumentError('PDF filename must end with .pdf');
    }
    final updated = _packages[index].copyWith(
      pdfFileName: name,
      updatedAt: DateTime.now().toUtc(),
    );
    _packages[index] = updated;
    return updated;
  }

  @override
  Future<WeeklyGuidancePackage> setActivityTips({
    required String id,
    required List<String> tips,
  }) async {
    if (alwaysFail) throw StateError('Tips update failed');
    final index = _packages.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Package not found');
    final cleaned = [
      for (final tip in tips)
        if (tip.trim().isNotEmpty) tip.trim(),
    ];
    final updated = _packages[index].copyWith(
      activityTips: cleaned,
      updatedAt: DateTime.now().toUtc(),
    );
    _packages[index] = updated;
    return updated;
  }

  @override
  Future<WeeklyGuidancePackage> publish(String id) async {
    if (alwaysFail) throw StateError('Publish failed');
    final index = _packages.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Package not found');
    final current = _packages[index];
    final error = WeeklyGuidancePublishPolicy.validateForPublish(current);
    if (error != null) throw StateError(error);
    final now = DateTime.now().toUtc();
    final updated = current.copyWith(
      status: WeeklyGuidancePackageStatus.published,
      publishedAt: now,
      updatedAt: now,
    );
    _packages[index] = updated;
    return updated;
  }
}
