import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// PAR-03 guardian invite create / demo accept / list / revoke.
class GuardianLinkPage extends StatefulWidget {
  const GuardianLinkPage({
    super.key,
    required this.repository,
    required this.childUserId,
    required this.childDisplayName,
    this.demoGuardianId = 'guardian-demo',
  });

  final GuardianLinkRepository repository;
  final String childUserId;
  final String childDisplayName;
  final String demoGuardianId;

  @override
  State<GuardianLinkPage> createState() => _GuardianLinkPageState();
}

class _GuardianLinkPageState extends State<GuardianLinkPage> {
  NanoViewState _state = const NanoViewLoading();
  GuardianInvite? _invite;
  List<GuardianLinkRecord> _links = const [];
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final invite = await widget.repository.currentInvite(
        childUserId: widget.childUserId,
      );
      final links = await widget.repository.listLinksForChild(
        childUserId: widget.childUserId,
      );
      if (!mounted) return;
      setState(() {
        _invite = invite;
        _links = links;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(
        () => _state = NanoViewError(message: copy.guardianLinkLoadError),
      );
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

  Future<void> _createInvite() async {
    await _run(() async {
      await widget.repository.createInvite(
        childUserId: widget.childUserId,
        childDisplayName: widget.childDisplayName,
      );
    });
  }

  Future<void> _acceptDemo() async {
    final invite = _invite;
    if (invite == null) return;
    await _run(() async {
      await widget.repository.acceptInvite(
        guardianId: widget.demoGuardianId,
        code: invite.code,
        guardianDisplayName: 'Demo guardian',
      );
    });
  }

  Future<void> _revoke(GuardianLinkRecord link) async {
    await _run(() async {
      await widget.repository.revokeLink(
        guardianId: link.guardianId,
        childUserId: link.childUserId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final invite = _invite;

    return Scaffold(
      appBar: AppBar(title: Text(copy.guardianLinkTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: ListView(
          padding: const EdgeInsets.all(NanoSpacing.md),
          children: [
            Text(copy.guardianLinkHint),
            const SizedBox(height: NanoSpacing.md),
            if (invite != null) ...[
              Text(copy.guardianLinkCodeLabel,
                  style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(invite.code),
                subtitle: Text(invite.childDisplayName),
                trailing: IconButton(
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invite.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(invite.code)),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                ),
              ),
              if (kDebugMode)
                FilledButton.tonal(
                  onPressed: _busy ? null : _acceptDemo,
                  child: Text(copy.guardianLinkAcceptDemo),
                ),
            ] else
              FilledButton(
                onPressed: _busy ? null : _createInvite,
                child: Text(copy.guardianLinkCreate),
              ),
            if (invite != null) ...[
              const SizedBox(height: NanoSpacing.sm),
              TextButton(
                onPressed: _busy ? null : _createInvite,
                child: Text(copy.guardianLinkCreate),
              ),
            ],
            const SizedBox(height: NanoSpacing.lg),
            Text(
              copy.guardianLinkLinkedLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_links.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: NanoSpacing.sm),
                child: Text(copy.guardianLinkEmpty),
              )
            else
              for (final link in _links)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(link.guardianDisplayName ?? link.guardianId),
                  subtitle: Text(link.guardianId),
                  trailing: TextButton(
                    onPressed: _busy ? null : () => _revoke(link),
                    child: Text(copy.guardianLinkRevoke),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
