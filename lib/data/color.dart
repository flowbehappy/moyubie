import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';

Color getColor(int seed) {
  return _colors[seed % _colors.length];
}

const List<Color> _colors = [
  Color(0xffc22c1e),
  Color(0xffd2372b),
  Color(0xffdf3d32),
  Color(0xfff14738),
  Color(0xfffe5037),
  Color(0xffef7b77),
  Color(0xffdd4d11),
  Color(0xffe76714),
  Color(0xffed7616),
  Color(0xfff38618),
  Color(0xff920059),
  Color(0xffb90060),
  Color(0xffce0063),
];

const FlexSchemeData moyubieSchemeData = FlexSchemeData(
  name: "moyubie",
  description: "",
  light: FlexSchemeColor(
    primary: Color.fromARGB(255, 42, 42, 42),
    primaryContainer: Color(0xFF9BA7CF),
    secondary: Color(0xFF006B54),
    secondaryContainer: Color(0xFF8FC3AD),
    tertiary: Color(0xFF004B3B),
    tertiaryContainer: Color(0xFF82BCB5),
    appBarColor: Color(0xFF004B3B),
    error: Color(0xFFB00020),
    swapOnMaterial3: true,
  ),
  dark: FlexSchemeColor(
    // primary: Color(0xFF4E597D),
    primary: Color.fromARGB(255, 42, 42, 42),
    primaryContainer: Color(0xFF202541),
    secondary: Color(0xFF4BA390),
    secondaryContainer: Color(0xFF0B5341),
    tertiary: Color(0xFF3D8475),
    tertiaryContainer: Color(0xFF063F36),
    appBarColor: Color(0xFF3D8475),
    error: Color(0xFFCF6679),
    swapOnMaterial3: true,
  ),
);
