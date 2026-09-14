import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_config.dart';
import 'dev_menu.dart';

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
DevMenuEntry devResetEntry({required List<DevResetStep> steps}) => DevMenuEntry(
  label: 'Reset app data',
  subtitle: 'Wipe what the app stores on this device',
  icon: Icons.restart_alt_rounded,
  onTap: (BuildContext context) => runDevReset(context, steps: steps),
);

/// What [devResetEntry] runs. Every step is attempted even when one
/// fails; the failures are named afterwards.
Future<void> runDevReset(
  BuildContext context, {
  required List<DevResetStep> steps,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Reset app data'),
      content: Text(
        'As freshly installed. This wipes:\n\n'
        '${steps.map((DevResetStep s) => '• ${s.label}').join('\n')}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final List<String> failed = [];
  for (final DevResetStep step in steps) {
    try {
      await step.run();
    } catch (e) {
      debugPrint('Dev reset: ${step.label} failed: $e');
      failed.add('Could not wipe ${step.label}: $e');
    }
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        failed.isEmpty
            ? 'Wiped. Restart the app to start clean.'
            : failed.join('\n'),
      ),
    ),
  );
}
