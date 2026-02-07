import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scout_report_analysis.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

class AnimatedAutoPath extends StatefulWidget {
  const AnimatedAutoPath({
    super.key,
    required this.analysis,
  });

  final SingleScoutReportAnalysis analysis;

  @override
  State<AnimatedAutoPath> createState() => _AnimatedAutoPathState();
}

class _AnimatedAutoPathState extends State<AnimatedAutoPath>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final AnimationController playPauseController;

  bool playing = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    playPauseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    controller.addListener(() {
      if (controller.value == 1) {
        playPauseController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, widget) {
        return EmphasizedContainer(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 3),
          child: Column(
            children: [
              AutoPathField(paths: [
                AutoPathWidget(
                  animationProgress: controller.value == 0
                      ? null
                      : Duration(
                          milliseconds: (controller.value * 15 * 1000).round(),
                        ),
                  autoPath: analysis.autoPath,
                  teamColor: Colors.blue[600],
                ),
              ]),
              AnimatedAutoPathControls(
                controller: controller,
                playPauseController: playPauseController,
              ),
            ],
          ),
        );
      },
    );
  }
}
