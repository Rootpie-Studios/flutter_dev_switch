import 'package:flutter/material.dart';

/// The bottom sheet every part of the menu opens as: drag handle, rounded
/// top, scrollable, at most nine tenths of the screen high (the default
/// cap silently cuts off the rows at the bottom on a phone).
Future<T?> showDevSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
  ),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: builder,
);

/// Close the sheet [context] is in, then run [next] with the root
/// navigator's context: what a row does to open something in the sheet's
/// place instead of on top of it, or to act on the app once the menu has
/// gone.
Future<void> closeThen(
  BuildContext context,
  Future<void> Function(BuildContext root) next,
) {
  final NavigatorState nav = Navigator.of(context);
  final BuildContext root = nav.context;
  nav.pop();
  return next(root);
}

/// The body of a sheet: a title, then [children].
class DevSheetBody extends StatelessWidget {
  final String title;
  final String? help;
  final List<Widget> children;

  const DevSheetBody({
    super.key,
    required this.title,
    this.help,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, help == null ? 8 : 4),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (help case final String h)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(h, style: Theme.of(context).textTheme.bodySmall),
            ),
          ...children,
        ],
      ),
    ),
  );
}

/// One of several choices in a sheet, with a radio mark when [selected].
class DevChoiceTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const DevChoiceTile({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected ? colors.primary : colors.outline,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
