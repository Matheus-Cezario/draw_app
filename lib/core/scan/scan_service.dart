import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'scan_pipeline.dart';

/// Longest side (px) an imported picture is scaled down to. See decision D10.
const int kMaxScanSide = 1600;

/// A decoded, downscaled picture ready to be scanned (cheap to re-scan).
class DecodedPicture {
  DecodedPicture(this.rgba, this.width, this.height);
  final Uint8List rgba;
  final int width;
  final int height;
}

class _ScanRequest {
  _ScanRequest(this.picture, this.params);
  final DecodedPicture picture;
  final ScanParams params;
}

/// Decodes pictures and runs the scan off the UI isolate.
class ScanService {
  const ScanService();

  Future<DecodedPicture> decode(Uint8List encoded) =>
      compute(_decode, encoded);

  Future<ScanResult> scan(DecodedPicture picture, ScanParams params) =>
      compute(_scan, _ScanRequest(picture, params));
}

DecodedPicture _decode(Uint8List encoded) {
  var image = img.decodeImage(encoded);
  if (image == null) throw const FormatException('Unsupported image file');
  image = img.bakeOrientation(image);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > kMaxScanSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: kMaxScanSide)
        : img.copyResize(image, height: kMaxScanSide);
  }
  image = image.convert(numChannels: 4);
  return DecodedPicture(
    image.getBytes(order: img.ChannelOrder.rgba),
    image.width,
    image.height,
  );
}

ScanResult _scan(_ScanRequest request) => scanLineArt(
      request.picture.rgba,
      request.picture.width,
      request.picture.height,
      request.params,
    );
