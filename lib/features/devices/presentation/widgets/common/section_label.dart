import 'package:flutter/widgets.dart';
import 'package:obers_ui/obers_ui.dart';

/// Small heading above a group of cards, uppercased as in the mockups.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: OiLabel.overline(
      text.toUpperCase(),
      semanticsLabel: text,
      color: context.colors.textSubtle,
    ),
  );
}
