import 'package:flutter/material.dart';

/// Flat UI Colors "Chinese Palette" by Wenjun (https://flatuicolors.com/palette/cn).
abstract final class ChinesePalette {
  static const Color goldenSand = Color(0xFFECCC68);
  static const Color coral = Color(0xFFFF7F50);
  static const Color wildWatermelon = Color(0xFFFF6B81);
  static const Color peace = Color(0xFFA4B0BE);
  static const Color grisaille = Color(0xFF57606F);
  static const Color orange = Color(0xFFFFA502);
  static const Color bruschettaTomato = Color(0xFFFF6348);
  static const Color watermelon = Color(0xFFFF4757);
  static const Color bayWharf = Color(0xFF747D8C);
  static const Color prestigeBlue = Color(0xFF2F3542);
  static const Color limeSoap = Color(0xFF7BED9F);
  static const Color frenchSkyBlue = Color(0xFF70A1FF);
  static const Color saturatedSky = Color(0xFF5352ED);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cityLights = Color(0xFFDFE4EA);
  static const Color ufoGreen = Color(0xFF2ED573);
  static const Color clearChill = Color(0xFF1E90FF);
  static const Color brightGreek = Color(0xFF3742FA);
  static const Color antiFlashWhite = Color(0xFFF1F2F6);
  static const Color twinkleBlue = Color(0xFFCED6E0);
}

/// Every colour of the app's interface in one place. Change a value here and
/// it changes everywhere. (Colours inside the little hand-drawn illustrations,
/// such as the animal magnets and the start scene, stay next to their code.)
abstract final class AppColors {
  // Core look
  static const Color ink = ChinesePalette.prestigeBlue; // outlines and text
  static const Color board = ChinesePalette.frenchSkyBlue; // gallery / screen background
  static const Color cream = ChinesePalette.antiFlashWhite; // panels and highlights
  static const Color paper = ChinesePalette.white; // sheet of paper
  static const Color panel = ChinesePalette.cityLights; // editor tool panel
  static const Color seed = Colors.deepPurple; // Material theme seed

  // Illustrations (start scene, tool icons, new-drawing tiles)
  static const Color artYellow = ChinesePalette.goldenSand;
  static const Color artBlue = ChinesePalette.clearChill;

  // Buttons and bars
  static const Color appBar = ChinesePalette.goldenSand;
  static const Color back = ChinesePalette.clearChill;
  static const Color danger = ChinesePalette.watermelon; // delete, spinner
  static const Color go = ChinesePalette.ufoGreen; // "Let's go!"
  static const Color confirm = ChinesePalette.ufoGreen;
  static const Color accent = ChinesePalette.bruschettaTomato;
  static const Color accentPurple = ChinesePalette.saturatedSky;
  static const Color disabled = ChinesePalette.twinkleBlue;
  static const Color disabledText = ChinesePalette.bayWharf;

  // Scan screen option stickers
  static const Color chipLines = ChinesePalette.wildWatermelon;
  static const Color chipGaps = ChinesePalette.frenchSkyBlue;
  static const Color chipTurn = ChinesePalette.peace;
  static const Color chipCut = ChinesePalette.limeSoap;
  static const Color chipColours = ChinesePalette.orange;

  // Shadows and overlays
  static const Color shadow = Color(0x40000000);
  static const Color shadowStrong = Color(0x55000000);
  static const Color scrim = Color(0x66000000);
  static const Color cropShade = Color(0x99000000);
  static const Color hairline = Color(0x1F000000);
  static const Color hairlineSoft = Color(0x22000000);

  // Editor canvas
  static const Color canvasBackdrop = ChinesePalette.frenchSkyBlue;

  // New drawing sheet tiles
  static const Color tileBlank = ChinesePalette.goldenSand;
  static const Color tilePicture = ChinesePalette.frenchSkyBlue;
  static const Color tileCamera = ChinesePalette.wildWatermelon;
  static const Color tileBook = ChinesePalette.limeSoap;

  // Colouring book categories
  static const Color categoryAnimals = ChinesePalette.orange;
  static const Color categoryDinosaurs = ChinesePalette.ufoGreen;
  static const Color categoryOcean = ChinesePalette.clearChill;
  static const Color categoryForest = ChinesePalette.limeSoap;
  static const Color categoryCars = ChinesePalette.watermelon;
  static const Color categoryTrains = ChinesePalette.saturatedSky;
  static const Color categoryCity = ChinesePalette.peace;
  static const Color categorySpace = ChinesePalette.brightGreek;
  static const Color categoryPrincesses = ChinesePalette.wildWatermelon;
  static const Color categoryToys = ChinesePalette.goldenSand;
  static const Color categoryPlush = ChinesePalette.coral;
  static const Color categoryFood = ChinesePalette.bruschettaTomato;

  // Tool tiles in the editor
  static const Color toolBrush = ChinesePalette.orange;
  static const Color toolFill = ChinesePalette.frenchSkyBlue;
  static const Color toolPencil = ChinesePalette.goldenSand;
  static const Color toolEraser = ChinesePalette.wildWatermelon;
  static const Color toolEyedropper = ChinesePalette.watermelon;
  static const Color toolLine = ChinesePalette.brightGreek;
  static const Color toolRectangle = ChinesePalette.limeSoap;
  static const Color toolEllipse = ChinesePalette.coral;
  static const Color toolText = ChinesePalette.peace;
  static const Color toolSelection = ChinesePalette.clearChill;

  // Letters of the title on the start screen
  static const List<Color> titleLetters = [
    ChinesePalette.watermelon,
    ChinesePalette.orange,
    ChinesePalette.ufoGreen,
    ChinesePalette.clearChill,
    ChinesePalette.saturatedSky,
    ChinesePalette.watermelon,
    ChinesePalette.orange,
  ];

  /// Fixed painting palette: kids pick from big colours instead of sliders.
  /// Ordered in pairs (light on top, strong below) so a two-row bar groups
  /// similar hues.
  static const List<Color> swatches = [
    Color(0xFFFFFFFF), Color(0xFF000000), // white, black
    Color(0xFFE0E0E0), Color(0xFF757575), // greys
    Color(0xFFFFCDD2), Color(0xFFE53935), // red
    Color(0xFFF48FB1), Color(0xFFD81B60), // pink
    Color(0xFFFFCCBC), Color(0xFFFF7043), // coral
    Color(0xFFFFE0B2), Color(0xFFFB8C00), // orange
    Color(0xFFFFF59D), Color(0xFFFDD835), // yellow
    Color(0xFFDCEDC8), Color(0xFF9CCC65), // light green
    Color(0xFF81C784), Color(0xFF2E7D32), // green
    Color(0xFFB2EBF2), Color(0xFF00ACC1), // turquoise
    Color(0xFF90CAF9), Color(0xFF1E88E5), // blue
    Color(0xFF9FA8DA), Color(0xFF283593), // dark blue
    Color(0xFFE1BEE7), Color(0xFF8E24AA), // purple
    Color(0xFFD7CCC8), Color(0xFF6D4C41), // brown
    Color(0xFFFFD6B0), Color(0xFFD7A86E), // skin / sand
  ];
}
