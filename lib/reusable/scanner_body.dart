import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerBody extends StatelessWidget {
  const ScannerBody({
    Key? key,
    required this.onDetect,
    this.childBelow,
  }) : super(key: key);

  final Widget? childBelow;
  final Function(Barcode, MobileScannerArguments?) onDetect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          onDetect: onDetect,
        ),
        ColorFiltered(
          colorFilter:
              ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.srcOut),
          child: Stack(children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xC7000000),
                backgroundBlendMode: BlendMode.dstOut,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(21.5),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: const Padding(
                        padding: EdgeInsets.all(2.5),
                        child: AspectRatio(
                          aspectRatio: 1 / 1,
                          child: Image(
                              image: AssetImage(
                                  'lib/assets/qr_guide_lines_mask.png')),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 1,
                      child: childBelow,
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(21.5),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: const AspectRatio(
                    aspectRatio: 1 / 1,
                    child: Image(
                        image: AssetImage('lib/assets/qr_guide_lines.png')),
                  ),
                ),
                Opacity(
                  opacity: 0,
                  child: childBelow,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(21.5),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    child: Container(),
                  ),
                ),
                Container(child: childBelow),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
