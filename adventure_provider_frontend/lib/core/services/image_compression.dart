import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Runs inside a [compute] isolate — keep only pure Dart + [image] here.
Uint8List compressRawJpegUnder1Mb(Uint8List raw) {
  const maxBytes = 1024 * 1024;

  final decoded = img.decodeImage(raw);
  if (decoded == null) {
    throw StateError('decode_failed');
  }

  var work = decoded;
  var quality = 88;

  List<int> encode() =>
      img.encodeJpg(work, quality: quality.clamp(5, 100));

  void shrink() {
    final w = work.width;
    final h = work.height;
    if (w <= 320 && h <= 320) return;
    final nw = (w * 0.82).round().clamp(1, w);
    final nh = (h * 0.82).round().clamp(1, h);
    work = img.copyResize(work, width: nw, height: nh);
  }

  var out = encode();
  for (var pass = 0; pass < 48 && out.length > maxBytes; pass++) {
    if (quality > 24) {
      quality -= 6;
      out = encode();
      continue;
    }
    final w0 = work.width;
    final h0 = work.height;
    shrink();
    if (work.width == w0 && work.height == h0) {
      quality -= 4;
      if (quality < 8) {
        throw StateError('too_large');
      }
      out = encode();
      continue;
    }
    quality = 82;
    out = encode();
  }

  if (out.length > maxBytes) {
    throw StateError('too_large');
  }
  return Uint8List.fromList(out);
}
