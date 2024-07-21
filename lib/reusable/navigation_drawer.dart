import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

LovatUserProfile? cachedUserProfile;

class GlobalNavigationDrawer extends StatefulWidget {
  const GlobalNavigationDrawer({
    Key? key,
  }) : super(key: key);

  @override
  State<GlobalNavigationDrawer> createState() => _GlobalNavigationDrawerState();
}

class _GlobalNavigationDrawerState extends State<GlobalNavigationDrawer> {
  Tournament? selectedTournament;
  LovatUserProfile? userProfile;

  Future<void> fetchData() async {
    final tournament = await Tournament.getCurrent();

    setState(() {
      selectedTournament = tournament;
    });

    try {
      final profile = await lovatAPI.getUserProfile();

      cachedUserProfile = profile;

      setState(() {
        userProfile = profile;
      });
    } on LovatAPIException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to load user profile: ${e.message}"),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to load user profile"),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<String?> getTournamentName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("tournament_localized");
  }

  @override
  void initState() {
    super.initState();
    userProfile = cachedUserProfile;
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
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
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          "/settings", (route) => false);
                    },
                    icon: const Icon(Icons.settings),
                    tooltip: "Settings",
                  ),
                ],
              ),
              Divider(
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              SectionHeader(
                  title: selectedTournament?.localized ??
                      "No tournament selected"),
              Divider(
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              if (selectedTournament != null ||
                  (userProfile?.role == UserRole.scoutingLead &&
                      userProfile?.team != null))
                const SectionHeader(title: "Data & Utilities"),
              if (selectedTournament != null) ...[
                DrawerDestination(
                  label: "Match Schedule",
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, "/match_schedule", (route) => false);
                  },
                  isSelected: ModalRoute.of(context)?.settings.name ==
                      "/match_schedule",
                  icon: Icons.today,
                ),
              ],
              if (userProfile?.role == UserRole.scoutingLead &&
                  userProfile?.team != null) ...[
                DrawerDestination(
                  label: "Scouters",
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, "/scouters", (route) => false);
                  },
                  isSelected:
                      ModalRoute.of(context)?.settings.name == "/scouters",
                  icon: Icons.supervised_user_circle,
                ),
              ],
              if (selectedTournament != null) ...[
                DrawerDestination(
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
              ],
              const SectionHeader(title: "Analysis & Strategy"),
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
              if (selectedTournament != null)
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
