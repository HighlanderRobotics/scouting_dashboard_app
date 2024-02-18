import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerBody extends StatefulWidget {
  const ScannerBody({
    Key? key,
    required this.onDetect,
    this.childBelow,
  }) : super(key: key);

  final Widget? childBelow;
  final Function(BarcodeCapture) onDetect;

  @override
  State<ScannerBody> createState() => _ScannerBodyState();
}

class _ScannerBodyState extends State<ScannerBody> {
  final scannerController = MobileScannerController(
    formats: [
      BarcodeFormat.qrCode,
    ],
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: widget.onDetect,
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.8), BlendMode.srcOut),
            child: Stack(children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xC7000000),
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(21.5).copyWith(top: 64),
                child: Center(
                  child: RowOrColumn(
                    isRow: false,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: const Padding(
                          padding: EdgeInsets.all(2.5),
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: Image(
                              image: AssetImage(
                                  'assets/images/qr_guide_lines_mask.png'),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 1,
                        child: widget.childBelow,
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(21.5).copyWith(top: 64),
            child: Center(
              child: RowOrColumn(
                isRow: false,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: const AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Image(
                          image:
                              AssetImage('assets/images/qr_guide_lines.png')),
                    ),
                  ),
                  Opacity(
                    opacity: 0,
                    child: widget.childBelow,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(21.5).copyWith(top: 64),
            child: Center(
              child: RowOrColumn(
                isRow: false,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Container(),
                    ),
                  ),
                  Container(child: widget.childBelow),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class RowOrColumn extends StatelessWidget {
  const RowOrColumn({
    super.key,
    required this.isRow,
    required this.children,
  });

  final bool isRow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return isRow
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          );
  }
}
