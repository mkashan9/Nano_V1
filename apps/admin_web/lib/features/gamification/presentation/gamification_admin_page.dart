import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-05 Gamification hub: policy, levels, catalogs, and manual XP adjust.
class GamificationAdminPage extends StatefulWidget {
  const GamificationAdminPage({
    super.key,
    required this.repository,
  });

  final GamificationAdminRepository repository;

  @override
  State<GamificationAdminPage> createState() => _GamificationAdminPageState();
}

class _GamificationAdminPageState extends State<GamificationAdminPage> {
  NanoViewState _state = const NanoViewLoading();
  GamificationAdminSnapshot? _snapshot;
  var _busy = false;

  final _capController = TextEditingController();
  final _levelController = TextEditingController();
  final _adjustUserController = TextEditingController(
    text: TenancyFixtures.aliAlphaId,
  );
  final _adjustAmountController = TextEditingController(text: '10');
  final _adjustReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _capController.dispose();
    _levelController.dispose();
    _adjustUserController.dispose();
    _adjustAmountController.dispose();
    _adjustReasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final snapshot = await widget.repository.load();
      if (!mounted) return;
      _capController.text = '${snapshot.dailyCap}';
      _levelController.text = '${snapshot.xpPerLevel}';
      setState(() {
        _snapshot = snapshot;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final snapshot = _snapshot;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NanoViewStateHost(
          state: _state,
          onRetry: _load,
          child: snapshot == null
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(text: copy.gamificationPolicyTab),
                          Tab(text: copy.gamificationLevelsTab),
                          Tab(text: copy.gamificationCatalogTab),
                          Tab(text: copy.gamificationAdjustTab),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _PolicyTab(
                            snapshot: snapshot,
                            capController: _capController,
                            busy: _busy,
                            onSaveCap: () => _run(() async {
                              await widget.repository.setDailyCap(
                                int.parse(_capController.text.trim()),
                              );
                            }),
                            onSaveAward: (kind, amount) => _run(() async {
                              await widget.repository.setAwardAmount(
                                sourceKind: kind,
                                amount: amount,
                              );
                            }),
                          ),
                          _LevelsTab(
                            snapshot: snapshot,
                            levelController: _levelController,
                            busy: _busy,
                            onSave: () => _run(() async {
                              await widget.repository.setLevelStep(
                                int.parse(_levelController.text.trim()),
                              );
                            }),
                          ),
                          _CatalogTab(
                            snapshot: snapshot,
                            busy: _busy,
                            onToggleAchievement: (id, active) => _run(() async {
                              await widget.repository.setAchievementActive(
                                achievementId: id,
                                active: active,
                              );
                            }),
                            onToggleMission: (id, active) => _run(() async {
                              await widget.repository.setMissionActive(
                                missionId: id,
                                active: active,
                              );
                            }),
                          ),
                          _AdjustTab(
                            userController: _adjustUserController,
                            amountController: _adjustAmountController,
                            reasonController: _adjustReasonController,
                            busy: _busy,
                            onSubmit: () => _run(() async {
                              final amount = int.parse(
                                _adjustAmountController.text.trim(),
                              );
                              final result = await widget.repository.adjustXp(
                                userId: _adjustUserController.text.trim(),
                                amount: amount,
                                reason: _adjustReasonController.text,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    copy.gamificationAdjusted(
                                      result.amount,
                                    ),
                                  ),
                                ),
                              );
                              _adjustReasonController.clear();
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PolicyTab extends StatelessWidget {
  const _PolicyTab({
    required this.snapshot,
    required this.capController,
    required this.busy,
    required this.onSaveCap,
    required this.onSaveAward,
  });

  final GamificationAdminSnapshot snapshot;
  final TextEditingController capController;
  final bool busy;
  final VoidCallback onSaveCap;
  final void Function(String kind, int amount) onSaveAward;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    return ListView(
      padding: const EdgeInsets.all(NanoSpacing.md),
      children: [
        Text(
          copy.gamificationPageTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: NanoSpacing.xs),
        Text(copy.gamificationPageSubtitle),
        const SizedBox(height: NanoSpacing.md),
        TextField(
          controller: capController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: copy.gamificationDailyCap),
        ),
        const SizedBox(height: NanoSpacing.sm),
        FilledButton(
          onPressed: busy ? null : onSaveCap,
          child: Text(copy.gamificationSaveCap),
        ),
        const SizedBox(height: NanoSpacing.lg),
        Text(
          copy.gamificationAwardRules,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: NanoSpacing.sm),
        for (final rule in snapshot.awardRules)
          if (rule.isEditable)
            Card(
              child: ListTile(
                title: Text('${rule.sourceKind} · ${rule.amount} XP'),
                subtitle: Text(rule.notes),
                trailing: TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final controller = TextEditingController(
                            text: '${rule.amount}',
                          );
                          final value = await showDialog<int>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(rule.sourceKind),
                              content: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'XP',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(copy.cancelLabel),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    int.tryParse(controller.text.trim()),
                                  ),
                                  child: Text(copy.gamificationSaveAward),
                                ),
                              ],
                            ),
                          );
                          controller.dispose();
                          if (value != null) {
                            onSaveAward(rule.sourceKind, value);
                          }
                        },
                  child: Text(copy.gamificationEditAward),
                ),
              ),
            ),
      ],
    );
  }
}

