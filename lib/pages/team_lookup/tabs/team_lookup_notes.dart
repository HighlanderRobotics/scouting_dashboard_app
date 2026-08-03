import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/custom_field_indicator.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_notes.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';
import 'package:skeletons_forked/skeletons_forked.dart';

class TeamLookupNotesTab extends StatelessWidget {
  const TeamLookupNotesTab({super.key, required this.team});

  final int team;

  @override
  Widget build(BuildContext context) {
    return StaleRefreshBuilder(
      query: lovatAPI.notesQuery(team),
      builder: (context, result) {
        final data = result.data;
        final error = result.error;
        final refetch = result.refetch;
        if (data != null) {
          // Tag each note with the team being looked up so its card can open
          // the matching raw scout report.
          final withTeam =
              data.map((e) => e.copyWith(teamNumber: team)).toList();
          final sortedNotes = [
            ...withTeam.where((e) => e.type == NoteType.breakDescription),
            ...withTeam.where((e) => e.type != NoteType.breakDescription),
          ];
          return Stack(
            children: [
              sortedNotes.isEmpty
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 100),
                          Image.asset(
                            'assets/images/no-notes-${Theme.of(context).brightness.name}.png',
                            width: 250,
                          ),
                          Text(
                            "No notes on $team",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    )
                  : ScrollablePageBody(
                      children: [
                        NotesList(
                          notes: sortedNotes
                              .map(
                                (note) => NoteWidget(
                                  note,
                                  onEdit: refetch,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: StaleRefreshIndicator.result(result),
              ),
            ],
          );
        }

        if (error != null) {
          return FriendlyErrorView.result(result);
        }

        return PageBody(
          bottom: false,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: SkeletonListView(
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  borderRadius: BorderRadius.circular(10),
                  randomHeight: true,
                  minHeight: 74,
                  maxHeight: 160,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BreakDescriptionsPage extends StatelessWidget {
  const BreakDescriptionsPage({super.key, required this.breakDescriptions});

  final List<NoteWidget> breakDescriptions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Robot Breaks"),
      ),
      body: ScrollablePageBody(
          children: [NotesList(notes: breakDescriptions, showWarning: false)]),
    );
  }
}

class RobotBrokeBox extends StatelessWidget {
  const RobotBrokeBox({super.key, required this.breakDescriptions});

  final List<NoteWidget> breakDescriptions;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = HSLColor.fromColor(Colors.amber)
        .withSaturation(1)
        .withLightness(0.2)
        .toColor();

    final foregroundColor = HSLColor.fromColor(Colors.amber)
        .withSaturation(1)
        .withLightness(0.8)
        .toColor();

    const double iconSize = 24;

    final String description =
        "View ${breakDescriptions.length} ${breakDescriptions.length > 1 ? "reports" : "report"}";

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushWidget(
            BreakDescriptionsPage(breakDescriptions: breakDescriptions));
      },
      child: EmphasizedContainer(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: foregroundColor,
                  size: iconSize,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Robot broke",
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: foregroundColor, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: foregroundColor.withAlpha(225)),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: foregroundColor)
          ],
        ),
      ),
    );
  }
}

class NotesList extends StatelessWidget {
  const NotesList({Key? key, required this.notes, this.showWarning = true})
      : super(key: key);

  final List<NoteWidget> notes;
  final bool showWarning;
  @override
  Widget build(BuildContext context) {
    final List<NoteWidget> notes =
        this.notes.where((e) => e.note.type == NoteType.note).toList();
    final List<NoteWidget> breakDescriptions = this
        .notes
        .where((e) => e.note.type == NoteType.breakDescription)
        .toList();

    return Column(
      spacing: 15,
      children: [
        ...breakDescriptions.isEmpty || !showWarning
            ? []
            : [RobotBrokeBox(breakDescriptions: breakDescriptions)],
        ...notes.isEmpty ? [] : notes,
        ...!showWarning
            ? breakDescriptions.map((e) => NoteWidget(
                  e.note,
                  foregroundColor: HSLColor.fromColor(Colors.amber)
                      .withSaturation(1)
                      .withLightness(0.8)
                      .toColor(),
                  backgroundColor: HSLColor.fromColor(Colors.amber)
                      .withSaturation(1)
                      .withLightness(0.2)
                      .toColor(),
                ))
            : [],
      ],
    );
  }
}

class NoteWidget extends StatelessWidget {
  const NoteWidget(
    this.note, {
    Key? key,
    this.foregroundColor,
    this.backgroundColor,
    this.onEdit,
  }) : super(key: key);

  final Note note;
  final dynamic Function()? onEdit;

  final Color? backgroundColor;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Colour roles for hierarchy: an accent for the match and field labels, a
    // high-contrast colour for the note body, and a muted colour for secondary
    // metadata (tournament, attribution). Break descriptions pass a foreground
    // colour that overrides all three.
    // Neutral "plain" card (the app's default EmphasizedContainer surface) so
    // the body reads as standard on-surface text rather than white-on-purple.
    final bodyColor = foregroundColor ?? scheme.onSurface;
    final mutedColor =
        foregroundColor?.withValues(alpha: 0.75) ?? scheme.onSurfaceVariant;

