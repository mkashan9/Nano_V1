import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    assert(
      !config.environment.isProduction,
      'Diagnostics must not ship in production builds.',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('App'),
            subtitle: Text(config.appDisplayName),
          ),
          ListTile(
            title: const Text('Environment'),
            subtitle: Text(config.environment.name),
          ),
          ListTile(
            title: const Text('Supabase URL set'),
            subtitle: Text(config.supabaseUrl.isEmpty ? 'no' : 'yes'),
          ),
          ListTile(
            title: const Text('Anon key set'),
            subtitle: Text(config.supabaseAnonKey.isEmpty ? 'no' : 'yes'),
          ),
          ListTile(
            title: const Text('Build mode'),
            subtitle: Text(kReleaseMode ? 'release' : 'debug/profile'),
          ),
          ListTile(
            title: const Text('Feature flags'),
            subtitle: Text(config.featureFlags.toString()),
          ),
        ],
      ),
    );
  }
}
