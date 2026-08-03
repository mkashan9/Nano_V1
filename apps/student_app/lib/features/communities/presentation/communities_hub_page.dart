import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// COM-01 Communities hub: My + Discover (create/join later).
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
        builder: (context) => _CommunityDetailSheet(detail: detail),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
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
          Text(
            copy.communities,
            style: Theme.of(context).textTheme.headlineSmall,
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

class _CommunityDetailSheet extends StatelessWidget {
  const _CommunityDetailSheet({required this.detail});

  final CommunityDetail detail;

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
              if (detail.isMember) ...[
                const SizedBox(height: NanoSpacing.xs),
                Text(copy.communitiesYouAreMember),
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
              const SizedBox(height: NanoSpacing.lg),
              Text(copy.communitiesJoinDeferredHint),
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
