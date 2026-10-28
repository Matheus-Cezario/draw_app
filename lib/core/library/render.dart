import 'package:flutter/services.dart';

import '../scan/scan_service.dart';
import 'drawing.dart';

/// Loads a ready-made drawing so it goes through the very same scan as a
/// photographed picture.
Future<DecodedPicture> loadDrawing(Drawing drawing, {AssetBundle? bundle}) async {
  final data = await (bundle ?? rootBundle).load(drawing.asset);
  return const ScanService().decode(data.buffer.asUint8List());
}
