import 'package:flutter/material.dart';

import 'api_config.dart';
import 'api_environment.dart';
import 'dev_tools_strings.dart';
import 'slowdown_picker.dart';

/// The hidden server switch for testers. Lists the known servers plus a URL
/// of one's own (a developer machine on the LAN, best by its `.local`
/// name), marks the one in use, and remembers the choice across restarts.
///
/// Open it with [show]; nothing on screen should hint that it exists. The
/// [DevMenu]'s Server row shows the pick.
class ServerPicker extends StatelessWidget {
  final ApiConfig config;
  final DevToolsStrings strings;

  /// Prefilled into the custom-URL dialog, so the common case (the
  /// developer's own machine) is one tap away.
  final String customExample;

  const ServerPicker({
    super.key,
    required this.config,
    this.strings = const DevToolsStrings(),
    this.customExample = 'http://my-macbook.local/api',
  });

  static Future<void> show(
    BuildContext context, {
    required ApiConfig config,
    DevToolsStrings strings = const DevToolsStrings(),
    String customExample = 'http://my-macbook.local/api',
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Without this the sheet is capped at nine sixteenths of the screen,
    // which on a phone silently cuts off the rows at the bottom.
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ServerPicker(
      config: config,
      strings: strings,
      customExample: customExample,
    ),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  strings.server,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final ApiEnvironment e in config.environments)
                ListTile(
                  leading: Icon(
                    e == config.environment
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: e == config.environment
                        ? colors.primary
                        : colors.outline,
                  ),
                  title: Text(e.label),
                  subtitle: Text(e.baseUrl),
                  onTap: () async {
                    await config.pick(e);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              _CustomRow(config, strings, customExample),
              if (config.hasPick)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TextButton(
                    onPressed: () async {
                      await config.pick(null);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(strings.resetToDefault),
                  ),
                ),
              if (config.defineUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    strings.buildPointsAt.replaceFirst(
                      '{url}',
                      config.defineUrl,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "own URL" row: shows the typed URL when one is in use, otherwise a
/// hint. Tapping opens a dialog to type or change it.
class _CustomRow extends StatelessWidget {
  final ApiConfig config;
  final DevToolsStrings strings;
  final String example;
  const _CustomRow(this.config, this.strings, this.example);

  Future<void> _edit(BuildContext context) async {
    final String? url = await showDialog<String>(
      context: context,
      builder: (_) => _CustomUrlDialog(
        initial: config.custom ?? example,
        strings: strings,
        example: example,
      ),
    );
    if (url == null || !context.mounted) return;
    if (await config.pickCustom(url)) {
      if (context.mounted) Navigator.of(context).pop();
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.invalidAddress)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool active = config.custom != null;
    return ListTile(
      leading: Icon(
        active
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: active ? colors.primary : colors.outline,
      ),
      title: Text(strings.customAddress),
      subtitle: Text(config.custom ?? '${strings.customAddressHint}$example'),
      trailing: Icon(Icons.edit_outlined, color: colors.outline),
      onTap: () => _edit(context),
    );
  }
}

class _CustomUrlDialog extends StatefulWidget {
  final String? initial;
  final DevToolsStrings strings;
  final String example;
  const _CustomUrlDialog({
    this.initial,
    required this.strings,
    required this.example,
  });

  @override
  State<_CustomUrlDialog> createState() => _CustomUrlDialogState();
}

class _CustomUrlDialogState extends State<_CustomUrlDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_text.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.strings.customAddressTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(hintText: widget.example),
        ),
        const SizedBox(height: 10),
        Text(
          widget.strings.customAddressHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(widget.strings.cancel),
      ),
      TextButton(onPressed: _submit, child: Text(widget.strings.use)),
    ],
  );
}
