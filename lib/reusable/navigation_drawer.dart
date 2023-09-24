import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalNavigationDrawer extends StatelessWidget {
  const GlobalNavigationDrawer({
    Key? key,
  }) : super(key: key);

  Future<String> getTournamentName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("tournament_localized")!;
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
                  const SectionHeader(title: "Lovat Dashboard"),
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).popAndPushNamed("/settings");
                      },
                      icon: const Icon(Icons.settings)),
                ],
              ),
              Divider(
                color: Theme.of(context).colorScheme.outline,
              ),
              FutureBuilder(
                builder: ((context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SectionHeader(title: snapshot.data!);
                  }

                  return const SectionHeader(title: "--");
                }),
                future: getTournamentName(),
              ),
              Divider(
                color: Theme.of(context).colorScheme.outline,
              ),
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
              RoleExclusive(
                roles: const ['8033_scouting_lead'],
                child: DrawerDestination(
                  label: "Scan QR Codes",
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/scan_qr_codes",
                      (route) => false,
                    );
                  },
                  isSelected:
                      ModalRoute.of(context)?.settings.name == "/scan_qr_codes",
                  icon: Icons.qr_code_scanner,
                ),
              ),
              const SectionHeader(title: "Data Analysis"),
              DrawerDestination(
                label: "Match Predictor",
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/match_predictor_opener", (route) => false);
                },
                isSelected: ModalRoute.of(context)?.settings.name ==
                    "/match_predictor_opener",
                icon: Icons.psychology,
              ),
              // DrawerDestination(
              //   label: "Match Suggestions",
              //   onTap: () {
              //     Navigator.pushNamedAndRemoveUntil(
              //         context, "/match_suggestions_opener", (route) => false);
              //   },
              //   isSelected: ModalRoute.of(context)?.settings.name ==
              //       "/match_suggestions_opener",
              //   icon: Icons.assistant,
              // ),
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
              DrawerDestination(
                label: "Picklist",
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/picklists", (route) => false);
                },
                isSelected:
                    ModalRoute.of(context)?.settings.name == "/picklists",
                icon: Icons.format_list_numbered,
              ),
              DrawerDestination(
                label: "My Alliance",
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/my_alliance", (route) => false);
                },
                isSelected:
                    ModalRoute.of(context)?.settings.name == "/my_alliance",
                icon: Icons.group_work,
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
