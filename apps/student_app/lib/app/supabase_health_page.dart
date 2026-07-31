import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class SupabaseHealthPage extends StatefulWidget {
  const SupabaseHealthPage({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  State<SupabaseHealthPage> createState() => _SupabaseHealthPageState();
}

class _SupabaseHealthPageState extends State<SupabaseHealthPage> {
  String _status = 'Not checked';
  AppHealthSnapshot? _snapshot;
  Object? _error;

  Future<void> _check() async {
    setState(() {
      _status = 'Checking…';
      _error = null;
      _snapshot = null;
    });
    try {
      if (widget.config.supabaseUrl.isEmpty ||
          widget.config.supabaseAnonKey.isEmpty) {
        setState(() {
          _status = 'Missing SUPABASE_URL / SUPABASE_ANON_KEY dart-defines';
        });
        return;
      }
      final gateway = NanoSupabase.fromConfig(widget.config);
      final snap = await gateway.fetchAppHealth();
      setState(() {
        _snapshot = snap;
        _status = snap == null ? 'No app_health row' : 'OK';
      });
    } catch (e) {
      setState(() {
        _error = e;
        _status = 'Failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      appBar: AppBar(title: const Text('Supabase health')),
      body: ListView(
        children: [
          Text('Project URL configured: '
              '${widget.config.supabaseUrl.isEmpty ? 'no' : 'yes'}'),
          const SizedBox(height: NanoSpacing.sm),
          Text('Status: $_status'),
          if (_snapshot != null) ...[
            Text('Environment: ${_snapshot!.environment}'),
            Text('Schema: ${_snapshot!.schemaVersion}'),
            Text('Notes: ${_snapshot!.notes}'),
          ],
          if (_error != null) Text('Error: $_error'),
          const SizedBox(height: NanoSpacing.md),
          FilledButton(
            onPressed: _check,
            child: const Text('Check app_health'),
          ),
        ],
      ),
    );
  }
}
