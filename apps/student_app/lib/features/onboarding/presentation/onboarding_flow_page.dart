import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// STU-01 first-run flow. Every step transition is saved, so an interrupted
/// learner resumes where they stopped instead of starting over.
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({
    super.key,
    required this.repository,
    required this.progress,
    required this.principal,
    required this.onProgressChanged,
    required this.onCompleted,
    this.schoolName,
    this.preferencesRepository,
    this.preferences,
    this.onPreferencesChanged,
  });

  final OnboardingRepository repository;
  final OnboardingProgress progress;
  final SessionPrincipal principal;
  final ValueChanged<OnboardingProgress> onProgressChanged;
  final void Function(OnboardingProgress progress, ExperienceTrack track)
      onCompleted;
  final String? schoolName;
  final StudentPreferencesRepository? preferencesRepository;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  late OnboardingProgress _progress = widget.progress;
  late OnboardingStep _step = widget.progress.resumeStep;
  late StudentPreferences _preferences = widget.preferences ??
      StudentPreferences(userId: widget.principal.userId ?? 'local');
  late final TextEditingController _companionName =
      TextEditingController(text: _preferences.companionName);
  var _busy = false;
  String? _nameError;

  @override
  void dispose() {
    _companionName.dispose();
    super.dispose();
  }

  bool get _independent =>
      widget.principal.role == AppRole.independentStudent;

  bool get _resumed => widget.progress.currentStep != OnboardingStep.welcome;

  ExperienceTrack get _track => ExperiencePolicy.resolve(
        selfReportedGradeLevel: _progress.selfReportedGradeLevel,
        authorizedOverride: _progress.experienceTrack,
      );

  Future<void> _persist(OnboardingProgress next) async {
    setState(() => _busy = true);
    try {
      final saved = await widget.repository.save(next);
      if (!mounted) return;
      setState(() {
        _progress = saved;
        _step = saved.isComplete ? OnboardingStep.ready : saved.currentStep;
      });
      widget.onProgressChanged(saved);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePreferences(StudentPreferences next) async {
    final repo = widget.preferencesRepository;
    setState(() {
      _preferences = next;
      _nameError = null;
    });
    widget.onPreferencesChanged?.call(next);
    if (repo == null) return;
    await repo.save(next);
  }

  /// Returns false when the current step still needs a correction.
  Future<bool> _commitStep() async {
    if (_step != OnboardingStep.preferences) return true;
    final error = CompanionNamePolicy.validate(_companionName.text);
    if (error != null) {
      setState(() => _nameError = error);
      return false;
    }
    await _savePreferences(
      _preferences.copyWith(
        companionName: CompanionNamePolicy.normalize(_companionName.text),
      ),
    );
    return true;
  }

  Future<void> _advance() async {
    if (!await _commitStep()) return;
    if (_step.isLast) {
      final completed = _progress.copyWith(
        currentStep: OnboardingStep.ready,
        experienceTrack: _track,
        completedAt: DateTime.now().toUtc(),
      );
      await _persist(completed);
      if (!mounted) return;
      widget.onCompleted(completed, _track);
      return;
    }
    await _persist(_progress.copyWith(currentStep: _step.next));
  }

  Future<void> _back() async {
    if (_step == OnboardingStep.welcome) return;
    await _persist(_progress.copyWith(currentStep: _step.previous));
  }

  Future<void> _chooseGrade(int gradeLevel) async {
    await _persist(
      _progress.copyWith(
        selfReportedGradeLevel: gradeLevel,
        experienceTrack: ExperiencePolicy.fromGradeLevel(gradeLevel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.copyOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(NanoSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_resumed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: NanoSpacing.md),
                        child: Text(
                          copy.onboardingResumed,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    _StepProgress(step: _step),
                    const SizedBox(height: NanoSpacing.lg),
                    ..._stepContent(copy, theme),
                    const SizedBox(height: NanoSpacing.lg),
                    FilledButton(
                      onPressed: _busy || !_canAdvance ? null : _advance,
                      child: Text(
                        _step.isLast
                            ? copy.onboardingStart
                            : copy.onboardingContinue,
                      ),
                    ),
                    if (_step != OnboardingStep.welcome)
                      TextButton(
                        onPressed: _busy ? null : _back,
                        child: Text(copy.onboardingBack),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _canAdvance =>
      _step != OnboardingStep.experience ||
      _progress.selfReportedGradeLevel != null;

  List<Widget> _stepContent(NanoCopy copy, ThemeData theme) {
    switch (_step) {
      case OnboardingStep.welcome:
        return [
          const CompanionSlot(),
          const SizedBox(height: NanoSpacing.md),
          Text(
            copy.onboardingWelcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(
            copy.welcomeLine(widget.principal.displayName),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ];
      case OnboardingStep.experience:
        return [
          Text(
            copy.onboardingExperienceTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(
            copy.onboardingExperienceHelp,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: NanoSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: NanoSpacing.sm,
            runSpacing: NanoSpacing.sm,
            children: [
              for (var grade = 1; grade <= 12; grade++)
                ChoiceChip(
                  label: Text('$grade'),
                  selected: _progress.selfReportedGradeLevel == grade,
                  onSelected:
                      _busy ? null : (_) => _chooseGrade(grade),
                ),
            ],
          ),
          if (_progress.selfReportedGradeLevel != null) ...[
            const SizedBox(height: NanoSpacing.md),
            Text(
              _track == ExperienceTrack.junior
                  ? copy.onboardingJunior
                  : copy.onboardingSenior,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ];
      case OnboardingStep.preferences:
        final a11y = _preferences.accessibility;
        return [
          Text(
            copy.onboardingSetupTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: NanoSpacing.md),
          TextField(
            controller: _companionName,
            enabled: !_busy,
            maxLength: CompanionNamePolicy.maxLength,
            decoration: InputDecoration(
              labelText: copy.companionNameLabel,
              helperText: copy.companionNameHelp,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          SegmentedButton<NanoAppLocale>(
            segments: [
              ButtonSegment(
                value: NanoAppLocale.en,
                label: Text(copy.languageEnglish),
              ),
              ButtonSegment(
                value: NanoAppLocale.ur,
                label: Text(copy.languageUrdu),
              ),
            ],
            selected: {_preferences.locale},
            onSelectionChanged: _busy
                ? null
                : (selection) =>
                    _savePreferences(_preferences.copyWith(locale: selection.first)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(copy.soundLabel),
            value: a11y.soundEnabled,
            onChanged: _busy
                ? null
                : (value) => _savePreferences(
                      _preferences.copyWith(
                        accessibility: a11y.copyWith(soundEnabled: value),
                      ),
                    ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(copy.captionsLabel),
            value: a11y.captionsEnabled,
            onChanged: _busy
                ? null
                : (value) => _savePreferences(
                      _preferences.copyWith(
                        accessibility: a11y.copyWith(captionsEnabled: value),
                      ),
                    ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(copy.reducedMotionLabel),
            value: a11y.reducedMotion,
            onChanged: _busy
                ? null
                : (value) => _savePreferences(
                      _preferences.copyWith(
                        accessibility: a11y.copyWith(reducedMotion: value),
                      ),
                    ),
          ),
        ];
      case OnboardingStep.context:
        return [
          Text(
            _independent
                ? copy.onboardingIndependentIntro
                : copy.onboardingSchoolIntro(widget.schoolName ?? copy.appName),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ];
      case OnboardingStep.ready:
        return [
          Text(
            copy.onboardingReadyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(
            copy.companionGreeting(_preferences.companionName),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ];
    }
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final index = OnboardingStep.values.indexOf(step);
    return Semantics(
      label: 'Step ${index + 1} of ${OnboardingStep.values.length}',
      child: LinearProgressIndicator(
        value: (index + 1) / OnboardingStep.values.length,
      ),
    );
  }
}
