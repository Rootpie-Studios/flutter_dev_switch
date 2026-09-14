import 'package:flutter/material.dart';

import 'api_config.dart';
import 'api_environment.dart';
import 'dev_sheet.dart';
import 'dev_tools_strings.dart';

/// The server switch for testers. Lists the known servers plus a URL of
/// one's own (a developer machine on the LAN, best by its `.local` name),
/// marks the one in use, and remembers the choice across restarts.
///
/// Opened from the [DevMenu], whose Server row shows the pick; [show] for
/// anywhere else.
class ServerPicker extends StatelessWidget {
  final ApiConfig config;
  final DevToolsStrings strings;

  const ServerPicker({
    super.key,
    required this.config,
    this.strings = const DevToolsStrings(),
  });

  static Future<void> show(
    BuildContext context, {
    required ApiConfig config,
    DevToolsStrings strings = const DevToolsStrings(),
  }) => showDevSheet<void>(
    context,
    builder: (_) => ServerPicker(config: config, strings: strings),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: config,
    builder: (context, _) => DevSheetBody(
      title: strings.server,
      children: [
        for (final ApiEnvironment e in config.environments)
          DevChoiceTile(
            selected: e == config.environment,
            title: e.label,
            subtitle: e.baseUrl,
            onTap: () async {
              await config.pick(e);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        _CustomRow(config, strings),
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
              strings.buildPointsAt.fill({'url': config.defineUrl}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    ),
  );
}

/// The "own URL" row: shows the typed URL when one is in use, otherwise a
/// hint. Tapping opens a dialog to type or change it.
class _CustomRow extends StatelessWidget {
  final ApiConfig config;
  final DevToolsStrings strings;
  const _CustomRow(this.config, this.strings);

  Future<void> _edit(BuildContext context) async {
    final String? url = await showDialog<String>(
      context: context,
      builder: (_) => _CustomUrlDialog(
        initial: config.custom ?? config.customExample,
        strings: strings,
        example: config.customExample,
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
  Widget build(BuildContext context) => DevChoiceTile(
    selected: config.custom != null,
    title: strings.customAddress,
    subtitle:
        config.custom ?? '${strings.customAddressHint}${config.customExample}',
    trailing: Icon(
      Icons.edit_outlined,
      color: Theme.of(context).colorScheme.outline,
    ),
    onTap: () => _edit(context),
  );
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
