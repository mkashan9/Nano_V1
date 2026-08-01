import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-03 Users destination: search, suspend/restore, replace admin, revoke.
class UsersPage extends StatefulWidget {
  const UsersPage({
    super.key,
    required this.repository,
  });

  final PlatformUserRepository repository;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  NanoViewState _state = const NanoViewLoading();
  List<PlatformUserSummary> _users = const [];
  final _query = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final users = await widget.repository.search(query: _query.text);
      if (!mounted) return;
      setState(() {
        _users = users;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _promptReasonAction({
    required String title,
    required Future<void> Function(String reason) action,
  }) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(labelText: copy.usersReasonLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.usersConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      await action(reasonController.text);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      reasonController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleStatus(PlatformUserSummary user) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final next = user.isSuspended
        ? MembershipStatus.active
        : MembershipStatus.suspended;
    await _promptReasonAction(
      title: user.isSuspended
          ? copy.usersRestoreTitle
          : copy.usersSuspendTitle,
      action: (reason) async {
        await widget.repository.setProfileStatus(
          userId: user.id,
          status: next,
          reason: reason,
        );
      },
    );
  }

  Future<void> _revoke(PlatformUserSummary user) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    await _promptReasonAction(
      title: copy.usersRevokeSessionsTitle,
      action: (reason) async {
        final count = await widget.repository.revokeSessions(
          userId: user.id,
          reason: reason,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(copy.usersRevokedCount(count))),
        );
      },
    );
  }

  Future<void> _replaceAdmin(PlatformUserSummary user) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    UserSchoolSummary? adminSchool;
    for (final school in user.schoolSummaries) {
      if (school.role == MembershipRole.schoolAdmin &&
          school.status == MembershipStatus.active) {
        adminSchool = school;
        break;
      }
    }
    final schoolId = adminSchool?.schoolId ?? TenancyFixtures.alphaSchoolId;
    final newUserController = TextEditingController(
      text: TenancyFixtures.teacherId,
    );
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.usersReplaceAdminTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newUserController,
                decoration: InputDecoration(
                  labelText: copy.usersNewAdminIdLabel,
                ),
              ),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(labelText: copy.usersReasonLabel),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.usersConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      newUserController.dispose();
      reasonController.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.replaceSchoolAdmin(
        schoolId: schoolId,
        newUserId: newUserController.text.trim(),
        reason: reasonController.text,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      newUserController.dispose();
      reasonController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              children: [
                Text(copy.usersPageTitle, style: theme.textTheme.headlineMedium),
                const SizedBox(height: NanoSpacing.xs),
                Text(
                  copy.usersPageSubtitle,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: NanoSpacing.md),
                TextField(
                  controller: _query,
                  decoration: InputDecoration(
                    hintText: copy.usersSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _busy ? null : _load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: NanoSpacing.md),
                if (_users.isEmpty)
                  Text(copy.usersEmpty)
                else
                  for (final user in _users)
                    Card(
                      margin: const EdgeInsets.only(bottom: NanoSpacing.sm),
                      child: ListTile(
                        leading: Icon(
                          user.isSuspended
                              ? Icons.person_off_outlined
                              : Icons.person_outline,
                        ),
                        title: Text(
                          '${user.displayName} · ${user.status.wireName}',
                        ),
                        subtitle: Text(
                          [
                            user.accountKind.name,
                            if (user.schoolSummaries.isNotEmpty)
                              user.schoolSummaries
                                  .map((s) => '${s.schoolCode}/${s.role.name}')
                                  .join(', '),
                            copy.usersSessionsLabel(user.activeSessionCount),
                          ].join(' · '),
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: NanoSpacing.xs,
                          children: [
                            TextButton(
                              onPressed:
                                  _busy ? null : () => _toggleStatus(user),
                              child: Text(
                                user.isSuspended
                                    ? copy.usersRestoreAction
                                    : copy.usersSuspendAction,
                              ),
                            ),
                            TextButton(
                              onPressed: _busy || user.activeSessionCount == 0
                                  ? null
                                  : () => _revoke(user),
                              child: Text(copy.usersRevokeAction),
                            ),
                            if (user.schoolSummaries.any(
                              (s) =>
                                  s.role == MembershipRole.schoolAdmin &&
                                  s.status == MembershipStatus.active,
                            ))
                              TextButton(
                                onPressed:
                                    _busy ? null : () => _replaceAdmin(user),
                                child: Text(copy.usersReplaceAdminAction),
                              ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
