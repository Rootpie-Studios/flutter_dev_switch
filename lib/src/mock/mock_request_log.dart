import 'dart:convert';

import 'package:flutter/material.dart';

import 'mock_server.dart';

/// What the app sent to a [MockServer], newest first, with a Clear button.
/// A request with a body unfolds to show it as JSON.
class MockRequestLog extends StatelessWidget {
  final MockServer server;

  const MockRequestLog({super.key, required this.server});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: server,
    builder: (context, _) {
      final List<MockRequest> requests = server.requests;
      if (requests.isEmpty) {
        return const ListTile(
          subtitle: Text('Nothing yet. Open a screen and save something.'),
        );
      }
      return Column(
        children: [
          ListTile(
            dense: true,
            title: Text('${requests.length} requests'),
            trailing: TextButton(
              onPressed: server.clearRequests,
              child: const Text('Clear'),
            ),
          ),
          for (final MockRequest r in requests) _RequestTile(r),
        ],
      );
    },
  );
}

class _RequestTile extends StatelessWidget {
  final MockRequest request;

  const _RequestTile(this.request);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String time = TimeOfDay.fromDateTime(request.at).format(context);
    final String status = request.status == 0 ? 'offline' : '${request.status}';
    final Widget leading = Chip(
      label: Text(request.method),
      labelStyle: TextStyle(
        fontSize: 11,
        color: request.failed
            ? colors.onError
            : request.isWrite
            ? colors.onPrimary
            : colors.onSurfaceVariant,
      ),
      backgroundColor: request.failed
          ? colors.error
          : request.isWrite
          ? colors.primary
          : colors.surfaceContainerHighest,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
    if (request.body == null) {
      return ListTile(
        dense: true,
        leading: leading,
        title: Text(request.path),
        subtitle: Text('$time · $status'),
      );
    }
    return ExpansionTile(
      dense: true,
      leading: leading,
      title: Text(request.path),
      subtitle: Text('$time · $status'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(request.body),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
