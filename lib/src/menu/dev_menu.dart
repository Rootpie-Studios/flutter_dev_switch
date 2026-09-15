import 'package:flutter/material.dart';

import '../api/api_config.dart';
import '../api/server_picker.dart';
import '../dev_tools.dart';
import '../faults/dev_faults_panel.dart';
import 'dev_sheet.dart';

/// One app-specific row in the [DevMenu]: a test login, a data generator,
/// a cache wipe. [onTap] runs after the menu has closed, with the root
/// navigator's context.
class DevMenuEntry {
  final String label;
  final IconData icon;
  final String? subtitle;
  final Future<void> Function(BuildContext context) onTap;

  /// Whether to list the row, asked again whenever the menu rebuilds (it
  /// follows the [ApiConfig]), so a row can depend on the server picked.
  final bool Function()? when;

  const DevMenuEntry({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.when,
  });
}

/// The hidden developer menu, in three sections: "Server" (the pick, a
/// row opening the [ServerPicker]), "Faults" (the [DevFaultsPanel] for
/// [ApiConfig.faults]: delay, offline, refuse requests), and "App", whatever
/// [entries] the app adds. [show] opens it; the DevShell calls that from
/// every screen. Shows nothing and does nothing unless [DevTools.enabled].
class DevMenu extends StatelessWidget {
  final ApiConfig config;
  final List<DevMenuEntry> entries;

  const DevMenu({super.key, required this.config, this.entries = const []});

  static Future<void> show(
    BuildContext context, {
    required ApiConfig config,
    List<DevMenuEntry> entries = const [],
  }) {
    if (!DevTools.enabled) return Future<void>.value();
    return showDevSheet<void>(
      context,
      builder: (_) => DevMenu(config: config, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: config,
    builder: (context, _) {
      final List<DevMenuEntry> listed = [
        for (final DevMenuEntry e in entries)
          if (e.when?.call() ?? true) e,
      ];
      return DevSheetBody(
        title: 'Developer',
        children: [
          const DevSectionHeader('Server'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(config.label),
            subtitle: config.environment == null ? null : Text(config.baseUrl),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => closeThen(
              context,
              (root) => ServerPicker.show(root, config: config),
            ),
          ),
          const DevSectionHeader('Faults'),
          DevFaultsPanel(faults: config.faults),
          if (listed.isNotEmpty) const DevSectionHeader('App'),
          for (final DevMenuEntry e in listed)
            ListTile(
              leading: Icon(e.icon),
              title: Text(e.label),
              subtitle: e.subtitle == null ? null : Text(e.subtitle!),
              onTap: () => closeThen(context, e.onTap),
            ),
        ],
      );
    },
  );
}
