import 'package:flutter/material.dart';

import '../api/api_config.dart';
import 'dev_menu.dart';
import 'dev_sheet.dart';

/// A seeded account testers can log in as without typing.
class DevAccount {
  final String label;
  final String email;
  final String password;

  const DevAccount({
    required this.label,
    required this.email,
    required this.password,
  });
}

/// Performs the app's own login for [account] and stores the session the
/// way a typed login would. Return null on success, otherwise the reason
/// in words, which the tester gets to see. Throwing counts as failure with
/// the exception as the reason.
typedef DevLoginHandler =
    Future<String?> Function(BuildContext context, DevAccount account);

/// A [DevMenuEntry] for the developer menu: get in as one of [accounts]
/// without typing. Seed credentials exist on local, dev and staging
/// servers and open nothing on production, which is the one server the
/// row is not listed on.
DevMenuEntry devLoginEntry({
  required ApiConfig config,
  required List<DevAccount> accounts,
  required DevLoginHandler login,
}) => DevMenuEntry(
  label: 'Test login',
  icon: Icons.science_outlined,
  when: () => config.isNonProduction,
  onTap: (BuildContext context) =>
      runDevLogin(context, config: config, accounts: accounts, login: login),
);

/// What [devLoginEntry] runs: pick an account, log in with it behind a
/// "logging in" dialog, and say why when it fails.
Future<void> runDevLogin(
  BuildContext context, {
  required ApiConfig config,
  required List<DevAccount> accounts,
  required DevLoginHandler login,
}) async {
  final DevAccount? account = await showDevAccountPicker(
    context,
    config: config,
    accounts: accounts,
  );
  if (account == null || !context.mounted) return;

  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final NavigatorState nav = Navigator.of(context, rootNavigator: true);
  String? reason;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _BusyDialog('Logging in as ${account.email}…'),
    ),
  );
  try {
    reason = await login(context, account);
  } catch (e) {
    reason = '$e';
  } finally {
    nav.pop();
  }
  if (reason == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Test login as ${account.email} failed on ${config.label}: $reason',
      ),
    ),
  );
}

/// Lets the tester pick one of [accounts]. Null when dismissed.
Future<DevAccount?> showDevAccountPicker(
  BuildContext context, {
  required ApiConfig config,
  required List<DevAccount> accounts,
}) => showDevSheet<DevAccount>(
  context,
  builder: (BuildContext context) => DevSheetBody(
    title: 'Test login on ${config.label}',
    children: [
      for (final DevAccount a in accounts)
        ListTile(
          leading: const Icon(Icons.person_outline_rounded),
          title: Text(a.label),
          subtitle: Text(a.email),
          onTap: () => Navigator.pop(context, a),
        ),
    ],
  ),
);

class _BusyDialog extends StatelessWidget {
  final String text;
  const _BusyDialog(this.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    content: Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
