import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc_zxing/flutter_webrtc_zxing.dart' as zxing;
import 'package:image/image.dart' as image;
import 'package:ndk_demo/linux_qr_scanner.dart';

// Run on Linux after flutter build linux --debug with bundle/lib on
// LD_LIBRARY_PATH so the real native ZXing decoder is available.
const offer =
    'lno1pgqppmsrse80qf0aara4slvcjxrvu6j2rp5ftmjy4yntlsmsutpkvkt6878sx37ttar5fpecarm57v2y2can2uxq02l7k0er7czs6gsuzkdhe4tlqgpat4k4mrvvjwla3whdhmkvdtfq98w4jlg8wgsf26cndmndd0c33fqqx0y9hunesw4caaxfnw3uam5yy4kxtuqvujapdx93sd24wt7mdpeukuw46tp5zugxceqrr2ffkzpjcen3p77sy8jk8v7h04wlp9lg6ls76xqcn3nethq7e7553xn3vugt5vzlea2sqqedvc6k8r8hetzw9tvnlnw9muh4vaywdn5jgvj80ad3r9600ang39vvjnvn0aytg07ss05v6g9ru45p2srs';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<image.Image> makeFrame({int left = 795, bool inverted = false}) async {
    const size = 330;
    final encoded = await zxing.zx.encodeBarcode(
      contents: offer,
      params: zxing.EncodeParams(width: size, height: size, margin: 4),
    );
    expect(encoded.isValid, isTrue);
    expect(encoded.data!.length, size * size);
    final qr = image.Image.fromBytes(
      width: size,
      height: size,
      bytes: encoded.data!.buffer,
      numChannels: 1,
    );
    final frame = image.Image(width: 1920, height: 1080);
    image.fill(frame, color: image.ColorRgb8(255, 255, 255));
    image.compositeImage(frame, qr, dstX: left, dstY: 375);
    return inverted ? image.invert(frame) : frame;
  }

  test('decodes dense offer at original resolution in background isolate',
      () async {
    final frame = await makeFrame();
    expect(await compute(decodeLinuxQrFrame, image.encodePng(frame)), offer);

    // Reproduce the old ReaderWidget's destructive 768px resize.
    final reduced = zxing.resizeToMaxSize(frame, 768);
    final oldResult = zxing.zx.readBarcode(
      zxing.rgbBytes(reduced),
      zxing.DecodeParams(
        width: reduced.width,
        height: reduced.height,
        imageFormat: zxing.ImageFormat.rgb,
        format: zxing.Format.qrCode,
      ),
    );
    expect(oldResult.isValid, isFalse);
  });

  test('decodes offer outside the old central crop', () async {
    final frame = await makeFrame(left: 100);
    expect(decodeLinuxQrFrame(image.encodePng(frame)), offer);
  });

  test('decodes inverted dense offer', () async {
    final frame = await makeFrame(inverted: true);
    expect(decodeLinuxQrFrame(image.encodePng(frame)), offer);
  });

  test('blank frame returns no result', () {
    final frame = image.Image(width: 320, height: 240);
    image.fill(frame, color: image.ColorRgb8(255, 255, 255));
    expect(decodeLinuxQrFrame(image.encodePng(frame)), isNull);
  });
}
