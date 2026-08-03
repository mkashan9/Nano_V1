import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/league/presentation/league_board_page.dart';
import 'package:student_app/features/qa/presentation/offline_network_audit_page.dart';
import 'package:student_app/features/qa/presentation/performance_audit_page.dart';
import 'package:student_app/features/notifications/presentation/notification_preferences_page.dart';
import 'package:student_app/features/parent/presentation/guardian_link_page.dart';
import 'package:student_app/features/parent/presentation/parent_guidance_page.dart';
import 'package:student_app/features/profile/presentation/social_identity_section.dart';
import 'package:student_app/features/share/presentation/social_share_sheet.dart';

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
    this.friendGraphRepository,
    this.safetyReportRepository,
    this.accessRepository,
    this.schoolLinkRepository,
    this.onSchoolLinked,
    this.parentGuidanceRepository,
    this.guardianLinkRepository,
    this.notificationPreferencesRepository,
    this.pushDeliveryRepository,
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

  /// SOC-02: friend requests / remove / block.
  final FriendGraphRepository? friendGraphRepository;

  /// SAFE-01: report peer with optional block.
  final SafetyReportRepository? safetyReportRepository;

  /// IND-02: independent access entitlements card.
  final IndependentAccessRepository? accessRepository;

  /// IND-04: school invite redeem / account linking.
  final SchoolLinkRepository? schoolLinkRepository;
  final ValueChanged<SessionPrincipal>? onSchoolLinked;

  /// PAR-01: weekly parent guidance card.
  final ParentGuidanceRepository? parentGuidanceRepository;

  /// PAR-03: guardian invite / link foundations.
  final GuardianLinkRepository? guardianLinkRepository;

  /// NOT-02: quiet hours / category mute / digest.
  final NotificationPreferencesRepository? notificationPreferencesRepository;
  final PushDeliveryRepository? pushDeliveryRepository;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  NanoViewState _state = const NanoViewLoading();
  StudentProfileView? _profile;
  PrivacySettings? _privacy;
  List<DeviceSession> _sessions = const [];
  LeagueStatus? _league;
  IndependentEntitlements? _access;
  IndependentPlanSnapshot? _plan;
  var _joiningLeague = false;
  var _updatingPlan = false;
  var _linkingSchool = false;
  var _signingOut = false;
  String? _revokingId;
  String? _busyAwardId;
  final _schoolCodeController = TextEditingController();
  SchoolInvitePreview? _schoolPreview;
  String? _schoolLinkError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _schoolCodeController.dispose();
    super.dispose();
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
      IndependentEntitlements? access;
      IndependentPlanSnapshot? plan;
      if (widget.principal.role == AppRole.independentStudent) {
        final accessRepo =
            widget.accessRepository ?? FakeIndependentAccessRepository();
        plan = await accessRepo.loadPlan(userId: userId);
        access = plan.entitlements;
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
        _access = access;
        _plan = plan;
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

  Future<void> _startTrial() async {
    if (_updatingPlan || widget.principal.userId == null) return;
    final accessRepo =
        widget.accessRepository ?? FakeIndependentAccessRepository();
    setState(() => _updatingPlan = true);
    try {
      final plan = await accessRepo.applyPlan(
        userId: widget.principal.userId!,
        kind: IndependentPlanKind.trial,
      );
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _access = plan.entitlements;
        _updatingPlan = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingPlan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start trial')),
      );
    }
  }

  Future<void> _previewSchoolCode() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final gate = SchoolLinkPolicy.canPreview(
      role: widget.principal.role,
      schoolId: widget.principal.schoolId,
    );
    if (!gate.allowed) return;
    setState(() {
      _linkingSchool = true;
      _schoolLinkError = null;
      _schoolPreview = null;
    });
    try {
      final repo =
          widget.schoolLinkRepository ?? FakeSchoolLinkRepository();
      final preview =
          await repo.previewInvite(_schoolCodeController.text);
      if (!mounted) return;
      if (!preview.isLinkable) {
        setState(() {
          _linkingSchool = false;
          _schoolLinkError = copy.schoolLinkUnavailable;
        });
        return;
      }
      setState(() {
        _schoolPreview = preview;
        _linkingSchool = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _linkingSchool = false;
        _schoolLinkError = copy.schoolLinkInvalid;
      });
    }
  }

  Future<void> _confirmSchoolLink() async {
    final preview = _schoolPreview;
    if (preview == null || _linkingSchool) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() => _linkingSchool = true);
    try {
      final repo =
          widget.schoolLinkRepository ?? FakeSchoolLinkRepository();
      final result = await repo.linkAccount(
        principal: widget.principal,
        code: preview.code,
      );
      if (!mounted) return;
      setState(() => _linkingSchool = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.schoolLinkSuccess)),
      );
      widget.onSchoolLinked?.call(result.principal);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _linkingSchool = false;
        _schoolLinkError = copy.schoolLinkInvalid;
      });
    }
  }

  void _openParentGuidance() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParentGuidancePage(
          repository: widget.parentGuidanceRepository ??
              FakeParentGuidanceRepository(),
          childUserId: widget.principal.userId,
        ),
      ),
    );
  }

  void _openGuardianLinks() {
    final profile = _profile;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuardianLinkPage(
          repository:
              widget.guardianLinkRepository ?? FakeGuardianLinkRepository(),
          childUserId: widget.principal.userId ?? 'local-child',
          childDisplayName: profile?.displayName ?? widget.principal.displayName,
        ),
      ),
    );
  }

  void _openNotificationPreferences() {
    final inbox = FakeStudentNotificationInboxRepository();
    final push = widget.pushDeliveryRepository ??
        FakePushDeliveryRepository(inbox: inbox);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationPreferencesPage(
          preferencesRepository: widget.notificationPreferencesRepository ??
              FakeNotificationPreferencesRepository(),
          userId: widget.principal.userId ?? 'local-student',
          pushDelivery: push,
        ),
      ),
    );
  }

  void _openPerformanceAudit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PerformanceAuditPage(),
      ),
    );
  }

  void _openOfflineNetworkAudit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OfflineNetworkAuditPage(),
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
      if (!mounted) return;
      final outcome = await showSocialShareSheet(
        context: context,
        card: card,
        copy: copy,
      );
      if (!mounted || outcome == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shareOutcomeMessage(outcome, copy))),
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
              access: _access,
              plan: _plan,
              updatingPlan: _updatingPlan,
              onStartTrial: _plan?.canStartTrial == true ? _startTrial : null,
              showSchoolLink: SchoolLinkPolicy.canPreview(
                    role: widget.principal.role,
                    schoolId: widget.principal.schoolId,
                  ).allowed,
              schoolCodeController: _schoolCodeController,
              schoolPreview: _schoolPreview,
              schoolLinkError: _schoolLinkError,
              linkingSchool: _linkingSchool,
              onPreviewSchool: _previewSchoolCode,
              onConfirmSchoolLink: _schoolPreview == null
                  ? null
                  : _confirmSchoolLink,
              onOpenParentGuidance: _openParentGuidance,
              onOpenGuardianLinks: _openGuardianLinks,
              onOpenNotificationPreferences: _openNotificationPreferences,
              onOpenPerformanceAudit: _openPerformanceAudit,
              onOpenOfflineNetworkAudit: _openOfflineNetworkAudit,
              socialIdentityRepository: widget.socialIdentityRepository,
              friendGraphRepository: widget.friendGraphRepository,
              safetyReportRepository: widget.safetyReportRepository,
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
    this.access,
    this.plan,
    this.updatingPlan = false,
    this.onStartTrial,
    this.showSchoolLink = false,
    this.schoolCodeController,
    this.schoolPreview,
    this.schoolLinkError,
    this.linkingSchool = false,
    this.onPreviewSchool,
    this.onConfirmSchoolLink,
    this.onOpenParentGuidance,
    this.onOpenGuardianLinks,
    this.onOpenNotificationPreferences,
    this.onOpenPerformanceAudit,
    this.onOpenOfflineNetworkAudit,
    this.socialIdentityRepository,
    this.friendGraphRepository,
    this.safetyReportRepository,
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
  final IndependentEntitlements? access;
  final IndependentPlanSnapshot? plan;
  final bool updatingPlan;
  final VoidCallback? onStartTrial;
  final bool showSchoolLink;
  final TextEditingController? schoolCodeController;
  final SchoolInvitePreview? schoolPreview;
  final String? schoolLinkError;
  final bool linkingSchool;
  final VoidCallback? onPreviewSchool;
  final VoidCallback? onConfirmSchoolLink;
  final VoidCallback? onOpenParentGuidance;
  final VoidCallback? onOpenGuardianLinks;
  final VoidCallback? onOpenNotificationPreferences;
  final VoidCallback? onOpenPerformanceAudit;
  final VoidCallback? onOpenOfflineNetworkAudit;
  final SocialIdentityRepository? socialIdentityRepository;
  final FriendGraphRepository? friendGraphRepository;
  final SafetyReportRepository? safetyReportRepository;

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
        if (access != null) ...[
          const SizedBox(height: NanoSpacing.md),
          Text(copy.accessStatusLabel, style: theme.textTheme.titleMedium),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              access!.isReduced
                  ? Icons.lock_outline
                  : Icons.verified_user_outlined,
            ),
            title: Text(
              plan == null
                  ? copy.accessTierLabel(access!.tier)
                  : copy.planKindLabel(plan!.kind),
            ),
            subtitle: Text(
              [
                if (plan?.daysRemaining != null)
                  copy.planDaysLeft(plan!.daysRemaining!),
                access!.planLabel,
                if (plan?.kind == IndependentPlanKind.expired)
                  copy.planExpiredHint
                else if (access!.allows(IndependentFeature.games))
                  copy.games
                else
                  copy.accessGamesBlocked,
              ].join(' · '),
            ),
            trailing: onStartTrial == null
                ? null
                : TextButton(
                    onPressed: updatingPlan ? null : onStartTrial,
                    child: Text(copy.planStartTrial),
                  ),
          ),
        ],
        if (showSchoolLink && schoolCodeController != null) ...[
          const SizedBox(height: NanoSpacing.md),
          Text(copy.schoolLinkTitle, style: theme.textTheme.titleMedium),
          Text(copy.schoolLinkHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: NanoSpacing.sm),
          TextField(
            controller: schoolCodeController,
            enabled: !linkingSchool,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: copy.schoolLinkCodeLabel,
              errorText: schoolLinkError,
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          Row(
            children: [
              TextButton(
                onPressed: linkingSchool ? null : onPreviewSchool,
                child: Text(copy.schoolLinkPreview),
              ),
              if (schoolPreview != null) ...[
                const SizedBox(width: NanoSpacing.sm),
                Expanded(
                  child: Text(copy.schoolLinkPreviewLabel(schoolPreview!.schoolName)),
                ),
                TextButton(
                  onPressed: linkingSchool ? null : onConfirmSchoolLink,
                  child: Text(copy.schoolLinkConfirm),
                ),
              ],
            ],
          ),
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.family_restroom_outlined),
          title: Text(copy.parentGuidanceTitle),
          subtitle: Text(copy.parentGuidancePrivacyHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenParentGuidance,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.link_outlined),
          title: Text(copy.guardianLinkTitle),
          subtitle: Text(copy.guardianLinkHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenGuardianLinks,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_active_outlined),
          title: Text(copy.notificationPrefsTitle),
          subtitle: Text(copy.notificationPrefsHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenNotificationPreferences,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.speed_outlined),
          title: Text(copy.performanceAuditTitle),
          subtitle: Text(copy.performanceAuditSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenPerformanceAudit,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.wifi_off_outlined),
          title: Text(copy.offlineNetworkAuditTitle),
          subtitle: Text(copy.offlineNetworkAuditSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenOfflineNetworkAudit,
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
            friendGraph: friendGraphRepository,
            safetyReports: safetyReportRepository,
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
