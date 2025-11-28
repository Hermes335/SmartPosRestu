import 'package:flutter/material.dart';

/// Utilities for rendering currency strings with a reliable peso symbol glyph.
class CurrencyTextHelper {
  static const String _symbol = '₱';
  static const String _symbolFontFamily = 'Roboto';
  static const List<String> _symbolFallback = <String>[
    'Noto Sans',
    'sans-serif',
  ];

  /// Returns true when the value appears to start with the app's peso symbol.
  static bool isCurrencyValue(String value) {
    return value.trim().startsWith(_symbol);
  }

  /// Builds a span that isolates the peso symbol so we can apply fallback fonts.
  static InlineSpan buildCurrencySpan({
    required String formattedValue,
    required TextStyle style,
  }) {
    final trimmed = formattedValue.trim();
    final hasSymbol = trimmed.startsWith(_symbol);
    final numberText = hasSymbol
        ? trimmed.substring(_symbol.length)
        : trimmed;
    final symbolStyle = style.copyWith(
      fontFamily: _symbolFontFamily,
      fontFamilyFallback: _symbolFallback,
    );

    return TextSpan(
      style: style,
      children: [
        if (hasSymbol)
          TextSpan(
            text: _symbol,
            style: symbolStyle,
          ),
        TextSpan(text: numberText),
      ],
    );
  }

  /// Wraps [buildCurrencySpan] in a [Text.rich] for drop-in widget usage.
  static Widget buildCurrencyText({
    required String formattedValue,
    required TextStyle style,
    TextAlign? textAlign,
    int maxLines = 1,
  }) {
    final span = buildCurrencySpan(
      formattedValue: formattedValue,
      style: style,
    );

    return Text.rich(
      span,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}
