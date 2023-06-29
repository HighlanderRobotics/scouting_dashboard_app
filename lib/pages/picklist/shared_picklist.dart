import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';

class SharedPicklistPage extends StatelessWidget {
  const SharedPicklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    ConfiguredPicklist picklist = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['picklist'];

    return Scaffold(
      appBar: AppBar(
        title: Text(picklist.title),
        actions: [
          RoleExclusive(
            roles: const [
              "8033_analyst",
              "8033_scouting_lead",
            ],
            child: IconButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text("Converting to mutable..."),
                ));

                try {
                  final mutablePicklist =
                      await MutablePicklist.fromReactivePicklist(picklist);

                  await mutablePicklist.upload();
                } catch (error) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        "Error converting to mutable: ${error.toString()}",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                    ),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text("Successfully converted to mutable."),
                  ),
                );
              },
              icon: const Icon(Icons.swap_vert),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/view_picklist_weights', arguments: {
                'picklist': picklist,
              });
            },
            icon: const Icon(Icons.balance),
          ),
        ],
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: PicklistVisuzlization(
          analysisFunction: PicklistAnalysis(picklist: picklist),
        ),
      ),
    );
  }
}