class _LevelsTab extends StatelessWidget {
  const _LevelsTab({
    required this.snapshot,
    required this.levelController,
    required this.busy,
    required this.onSave,
  });

  final GamificationAdminSnapshot snapshot;
  final TextEditingController levelController;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    return ListView(
      padding: const EdgeInsets.all(NanoSpacing.md),
      children: [
        Text(
          copy.gamificationLevelStep,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: NanoSpacing.sm),
        TextField(
          controller: levelController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: copy.gamificationXpPerLevel,
          ),
        ),
        const SizedBox(height: NanoSpacing.sm),
        FilledButton(
          onPressed: busy ? null : onSave,
          child: Text(copy.gamificationSaveLevels),
        ),
        const SizedBox(height: NanoSpacing.md),
        for (final rule in snapshot.levelRules.take(8))
          ListTile(
            dense: true,
            title: Text('${copy.gamificationLevel} ${rule.level}'),
            trailing: Text('${rule.minXp} XP'),
          ),
        if (snapshot.levelRules.length > 8)
          Text(copy.gamificationMoreLevels(snapshot.levelRules.length - 8)),
      ],
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({
    required this.snapshot,
    required this.busy,
    required this.onToggleAchievement,
    required this.onToggleMission,
  });

  final GamificationAdminSnapshot snapshot;
  final bool busy;
  final void Function(String id, bool active) onToggleAchievement;
  final void Function(String id, bool active) onToggleMission;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    return ListView(
      padding: const EdgeInsets.all(NanoSpacing.md),
      children: [
        Text(
          copy.gamificationAchievements,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final item in snapshot.achievements)
          SwitchListTile(
            title: Text(item.titleEn),
            subtitle: Text('${item.slug} · ${item.kind}'),
            value: item.active,
            onChanged: busy
                ? null
                : (value) => onToggleAchievement(item.id, value),
          ),
        const SizedBox(height: NanoSpacing.md),
        Text(
          copy.gamificationMissions,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final item in snapshot.missions)
          SwitchListTile(
            title: Text(item.titleEn),
            subtitle: Text(
              '${item.cadence} · target ${item.targetCount} · '
              '+${item.xpBonus} XP',
            ),
            value: item.active,
            onChanged:
                busy ? null : (value) => onToggleMission(item.id, value),
          ),
      ],
    );
  }
}

class _AdjustTab extends StatelessWidget {
  const _AdjustTab({
    required this.userController,
    required this.amountController,
    required this.reasonController,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController userController;
  final TextEditingController amountController;
  final TextEditingController reasonController;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    return ListView(
      padding: const EdgeInsets.all(NanoSpacing.md),
      children: [
        Text(
          copy.gamificationAdjustTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: NanoSpacing.sm),
        TextField(
          controller: userController,
          decoration: InputDecoration(labelText: copy.gamificationUserId),
        ),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: copy.gamificationAmount),
        ),
        TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: copy.gamificationReason),
        ),
        const SizedBox(height: NanoSpacing.md),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: Text(copy.gamificationSubmitAdjust),
        ),
      ],
    );
  }
}
