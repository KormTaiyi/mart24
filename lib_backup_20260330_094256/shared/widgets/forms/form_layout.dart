import 'package:flutter/material.dart';

class AppFormSectionLabel extends StatelessWidget {
  const AppFormSectionLabel({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.only(left: 2, bottom: 8),
    this.style,
  });

  final String text;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style:
            style ??
            const TextStyle(
              color: Color(0xFF69729A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class AppLabeledFormField extends StatelessWidget {
  const AppLabeledFormField({
    super.key,
    required this.label,
    required this.child,
    this.labelStyle,
  });

  final String label;
  final Widget child;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormSectionLabel(text: label, style: labelStyle),
        child,
      ],
    );
  }
}

class AppTwoColumnFormRow extends StatelessWidget {
  const AppTwoColumnFormRow({
    super.key,
    required this.left,
    required this.right,
    this.gap = 12,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final Widget left;
  final Widget right;
  final double gap;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: leftFlex, child: left),
        SizedBox(width: gap),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}
