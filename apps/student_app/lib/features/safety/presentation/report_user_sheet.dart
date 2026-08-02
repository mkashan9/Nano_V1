import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SAFE-01 report sheet: category, optional note, optional block.
Future<ReportDraft?> showReportUserSheet({
  required BuildContext context,
  required String peerLabel,
}) {
  return showModalBottomSheet<ReportDraft>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReportUserSheet(peerLabel: peerLabel),
  );
}

class _ReportUserSheet extends StatefulWidget {
  const _ReportUserSheet({required this.peerLabel});

  final String peerLabel;

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  ReportCategory _category = ReportCategory.harassment;
  final _detailsCtrl = TextEditingController();
  var _alsoBlock = true;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        NanoSpacing.md,
        NanoSpacing.md,
        NanoSpacing.md,
        NanoSpacing.md + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(copy.reportUserTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(
              copy.reportUserSubtitle(widget.peerLabel),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: NanoSpacing.md),
            Wrap(
              spacing: NanoSpacing.sm,
              runSpacing: NanoSpacing.sm,
              children: [
                for (final category in ReportCategory.values)
                  ChoiceChip(
                    label: Text(copy.reportCategoryLabel(category)),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: NanoSpacing.md),
            TextField(
              controller: _detailsCtrl,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: copy.reportDetailsHint,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(copy.reportAlsoBlockLabel),
              value: _alsoBlock,
              onChanged: (value) => setState(() => _alsoBlock = value),
            ),
            const SizedBox(height: NanoSpacing.sm),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  ReportDraft(
                    category: _category,
                    details: _detailsCtrl.text.trim().isEmpty
                        ? null
                        : _detailsCtrl.text.trim(),
                    alsoBlock: _alsoBlock,
                  ),
                );
              },
              child: Text(copy.submitReportLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(copy.cancelRequestLabel),
            ),
          ],
        ),
      ),
    );
  }
}
