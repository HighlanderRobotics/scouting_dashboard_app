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

    final analysisFunction = SharedPicklistAnalysis(picklistMeta: picklistMeta);

    return Scaffold(
      appBar: AppBar(
        title: Text(picklistMeta.title),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  title: Text("Convert to mutable"),
                  leading: Icon(Icons.swap_vert),
                ),
                onTap: () async {
                  final scaffoldMessengerState = ScaffoldMessenger.of(context);
                  final themeData = Theme.of(context);

                  scaffoldMessengerState.showSnackBar(const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text("Converting to mutable..."),
                  ));

                  try {
                    final picklist = await picklistMeta.getPicklist();

                    final mutablePicklist =
                        await MutablePicklist.fromReactivePicklist(picklist);

                    await mutablePicklist.upload();
                  } catch (error) {
                    scaffoldMessengerState.hideCurrentSnackBar();
                    scaffoldMessengerState.showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          "Error converting to mutable: ${error.toString()}",
                          style: TextStyle(
                              color: themeData.colorScheme.onErrorContainer),
                        ),
                        backgroundColor: themeData.colorScheme.errorContainer,
                      ),
                    );
                    return;
                  }

                  scaffoldMessengerState.hideCurrentSnackBar();
                  scaffoldMessengerState.showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text("Successfully converted to mutable."),
                    ),
                  );
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  title: Text("View weights"),
                  leading: Icon(Icons.balance),
                ),
                onTap: () {
                  Navigator.of(context)
                      .pushNamed('/view_picklist_weights', arguments: {
                    'picklistMeta': picklistMeta,
                  });
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  title: Text("Export CSV"),
                  leading: Icon(Icons.download_outlined),
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        PicklistExportDrawer(analysisFunction),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: PicklistVisuzlization(
          analysisFunction: analysisFunction,
        ),
      ),
    );
  }
}
