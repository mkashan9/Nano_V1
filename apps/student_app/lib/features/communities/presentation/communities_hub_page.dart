import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/communities/presentation/community_chat_page.dart';

/// COM-01..04 Communities hub: discovery, join, roles, and chat entry.
class CommunitiesHubPage extends StatefulWidget {
  const CommunitiesHubPage({
    super.key,
    required this.repository,
    this.messagingRepository,
  });

  final CommunityDiscoveryRepository repository;
  final CommunityMessagingRepository? messagingRepository;

  @override
  State<CommunitiesHubPage> createState() => _CommunitiesHubPageState();
}

class _CommunitiesHubPageState extends State<CommunitiesHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  NanoViewState _state = const NanoViewLoading();
  List<CommunitySummary> _mine = const [];
  List<CommunitySummary> _discover = const [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final mine = await widget.repository.myCommunities();
      final discover = await widget.repository.discoverPublic(
        query: _search.text,
      );
      if (!mounted) return;
      setState(() {
        _mine = mine;
        _discover = discover;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() => _state = NanoViewError(message: copy.communitiesLoadError));
    }
  }

  Future<void> _openDetail(CommunitySummary item) async {
    try {
      final detail = await widget.repository.getDetail(item.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _CommunityDetailSheet(
          detail: detail,
          repository: widget.repository,
          messagingRepository: widget.messagingRepository ??
              FakeCommunityMessagingRepository(),
          onChanged: _load,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _create() async {
    final created = await showModalBottomSheet<CommunityDetail>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateCommunitySheet(
        repository: widget.repository,
      ),
    );
    if (created == null || !mounted) return;
    await _load();
    _tabs.animateTo(0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(created.name)),
    );
  }

  Future<void> _redeem() async {
    final joined = await showModalBottomSheet<CommunityDetail>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RedeemInviteSheet(
        repository: widget.repository,
      ),
    );
    if (joined == null || !mounted) return;
    await _load();
    _tabs.animateTo(0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(joined.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return NanoScaffold(
      padBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  copy.communities,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(
                onPressed: _redeem,
                child: Text(copy.communitiesRedeemTitle),
              ),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: Text(copy.communitiesCreate),
              ),
            ],
          ),
          const SizedBox(height: NanoSpacing.xs),
          Text(copy.communitiesHubHint),
          const SizedBox(height: NanoSpacing.md),
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: copy.communitiesMyTab),
              Tab(text: copy.communitiesDiscoverTab),
            ],
          ),
          Expanded(
            child: NanoViewStateHost(
              state: _state,
              onRetry: _load,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _CommunityList(
                    items: _mine,
                    emptyTitle: copy.communitiesMyEmptyTitle,
                    emptyMessage: copy.communitiesMyEmptyBody,
                    onTap: _openDetail,
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: NanoSpacing.sm,
                        ),
                        child: TextField(
                          controller: _search,
                          decoration: InputDecoration(
                            hintText: copy.communitiesSearchHint,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _load,
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _load(),
                        ),
                      ),
                      Expanded(
                        child: _CommunityList(
                          items: _discover,
                          emptyTitle: copy.communitiesDiscoverEmptyTitle,
                          emptyMessage: copy.communitiesDiscoverEmptyBody,
                          onTap: _openDetail,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityList extends StatelessWidget {
  const _CommunityList({
    required this.items,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onTap,
  });

  final List<CommunitySummary> items;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<CommunitySummary> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emptyTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: NanoSpacing.sm),
              Text(emptyMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: NanoSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.summary),
          trailing: Text(copy.communitiesMemberCount(item.memberCount)),
          onTap: () => onTap(item),
        );
      },
    );
  }
}

class _CreateCommunitySheet extends StatefulWidget {
  const _CreateCommunitySheet({required this.repository});

  final CommunityDiscoveryRepository repository;

  @override
  State<_CreateCommunitySheet> createState() => _CreateCommunitySheetState();
}

