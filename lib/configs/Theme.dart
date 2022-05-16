import 'package:flutter/material.dart';

enum Themes {
  Base,
}

ThemeData getThemeByType(Themes type) {
  switch (type) {
    case Themes.Base:
      return ThemeData(
        brightness: Brightness.light,
      );
  }
}