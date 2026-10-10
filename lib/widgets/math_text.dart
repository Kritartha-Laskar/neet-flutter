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

    // Normalize potential double backslash escaping from JSON or DB
    final normalizedText = text
        .replaceAll(r'\\(', r'\(')
        .replaceAll(r'\\)', r'\)')
        .replaceAll(r'\\\[', r'\[')
        .replaceAll(r'\\\]', r'\]');

    // Matches \( ... \), \[ ... \], $$ ... $$, or $ ... $
    final regex = RegExp(
      r'(\\\([\s\S]*?\\\)|\\\[[\s\S]*?\\\]|\$\$[\s\S]*?\$\$|\$[\s\S]*?\$)',
      multiLine: true,
    );

    final matches = regex.allMatches(normalizedText).toList();
    final defaultFontSize = style?.fontSize ?? 14.0;
    final defaultColor = style?.color;

    if (matches.isEmpty) {
      // Check if text is raw LaTeX without delimiters (e.g. \frac{a}{b}, \sqrt{x})
      final hasRawLatex = RegExp(
        r'\\(frac|sqrt|cdot|times|pm|mp|le|ge|neq|approx|alpha|beta|gamma|delta|pi|theta|lambda|sigma|omega|sum|int|infty|degree|text|mathbf|mathrm|partial)\b',
      ).hasMatch(normalizedText);

      if (hasRawLatex) {
        return Math.tex(
          normalizedText.trim(),
          mathStyle: MathStyle.text,
          textStyle: TextStyle(
            fontSize: defaultFontSize,
            color: defaultColor,
          ),
          onErrorFallback: (_) => Text(
            text,
            style: style,
            textAlign: textAlign,
            overflow: overflow,
            maxLines: maxLines,
          ),
        );
      }

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

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: normalizedText.substring(lastEnd, match.start),
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

    if (lastEnd < normalizedText.length) {
      spans.add(TextSpan(
        text: normalizedText.substring(lastEnd),
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
