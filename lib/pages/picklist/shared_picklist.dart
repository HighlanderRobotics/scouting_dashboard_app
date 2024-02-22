import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

class SharedPicklistPage extends StatelessWidget {
  const SharedPicklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    ConfiguredPicklistMeta picklistMeta = (ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>)['picklist'];

    return Scaffold(
      appBar: AppBar(
        title: Text(picklistMeta.title),
        actions: [
          IconButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text("Converting to mutable..."),
              ));

              try {
                final picklist = await picklistMeta.getPicklist();

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
            tooltip: "Convert to mutable picklist",
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/view_picklist_weights', arguments: {
                'picklistMeta': picklistMeta,
              });
            },
            icon: const Icon(Icons.balance),
            tooltip: "View picklist weights",
          ),
        ],
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: PicklistVisuzlization(
          analysisFunction: SharedPicklistAnalysis(picklistMeta: picklistMeta),
          key: GlobalKey(),
        ),
      ),
    );
  }
}
