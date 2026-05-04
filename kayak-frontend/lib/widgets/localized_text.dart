import 'package:flutter/material.dart';

/// Localized text widget
///
/// Automatically applies text direction based on current locale.
/// This is useful for RTL language support in the future.
class LocalizedText extends StatelessWidget {
  const LocalizedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}

/// Localized rich text widget
///
/// A rich text version of LocalizedText for more complex text formatting.
class LocalizedRichText extends StatelessWidget {
  const LocalizedRichText({
    super.key,
    required this.textSpan,
    this.textAlign,
  });
  final InlineSpan textSpan;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: textSpan,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