class _CreateCommunitySheetState extends State<_CreateCommunitySheet> {
  final _name = TextEditingController();
  final _summary = TextEditingController();
  final _rules = TextEditingController();
  var _visibility = CommunityVisibility.public;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _summary.dispose();
    _rules.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final created = await widget.repository.createCommunity(
        name: _name.text,
        summary: _summary.text,
        rulesText: _rules.text,
        visibility: _visibility,
      );
      if (!mounted) return;
      Navigator.pop(context, created);
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        NanoSpacing.lg,
        NanoSpacing.lg,
        NanoSpacing.lg,
        NanoSpacing.lg + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.communitiesCreateTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: NanoSpacing.md),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: copy.communitiesNameLabel),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: NanoSpacing.sm),
            TextField(
              controller: _summary,
              decoration:
                  InputDecoration(labelText: copy.communitiesSummaryLabel),
              maxLines: 2,
            ),
            const SizedBox(height: NanoSpacing.sm),
            TextField(
              controller: _rules,
              decoration: InputDecoration(labelText: copy.communitiesRulesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: NanoSpacing.sm),
            SegmentedButton<CommunityVisibility>(
              segments: [
                ButtonSegment(
                  value: CommunityVisibility.public,
                  label: Text(copy.communitiesVisibilityPublic),
                ),
                ButtonSegment(
                  value: CommunityVisibility.private,
                  label: Text(copy.communitiesVisibilityPrivate),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: _busy
                  ? null
                  : (next) => setState(() => _visibility = next.first),
            ),
            const SizedBox(height: NanoSpacing.lg),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(copy.communitiesCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedeemInviteSheet extends StatefulWidget {
  const _RedeemInviteSheet({required this.repository});

  final CommunityDiscoveryRepository repository;

  @override
  State<_RedeemInviteSheet> createState() => _RedeemInviteSheetState();
}

class _RedeemInviteSheetState extends State<_RedeemInviteSheet> {
  final _code = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final joined = await widget.repository.redeemInvite(_code.text);
      if (!mounted) return;
      Navigator.pop(context, joined);
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        NanoSpacing.lg,
        NanoSpacing.lg,
        NanoSpacing.lg,
        NanoSpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy.communitiesRedeemTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: NanoSpacing.md),
          TextField(
            controller: _code,
            decoration: InputDecoration(labelText: copy.communitiesRedeemHint),
            textCapitalization: TextCapitalization.characters,
            enabled: !_busy,
          ),
          const SizedBox(height: NanoSpacing.lg),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(copy.communitiesJoin),
          ),
        ],
      ),
    );
  }
}

class _CommunityDetailSheet extends StatefulWidget {
  const _CommunityDetailSheet({
    required this.detail,
    required this.repository,
    required this.messagingRepository,
    required this.onChanged,
  });

  final CommunityDetail detail;
  final CommunityDiscoveryRepository repository;
  final CommunityMessagingRepository messagingRepository;
  final VoidCallback onChanged;

  @override
  State<_CommunityDetailSheet> createState() => _CommunityDetailSheetState();
}

