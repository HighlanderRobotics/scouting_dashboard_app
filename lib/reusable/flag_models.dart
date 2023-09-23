import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/flags.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';
import 'package:http/http.dart' as http;

class FlagType {
  const FlagType(
    this.path, {
    required this.readableName,
    required this.description,
    required this.defaultHue,
    required this.visualizationBuilder,
    this.disableHue = false,
  });

  final String path;
  final String readableName;
  final String description;

  final double defaultHue;
  final bool disableHue;

  final Widget Function(
    BuildContext context,
    dynamic data,
    Color foregroundColor,
    Color backgroundColor,
  ) visualizationBuilder;

  factory FlagType.byPath(String path) => flags.singleWhere(
        (f) => f.path == path,
        orElse: () => unknown,
      );

  factory FlagType.categoryMetric(CategoryMetric metric) {
    final category =
        metricCategories.firstWhere((e) => e.metrics.contains(metric));

    return FlagType(
      metric.path,
      readableName: metric.localizedName,
      description:
          '${metric.localizedName} metric from ${category.localizedName}',
      defaultHue: 1,
      visualizationBuilder: (context, data, foregroundColor, backgroundColor) =>
          FlagTemplate(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        child: Text(
          metric.valueVizualizationBuilder(data),
        ),
      ),
    );
  }

  static FlagType unknown = FlagType(
    'unknown',
    readableName: 'Unknown',
    description: 'An unknown team tag',
    defaultHue: 1,
    visualizationBuilder: (context, data, foregroundColor, backgroundColor) =>
        FlagTemplate(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      icon: Icons.error,
    ),
  );
}

class FlagConfiguration {
  FlagConfiguration(this.type, this.hue);

  final FlagType type;
  double hue;

  Widget getWidget(BuildContext context, dynamic data) {
    return type.visualizationBuilder(
      context,
      data,
      HSLColor.fromAHSL(1, hue, 1, 0.15).toColor(),
      HSLColor.fromAHSL(1, hue, 0.6, 0.7).toColor(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.path,
        'hue': hue,
      };

  factory FlagConfiguration.fromJson(Map<String, dynamic> json) =>
      FlagConfiguration(
        FlagType.byPath(json['type']),
        json['hue'],
      );

  factory FlagConfiguration.start(FlagType type) =>
      FlagConfiguration(type, type.defaultHue);
}

Future<List<FlagConfiguration>> getPicklistFlags() async {
  final prefs = await SharedPreferences.getInstance();
  final stringList = prefs.getStringList('picklist_flags');
  return stringList!
      .map((e) => FlagConfiguration.fromJson(jsonDecode(e)))
      .toList();
}

class Flag extends StatelessWidget {
  const Flag({
    super.key,
    required this.isLoaded,
    required this.configuration,
    this.data,
  });

  final bool isLoaded;
  final FlagConfiguration configuration;
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      return configuration.getWidget(context, data);
    } else {
      return const SkeletonFlag();
    }
  }
}

class SkeletonFlag extends StatelessWidget {
  const SkeletonFlag({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonAvatar(
      style: SkeletonAvatarStyle(
        borderRadius: BorderRadius.circular(7),
        height: 40,
        width: 40,
      ),
    );
  }
}

class FlagFrame extends StatelessWidget {
  const FlagFrame({
    super.key,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.child,
  });

  final Color foregroundColor;
  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: foregroundColor,
            ),
        child: child,
      ),
    );
  }
}

class FlagTemplate extends StatelessWidget {
  const FlagTemplate({
    super.key,
    required this.foregroundColor,
    required this.backgroundColor,
    this.icon,
    this.child,
  });

  final Color foregroundColor;
  final Color backgroundColor;

  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return FlagFrame(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                color: foregroundColor,
                size: 24,
              )
            : child,
      ),
    );
  }
}

class NetworkFlag extends StatefulWidget {
  const NetworkFlag({
    super.key,
    required this.team,
    required this.flag,
  });

  final int team;
  final FlagConfiguration flag;

  @override
  State<NetworkFlag> createState() => _NetworkFlagState();
}

class _NetworkFlagState extends State<NetworkFlag> {
  dynamic data;
  bool loaded = false;
  int? loadingTeam;

  Future<void> load() async {
    setState(() {
      loaded = false;
      loadingTeam = widget.team;
    });

    final prefs = await SharedPreferences.getInstance();
    final authority = (await getServerAuthority())!;
    final response = await http.get(Uri.http(authority, '/API/analysis/flag', {
      'types': jsonEncode([widget.flag.type.path]),
      'team': widget.team.toString(),
      'tournamentKey': prefs.getString('tournament'),
    }));

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error fetching ${widget.flag.type.readableName}: ${response.statusCode} ${response.reasonPhrase}: ${response.body}",
          ),
        ),
      );
    }

    setState(() {
      loaded = true;
      data = jsonDecode(response.body)[0]['result'][0]['result'];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadingTeam != widget.team) load();

    if (!loaded) return const SkeletonFlag();
    if (data == null) return Container();
    return widget.flag.getWidget(context, data);
  }
}
