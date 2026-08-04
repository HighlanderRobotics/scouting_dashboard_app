import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/inset_picker.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/custom_fields.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons_forked/skeletons_forked.dart';
import 'package:url_launcher/url_launcher.dart';

const _customFieldsGuideUrl = "https://learn.lovat.app/guides/custom-fields";

String _customFieldSubtitle(CustomField field) {
  if (field.type == CustomFieldType.singleSelect ||
      field.type == CustomFieldType.multiSelect) {
    return "${field.type.localizedDescription} · ${field.options.length} option${field.options.length == 1 ? '' : 's'}";
  }

  return field.type.localizedDescription;
}

class CustomFieldsPage extends StatefulWidget {
  const CustomFieldsPage({super.key});

  @override
  State<CustomFieldsPage> createState() => _CustomFieldsPageState();
}

class _CustomFieldsPageState extends State<CustomFieldsPage> {
  List<CustomField>? fields;
  String? error;

  Future<void> fetchData() async {
    try {
      setState(() {
        fields = null;
        error = null;
      });

      final data = await getCustomFieldDefinitions(force: true);

      setState(() {
        fields = data.where((field) => !field.archived).toList();
      });
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (_) {
      setState(() {
        error = "Failed to load custom fields";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final previousFields = fields!.toList();
    final reorderedFields = fields!.toList();
    final field = reorderedFields.removeAt(oldIndex);
    reorderedFields.insert(newIndex, field);

    setState(() {
      fields = reorderedFields;
    });

    try {
      await lovatAPI.reorderCustomFields(
        reorderedFields.map((field) => field.uuid).toList(),
      );
      cachedCustomFields = null;
    } catch (e) {
      // Roll the list back and surface the failure — otherwise a rejected
      // reorder silently looks like it succeeded.
      if (!mounted) return;
      setState(() {
        fields = previousFields;
      });
      scaffoldMessengerState.showSnackBar(SnackBar(
        content: Text(
          e is LovatAPIException ? e.message : "Failed to reorder fields",
        ),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = SkeletonListView(
      itemBuilder: (context, index) => SkeletonListTile(),
    );

    if (fields != null) {
      if (fields!.isEmpty) {
        body = PageBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/no-notes-dark.png", width: 250),
              const SizedBox(height: 8),
              Text(
                "No custom fields",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                "Tap + to ask your scouts extra questions after each match.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(_customFieldsGuideUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text("Learn more"),
              ),
            ],
          ),
        );
      } else {
        body = PageBody(
          padding: EdgeInsets.zero,
          bottom: false,
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            onReorder: reorder,
            children: fields!
                .asMap()
                .entries
                .map(
                  (entry) => ListTile(
                    key: Key(entry.value.uuid),
                    title: Text(entry.value.name),
                    subtitle: Text(_customFieldSubtitle(entry.value)),
                    onTap: () {
                      Navigator.of(context).pushWidget(CustomFieldEditorPage(
                        field: entry.value,
                        onSaved: fetchData,
                      ));
                    },
                    trailing: ReorderableDragStartListener(
                      index: entry.key,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      }
    }

    if (error != null) {
      body = FriendlyErrorView(errorMessage: error, onRetry: fetchData);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Fields"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushWidget(ArchivedCustomFieldsPage(
                onChanged: fetchData,
              ));
            },
            icon: const Icon(Icons.access_time),
            tooltip: "View archived fields",
          ),
        ],
      ),
      drawer: const GlobalNavigationDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushWidget(CustomFieldEditorPage(
            onSaved: fetchData,
          ));
        },
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}

class CustomFieldEditorPage extends StatefulWidget {
  const CustomFieldEditorPage({
    super.key,
    this.field,
    this.onSaved,
  });

  /// The field to edit, or null to create a new one.
  final CustomField? field;
  final Function()? onSaved;

  @override
  State<CustomFieldEditorPage> createState() => _CustomFieldEditorPageState();
}

class _CustomFieldEditorPageState extends State<CustomFieldEditorPage> {
  late final TextEditingController questionController;
  final List<TextEditingController> optionControllers = [];
  final List<TextEditingController> spawnedControllers = [];

  CustomFieldType? type;
  bool submitting = false;
  bool archiving = false;
  String? questionError;
  String? optionsError;

  bool get isEditing => widget.field != null;

  bool get isArchived => widget.field?.archived ?? false;

  bool get isSelect =>
      type == CustomFieldType.singleSelect ||
      type == CustomFieldType.multiSelect;

  /// Number of options that already existed on the saved field. These can't be
  /// renamed or removed (only appended to), so their rows are locked.
  int get lockedOptionCount => widget.field?.options.length ?? 0;

  TextEditingController newOptionController([String text = ""]) {
    final controller = TextEditingController(text: text);
    spawnedControllers.add(controller);
    return controller;
  }

  @override
  void initState() {
    super.initState();

    questionController = TextEditingController(text: widget.field?.name ?? "");
    type = widget.field?.type;

    for (final option in widget.field?.options ?? <String>[]) {
      optionControllers.add(newOptionController(option));
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    for (final controller in spawnedControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void ensureMinimumOptionRows() {
    while (optionControllers.length < 2) {
      optionControllers.add(newOptionController());
    }
  }

  String typeDescription(CustomFieldType type) {
    switch (type) {
      case CustomFieldType.text:
        return "Scouts type a free-form answer";
      case CustomFieldType.number:
        return "Scouts enter a number, averaged in analysis";
      case CustomFieldType.singleSelect:
        return "Scouts pick one option";
      case CustomFieldType.multiSelect:
        return "Scouts pick any number of options";
    }
  }

  Future<void> save() async {
    final name = questionController.text.trim();
    final options = optionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    String? questionError;
    String? optionsError;

    if (name.isEmpty) {
      questionError = "Enter a question";
    }

    if (isSelect) {
      if (options.length < 2) {
        optionsError = "Add at least 2 options";
      } else if (options.toSet().length != options.length) {
        optionsError = "Options must be unique";
      }
    }

    setState(() {
      this.questionError = questionError;
      this.optionsError = optionsError;
    });

    if (questionError != null || optionsError != null) return;

    setState(() {
      submitting = true;
    });

    final navigatorState = Navigator.of(context);
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    try {
      if (isEditing) {
        await lovatAPI.updateCustomField(
          widget.field!.uuid,
          name: name,
          options: isSelect ? options : null,
        );
      } else {
        await lovatAPI.createCustomField(
          name: name,
          type: type!,
          options: isSelect ? options : const [],
        );
      }

      cachedCustomFields = null;
      widget.onSaved?.call();

      scaffoldMessengerState.showSnackBar(SnackBar(
        content:
            Text(isEditing ? "Saved custom field" : "Created custom field"),
        behavior: SnackBarBehavior.floating,
      ));

      navigatorState.pop();
    } on LovatAPIException catch (e) {
      scaffoldMessengerState.showSnackBar(SnackBar(
        content: Text(e.message),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      scaffoldMessengerState.showSnackBar(const SnackBar(
        content: Text("Failed to save custom field"),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  Future<void> archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ArchiveConfirmationDialog(),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      archiving = true;
    });

    final navigatorState = Navigator.of(context);
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    try {
      await lovatAPI.archiveCustomField(widget.field!.uuid);
      cachedCustomFields = null;
      widget.onSaved?.call();
      scaffoldMessengerState.showSnackBar(const SnackBar(
        content: Text("Archived custom field"),
        behavior: SnackBarBehavior.floating,
      ));
      navigatorState.pop();
    } on LovatAPIException catch (e) {
      _showActionError("Failed to archive field: ${e.message}");
    } catch (_) {
      _showActionError("Failed to archive field");
    }
  }

  Future<void> unarchive() async {
    setState(() {
      archiving = true;
    });

    final navigatorState = Navigator.of(context);
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    try {
      await lovatAPI.unarchiveCustomField(widget.field!.uuid);
      cachedCustomFields = null;
      widget.onSaved?.call();
      scaffoldMessengerState.showSnackBar(const SnackBar(
        content: Text("Unarchived custom field"),
        behavior: SnackBarBehavior.floating,
      ));
      navigatorState.pop();
    } on LovatAPIException catch (e) {
      _showActionError("Failed to unarchive field: ${e.message}");
    } catch (_) {
      _showActionError("Failed to unarchive field");
    }
  }

  void _showActionError(String message) {
    if (!mounted) return;
    setState(() {
      archiving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final busy = submitting || archiving;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Custom Field" : "New Custom Field"),
        actions: [
          IconButton(
            onPressed: busy || type == null ? null : save,
            icon: const Icon(Icons.check),
            tooltip: isEditing ? "Save changes" : "Create",
            color: Colors.green,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: busy
              ? const LinearProgressIndicator()
              : const SizedBox(height: 4),
        ),
      ),
      body: ScrollablePageBody(
        children: [
          TextField(
            controller: questionController,
            decoration: InputDecoration(
              filled: true,
              labelText: "Question",
              errorText: questionError,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          Text(
            "Type",
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          InsetPicker(
            CustomFieldType.values,
            titleBuilder: (type) => type.localizedDescription,
            descriptionBuilder: typeDescription,
            selectedItem: type,
            onChanged: isEditing
                ? null
                : (CustomFieldType? value) => setState(() {
                      type = value;
                      if (isSelect) ensureMinimumOptionRows();
                    }),
          ),
          if (isEditing) ...[
            const SizedBox(height: 8),
            Text(
              "Type can't be changed after a field is created. Archive this field and create a new one instead.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (isSelect) ...[
            const SizedBox(height: 24),
            Text(
              "Options",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            ...optionControllers.asMap().entries.map(
              (entry) {
                // Options that were already saved can't be renamed or removed
                // (only reordered/appended to), so lock their row.
                final locked = entry.key < lockedOptionCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          enabled: !locked,
                          decoration: InputDecoration(
                            filled: true,
                            labelText: "Option ${entry.key + 1}",
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        onPressed: locked
                            ? null
                            : () {
                                setState(() {
                                  optionControllers.removeAt(entry.key);
                                });
                              },
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: locked
                            ? "Existing options can't be removed"
                            : "Remove option",
                      ),
                    ],
                  ),
                );
              },
            ),
            if (optionsError != null) ...[
              const SizedBox(height: 2),
              Text(
                optionsError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 2),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    optionControllers.add(newOptionController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add option"),
              ),
            ),
          ],
          if (isEditing) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: isArchived
                  ? FilledButton.tonalIcon(
                      onPressed: busy ? null : unarchive,
                      icon: const Icon(Icons.unarchive_outlined),
                      label: const Text("Unarchive field"),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: busy ? null : archive,
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text("Archive field"),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirmation dialog for archiving; pops with `true` when confirmed.
class _ArchiveConfirmationDialog extends StatelessWidget {
  const _ArchiveConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Archive field?"),
      content: const Text(
          "Scouts will stop seeing this question in Lovat Collection. Answers already collected stay in your data, and you can unarchive it later."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Archive"),
        ),
      ],
    );
  }
}

class ArchivedCustomFieldsPage extends StatefulWidget {
  const ArchivedCustomFieldsPage({
    super.key,
    this.onChanged,
  });

  final Function()? onChanged;

  @override
  State<ArchivedCustomFieldsPage> createState() =>
      _ArchivedCustomFieldsPageState();
}

class _ArchivedCustomFieldsPageState extends State<ArchivedCustomFieldsPage> {
  List<CustomField>? fields;
  String? error;

  Future<void> fetchData() async {
    try {
      setState(() {
        fields = null;
        error = null;
      });

      final data = await getCustomFieldDefinitions(force: true);

      setState(() {
        fields = data.where((field) => field.archived).toList();
      });
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (_) {
      setState(() {
        error = "Failed to load custom fields";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = SkeletonListView(
      itemBuilder: (context, index) => SkeletonListTile(),
    );

    if (fields != null) {
      if (fields!.isEmpty) {
        body = PageBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/no-notes-dark.png", width: 250),
              const SizedBox(height: 8),
              Text(
                "No archived fields",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      } else {
        body = ScrollablePageBody(
          padding: EdgeInsets.zero,
          children: fields!
              .map(
                (field) => ListTile(
                  title: Text(field.name),
                  subtitle: Text(_customFieldSubtitle(field)),
                  onTap: () {
                    Navigator.of(context).pushWidget(CustomFieldEditorPage(
                      field: field,
                      onSaved: () {
                        fetchData();
                        widget.onChanged?.call();
                      },
                    ));
                  },
                ),
              )
              .toList(),
        );
      }
    }

    if (error != null) {
      body = FriendlyErrorView(errorMessage: error, onRetry: fetchData);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Archived Custom Fields"),
      ),
      body: body,
    );
  }
}
