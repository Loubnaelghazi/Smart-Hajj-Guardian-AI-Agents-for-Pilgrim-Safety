import 'package:flutter/material.dart';

import 'arabic.dart';

extension LocalizedMessage on String {
  String tr(BuildContext context) =>
      translate(this, Localizations.localeOf(context).languageCode);
}

/// Localizes known UI messages at render time, including const widgets.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;
  final TextDirection? textDirection;
  @override
  Widget build(BuildContext context) => Text(
    data.tr(context),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel?.tr(context),
    textDirection: textDirection,
  );
}
