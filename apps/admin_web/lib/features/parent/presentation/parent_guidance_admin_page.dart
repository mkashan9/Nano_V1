import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// PAR-02 superadmin weekly PDF + activity package upload.
class ParentGuidanceAdminPage extends StatefulWidget {
  const ParentGuidanceAdminPage({
    super.key,
    required this.repository,
  });

  final WeeklyGuidanceAdminRepository repository;

  @override
  State<ParentGuidanceAdminPage> createState() =>
      _ParentGuidanceAdminPageState();
}

class _ParentGuidanceAdminPageState extends State<ParentGuidanceAdminPage> {
  NanoViewState _state = const NanoViewLoading();
  List<WeeklyGuidancePackage> _packages = const [];
  WeeklyGuidancePackage? _selected;
  final _pdfController = TextEditingController();
  final _tipsController = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final packages = await widget.repository.listPackages();
      if (!mounted) return;
      final selected = packages.isEmpty
          ? null
          : packages.firstWhere(
              (item) => item.id == _selected?.id,
              orElse: () => packages.first,
            );
      setState(() {
        _packages = packages;
        _selected = selected;
        _pdfController.text = selected?.pdfFileName ?? '';
        _tipsController.text = selected?.activityTips.join('\n') ?? '';
        _state = packages.isEmpty
            ? const NanoViewEmpty(
                title: 'No weekly packages yet',
                message: 'Create a draft to attach a PDF and tips.',
              )
            : const NanoViewReady();
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

  Future<void> _createDraft() async {
    final stamp = DateTime.now().toUtc();
    final week = '2026-W${stamp.month.toString().padLeft(2, '0')}';
    await _run(() async {
      final created = await widget.repository.createDraft(
        weekKey: week,
        titleEn: 'Weekly tip $week',
        bodyEn: 'Celebrate short daily learning together this week.',
      );
      _selected = created;
    });
  }

  Future<void> _attachPdf() async {
    final selected = _selected;
    if (selected == null) return;
    await _run(() async {
      await widget.repository.attachPdf(
        id: selected.id,
        pdfFileName: _pdfController.text,
      );
    });
  }

  Future<void> _saveTips() async {
    final selected = _selected;
    if (selected == null) return;
    await _run(() async {
      await widget.repository.setActivityTips(
        id: selected.id,
        tips: _tipsController.text.split('\n'),
      );
    });
  }

  Future<void> _publish() async {
    final selected = _selected;
    if (selected == null) return;
    await _run(() async {
      await widget.repository.publish(selected.id);
    });
  }

  void _select(WeeklyGuidancePackage package) {
    setState(() {
      _selected = package;
      _pdfController.text = package.pdfFileName ?? '';
      _tipsController.text = package.activityTips.join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.parentGuidanceAdminTitle),
        actions: [
          TextButton(
            onPressed: _busy ? null : _createDraft,
            child: Text(copy.parentGuidanceAdminNew),
          ),
        ],
      ),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: ListView.separated(
                itemCount: _packages.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _packages[index];
                  return ListTile(
                    selected: item.id == selected?.id,
                    title: Text(item.titleEn),
                    subtitle: Text(
                      '${item.weekKey} · ${item.status.name}'
                      '${item.hasPdf ? ' · PDF' : ''}',
                    ),
                    onTap: () => _select(item),
                  );
                },
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: selected == null
                  ? Center(child: Text(copy.parentGuidanceAdminEmpty))
                  : ListView(
                      padding: const EdgeInsets.all(NanoSpacing.md),
                      children: [
                        Text(
                          selected.titleEn,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(selected.bodyEn),
                        const SizedBox(height: NanoSpacing.md),
                        TextField(
                          controller: _pdfController,
                          decoration: InputDecoration(
                            labelText: copy.parentGuidanceAdminPdfName,
                            hintText: 'week-guidance.pdf',
                          ),
                        ),
                        const SizedBox(height: NanoSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonal(
                            onPressed: _busy ? null : _attachPdf,
                            child: Text(copy.parentGuidanceAdminAttachPdf),
                          ),
                        ),
                        const SizedBox(height: NanoSpacing.md),
                        TextField(
                          controller: _tipsController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: copy.parentGuidanceAdminTips,
                          ),
                        ),
                        const SizedBox(height: NanoSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.tonal(
                            onPressed: _busy ? null : _saveTips,
                            child: const Text('Save tips'),
                          ),
                        ),
                        const SizedBox(height: NanoSpacing.lg),
                        FilledButton(
                          onPressed: _busy || selected.isPublished
                              ? null
                              : _publish,
                          child: Text(copy.parentGuidanceAdminPublish),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
