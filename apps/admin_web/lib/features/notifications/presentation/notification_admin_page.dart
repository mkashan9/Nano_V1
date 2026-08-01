import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-07 Notifications hub: draft, publish, and disable templates.
class NotificationAdminPage extends StatefulWidget {
  const NotificationAdminPage({
    super.key,
    required this.repository,
  });

  final NotificationAdminRepository repository;

  @override
  State<NotificationAdminPage> createState() => _NotificationAdminPageState();
}

class _NotificationAdminPageState extends State<NotificationAdminPage> {
  NanoViewState _state = const NanoViewLoading();
  List<AdminNotificationTemplate> _templates = const [];
  AdminNotificationTemplate? _selected;
  final _search = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final templates =
          await widget.repository.listTemplates(query: _search.text);
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _selected = templates.isEmpty
            ? null
            : templates.firstWhere(
                (item) => item.id == _selected?.id,
                orElse: () => templates.first,
              );
        _state = templates.isEmpty
            ? const NanoViewEmpty(
                title: 'No templates yet',
                message: 'Create a draft template to start the catalog.',
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

  Future<void> _createTemplate() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _run(() async {
      final created = await widget.repository.createDraft(
        slug: 'template_$stamp',
        titleEn: 'New template $stamp',
        bodyEn: 'Draft notification awaiting copy review.',
        category: 'system',
      );
      _selected = created;
    });
  }

  Future<void> _disable(AdminNotificationTemplate template) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final copy = NanoLocaleScope.maybeOf(context)?.copy ??
            const NanoCopy(NanoAppLocale.en);
        return AlertDialog(
          title: Text(copy.notificationAdminDisable),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: copy.notificationAdminReason,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, reasonController.text),
              child: Text(copy.notificationAdminDisable),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null) return;
    await _run(() async {
      await widget.repository.disable(
        templateId: template.id,
        reason: reason,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final selected = _selected;

    return Scaffold(
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(NanoSpacing.sm),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: copy.notificationAdminSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: _busy ? null : _load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: NanoSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _createTemplate,
                        icon: const Icon(Icons.add),
                        label: Text(copy.notificationAdminNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _templates.length,
                      itemBuilder: (context, index) {
                        final template = _templates[index];
                        return ListTile(
                          selected: template.id == selected?.id,
                          title: Text(template.titleEn),
                          subtitle: Text(
                            '${template.slug} · ${template.status.wireName}'
                            '${template.enabled ? '' : ' · off'}',
                          ),
                          onTap: () => setState(() => _selected = template),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: selected == null
                  ? Center(child: Text(copy.notificationAdminEmptyDetail))
                  : Padding(
                      padding: const EdgeInsets.all(NanoSpacing.md),
                      child: ListView(
                        children: [
                          Text(
                            selected.titleEn,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: NanoSpacing.xs),
                          Text(
                            '${selected.slug} · ${selected.category}'
                            '${selected.mandatory ? ' · mandatory' : ''}',
                          ),
                          if (selected.bodyEn.isNotEmpty) ...[
                            const SizedBox(height: NanoSpacing.sm),
                            Text(selected.bodyEn),
                          ],
                          const SizedBox(height: NanoSpacing.sm),
                          Text(
                            '${copy.notificationAdminStatus}: '
                            '${selected.status.wireName}'
                            '${selected.enabled ? '' : ' (disabled)'}',
                          ),
                          Text(
                            '${copy.notificationAdminChannel}: '
                            '${selected.channelPolicy}',
                          ),
                          Text(
                            '${copy.notificationAdminDeepLink}: '
                            '${selected.deepLinkTemplate}',
                          ),
                          const SizedBox(height: NanoSpacing.md),
                          Wrap(
                            spacing: NanoSpacing.sm,
                            runSpacing: NanoSpacing.sm,
                            children: [
                              if (selected.isDraft)
                                FilledButton(
                                  onPressed: _busy ||
                                          !NotificationTemplatePublishPolicy
                                              .ready(selected)
                                      ? null
                                      : () => _run(() async {
                                            await widget.repository.publish(
                                              selected.id,
                                            );
                                          }),
                                  child: Text(copy.notificationAdminPublish),
                                ),
                              if (selected.enabled)
                                OutlinedButton(
                                  onPressed:
                                      _busy ? null : () => _disable(selected),
                                  child: Text(copy.notificationAdminDisable),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
