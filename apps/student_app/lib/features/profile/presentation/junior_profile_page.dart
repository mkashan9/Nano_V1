import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/parent/presentation/parent_guidance_page.dart';
import 'package:student_app/features/profile/fixtures/junior_profile_fixtures.dart';
import 'package:student_app/features/profile/visual/junior_profile_visual_assets.dart';

/// Kids Profile visual surface (VIS-04) — reference-matched layout.
class JuniorProfilePage extends StatefulWidget {
  const JuniorProfilePage({
    super.key,
    required this.repository,
    required this.principal,
    this.preferences,
    this.onPreferencesChanged,
    this.onOpenAccessibility,
    this.parentGuidanceRepository,
    this.useVisualAssets = true,
  });

  final StudentProfileRepository repository;
  final SessionPrincipal principal;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final VoidCallback? onOpenAccessibility;
  final ParentGuidanceRepository? parentGuidanceRepository;
  final bool useVisualAssets;

  @override
  State<JuniorProfilePage> createState() => _JuniorProfilePageState();
}

class _JuniorProfilePageState extends State<JuniorProfilePage> {
  NanoViewState _state = const NanoViewLoading();
  StudentProfileView? _profile;
  var _darkMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final userId = widget.principal.userId ?? TenancyFixtures.aliAlphaId;
      final profile = await widget.repository.loadProfile(
        userId: userId,
        displayName: widget.principal.displayName,
        role: widget.principal.role,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError(message: 'Profile unavailable'));
    }
  }

  StudentPreferences get _prefs =>
      widget.preferences ??
      StudentPreferences(
        userId: widget.principal.userId ?? TenancyFixtures.aliAlphaId,
      );

  void _setSound(bool enabled) {
    final next = _prefs.copyWith(
      accessibility: _prefs.accessibility.copyWith(soundEnabled: enabled),
    );
    widget.onPreferencesChanged?.call(next);
  }

  void _cycleLocale() {
    final nextLocale = _prefs.locale == NanoAppLocale.en
        ? NanoAppLocale.ur
        : NanoAppLocale.en;
    widget.onPreferencesChanged?.call(_prefs.copyWith(locale: nextLocale));
  }

  void _openParents() {
    final repo = widget.parentGuidanceRepository;
    if (repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent updates coming soon')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParentGuidancePage(repository: repo),
      ),
    );
  }

  ImageProvider? _recentImage(String key) {
    if (!widget.useVisualAssets) return null;
    return AssetImage(switch (key) {
      'math' => JuniorProfileVisualAssets.recentMath,
      'science' => JuniorProfileVisualAssets.recentScience,
      _ => JuniorProfileVisualAssets.recentReading,
    });
  }

  @override
  Widget build(BuildContext context) {
    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: _profile == null
          ? const SizedBox.shrink()
          : Builder(
              builder: (context) {
                final profile = _profile!;
                final prefs = _prefs;
                return ColoredBox(
                  color: NanoColors.canvas,
                  child: ListView(
                    padding:
                        const EdgeInsets.only(top: NanoSpacing.md, bottom: 24),
                    children: [
                      JuniorProfileHeader(
                        displayName: profile.displayName,
                        level: JuniorProfileFixtures.displayLevel,
                        xpCurrent: JuniorProfileFixtures.xpCurrent,
                        xpMax: JuniorProfileFixtures.xpMax,
                        avatar: widget.useVisualAssets
                            ? const AssetImage(JuniorProfileVisualAssets.avatar)
                            : null,
                        foxIllustration: widget.useVisualAssets
                            ? const AssetImage(JuniorProfileVisualAssets.fox)
                            : null,
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded,
                                color: Color(0xFF9B6DFF), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Recent Learning',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: NanoSpacing.md),
                          itemCount: JuniorProfileFixtures.recent.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: NanoSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = JuniorProfileFixtures.recent[index];
                            return JuniorRecentLearningCard(
                              title: item.title,
                              subjectLabel: item.subject,
                              illustration: _recentImage(item.asset),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                color: Color(0xFF9B6DFF), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'My Weekly Journey',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      const JuniorWeeklyJourney(
                          days: JuniorProfileFixtures.journey),
                      const SizedBox(height: NanoSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: NanoSpacing.md),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: JuniorParentsCard(
                                  title: 'For Parents',
                                  subtitle: 'View progress and updates',
                                  onTap: _openParents,
                                ),
                              ),
                              const SizedBox(width: NanoSpacing.sm),
                              Expanded(
                                child: JuniorSettingsCard(
                                  soundEnabled:
                                      prefs.accessibility.soundEnabled,
                                  darkModeEnabled: _darkMode,
                                  languageLabel:
                                      prefs.locale.tag.toUpperCase(),
                                  onSoundChanged:
                                      widget.onPreferencesChanged == null
                                          ? null
                                          : _setSound,
                                  onDarkModeChanged: (v) =>
                                      setState(() => _darkMode = v),
                                  onLanguageTap:
                                      widget.onPreferencesChanged == null
                                          ? widget.onOpenAccessibility
                                          : _cycleLocale,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
