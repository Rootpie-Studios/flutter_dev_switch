import 'package:flutter/material.dart';

import 'api_config.dart';
import 'dev_menu.dart';
import 'dev_tools.dart';
import 'dev_tools_strings.dart';

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

/// Performs the app's own login for [account]. Return true on success; the
/// app is expected to have stored the session itself. On false the button
/// shows [DevToolsStrings.devLoginFailed].
typedef DevLoginHandler =
    Future<bool> Function(BuildContext context, DevAccount account);

/// Lets the tester pick one of [accounts] from a bottom sheet. Null when
/// dismissed.
Future<DevAccount?> showDevAccountPicker(
  BuildContext context, {
  required ApiConfig config,
  required List<DevAccount> accounts,
  DevToolsStrings strings = const DevToolsStrings(),
}) => showModalBottomSheet<DevAccount>(
  context: context,
  showDragHandle: true,
  builder: (BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            strings.devLoginTitle.replaceFirst('{server}', config.label),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        for (final DevAccount a in accounts)
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(a.label),
            subtitle: Text(a.email),
            onTap: () => Navigator.pop(context, a),
          ),
        const SizedBox(height: 8),
      ],
    ),
  ),
);

/// Pick an account and log in with it, reporting failure in a snackbar.
/// Shared by [DevLoginButton] and [devLoginEntry].
Future<void> runDevLogin(
  BuildContext context, {
  required ApiConfig config,
  required List<DevAccount> accounts,
  required DevLoginHandler login,
  DevToolsStrings strings = const DevToolsStrings(),
}) async {
  final DevAccount? account = await showDevAccountPicker(
    context,
    config: config,
    accounts: accounts,
    strings: strings,
  );
  if (account == null || !context.mounted) return;
  final bool ok = await login(context, account);
  if (ok || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        strings.devLoginFailed
            .replaceFirst('{email}', account.email)
            .replaceFirst('{server}', config.label),
      ),
    ),
  );
}

/// A [DevMenuEntry] for the developer menu that does the same as
/// [DevLoginButton]. Unlike the button it is offered on every server, so
/// only list accounts that exist where the entry can be used.
DevMenuEntry devLoginEntry({
  required ApiConfig config,
  required List<DevAccount> accounts,
  required DevLoginHandler login,
  DevToolsStrings strings = const DevToolsStrings(),
}) => DevMenuEntry(
  label: strings.devLogin,
  icon: Icons.science_outlined,
  onTap: (BuildContext context) => runDevLogin(
    context,
    config: config,
    accounts: accounts,
    login: login,
    strings: strings,
  ),
);

/// Developer builds only, and only while a server other than production is
/// picked: a button to get in as one of [accounts] without typing. Seed
/// credentials exist on local, dev and staging servers and open nothing on
/// production, which is the one server the button hides on.
class DevLoginButton extends StatefulWidget {
  final ApiConfig config;
  final List<DevAccount> accounts;
  final DevLoginHandler login;
  final DevToolsStrings strings;
  final EdgeInsetsGeometry padding;

  const DevLoginButton({
    super.key,
    required this.config,
    required this.accounts,
    required this.login,
    this.strings = const DevToolsStrings(),
    this.padding = const EdgeInsets.only(top: 16),
  });

  @override
  State<DevLoginButton> createState() => _DevLoginButtonState();
}

class _DevLoginButtonState extends State<DevLoginButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await runDevLogin(
        context,
        config: widget.config,
        accounts: widget.accounts,
        login: widget.login,
        strings: widget.strings,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DevTools.enabled) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: widget.config,
      builder: (BuildContext context, _) {
        if (!widget.config.isNonProduction) return const SizedBox.shrink();
        return Padding(
          padding: widget.padding,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _run,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            icon: const Icon(Icons.science_outlined, size: 18),
            label: Text(
              _busy ? widget.strings.devLoggingIn : widget.strings.devLogin,
            ),
          ),
        );
      },
    );
  }
}
