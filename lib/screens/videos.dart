import 'package:flutter/material.dart';

import '../board.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

enum _VideoView { board, table }

/// Published videos older than this drop off the board (the table has all).
const _publishedWindowDays = 30;

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  _VideoView _view = _VideoView.board;
  String _query = '';
  String? _series;
  String? _assigneeId;
  VideoFormat? _format;

  bool _matches(Video v) {
    if (_series != null && v.series != _series) return false;
    if (_assigneeId != null && v.assigneeId != _assigneeId) return false;
    if (_format != null && v.format != _format) return false;
    if (_query.isNotEmpty && !v.title.toLowerCase().contains(_query)) {
      return false;
    }
    return true;
  }

  static int _byPublishDate(Video a, Video b) {
    final ad = a.publishAt, bd = b.publishAt;
    if (ad != null && bd != null) return ad.compareTo(bd);
    if (ad != null) return -1;
    if (bd != null) return 1;
    return a.stageSince.compareTo(b.stageSince);
  }

  Future<void> _move(Video v, VideoStage stage) async {
    final store = StoreScope.read(context);
    if (v.stage == stage) return;
    String? url;
    if (stage == VideoStage.published && v.youtubeUrl == null) {
      url = await showDialog<String>(
        context: context,
        barrierColor: C.ink.withValues(alpha: 0.45),
        builder: (_) => _PublishLinkDialog(video: v),
      );
      if (url == null) return;
    }
    store.moveVideo(v, stage, youtubeUrl: url);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final visible = store.videos.where(_matches).toList();
    final inProduction = visible.where((v) => v.stage.inProduction).length;
    final stuck = visible.where((v) => v.isStuck(now)).length;
    final g = gutter(context);

    Widget body;
    if (!store.loaded('videos')) {
      body = Padding(
        padding: EdgeInsets.symmetric(horizontal: g),
        child: const SkeletonList(rows: 6, height: 64),
      );
    } else if (store.videos.isEmpty) {
      body = EmptyState(
        icon: Icons.movie_outlined,
        title: 'The pipeline is empty',
        message:
            'Add the videos you’re planning for Original Morals. Each one moves '
            'from idea to published, so everyone can see where it is.',
        actionLabel: 'New video',
        onAction: () => showVideoDialog(context),
      );
    } else if (_view == _VideoView.board) {
      body = Board<VideoStage, Video>(
        columns: VideoStage.values,
        minColumnWidth: 252,
        titleOf: (s) => s == VideoStage.published
            ? 'Published · ${_publishedWindowDays}d'
            : s.label,
        colorOf: stageColor,
        itemsOf: (s) {
          final items = visible.where((v) => v.stage == s);
          if (s == VideoStage.published) {
            return items
                .where((v) =>
                    daysBetween(v.stageSince, now) <= _publishedWindowDays)
                .toList()
              ..sort((a, b) => b.stageSince.compareTo(a.stageSince));
          }
          return items.toList()..sort(_byPublishDate);
        },
        cardBuilder: (context, v) => VideoCard(v),
        onMove: _move,
        onAdd: (s) => showVideoDialog(context, stage: s),
      );
    } else {
      final sorted = [...visible]..sort(_byPublishDate);
      body = Padding(
        padding: EdgeInsets.fromLTRB(g, 0, g, 24),
        child: AppTable<Video>(
          shrinkWrap: false,
          minWidth: 900,
          rows: sorted,
          onTap: (v) => showVideoDialog(context, video: v),
          empty: const EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'Nothing matches',
            message: 'No videos match these filters.',
          ),
          columns: [
            Col('Video', flex: 4, (v) => cellText(v.title, strong: true)),
            Col('Series', flex: 2,
                (v) => Tag(v.series, color: seedColor(v.series))),
            Col('Format', width: 80, (v) => FormatBadge(v.format)),
            Col('Stage', width: 130,
                (v) => Tag(v.stage.label, color: stageColor(v.stage))),
            Col('In stage', width: 90, (v) => StageAge(v, short: true)),
            Col('Owner', flex: 2,
                (v) => UserLabel(store.userById(v.assigneeId))),
            Col(
                'Publish',
                width: 100,
                (v) => cellText(
                    v.publishAt == null ? '—' : fmtDay(v.publishAt!),
                    color: v.publishAt == null ? C.faint : C.text)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Videos',
          subtitle: stuck > 0
              ? '$inProduction in production · $stuck stuck more than $kStuckDays days'
              : '$inProduction in production for Original Morals',
          actions: [
            Segmented<_VideoView>(
              values: _VideoView.values,
              selected: _view,
              labelOf: (v) => v == _VideoView.board ? 'Pipeline' : 'Table',
              iconOf: (v) => v == _VideoView.board
                  ? Icons.view_week_outlined
                  : Icons.table_rows_outlined,
              onChanged: (v) => setState(() => _view = v),
            ),
            FilledButton.icon(
              onPressed: () => showVideoDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New video'),
            ),
          ],
        ),
        FilterBar(children: [
          SearchBox(
            hint: 'Search videos',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          FilterMenu<String>(
            label: 'Series',
            value: _series,
            options: store.seriesOptions,
            textOf: (s) => s,
            onChanged: (v) => setState(() => _series = v),
          ),
          FilterMenu<String>(
            label: 'Owner',
            value: _assigneeId,
            options: [for (final u in store.activeUsers) u.id],
            textOf: store.nameOf,
            onChanged: (v) => setState(() => _assigneeId = v),
          ),
          FilterMenu<VideoFormat>(
            label: 'Format',
            value: _format,
            options: VideoFormat.values,
            textOf: (f) => f.label,
            onChanged: (v) => setState(() => _format = v),
          ),
        ]),
        Expanded(child: body),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small video widgets
// ---------------------------------------------------------------------------

class FormatBadge extends StatelessWidget {
  const FormatBadge(this.format, {super.key});

  final VideoFormat format;

  @override
  Widget build(BuildContext context) {
    final short = format == VideoFormat.short;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: C.hairlineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            short ? Icons.stay_current_portrait_rounded : Icons.tv_rounded,
            size: 11,
            color: C.muted,
          ),
          const SizedBox(width: 3),
          Text(format.label,
              style: tx(11, w: FontWeight.w700, color: C.muted, h: 1.25)),
        ],
      ),
    );
  }
}

/// "3d in Editing" — amber after [kStuckDays], red after [kVeryStuckDays].
class StageAge extends StatelessWidget {
  const StageAge(this.video, {super.key, this.short = false});

  final Video video;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = video.daysInStage(now);
    final color = switch (video.staleness(now)) {
      2 => C.danger,
      1 => Color.lerp(C.warn, C.ink, 0.25)!,
      _ => C.muted,
    };
    final age = days == 0 ? 'Today' : '${days}d';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            short
                ? age
                : days == 0
                    ? '${video.stage.label} since today'
                    : '$age in ${video.stage.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tx(12.5,
                w: color == C.muted ? FontWeight.w600 : FontWeight.w700,
                color: color),
          ),
        ),
      ],
    );
  }
}

