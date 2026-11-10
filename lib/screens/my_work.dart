import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calls.dart';
import 'tasks.dart';
import 'videos.dart';

class MyWorkScreen extends StatelessWidget {
  const MyWorkScreen({super.key});

  static String _greeting(DateTime now) => now.hour < 12
      ? 'Good morning'
      : now.hour < 17
          ? 'Good afternoon'
          : 'Good evening';

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.me!;
    final now = DateTime.now();
    final g = gutter(context);

    final myTasks = store.tasks
        .where((t) => t.isOpen && t.assigneeId == me.id)
        .toList()
      ..sort(compareTasksByDue);
    final overdue = myTasks.where((t) => t.isOverdue(now)).length;
    final dueToday = myTasks.where((t) => t.isDueToday(now)).length;
    final myVideos = store.videos
        .where((v) => v.assigneeId == me.id && !v.isPublished)
        .toList()
      ..sort((a, b) => a.stageSince.compareTo(b.stageSince));
    final due = store.canCalls ? followUpsDue(store, now) : const <Lead>[];
    final showCalls = me.dept == Dept.marketing;
    // Managers from other teams only see these sections when they hold work.
    final showVideos =
        store.canVideos && (me.dept == Dept.youtube || myVideos.isNotEmpty);
    final showFollowUps = showCalls || due.isNotEmpty;

    final summary = [
      if (overdue > 0) '$overdue overdue',
      if (dueToday > 0) '$dueToday due today',
      if (overdue == 0 && dueToday == 0)
        myTasks.isEmpty
            ? 'nothing due'
            : plural(myTasks.length, 'open task'),
    ].join(' · ');

    final tasksSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel('My tasks', count: myTasks.length),
        if (!store.loaded('tasks'))
          const SkeletonList(rows: 4)
        else
          Panel(
            padding: EdgeInsets.zero,
            child: myTasks.isEmpty
                ? EmptyState(
                    compact: true,
                    icon: Icons.task_alt_rounded,
                    title: 'Nothing on your plate',
                    message:
                        'Tasks assigned to you show up here, soonest due date '
                        'first.',
                    actionLabel: 'New task',
                    onAction: () =>
                        showTaskDialog(context, assigneeId: me.id),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < myTasks.length; i++)
                        _MyTaskRow(myTasks[i],
                            divider: i < myTasks.length - 1),
                    ],
                  ),
          ),
      ],
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showVideos) ...[
          SectionLabel('My videos', count: myVideos.length),
          Panel(
            padding: EdgeInsets.zero,
            child: myVideos.isEmpty
                ? const EmptyState(
                    compact: true,
                    icon: Icons.movie_outlined,
                    title: 'No videos with you',
                    message:
                        'Videos you own in the pipeline appear here with how '
                        'long they’ve been in their current stage.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < myVideos.length; i++)
                        _MyVideoRow(myVideos[i],
                            divider: i < myVideos.length - 1),
                    ],
                  ),
          ),
          if (showFollowUps) const SizedBox(height: 28),
        ],
        if (showFollowUps) ...[
          SectionLabel('Follow-ups due', count: due.length),
          Panel(
            padding: EdgeInsets.zero,
            child: due.isEmpty
                ? const EmptyState(
                    compact: true,
                    icon: Icons.event_available_rounded,
                    title: 'No follow-ups due',
                    message:
                        'Leads you promised to call back today will be listed '
                        'here.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < due.length; i++)
                        FollowUpRow(due[i], divider: i < due.length - 1),
                    ],
                  ),
          ),
        ],
      ],
    );

    final hasSide = showVideos || showFollowUps;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(
          title: '${_greeting(now)}, ${me.firstName}',
          subtitle: '${fmtLongDay(now)} · $summary',
          actions: [
            OutlinedButton.icon(
              onPressed: () => showTaskDialog(context, assigneeId: me.id),
              icon: const Icon(Icons.add_rounded, size: 18, color: C.text),
              label: const Text('New task'),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: g),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCalls) ...[
                const CallTargetHero(),
                const SizedBox(height: 28),
              ],
              LayoutBuilder(builder: (context, c) {
                if (!hasSide) return tasksSection;
                if (c.maxWidth < 920) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Callers work their follow-ups first on a phone.
                      if (showCalls) ...[side, const SizedBox(height: 28)],
                      tasksSection,
                      if (!showCalls) ...[const SizedBox(height: 28), side],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: tasksSection),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: side),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyTaskRow extends StatelessWidget {
  const _MyTaskRow(this.task, {required this.divider});

  final Task task;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return ListRow(
      divider: divider,
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
      onTap: () => showTaskDialog(context, task: task),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mark as done',
            onPressed: () => store.setTaskStatus(task, TaskStatus.done),
            icon: const Icon(Icons.radio_button_unchecked_rounded,
                size: 22, color: C.faint),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  PriorityMark(task.priority),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tx(14, w: FontWeight.w600, h: 1.35)),
                  ),
                ]),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ProjectTag(task),
                    if (task.dueAt != null) DueChip(task),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusPill(task),
        ],
      ),
    );
  }
}

class _MyVideoRow extends StatelessWidget {
  const _MyVideoRow(this.video, {required this.divider});

  final Video video;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      divider: divider,
      onTap: () => showVideoDialog(context, video: video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tx(14, w: FontWeight.w600, h: 1.35)),
            ),
            const SizedBox(width: 10),
            Tag(video.stage.label, color: stageColor(video.stage)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Flexible(child: StageAge(video)),
            if (video.publishAt != null) ...[
              const SizedBox(width: 10),
              Text('Publish ${fmtDue(video.publishAt!)}',
                  style: tx(12.5, w: FontWeight.w600, color: C.muted)),
            ],
          ]),
          const SizedBox(height: 8),
          Bar(video.progress, color: stageColor(video.stage), height: 3),
        ],
      ),
    );
  }
}