class _CommunityDetailSheetState extends State<_CommunityDetailSheet> {
  late CommunityDetail _detail;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.detail;
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      final next = await widget.repository.joinCommunity(_detail.id);
      if (!mounted) return;
      setState(() => _detail = next);
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    setState(() => _busy = true);
    try {
      await widget.repository.leaveCommunity(_detail.id);
      if (!mounted) return;
      widget.onChanged();
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    setState(() => _busy = true);
    try {
      final invite = await widget.repository.createInvite(_detail.id);
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(copy.communitiesInviteCreated),
          content: SelectableText(invite.code),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(copy.cancelLabel),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setPrefs({bool? muted, bool? archived}) async {
    setState(() => _busy = true);
    try {
      final next = await widget.repository.setMemberPrefs(
        communityId: _detail.id,
        muted: muted,
        archived: archived,
      );
      if (!mounted) return;
      setState(() => _detail = next);
      widget.onChanged();
      if (archived == true && mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePostingMode() async {
    setState(() => _busy = true);
    try {
      final next = await widget.repository.setPostingMode(
        communityId: _detail.id,
        mode: _detail.isAdminsOnly ? 'open' : 'admins_only',
      );
      if (!mounted) return;
      setState(() => _detail = next);
      widget.onChanged();
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_detail.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.xs),
              Text(_detail.summary),
              const SizedBox(height: NanoSpacing.sm),
              Text(copy.communitiesMemberCount(_detail.memberCount)),
              if (_detail.myRole != null) ...[
                const SizedBox(height: NanoSpacing.xs),
                Text(copy.communitiesYourRole(_detail.myRole!)),
              ],
              if (_detail.isPending) ...[
                const SizedBox(height: NanoSpacing.sm),
                Text(copy.communitiesPending),
              ],
              const SizedBox(height: NanoSpacing.lg),
              Text(
                copy.communitiesRulesHeading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: NanoSpacing.xs),
              Text(
                _detail.rulesText.isEmpty
                    ? copy.communitiesRulesEmpty
                    : _detail.rulesText,
              ),
              if (_detail.isMember) ...[
                const SizedBox(height: NanoSpacing.lg),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => CommunityChatPage(
                                communityId: _detail.id,
                                communityName: _detail.name,
                                messagingRepository:
                                    widget.messagingRepository,
                                discoveryRepository: widget.repository,
                                canPin: _detail.canPin,
                              ),
                            ),
                          );
                        },
                  child: Text(copy.communitiesOpenChat),
                ),
              ],
              if (_detail.canJoin) ...[
                const SizedBox(height: NanoSpacing.lg),
                FilledButton(
                  onPressed: _busy ? null : _join,
                  child: Text(
                    _detail.visibility == CommunityVisibility.private
                        ? copy.communitiesRequestJoin
                        : copy.communitiesJoin,
                  ),
                ),
              ],
              if (_detail.canLeave) ...[
                const SizedBox(height: NanoSpacing.sm),
                OutlinedButton(
                  onPressed: _busy ? null : _leave,
                  child: Text(copy.communitiesLeave),
                ),
              ],
              if (_detail.isMember) ...[
                const SizedBox(height: NanoSpacing.sm),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _setPrefs(muted: !_detail.isMuted),
                  child: Text(
                    _detail.isMuted
                        ? copy.communitiesUnmute
                        : copy.communitiesMute,
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _setPrefs(archived: !_detail.isArchived),
                  child: Text(
                    _detail.isArchived
                        ? copy.communitiesUnarchive
                        : copy.communitiesArchive,
                  ),
                ),
              ],
              if (_detail.canSetPostingMode) ...[
                const SizedBox(height: NanoSpacing.sm),
                OutlinedButton(
                  onPressed: _busy ? null : _togglePostingMode,
                  child: Text(
                    _detail.isAdminsOnly
                        ? copy.communitiesOpenPosting
                        : copy.communitiesAdminsOnly,
                  ),
                ),
              ],
              if (_detail.canInvite) ...[
                const SizedBox(height: NanoSpacing.sm),
                OutlinedButton(
                  onPressed: _busy ? null : _invite,
                  child: Text(copy.communitiesInvite),
                ),
              ],
              if (_detail.canManageRoles) ...[
                const SizedBox(height: NanoSpacing.sm),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => _JoinRequestsSheet(
                              communityId: _detail.id,
                              repository: widget.repository,
                            ),
                          );
                          widget.onChanged();
                        },
                  child: Text(copy.communitiesJoinRequests),
                ),
                const SizedBox(height: NanoSpacing.sm),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => _MembersSheet(
                              communityId: _detail.id,
                              repository: widget.repository,
                              callerRole: _detail.myRole ?? 'member',
                            ),
                          );
                          widget.onChanged();
                        },
                  child: Text(copy.communitiesManageRoles),
                ),
              ],
              const SizedBox(height: NanoSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(copy.cancelLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinRequestsSheet extends StatefulWidget {
  const _JoinRequestsSheet({
    required this.communityId,
    required this.repository,
  });

  final String communityId;
  final CommunityDiscoveryRepository repository;

  @override
  State<_JoinRequestsSheet> createState() => _JoinRequestsSheetState();
}

class _JoinRequestsSheetState extends State<_JoinRequestsSheet> {
  NanoViewState _state = const NanoViewLoading();
  List<CommunityMember> _requests = const [];
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final requests =
          await widget.repository.listJoinRequests(widget.communityId);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _respond(CommunityMember request, bool accept) async {
    setState(() => _busy = true);
    try {
      final next = await widget.repository.respondJoinRequest(
        communityId: widget.communityId,
        userId: request.userId,
        accept: accept,
      );
      if (!mounted) return;
      setState(() => _requests = next);
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

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.communitiesJoinRequests,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: NanoSpacing.md),
              Expanded(
                child: NanoViewStateHost(
                  state: _state,
                  onRetry: _load,
                  child: _requests.isEmpty
                      ? Center(child: Text(copy.communitiesNoJoinRequests))
                      : ListView.separated(
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final request = _requests[index];
                            return ListTile(
                              title: Text(request.displayName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _respond(request, true),
                                    child: Text(copy.communitiesAccept),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _respond(request, false),
                                    child: Text(copy.communitiesReject),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersSheet extends StatefulWidget {
  const _MembersSheet({
    required this.communityId,
    required this.repository,
    required this.callerRole,
  });

  final String communityId;
  final CommunityDiscoveryRepository repository;
  final String callerRole;

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  NanoViewState _state = const NanoViewLoading();
  List<CommunityMember> _members = const [];
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final members = await widget.repository.listMembers(widget.communityId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  List<String> _rolesFor(CommunityMember member) {
    if (widget.callerRole == 'owner') {
      return const ['owner', 'admin', 'moderator', 'member'];
    }
    if (member.role == 'owner' || member.role == 'admin') {
      return [member.role];
    }
    return const ['moderator', 'member'];
  }

  Future<void> _setRole(CommunityMember member, String role) async {
    if (role == member.role) return;
    setState(() => _busy = true);
    try {
      final next = await widget.repository.setMemberRole(
        communityId: widget.communityId,
        userId: member.userId,
        role: role,
      );
      if (!mounted) return;
      setState(() => _members = next);
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

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.communitiesManageRoles,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: NanoSpacing.md),
              Expanded(
                child: NanoViewStateHost(
                  state: _state,
                  onRetry: _load,
                  child: ListView.separated(
                    itemCount: _members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final roles = _rolesFor(member);
                      return ListTile(
                        title: Text(
                          member.isSelf
                              ? '${member.displayName} (${copy.communitiesYou})'
                              : member.displayName,
                        ),
                        trailing: DropdownButton<String>(
                          value: roles.contains(member.role)
                              ? member.role
                              : roles.first,
                          items: [
                            for (final role in roles)
                              DropdownMenuItem(
                                value: role,
                                child: Text(copy.communitiesRoleLabel(role)),
                              ),
                          ],
                          onChanged: _busy || roles.length == 1
                              ? null
                              : (value) {
                                  if (value != null) {
                                    _setRole(member, value);
                                  }
                                },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
