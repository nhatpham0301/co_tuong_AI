import 'package:flutter/material.dart';

import '../global.dart';

/// Live Match list screen — stub for Phase 1.
/// Real-time data and MiniBoard widgets will be wired in Phase 5.
class LiveMatchScreen extends StatelessWidget {
  const LiveMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.liveMatch),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.sports_esports, size: 40),
              title: Text('Match ${index + 1}'),
              subtitle: const Text('Coming in Phase 5…'),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
