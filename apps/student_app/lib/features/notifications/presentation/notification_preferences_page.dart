import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// NOT-02 quiet hours, category mute, and digest controls.
class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({
    super.key,
    required this.preferencesRepository,
    required this.userId,
    this.pushDelivery,
  });

  final NotificationPreferencesRepository preferencesRepository;
  final String userId;
  final PushDeliveryRepository? pushDelivery;

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  NanoViewState _state = const NanoViewLoading();
  NotificationPreferences _prefs = NotificationPreferences.defaults;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final prefs =
          await widget.preferencesRepository.load(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _save(NotificationPreferences next) async {
    setState(() {
      _busy = true;
      _prefs = next;
    });
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    try {
      final saved = await widget.preferencesRepository.save(
        userId: widget.userId,
        preferences: next,
      );
      final push = widget.pushDelivery;
      if (push is FakePushDeliveryRepository) {
        push.preferences = saved;
      }
      if (!mounted) return;
      setState(() {
        _prefs = saved;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.notificationPrefsSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _flushDigest() async {
    final push = widget.pushDelivery;
    if (push == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await push.flushDigest(userId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Digest is empty'
                : 'Digest delivered',
          ),
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

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return Scaffold(
      appBar: AppBar(title: Text(copy.notificationPrefsTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: ListView(
          padding: const EdgeInsets.all(NanoSpacing.md),
          children: [
            Text(copy.notificationPrefsHint),
            const SizedBox(height: NanoSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(copy.notificationPrefsQuiet),
              subtitle: Text(copy.notificationPrefsQuietWindow),
              value: _prefs.quietHoursEnabled,
              onChanged: _busy
                  ? null
                  : (value) => _save(_prefs.copyWith(quietHoursEnabled: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(copy.notificationPrefsDigest),
              value: _prefs.digestEnabled,
              onChanged: _busy
                  ? null
                  : (value) => _save(_prefs.copyWith(digestEnabled: value)),
            ),
            const SizedBox(height: NanoSpacing.md),
            Text(
              copy.notificationPrefsCategories,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              copy.notificationPrefsMandatoryHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final category
                in NotificationPreferencePolicy.controllableCategories)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(category),
                value: _prefs.mutedCategories.contains(category),
                onChanged: _busy
                    ? null
                    : (muted) => _save(
                          _prefs.withCategoryMuted(category, muted),
                        ),
              ),
            const SizedBox(height: NanoSpacing.lg),
            FilledButton.tonal(
              onPressed: _busy || widget.pushDelivery == null
                  ? null
                  : _flushDigest,
              child: Text(copy.notificationPrefsFlushDigest),
            ),
          ],
        ),
      ),
    );
  }
}
