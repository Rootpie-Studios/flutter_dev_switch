import 'package:flutter/material.dart';

import 'api_config.dart';
import 'dev_tools_strings.dart';

/// The request slowdown for testers: every request waits the picked time
/// before it goes out, so loading states can be looked at on a real
/// screen. One of [choices] is marked as in use; the pick is kept across
/// restarts like a server pick, and the [ServerBadge] shows it.
///
/// Opened from the [DevMenu]; [show] for anywhere else.
class SlowdownPicker extends StatelessWidget {
  final ApiConfig config;
  final DevToolsStrings strings;
  final List<Duration> choices;

  /// Off, and a few steps long enough to see a spinner but short enough to
  /// keep testing bearable.
  static const List<Duration> defaultChoices = [
    Duration.zero,
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 6),
  ];

  const SlowdownPicker({
    super.key,
    required this.config,
    this.strings = const DevToolsStrings(),
    this.choices = defaultChoices,
  });

  static Future<void> show(
    BuildContext context, {
    required ApiConfig config,
    DevToolsStrings strings = const DevToolsStrings(),
    List<Duration> choices = defaultChoices,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        SlowdownPicker(config: config, strings: strings, choices: choices),
  );

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: config,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  strings.slowRequests,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  strings.slowRequestsHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final Duration d in _rows(config.slowdown))
                ListTile(
                  leading: Icon(
                    d == config.slowdown
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: d == config.slowdown
                        ? colors.primary
                        : colors.outline,
                  ),
                  title: Text(formatSlowdown(d, strings)),
                  onTap: () async {
                    await config.pickSlowdown(d);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// [choices], plus the current pick when it is not one of them, so what
  /// is in use can always be seen and switched off.
  List<Duration> _rows(Duration current) =>
      choices.contains(current) ? choices : ([...choices, current]..sort());
}

/// "Off" for zero, otherwise the seconds: "3 s", "0.5 s".
String formatSlowdown(Duration delay, DevToolsStrings strings) {
  if (delay <= Duration.zero) return strings.off;
  final double s = delay.inMilliseconds / 1000;
  final String n = s == s.roundToDouble() ? s.toInt().toString() : '$s';
  return strings.seconds.replaceFirst('{n}', n);
}
