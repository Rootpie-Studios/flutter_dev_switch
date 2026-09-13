import 'package:flutter/material.dart';

import 'api_config.dart';
import 'dev_tools.dart';
import 'dev_tools_strings.dart';
import 'server_picker.dart';
import 'slowdown_picker.dart';

/// One app-specific row in the [DevMenu]: a test login, a data generator,
/// a cache wipe. [onTap] runs after the menu has closed.
class DevMenuEntry {
  final String label;
  final IconData icon;
  final String? subtitle;
  final Future<void> Function(BuildContext context) onTap;

  const DevMenuEntry({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });
}

/// The hidden developer menu: a "Server" row that opens the [ServerPicker],
/// a "Slow requests" row that opens the [SlowdownPicker], then whatever
/// [entries] the app adds. Open it with [show] from anywhere (a settings
/// page, say), or wrap a logo in [DevMenuTrigger] so a long press opens it.
/// Shows nothing and does nothing unless [DevTools.enabled].
class DevMenu extends StatelessWidget {
  final ApiConfig config;
  final List<DevMenuEntry> entries;
  final DevToolsStrings strings;
  final String customExample;

  const DevMenu({
    super.key,
    required this.config,
    this.entries = const [],
    this.strings = const DevToolsStrings(),
    this.customExample = 'http://my-macbook.local/api',
  });

  static Future<void> show(
    BuildContext context, {
    required ApiConfig config,
    List<DevMenuEntry> entries = const [],
    DevToolsStrings strings = const DevToolsStrings(),
    String customExample = 'http://my-macbook.local/api',
  }) {
    if (!DevTools.enabled) return Future<void>.value();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DevMenu(
        config: config,
        entries: entries,
        strings: strings,
        customExample: customExample,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: config,
    builder: (context, _) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                strings.devMenuTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(strings.server),
              subtitle: Text(config.baseUrl),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _swapFor(
                context,
                (root) => ServerPicker.show(
                  root,
                  config: config,
                  strings: strings,
                  customExample: customExample,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_bottom_rounded),
              title: Text(strings.slowRequests),
              subtitle: Text(formatSlowdown(config.slowdown, strings)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _swapFor(
                context,
                (root) =>
                    SlowdownPicker.show(root, config: config, strings: strings),
              ),
            ),
            for (final DevMenuEntry e in entries)
              ListTile(
                leading: Icon(e.icon),
                title: Text(e.label),
                subtitle: e.subtitle == null ? null : Text(e.subtitle!),
                onTap: () async {
                  final NavigatorState nav = Navigator.of(context);
                  final BuildContext root = nav.context;
                  nav.pop();
                  await e.onTap(root);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Close the menu and open [sheet] in its place, instead of stacking one
/// sheet on another.
void _swapFor(BuildContext context, void Function(BuildContext root) sheet) {
  final NavigatorState nav = Navigator.of(context);
  final BuildContext root = nav.context;
  nav.pop();
  sheet(root);
}

/// Wraps a logo or wordmark so that a long press opens the [DevMenu].
/// Nothing on screen hints at it, and in a store build the gesture is not
/// even attached. Put a [ServerBadge] under it so a non-production server
/// stays visible.
class DevMenuTrigger extends StatelessWidget {
  final Widget child;
  final ApiConfig config;
  final List<DevMenuEntry> entries;
  final DevToolsStrings strings;
  final String customExample;

  const DevMenuTrigger({
    super.key,
    required this.child,
    required this.config,
    this.entries = const [],
    this.strings = const DevToolsStrings(),
    this.customExample = 'http://my-macbook.local/api',
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onLongPress: DevTools.enabled
        ? () => DevMenu.show(
            context,
            config: config,
            entries: entries,
            strings: strings,
            customExample: customExample,
          )
        : null,
    child: child,
  );
}
