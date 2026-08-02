import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/league/presentation/league_board_page.dart';
import 'package:student_app/features/profile/presentation/social_identity_section.dart';

/// STU-05 owner profile: identity, progress, privacy, settings, devices,
/// and a sign-out that clears private local caches.
///
/// XP-06 adds featured pins and privacy-safe achievement share cards.
class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({
    super.key,
    required this.repository,
    required this.principal,
    this.preferences,
    this.onPreferencesChanged,
    this.onPrivacyChanged,
    this.onOpenAccessibility,
    this.onOpenProgress,
    this.onSignOut,
    this.syncController,
    this.shareCards,
    this.leagueRepository,
    this.socialIdentityRepository,
  });

  final StudentProfileRepository repository;
  final SessionPrincipal principal;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final ValueChanged<PrivacySettings>? onPrivacyChanged;
  final VoidCallback? onOpenAccessibility;

  /// Opens the LRN-05 learning progress screen.
  final VoidCallback? onOpenProgress;
  final Future<void> Function()? onSignOut;

  /// Cleared on sign-out so private drafts and cache never survive logout.
  final NanoSyncController? syncController;

  /// XP-06: featured pins and share-card builder. Optional in previews.
  final ShareCardRepository? shareCards;

  /// LGE-01: personal weekly league status. Optional in previews.
  final LeagueRepository? leagueRepository;

  /// SOC-01: username, friend code, limited profile lookup.
  final SocialIdentityRepository? socialIdentityRepository;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  NanoViewState _state = const NanoViewLoading();
  StudentProfileView? _profile;
  PrivacySettings? _privacy;
  List<DeviceSession> _sessions = const [];
  LeagueStatus? _league;
  var _joiningLeague = false;
  var _signingOut = false;
  String? _revokingId;
  String? _busyAwardId;

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
      LeagueStatus? league;
      final leagues = widget.leagueRepository;
      if (leagues != null) {
        league = await leagues.currentStatus();
      }
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
        _league = league;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _joinLeague() async {
    final leagues = widget.leagueRepository;
    if (leagues == null || _joiningLeague) return;
    setState(() => _joiningLeague = true);
    try {
      final status = await leagues.joinCurrent();
      if (!mounted) return;
      setState(() {
        _league = status;
        _joiningLeague = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _joiningLeague = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not join the league')),
      );
    }
  }

  void _openLeagueBoard() {
    final leagues = widget.leagueRepository;
    if (leagues == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeagueBoardPage(repository: leagues),
      ),
    );
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

  Future<void> _toggleFeatured(ProfileAchievement achievement) async {
    final share = widget.shareCards;
    final profile = _profile;
    if (share == null || profile == null || _busyAwardId != null) return;

    final current = [
      for (final item in profile.achievements)
        if (item.isFeatured) item.id,
    ];
    final next = [...current];
    if (achievement.isFeatured) {
      next.remove(achievement.id);
    } else {
      if (next.length >= kMaxFeaturedAchievements) {
        final copy = NanoLocaleScope.maybeOf(context)?.copy ??
            const NanoCopy(NanoAppLocale.en);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(copy.featuredLimitHint)),
        );
        return;
      }
      next.add(achievement.id);
    }

    setState(() => _busyAwardId = achievement.id);
    try {
      await share.setFeatured(next);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update featured achievements')),
      );
    } finally {
      if (mounted) setState(() => _busyAwardId = null);
    }
  }

  Future<void> _shareAchievement(ProfileAchievement achievement) async {
    final share = widget.shareCards;
    if (share == null || _busyAwardId != null) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() => _busyAwardId = achievement.id);
    try {
      final card = await share.forAchievement(achievement.id);
      await Clipboard.setData(
        ClipboardData(text: card.shareTextFor(urdu: copy.isUrdu)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.shareCopiedSnack)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not build share card')),
      );
    } finally {
      if (mounted) setState(() => _busyAwardId = null);
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
              onOpenProgress: widget.onOpenProgress,
              onRevoke: _revoke,
              revokingId: _revokingId,
              onSignOut: widget.onSignOut == null ? null : _signOut,
              signingOut: _signingOut,
              canShare: widget.shareCards != null,
              busyAwardId: _busyAwardId,
              onToggleFeatured: widget.shareCards == null
                  ? null
                  : _toggleFeatured,
              onShareAchievement: widget.shareCards == null
                  ? null
                  : _shareAchievement,
              league: _league,
              joiningLeague: _joiningLeague,
              onJoinLeague:
                  widget.leagueRepository == null ? null : _joinLeague,
              onOpenLeagueBoard: widget.leagueRepository == null
                  ? null
                  : _openLeagueBoard,
              socialIdentityRepository: widget.socialIdentityRepository,
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
    this.onOpenProgress,
    this.revokingId,
    this.onSignOut,
    this.signingOut = false,
    this.canShare = false,
    this.busyAwardId,
    this.onToggleFeatured,
    this.onShareAchievement,
    this.league,
    this.joiningLeague = false,
    this.onJoinLeague,
    this.onOpenLeagueBoard,
    this.socialIdentityRepository,
  });

  final StudentProfileView profile;
  final PrivacySettings privacy;
  final List<DeviceSession> sessions;
  final NanoCopy copy;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final ValueChanged<PrivacySettings> onPrivacyChanged;
  final VoidCallback? onOpenAccessibility;
  final VoidCallback? onOpenProgress;
  final ValueChanged<DeviceSession> onRevoke;
  final String? revokingId;
  final Future<void> Function()? onSignOut;
  final bool signingOut;
  final bool canShare;
  final String? busyAwardId;
  final ValueChanged<ProfileAchievement>? onToggleFeatured;
  final ValueChanged<ProfileAchievement>? onShareAchievement;
  final LeagueStatus? league;
  final bool joiningLeague;
  final VoidCallback? onJoinLeague;
  final VoidCallback? onOpenLeagueBoard;
  final SocialIdentityRepository? socialIdentityRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = profile.level;
    final featured = [
      for (final achievement in profile.achievements)
        if (achievement.isFeatured) achievement,
    ];
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
        if (league != null) ...[
          const SizedBox(height: NanoSpacing.sm),
          Text(copy.leagueLabel, style: theme.textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(
              league!.joined
                  ? copy.leagueDivisionRank(
                      league!.divisionTitleFor(urdu: copy.isUrdu),
                      league!.rank ?? 0,
                      league!.peerCount,
                    )
                  : copy.leagueNotJoinedHint,
            ),
            subtitle: Text(
              league!.joined
                  ? [
                      copy.leagueWeekXp(league!.weekXp),
                      copy.leagueDaysLeft(
                        league!.timeRemaining.inDays.clamp(0, 7),
                      ),
                      copy.leagueJoinedHint,
                    ].join(' · ')
                  : league!.weekKey,
            ),
            trailing: !league!.joined
                ? (onJoinLeague == null
                    ? null
                    : TextButton(
                        onPressed: joiningLeague ? null : onJoinLeague,
                        child: Text(copy.leagueJoin),
                      ))
                : (onOpenLeagueBoard == null
                    ? null
                    : TextButton(
                        onPressed: onOpenLeagueBoard,
                        child: Text(copy.leagueBoardOpen),
                      )),
          ),
        ],
        if (onOpenProgress != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.trending_up),
            title: Text(copy.progressTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenProgress,
          ),
        if (profile.recommendedNext != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text(copy.nextUpLabel),
            subtitle: Text(profile.recommendedNext!),
          ),
        if (featured.isNotEmpty) ...[
          const SizedBox(height: NanoSpacing.md),
          Text(copy.featuredAchievementsLabel, style: theme.textTheme.titleLarge),
          const SizedBox(height: NanoSpacing.sm),
          for (final achievement in featured)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star),
              title: Text(achievement.title),
            ),
        ],
        if (profile.achievements.isNotEmpty) ...[
          const SizedBox(height: NanoSpacing.md),
          Text(copy.achievementsLabel, style: theme.textTheme.titleLarge),
          const SizedBox(height: NanoSpacing.sm),
          for (final achievement in profile.achievements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                achievement.isSticker
                    ? Icons.sticky_note_2_outlined
                    : Icons.emoji_events_outlined,
              ),
              title: Text(achievement.title),
              trailing: canShare
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: achievement.isFeatured
                              ? copy.unpinAchievementLabel
                              : copy.pinAchievementLabel,
                          onPressed: busyAwardId == achievement.id ||
                                  onToggleFeatured == null
                              ? null
                              : () => onToggleFeatured!(achievement),
                          icon: Icon(
                            achievement.isFeatured
                                ? Icons.star
                                : Icons.star_border,
                          ),
                        ),
                        IconButton(
                          tooltip: copy.shareAchievementLabel,
                          onPressed: busyAwardId == achievement.id ||
                                  onShareAchievement == null
                              ? null
                              : () => onShareAchievement!(achievement),
                          icon: const Icon(Icons.ios_share_outlined),
                        ),
                      ],
                    )
                  : null,
            ),
        ],
        const SizedBox(height: NanoSpacing.md),
        if (socialIdentityRepository != null)
          SocialIdentitySection(
            repository: socialIdentityRepository!,
            copy: copy,
          ),
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
