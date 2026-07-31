import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// STU-05 owner profile: identity, progress, privacy, settings, devices,
/// and a sign-out that clears private local caches.
class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({
    super.key,
    required this.repository,
    required this.principal,
    this.preferences,
    this.onPreferencesChanged,
    this.onPrivacyChanged,
    this.onOpenAccessibility,
    this.onSignOut,
    this.syncController,
  });

  final StudentProfileRepository repository;
  final SessionPrincipal principal;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final ValueChanged<PrivacySettings>? onPrivacyChanged;
  final VoidCallback? onOpenAccessibility;
  final Future<void> Function()? onSignOut;

  /// Cleared on sign-out so private drafts and cache never survive logout.
  final NanoSyncController? syncController;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  NanoViewState _state = const NanoViewLoading();
  StudentProfileView? _profile;
  PrivacySettings? _privacy;
  List<DeviceSession> _sessions = const [];
  var _signingOut = false;
  String? _revokingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    final userId = widget.principal.userId;
    if (userId == null) {
      setState(() => _state = const NanoViewPermissionDenied());
      return;
    }
    try {
      final profile = await widget.repository.loadProfile(
        userId: userId,
        displayName: widget.principal.displayName,
        role: widget.principal.role,
      );
      final privacy = await widget.repository.loadPrivacy(userId);
      final sessions = await widget.repository.loadSessions(userId);
      final prefs = widget.preferences;
      if (!mounted) return;
      setState(() {
        _profile = prefs == null
            ? profile
            : profile.copyWith(
                companionName: prefs.companionName,
                locale: prefs.locale,
              );
        _privacy = privacy;
        _sessions = sessions;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _setPrivacy(PrivacySettings next) async {
    setState(() => _privacy = next);
    try {
      final saved = await widget.repository.savePrivacy(next);
      if (!mounted) return;
      setState(() => _privacy = saved);
      widget.onPrivacyChanged?.call(saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save privacy settings')),
      );
      await _load();
    }
  }

  Future<void> _revoke(DeviceSession session) async {
    setState(() => _revokingId = session.id);
    try {
      await widget.repository.revokeSession(session.id);
      if (!mounted) return;
      setState(() {
        _sessions = [
          for (final item in _sessions)
            item.id == session.id
                ? item.copyWith(revokedAt: DateTime.now().toUtc())
                : item,
        ];
        _revokingId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _revokingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out that device')),
      );
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    // Clear private caches before the auth call so a failed network still
    // leaves nothing for the next person who sits at this device.
    widget.syncController?.cache.clear();
    widget.syncController?.queue.clear();
    try {
      await widget.onSignOut?.call();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: _profile == null || _privacy == null
          ? const SizedBox.shrink()
          : _ProfileBody(
              profile: _profile!,
              privacy: _privacy!,
              sessions: _sessions,
              copy: copy,
              preferences: widget.preferences,
              onPreferencesChanged: widget.onPreferencesChanged,
              onPrivacyChanged: _setPrivacy,
              onOpenAccessibility: widget.onOpenAccessibility,
              onRevoke: _revoke,
              revokingId: _revokingId,
              onSignOut: widget.onSignOut == null ? null : _signOut,
              signingOut: _signingOut,
            ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.privacy,
    required this.sessions,
    required this.copy,
    required this.onPrivacyChanged,
    required this.onRevoke,
    this.preferences,
    this.onPreferencesChanged,
    this.onOpenAccessibility,
    this.revokingId,
    this.onSignOut,
    this.signingOut = false,
  });

  final StudentProfileView profile;
  final PrivacySettings privacy;
  final List<DeviceSession> sessions;
  final NanoCopy copy;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final ValueChanged<PrivacySettings> onPrivacyChanged;
  final VoidCallback? onOpenAccessibility;
  final ValueChanged<DeviceSession> onRevoke;
  final String? revokingId;
  final Future<void> Function()? onSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = profile.level;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NanoSpacing.md,
        NanoSpacing.md,
        NanoSpacing.md,
        NanoSpacing.xxl,
      ),
      children: [
        Row(
          children: [
            NanoAvatar(
              initials: profile.initials,
              size: 72,
              semanticLabel: profile.displayName,
            ),
            const SizedBox(width: NanoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.displayName, style: theme.textTheme.headlineSmall),
                  Text(
                    '${copy.levelLabel(level.level)} · ${profile.role.label}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (profile.schoolName != null)
                    Text(
                      [
                        profile.schoolName!,
                        if (profile.className != null) profile.className!,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            XpChip(xp: profile.xp),
          ],
        ),
        const SizedBox(height: NanoSpacing.sm),
        Text(
          '${profile.companionName} · ${profile.locale.tag.toUpperCase()}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: NanoSpacing.lg),
        Text(copy.progressLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_fire_department_outlined),
          title: Text('${profile.streakDays} ${copy.streakLabel}'),
          subtitle: Text('${profile.completedTopics} ${copy.topicsCompleted}'),
        ),
        if (profile.recommendedNext != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text(copy.nextUpLabel),
            subtitle: Text(profile.recommendedNext!),
          ),
        if (profile.achievements.isNotEmpty) ...[
          const SizedBox(height: NanoSpacing.md),
          Text(copy.achievementsLabel, style: theme.textTheme.titleLarge),
          const SizedBox(height: NanoSpacing.sm),
          for (final achievement in profile.achievements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events_outlined),
              title: Text(achievement.title),
            ),
        ],
        const SizedBox(height: NanoSpacing.md),
        Text(copy.privacyLabel, style: theme.textTheme.titleLarge),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(copy.discoverableLabel),
          value: privacy.discoverable,
          onChanged: (value) =>
              onPrivacyChanged(privacy.copyWith(discoverable: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(copy.showAchievementsLabel),
          value: privacy.showAchievements,
          onChanged: (value) =>
              onPrivacyChanged(privacy.copyWith(showAchievements: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(copy.allowFriendRequestsLabel),
          value: privacy.allowFriendRequests,
          onChanged: (value) =>
              onPrivacyChanged(privacy.copyWith(allowFriendRequests: value)),
        ),
        const SizedBox(height: NanoSpacing.md),
        Text(copy.settingsLabel, style: theme.textTheme.titleLarge),
        if (preferences != null && onPreferencesChanged != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(copy.languageLabel),
            trailing: SegmentedButton<NanoAppLocale>(
              segments: const [
                ButtonSegment(value: NanoAppLocale.en, label: Text('EN')),
                ButtonSegment(value: NanoAppLocale.ur, label: Text('UR')),
              ],
              selected: {preferences!.locale},
              onSelectionChanged: (value) => onPreferencesChanged!(
                preferences!.copyWith(locale: value.first),
              ),
            ),
          ),
        if (onOpenAccessibility != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.accessibility_new),
            title: Text(copy.accessibilityLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenAccessibility,
          ),
        const SizedBox(height: NanoSpacing.md),
        Text(copy.devicesLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        if (sessions.isEmpty)
          Text(copy.planEmpty, style: theme.textTheme.bodyMedium)
        else
          for (final session in sessions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                session.isCurrent
                    ? Icons.smartphone
                    : Icons.devices_other_outlined,
              ),
              title: Text(
                session.isCurrent
                    ? '${session.deviceLabel} · ${copy.thisDeviceLabel}'
                    : session.deviceLabel,
              ),
              subtitle: Text(
                session.isActive
                    ? copy.lastSeen(session.lastSeenLabel)
                    : copy.revokedLabel,
              ),
              trailing: session.isRevocable
                  ? TextButton(
                      onPressed: revokingId == session.id
                          ? null
                          : () => onRevoke(session),
                      child: Text(copy.revokeLabel),
                    )
                  : null,
            ),
        if (onSignOut != null) ...[
          const SizedBox(height: NanoSpacing.lg),
          FilledButton.tonal(
            onPressed: signingOut ? null : onSignOut,
            child: Text(
              signingOut ? '…' : copy.signOutLabel,
            ),
          ),
        ],
      ],
    );
  }
}
