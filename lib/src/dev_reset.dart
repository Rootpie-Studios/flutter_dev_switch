import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'dev_menu.dart';
import 'dev_tools_strings.dart';

/// One thing a reset wipes, named for the confirmation.
class DevResetStep {
  final String label;
  final Future<void> Function() run;
  const DevResetStep(this.label, this.run);

  /// Every preference except the developer menu's own (see
  /// [ApiConfig.preferenceKeys]): a tester on staging stays on staging.
  static DevResetStep preferences(
    ApiConfig config, {
    String label = 'Preferences',
  }) => DevResetStep(label, () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final String key in prefs.getKeys()) {
      if (!config.preferenceKeys.contains(key)) await prefs.remove(key);
    }
  });
}

/// A [DevMenuEntry] that wipes what the app stores on the device, as
/// freshly installed: the app lists its stores as [steps], the row asks
/// once, naming them, then runs them in order and says so.
DevMenuEntry devResetEntry({
  required List<DevResetStep> steps,
  DevToolsStrings strings = const DevToolsStrings(),
}) => DevMenuEntry(
  label: strings.resetApp,
  subtitle: strings.resetAppHelp,
  icon: Icons.restart_alt_rounded,
  onTap: (BuildContext context) =>
      runDevReset(context, steps: steps, strings: strings),
);

/// What [devResetEntry] runs.
Future<void> runDevReset(
  BuildContext context, {
  required List<DevResetStep> steps,
  DevToolsStrings strings = const DevToolsStrings(),
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(strings.resetApp),
      content: Text(
        '${strings.resetConfirm}\n\n'
        '${steps.map((DevResetStep s) => '• ${s.label}').join('\n')}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.clear),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  for (final DevResetStep step in steps) {
    await step.run();
  }
  messenger.showSnackBar(SnackBar(content: Text(strings.resetDone)));
}
