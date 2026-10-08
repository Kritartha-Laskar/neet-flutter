import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Matches \( ... \), \[ ... \], $$ ... $$, or $ ... $
    final regex = RegExp(
      r'(\\\([\s\S]*?\\\)|\\\[[\s\S]*?\\\]|\$\$[\s\S]*?\$\$|\$[\s\S]*?\$)',
      multiLine: true,
    );

    final matches = regex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    final defaultFontSize = style?.fontSize ?? 14.0;
    final defaultColor = style?.color;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }

      String rawMath = match.group(0)!;
      bool isDisplayMode = false;

      if (rawMath.startsWith(r'\(') && rawMath.endsWith(r'\)')) {
        rawMath = rawMath.substring(2, rawMath.length - 2);
      } else if (rawMath.startsWith(r'\[') && rawMath.endsWith(r'\]')) {
        rawMath = rawMath.substring(2, rawMath.length - 2);
        isDisplayMode = true;
      } else if (rawMath.startsWith(r'$$') && rawMath.endsWith(r'$$')) {
        rawMath = rawMath.substring(2, rawMath.length - 2);
        isDisplayMode = true;
      } else if (rawMath.startsWith(r'$') && rawMath.endsWith(r'$')) {
        rawMath = rawMath.substring(1, rawMath.length - 1);
      }

      final mathCode = rawMath.trim();

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 2.0,
              vertical: isDisplayMode ? 4.0 : 0.0,
            ),
            child: Math.tex(
              mathCode,
              mathStyle: isDisplayMode ? MathStyle.display : MathStyle.text,
              textStyle: TextStyle(
                fontSize: defaultFontSize,
                color: defaultColor,
              ),
              onErrorFallback: (err) => Text(
                match.group(0)!,
                style: style,
              ),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
