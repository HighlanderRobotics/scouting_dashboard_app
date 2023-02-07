import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';

class AutoPathPainter extends CustomPainter {
  AutoPathPainter(this.positions, this.color);

  List<AutoPathPosition> positions;
  Color color;

  @override
  void paint(Canvas canvas, Size size) {
    print(size);

    Paint paint = Paint();
    paint.strokeWidth = 4;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;
    paint.color = color;

    Path path = Path();
    path.addPolygon(
      positions
          .fold(
            [],
            (previousValue, element) => [
              ...previousValue,
              if (autoPositions.containsKey(element)) element,
            ],
          )
          .map((e) => autoPositions[e]!)
          .map((e) => Offset(e.dx / 306 * size.width, e.dy / 212 * size.height))
          .toList(),
      false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}

class AutoPaths extends StatelessWidget {
  const AutoPaths({super.key, required this.layers});

  final List<AutoPathLayer> layers;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset('assets/images/auto_background.png'),
        Stack(children: layers)
      ],
    );
  }
}

class AutoPathLayer extends StatelessWidget {
  const AutoPathLayer(
      {super.key,
      required this.positions,
      this.color = const Color(0xFFFFFFFF)});

  final List<AutoPathPosition> positions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AutoPathPainter(positions, color),
      child: Opacity(
        opacity: 0,
        child: Image.asset('assets/images/auto_background.png'),
      ),
    );
    ;
  }
}