class VideoCard extends StatelessWidget {
  const VideoCard(this.video, {super.key});

  final Video video;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final publish = video.publishAt;
    return Panel(
      radius: kRadiusSm + 2,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      onTap: () => showVideoDialog(context, video: video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(child: Tag(video.series, color: seedColor(video.series))),
              const SizedBox(width: 6),
              FormatBadge(video.format),
            ],
          ),
          const SizedBox(height: 8),
          Text(video.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: tx(14, w: FontWeight.w600, h: 1.35)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StageAge(video),
                    if (publish != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.event_rounded,
                            size: 13, color: C.muted),
                        const SizedBox(width: 4),
                        Text(
                          video.isPublished
                              ? 'Published ${fmtDay(publish)}'
                              : 'Publish ${fmtDue(publish)}',
                          style: tx(12.5, w: FontWeight.w600, color: C.muted),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              Avatar(store.userById(video.assigneeId), size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Bar(video.progress, color: stageColor(video.stage), height: 3),
        ],
      ),
    );
  }
}

class _PublishLinkDialog extends StatefulWidget {
  const _PublishLinkDialog({required this.video});

  final Video video;

  @override
  State<_PublishLinkDialog> createState() => _PublishLinkDialogState();
}

class _PublishLinkDialogState extends State<_PublishLinkDialog> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add the YouTube link'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('“${widget.video.title}” is going live. Paste its link so '
                'the team can open it from here.'),
            const SizedBox(height: 16),
            TextField(
              controller: _url,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: tx(14),
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
              decoration:
                  const InputDecoration(hintText: 'https://youtu.be/…'),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Add later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _url.text.trim()),
          child: const Text('Publish'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Video dialog
// ---------------------------------------------------------------------------

Future<void> showVideoDialog(BuildContext context,
        {Video? video, VideoStage? stage}) =>
    showAppDialog<void>(
      context,
      maxWidth: 720,
      dismissible: false,
      builder: (_) => VideoDialog(video: video, initialStage: stage),
    );

class VideoDialog extends StatefulWidget {
  const VideoDialog({super.key, this.video, this.initialStage});

  final Video? video;
  final VideoStage? initialStage;

  @override
  State<VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
  late final VideoDraft _draft;
  late final TextEditingController _title;
  late final TextEditingController _url;
  late final TextEditingController _notes;
  bool _urlMissing = false;

  @override
  void initState() {
    super.initState();
    final store = StoreScope.read(context);
    final v = widget.video;
    _draft = v != null
        ? VideoDraft.of(v)
        : VideoDraft(
            stage: widget.initialStage ?? VideoStage.idea,
            assigneeId: store.me?.dept == Dept.youtube ? store.uid : null,
          );
    _title = TextEditingController(text: _draft.title);
    _url = TextEditingController(text: _draft.youtubeUrl);
    _notes = TextEditingController(text: _draft.notes);
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    _draft
      ..title = _title.text
      ..youtubeUrl = _url.text
      ..notes = _notes.text;
    if (_draft.title.trim().isEmpty) {
      toast('Give the video a working title');
      return;
    }
    final v = widget.video;
    final publishing = _draft.stage == VideoStage.published &&
        (v == null || v.stage != VideoStage.published);
    if (publishing && _draft.youtubeUrl.trim().isEmpty) {
      setState(() => _urlMissing = true);
      return;
    }
    if (v == null) {
      store.createVideo(_draft);
    } else {
      store.updateVideo(v, _draft);
    }
    Navigator.pop(context);
  }

  Future<void> _delete(Video v) async {
    final store = StoreScope.read(context);
    final navigator = Navigator.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete this video?',
      message: '“${v.title}” and its history will be removed from the pipeline.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    store.deleteVideo(v);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final original = widget.video;
    final live = original == null
        ? null
        : store.videos.where((v) => v.id == original.id).firstOrNull ??
            original;
    final people = [...store.activeUsers]..sort((a, b) {
        final ay = a.dept == Dept.youtube ? 0 : 1;
        final by = b.dept == Dept.youtube ? 0 : 1;
        return ay != by
            ? ay.compareTo(by)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final series = store.seriesOptions;

    return DialogFrame(
      title: live == null ? 'New video' : 'Video',
      subtitle: live == null
          ? null
          : 'Added by ${store.nameOf(live.createdBy)} · ${fmtDay(live.createdAt)}',
      leadingActions: [
        if (live != null && store.isManager)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: C.danger),
            onPressed: () => _delete(live),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: C.danger),
            label: const Text('Delete'),
          ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(live == null ? 'Add video' : 'Save changes'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            autofocus: live == null,
            style: tx(17, w: FontWeight.w700),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Working title'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Stage', style: tx(12.5, w: FontWeight.w700, color: C.muted)),
              const Spacer(),
              if (live != null && live.stage == _draft.stage)
                StageAge(live)
              else if (live != null)
                Text('Will move from ${live.stage.label}',
                    style: tx(12.5, w: FontWeight.w600, color: C.brandDeep)),
            ],
          ),
          const SizedBox(height: 10),
          StageStepper(
            stage: _draft.stage,
            onChanged: (s) => setState(() {
              _draft.stage = s;
              _urlMissing = false;
            }),
          ),
          const SizedBox(height: 20),
          FieldRow(children: [
            Labeled(
              'Series',
              child: SelectField<String>(
                value: _draft.series,
                options: series,
                textOf: (s) => s,
                leadingOf: (s) => Dot(seedColor(s ?? '')),
                onChanged: (v) => setState(() => _draft.series = v!),
              ),
            ),
            Labeled(
              'Format',
              child: ChipChoice<VideoFormat>(
                values: VideoFormat.values,
                selected: _draft.format,
                labelOf: (f) => f == VideoFormat.long ? 'Long video' : 'Short',
                iconOf: (f) => f == VideoFormat.short
                    ? Icons.stay_current_portrait_rounded
                    : Icons.tv_rounded,
                colorOf: (_) => C.youtube,
                onChanged: (f) => setState(() => _draft.format = f),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Owner',
              child: SelectField<String>(
                value: _draft.assigneeId,
                options: [for (final u in people) u.id],
                textOf: store.nameOf,
                leadingOf: (id) =>
                    Avatar(store.userById(id), size: 22, tooltip: false),
                noneLabel: 'Unassigned',
                onChanged: (v) => setState(() => _draft.assigneeId = v),
              ),
            ),
            Labeled(
              'Publish date',
              child: DateField(
                value: _draft.publishAt,
                hint: 'Not scheduled',
                onChanged: (v) => setState(() => _draft.publishAt = v),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Labeled(
            'YouTube link',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() => _urlMissing = false),
                    decoration: InputDecoration(
                      hintText: 'https://youtu.be/…',
                      errorText: _urlMissing
                          ? 'Add the link before marking it published'
                          : null,
                    ),
                  ),
                ),
                if (_url.text.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => openExternal(_url.text),
                    icon: const Icon(Icons.play_arrow_rounded,
                        size: 18, color: C.youtube),
                    label: Text(isPhone(context) ? 'Open' : 'Open on YouTube'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Labeled(
            'Notes',
            child: TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'Script link, references, feedback…'),
            ),
          ),
          if (live != null && live.history.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('History', style: tx(14, w: FontWeight.w800)),
            const SizedBox(height: 12),
            _HistoryTimeline(video: live),
          ],
        ],
      ),
    );
  }
}

/// Eight tappable steps showing how far along the pipeline a video is.
class StageStepper extends StatelessWidget {
  const StageStepper({super.key, required this.stage, required this.onChanged});

  final VideoStage stage;
  final ValueChanged<VideoStage> onChanged;

  @override
  Widget build(BuildContext context) {
    const stages = VideoStage.values;
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth < 560 ? 560.0 : c.maxWidth;
      final strip = SizedBox(
        width: width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in stages)
              Expanded(
                child: _Step(
                  stage: s,
                  current: stage,
                  onTap: () => onChanged(s),
                ),
              ),
          ],
        ),
      );
      if (c.maxWidth >= 560) return strip;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: strip,
      );
    });
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.stage, required this.current, required this.onTap});

  final VideoStage stage;
  final VideoStage current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = stage.index < current.index;
    final active = stage == current;
    final color = stageColor(current);
    Widget line(bool filled, bool visible) => Expanded(
          child: Container(
            height: 3,
            color: !visible
                ? Colors.transparent
                : (filled ? color : C.hairline),
          ),
        );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  line(done || active, stage.index > 0),
                  AnimatedContainer(
                    duration: kMotion,
                    width: active ? 26 : 18,
                    height: active ? 26 : 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || active ? color : C.surface,
                      border: Border.all(
                        color: done || active ? color : C.hairlineStrong,
                        width: 2,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 12, color: Colors.white)
                        : active
                            ? Center(
                                child: Text('${stage.index + 1}',
                                    style: tx(12,
                                        w: FontWeight.w800,
                                        color: Colors.white,
                                        h: 1)),
                              )
                            : null,
                  ),
                  line(done, stage.index < VideoStage.values.length - 1),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stage.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tx(11.5,
                  w: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? C.text : (done ? C.muted : C.faint)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final events = video.history.reversed.toList();
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Dot(stageColor(events[i].stage), size: 10),
                      if (i < events.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: C.hairline,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: store.nameOf(events[i].by),
                                style: tx(13.5, w: FontWeight.w700)),
                            TextSpan(
                                text: i == events.length - 1
                                    ? ' added it at '
                                    : ' moved it to ',
                                style: tx(13.5, color: C.muted)),
                            TextSpan(
                                text: events[i].stage.label,
                                style: tx(13.5, w: FontWeight.w700)),
                          ]),
                        ),
                        const SizedBox(height: 2),
                        Text(fmtWhen(events[i].at),
                            style: tx(12, color: C.faint)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
