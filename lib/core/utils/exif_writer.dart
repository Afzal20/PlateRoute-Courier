import 'dart:typed_data';

/// Minimal pure-Dart JPEG APP1 EXIF writer used to stamp the order id into
/// proof-of-delivery captures (FR-DLV-03: "order id stamped in image
/// metadata"). This injects a standard TIFF UserComment entry (tag 0x9286)
/// right after the SOI marker — no third-party exif dependency needed on the
/// rider's phone, and the bytes survive upload intact for server-side audit.
abstract final class ExifWriter {
  /// Returns a new JPEG byte buffer with the SOI followed by our EXIF APP1
  /// segment plus the original body. If [jpeg] does not start with FFD8 the
  /// original bytes are returned unchanged (defensive).
  static Uint8List stampUserComment(Uint8List jpeg, String comment) {
    if (jpeg.length < 2 || jpeg[0] != 0xFF || jpeg[1] != 0xD8) return jpeg;
    final app1 = _buildApp1(comment);

    final out = Uint8List(app1.length + jpeg.length);
    out.setRange(0, 2, jpeg); // SOI
    out.setRange(2, 2 + app1.length, app1);
    out.setRange(2 + app1.length, out.length, jpeg.sublist(2));
    return out;
  }

  /// FFE1 [len(2)] "Exif\0\0" [tiff]
  static Uint8List _buildApp1(String comment) {
    final tiff = _buildTiff(comment);
    final markerLen = 2 + 6 + tiff.length;
    final buf = Uint8List(markerLen);
    buf[0] = 0xFF;
    buf[1] = 0xE1;

    final lenBe = ByteData(2)..setUint16(0, markerLen);
    buf.setRange(2, 4, lenBe.buffer.asUint8List());

    const header = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]; // "Exif\0\0"
    buf.setRange(4, 10, header);
    buf.setRange(10, 10 + tiff.length, tiff);
    return buf;
  }

  /// Little-endian TIFF: header + IFD0 with a single UserComment entry,
  /// value stored right after the IFD (8-byte ASCII code + comment bytes).
  static Uint8List _buildTiff(String comment) {
    final commentBytes = Uint8List.fromList(comment.codeUnits);
    const charCodeLen = 8;
    final valueCount = charCodeLen + commentBytes.length;

    // Layout offsets:
    //   0..7   TIFF header ('II', 42, offset-to-IFD0 = 8)
    //   8..13  IFD0: entry count = 1 (2 bytes)
    //  10..19  entry: tag(2)=0x9286, type(2)=7, count(4), offset(4)
    //  20..21  next IFD offset = 0
    //  22..    value area (8-byte char code + comment)
    final total = 22 + valueCount;
    final buf = Uint8List(total);
    final view = ByteData.view(buf.buffer);

    buf[0] = 0x49; // 'I'
    buf[1] = 0x49; // 'I' little-endian
    view.setUint16(2, 42, Endian.little);
    view.setUint32(4, 8, Endian.little); // IFD0 offset

    view.setUint16(8, 1, Endian.little); // 1 directory entry

    view.setUint16(10, 0x9286, Endian.little); // UserComment
    view.setUint16(12, 7, Endian.little); // UNDEFINED
    view.setUint32(14, valueCount, Endian.little);
    view.setUint32(18, 22, Endian.little); // value offset
    view.setUint32(20, 0, Endian.little); // no next IFD

    // ASCII character code (8 bytes: 'ASCII\0\0\0') + comment bytes
    const code = <int>[0x41, 0x53, 0x43, 0x49, 0x49, 0x00, 0x00, 0x00];
    buf.setRange(22, 30, code);
    buf.setRange(30, 30 + commentBytes.length, commentBytes);
    return buf;
  }
}