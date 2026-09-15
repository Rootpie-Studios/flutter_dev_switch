import 'package:flutter/material.dart';

import 'dev_faults.dart';

/// The three knobs of a [DevFaults]: the delay and the refusal as rows of
/// choices, "Offline" as a switch. The refusal row says what the picked
/// status hits: writes for a 403 or a 500, every request for a 401. Rebuilds as they
/// change.
/// The developer menu shows one for the live API; a dev catalog shows one
/// for its mock server.
class DevFaultsPanel extends StatelessWidget {
  final DevFaults faults;
  final List<Duration> delays;

  const DevFaultsPanel({
    super.key,
    required this.faults,
    this.delays = DevFaults.delays,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: faults,
    builder: (context, _) => Column(
      children: [
        // The choices go under the label, stretched to the row's width,
        // so four of them fit a phone next to the icon.
        ListTile(
          leading: const Icon(Icons.hourglass_bottom_rounded),
          title: const Text('Delay'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<Duration>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final Duration d in _choices(faults.delay))
                  ButtonSegment(value: d, label: Text(formatDelay(d))),
              ],
              selected: {faults.delay},
              onSelectionChanged: (Set<Duration> s) =>
                  faults.pickDelay(s.first),
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_off_outlined),
          title: const Text('Offline'),
          subtitle: const Text('Every request fails to connect'),
          value: faults.offline,
          onChanged: (bool v) => faults.offline = v,
        ),
        ListTile(
          leading: const Icon(Icons.block_outlined),
          title: const Text('Refuse requests'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(switch (faults.refuseWith) {
                null => 'Writes get a 403 or a 500; every request gets a 401',
                DevFaults.sessionOver =>
                  'Every request gets a 401: the session is over',
                final int s => 'Writes get a $s; reads still work',
              }),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<int?>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    const ButtonSegment<int?>(value: null, label: Text('Off')),
                    for (final int status in DevFaults.refusals)
                      ButtonSegment<int?>(
                        value: status,
                        label: Text('$status'),
                      ),
                  ],
                  selected: {faults.refuseWith},
                  onSelectionChanged: (Set<int?> s) =>
                      faults.refuseWith = s.first,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// [delays], plus the current one when it is not among them, so what is
  /// in use can always be seen and switched off.
  List<Duration> _choices(Duration current) =>
      delays.contains(current) ? delays : ([...delays, current]..sort());
}