    final matchLabel =
        note.matchIdentity.getLocalizedDescription(includeTournament: false);
    final attribution = note.author ??
        (note.sourceTeam != null ? "Scouter from ${note.sourceTeam}" : null);
    // A note links to its raw scout report when we know both ids.
    final canOpen = note.uuid != null && note.teamNumber != null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Material(
        color: backgroundColor ?? scheme.surfaceContainerHighest,
        child: InkWell(
          onTap: canOpen ? () => _openRawReport(context) : null,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: match-type icon + concise match name, with the (longer)
                // tournament name beneath it, de-emphasised.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matchLabel,
                            style: textTheme.titleMedium!.copyWith(
                              color: bodyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            note.matchIdentity.localizedTournament,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall!
                                .copyWith(color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    if (canOpen)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Icon(
                          Icons.chevron_right,
                          color: mutedColor,
                          size: 22,
                        ),
                      ),
                  ],
                ),
                if (note.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ExpandableText(
                    note.body,
                    style: textTheme.bodyMedium!
                        .copyWith(color: bodyColor, height: 1.3),
                    linkColor: foregroundColor ?? scheme.onPrimaryContainer,
                  ),
                ],
                // Text custom field answers from the same report, set off by a
                // gap and labelled with the question + the Custom marker.
                ...note.customTextAnswers.map(
                  (answer) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                answer.name,
                                style: textTheme.labelLarge!.copyWith(
                                  color: bodyColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const CustomFieldIndicator(),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          answer.value,
                          style: textTheme.bodyMedium!
                              .copyWith(color: bodyColor, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
                if (attribution != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 15,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          attribution,
                          // Same style as the tournament line so they match.
                          style:
                              textTheme.bodySmall!.copyWith(color: mutedColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRawReport(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/raw_scout_report',
      arguments: {
        'uuid': note.uuid,
        'teamNumber': note.teamNumber,
        'matchIdentity': note.matchIdentity,
        'scoutName': note.author ??
            (note.sourceTeam != null
                ? "Scouter from ${note.sourceTeam}"
                : "Unknown scout"),
        'canModify': note.author != null,
        'onDeleted': () => onEdit?.call(),
      },
    );
  }
}

/// A note body that clamps to [maxLines] with a "Read more" / "Read less"
/// toggle when the text would otherwise overflow.
class ExpandableText extends StatefulWidget {
  const ExpandableText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 5,
    this.linkColor,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final Color? linkColor;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  static const _duration = Duration(milliseconds: 250);
  static const _curve = Curves.easeInOut;

  bool expanded = false;
  final GlobalKey _buttonKey = GlobalKey();

  double _textHeight(int? maxLines, double maxWidth) {
    return (TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth))
        .height;
  }

  void _toggle(double maxWidth) {
    if (expanded) {
      // Collapsing shrinks the text above the button by `delta`. Only scroll
      // the list up (to keep the button under the finger) if the button would
      // otherwise be pushed above the top of the viewport.
      final delta =
          _textHeight(null, maxWidth) - _textHeight(widget.maxLines, maxWidth);
      final scrollable = Scrollable.maybeOf(context);
      final buttonBox =
          _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final viewportBox = scrollable?.context.findRenderObject() as RenderBox?;
      if (scrollable != null &&
          buttonBox != null &&
          viewportBox != null &&
          delta > 0) {
        const margin = 12.0;
        final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
        // Where the button will sit once the text above it collapses.
        final projectedButtonTop =
            buttonBox.localToGlobal(Offset.zero).dy - delta;
        if (projectedButtonTop < viewportTop + margin) {
          // Scroll up only far enough to bring it back on-screen (the minimum),
          // rather than all the way back to where it started.
          final scrollUpBy = (viewportTop + margin) - projectedButtonTop;
          final position = scrollable.position;
          final target = (position.pixels - scrollUpBy)
              .clamp(position.minScrollExtent, position.maxScrollExtent);
          position.animateTo(target, duration: _duration, curve: _curve);
        }
      }
    }
    setState(() => expanded = !expanded);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final fullHeight = _textHeight(null, maxWidth);
        final collapsedHeight = _textHeight(widget.maxLines, maxWidth);

        // Short enough that nothing is clipped.
        if (fullHeight <= collapsedHeight + 0.5) {
          return Text(widget.text, style: widget.style);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The full text is always laid out; only the revealed height
            // animates and clips it, so the text never snaps when collapsing.
            TweenAnimationBuilder<double>(
              tween:
                  Tween<double>(end: expanded ? fullHeight : collapsedHeight),
              duration: _duration,
              curve: _curve,
              child: Text(widget.text, style: widget.style),
              builder: (context, height, child) {
                Widget clipped = ClipRect(
                  child: SizedBox(
                    height: height,
                    width: double.infinity,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: child,
                    ),
                  ),
                );
                // Soft-fade the bottom edge while any text is still hidden.
                if (height < fullHeight - 0.5) {
                  final fadeStop = (1 - (18 / height)).clamp(0.0, 1.0);
                  clipped = ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, fadeStop, 1.0],
                    ).createShader(rect),
                    child: clipped,
                  );
                }
                return clipped;
              },
            ),
            const SizedBox(height: 3),
            GestureDetector(
              key: _buttonKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(maxWidth),
              child: Text(
                expanded ? "Show less" : "Show more",
                style: (widget.style ?? const TextStyle()).copyWith(
                  color: widget.linkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
