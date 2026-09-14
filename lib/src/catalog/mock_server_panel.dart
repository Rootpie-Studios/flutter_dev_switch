import 'dart:convert';

import 'package:flutter/material.dart';

import '../dev_tools_strings.dart';
import '../mock/mock_server.dart';
import '../slowdown_picker.dart';

/// The knobs of a [MockServer]: latency, offline, refuse writes. Rebuilds
/// as the server changes; put the app's own switches after it.
class MockServerPanel extends StatelessWidget {
  final MockServer server;
  final List<Duration> latencies;
  final DevToolsStrings strings;

  /// Instant, a realistic round trip, and long enough to watch a spinner.
  static const List<Duration> defaultLatencies = [
    Duration.zero,
    Duration(milliseconds: 300),
    Duration(seconds: 3),
  ];

  const MockServerPanel({
    super.key,
    required this.server,
    this.latencies = defaultLatencies,
    this.strings = const DevToolsStrings(),
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: server,
    builder: (context, _) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(strings.latency)),
              SegmentedButton<Duration>(
                showSelectedIcon: false,
                segments: [
                  for (final Duration d in latencies)
                    ButtonSegment(
                      value: d,
                      label: Text(
                        d == Duration.zero
                            ? strings.instant
                            : formatSlowdown(d, strings),
                      ),
                    ),
                ],
                selected: {server.latency},
                onSelectionChanged: (s) => server.latency = s.first,
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: Text(strings.offline),
          subtitle: Text(strings.offlineHelp),
          value: server.offline,
          onChanged: (v) => server.offline = v,
        ),
        SwitchListTile(
          title: Text(strings.refuseWrites),
          subtitle: Text(strings.refuseWritesHelp),
          value: server.failWrites,
          onChanged: (v) => server.failWrites = v,
        ),
      ],
    ),
  );
}

/// What the app sent to a [MockServer], newest first, with a Clear button.
/// A request with a body unfolds to show it as JSON.
class MockRequestLog extends StatelessWidget {
  final MockServer server;
  final DevToolsStrings strings;

  const MockRequestLog({
    super.key,
    required this.server,
    this.strings = const DevToolsStrings(),
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: server,
    builder: (context, _) {
      final List<MockRequest> requests = server.requests;
      if (requests.isEmpty) {
        return ListTile(subtitle: Text(strings.noRequestsYet));
      }
      return Column(
        children: [
          ListTile(
            dense: true,
            title: Text(strings.requestCount.fill({'n': '${requests.length}'})),
            trailing: TextButton(
              onPressed: server.clearRequests,
              child: Text(strings.clear),
            ),
          ),
          for (final MockRequest r in requests)
            _RequestTile(r, offlineLabel: strings.offlineStatus),
        ],
      );
    },
  );
}

class _RequestTile extends StatelessWidget {
  final MockRequest request;
  final String offlineLabel;

  const _RequestTile(this.request, {required this.offlineLabel});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String time = TimeOfDay.fromDateTime(request.at).format(context);
    final String status = request.status == 0
        ? offlineLabel
        : '${request.status}';
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
