import 'package:flutter/material.dart';

/// A section title in a dev catalog: small caps in the primary colour,
/// with room above it.
class DevSectionHeader extends StatelessWidget {
  final String title;

  const DevSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

/// One screen or flow to open from a dev catalog. Greyed out when [onTap]
/// is null, so a row can say why it is not available in its [subtitle].
class DevScenarioTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const DevScenarioTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    enabled: onTap != null,
    onTap: onTap,
  );
}
