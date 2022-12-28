import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({
    Key? key,
  }) : super(key: key);

  Future<String> getTournamentName() async {
    final prefs = await SharedPreferences.getInstance();

    return getTournamentByKey(prefs.getString("tournament")!)!.localized;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionHeader(title: "8033 Scouting Dashboard"),
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).popAndPushNamed("/settings");
                      },
                      icon: const Icon(Icons.settings)),
                ],
              ),
              const Divider(),
              FutureBuilder(
                builder: ((context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SectionHeader(title: snapshot.data!);
                  }

                  return const SectionHeader(title: "--");
                }),
                future: getTournamentName(),
              ),
              const Divider(),
              const SectionHeader(title: "Scouting Lead"),
              DrawerDestination(
                label: "Match Schedule",
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/match_schedule", (route) => false);
                },
                isSelected:
                    ModalRoute.of(context)?.settings.name == "/match_schedule",
                icon: Icons.today,
              ),
              const SectionHeader(title: "Data Analysis"),
              DrawerDestination(
                label: "Score Predictor",
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/score_predictor", (route) => false);
                },
                isSelected:
                    ModalRoute.of(context)?.settings.name == "/score_predictor",
                icon: Icons.psychology,
              ),
              DrawerDestination(
                label: "Team Lookup",
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/team_lookup", (route) => false);
                },
                isSelected:
                    ModalRoute.of(context)?.settings.name == "/team_lookup",
                icon: Icons.search,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 18),
      child: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          )),
    );
  }
}

class DrawerDestination extends StatelessWidget {
  final void Function()? onTap;
  final String label;
  final bool isSelected;
  final IconData icon;

  const DrawerDestination(
      {Key? key,
      this.onTap,
      required this.label,
      required this.icon,
      this.isSelected = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    return isSelected
        ? Container(
            decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(100)))),
            child: content,
          )
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            splashColor: Theme.of(context).colorScheme.secondaryContainer,
            child: content,
          );
  }
}
