import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// COM-01/02 Communities hub: My + Discover + create + roles.
class CommunitiesHubPage extends StatefulWidget {
  const CommunitiesHubPage({
    super.key,
    required this.repository,
  });

  final CommunityDiscoveryRepository repository;

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

class _CommunityDetailSheet extends StatelessWidget {
  const _CommunityDetailSheet({
    required this.detail,
    required this.repository,
    required this.onChanged,
  });

  final CommunityDetail detail;
  final CommunityDiscoveryRepository repository;
  final VoidCallback onChanged;

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
              Text(detail.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.xs),
              Text(detail.summary),
              const SizedBox(height: NanoSpacing.sm),
              Text(copy.communitiesMemberCount(detail.memberCount)),
              if (detail.myRole != null) ...[
                const SizedBox(height: NanoSpacing.xs),
                Text(copy.communitiesYourRole(detail.myRole!)),
              ],
              const SizedBox(height: NanoSpacing.lg),
              Text(
                copy.communitiesRulesHeading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: NanoSpacing.xs),
              Text(
                detail.rulesText.isEmpty
                    ? copy.communitiesRulesEmpty
                    : detail.rulesText,
              ),
              if (detail.canManageRoles) ...[
                const SizedBox(height: NanoSpacing.lg),
                OutlinedButton(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => _MembersSheet(
                        communityId: detail.id,
                        repository: repository,
                        callerRole: detail.myRole ?? 'member',
                      ),
                    );
                    onChanged();
                  },
                  child: Text(copy.communitiesManageRoles),
                ),
              ] else if (!detail.isMember) ...[
                const SizedBox(height: NanoSpacing.lg),
                Text(copy.communitiesJoinDeferredHint),
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
