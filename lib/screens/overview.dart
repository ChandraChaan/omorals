import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shell.dart';
import 'tasks.dart';
import 'team.dart';
import 'videos.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final shell = ShellScope.of(context);
    final now = DateTime.now();
    final g = gutter(context);

    final openTasks = store.tasks.where((t) => t.isOpen).toList();
    final overdueTasks = openTasks.where((t) => t.isOverdue(now)).toList();
    final inProduction =
        store.videos.where((v) => v.stage.inProduction).length;
    final publishedThisMonth = store.videos
        .where((v) =>
            v.isPublished &&
            v.stageSince.year == now.year &&
            v.stageSince.month == now.month)
        .length;
    final callsToday = store.calls.where((c) => sameDay(c.at, now)).length;
    final teamTarget = store.activeUsers
        .where((u) => u.dept == Dept.marketing)
        .fold<int>(0, (sum, u) => sum + u.dailyCallTarget);
    final followUpsDue = store.leads.where((l) => l.followUpDue(now)).length;
    final followUpsOverdue =
        store.leads.where((l) => l.followUpOverdue(now)).length;
    final newEnquiries = store.inquiries.where((q) => q.isNew).length;

    final ready = store.loaded('tasks') &&
        store.loaded('videos') &&
        store.loaded('users');

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(
          title: 'Overview',
          subtitle: '${fmtLongDay(now)} · OMorals Media',
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: g),
          child: !ready
              ? const SkeletonList(rows: 5, height: 88)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResponsiveGrid(
                      minItemWidth: 148,
                      children: [
                        KpiCard(
                          label: 'Open tasks',
                          value: '${openTasks.length}',
                          icon: Icons.view_kanban_outlined,
                          hint:
                              '${openTasks.where((t) => t.status == TaskStatus.review).length} in review',
                          onTap: () => shell.go(Dest.tasks),
                        ),
                        KpiCard(
                          label: 'Overdue tasks',
                          value: '${overdueTasks.length}',
                          icon: Icons.warning_amber_rounded,
                          color: overdueTasks.isEmpty ? C.text : C.danger,
                          hint: overdueTasks.isEmpty
                              ? 'Everything on time'
                              : 'Past their due date',
                          onTap: () => shell.go(Dest.tasks),
                        ),
                        KpiCard(
                          label: 'In production',
                          value: '$inProduction',
                          icon: Icons.movie_outlined,
                          hint:
                              '${plural(inProduction, 'video')} being made',
                          onTap: () => shell.go(Dest.videos),
                        ),
                        KpiCard(
                          label: 'Published',
                          value: '$publishedThisMonth',
                          icon: Icons.rocket_launch_outlined,
                          color: publishedThisMonth > 0 ? C.success : C.text,
                          hint: 'Videos this month',
                          onTap: () => shell.go(Dest.videos),
                        ),
                        KpiCard(
                          label: 'Calls today',
                          value: '$callsToday',
                          icon: Icons.call_outlined,
                          hint: teamTarget > 0
                              ? 'Team target $teamTarget'
                              : 'No targets set',
                          onTap: () => shell.go(Dest.calls),
                        ),
                        KpiCard(
                          label: 'Follow-ups due',
                          value: '$followUpsDue',
                          icon: Icons.event_repeat_rounded,
                          color: followUpsOverdue > 0 ? C.danger : C.text,
                          hint: followUpsOverdue > 0
                              ? '$followUpsOverdue overdue'
                              : 'None overdue',
                          onTap: () => shell.go(Dest.calls),
                        ),
                        KpiCard(
                          label: 'New enquiries',
                          value: '$newEnquiries',
                          icon: Icons.mark_email_unread_outlined,
                          color: newEnquiries > 0 ? C.brand : C.text,
                          hint: 'From the website',
                          onTap: () => shell.go(Dest.calls),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const SectionLabel('Video pipeline'),
                    const _PipelineStrip(),
                    const SizedBox(height: 28),
                    const SectionLabel('Team pulse'),
                    const _TeamPulse(),
                    const SizedBox(height: 28),
                    LayoutBuilder(builder: (context, c) {
                      const attention = _NeedsAttention();
                      const feed = _ActivityPanel();
                      if (c.maxWidth < 920) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            attention,
                            SizedBox(height: 28),
                            feed,
                          ],
                        );
                      }
                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: attention),
                          SizedBox(width: 24),
                          Expanded(child: feed),
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

// ---------------------------------------------------------------------------
// Pipeline strip
// ---------------------------------------------------------------------------

class _PipelineStrip extends StatelessWidget {
  const _PipelineStrip();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final counts = {
      for (final s in VideoStage.values)
        s: store.videos.where((v) {
          if (v.stage != s) return false;
          // Published only counts this month so the bar stays meaningful.
          return s != VideoStage.published ||
              (v.stageSince.year == now.year && v.stageSince.month == now.month);
        }).length,
    };
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return Panel(
      onTap: () => ShellScope.of(context).go(Dest.videos),
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No videos in the pipeline yet. Add one from the Videos page.',
                style: tx(13.5, color: C.muted),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        for (final s in VideoStage.values)
                          if (counts[s]! > 0)
                            Expanded(
                              flex: counts[s]!,
                              child: Tooltip(
                                message: '${s.label}: ${counts[s]}',
                                child: Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  color: stageColor(s),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    for (final s in VideoStage.values)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Dot(stageColor(s)),
                          const SizedBox(width: 6),
                          Text(s.label,
                              style: tx(12.5,
                                  w: FontWeight.w600, color: C.muted)),
                          const SizedBox(width: 6),
                          Text('${counts[s]}',
                              style: tx(13,
                                  w: FontWeight.w800,
                                  color:
                                      counts[s] == 0 ? C.faint : C.text)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team pulse
// ---------------------------------------------------------------------------

class _Pulse {
  _Pulse({
    required this.user,
    required this.open,
    required this.done7,
    required this.overdue,
    required this.videos,
    required this.callsToday,
    required this.lastActive,
  });

  final AppUser user;
  final int open;
  final int done7;
  final int overdue;
  final int videos;
  final int callsToday;
  final DateTime? lastActive;
}

class _TeamPulse extends StatelessWidget {
  const _TeamPulse();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final rows = <_Pulse>[];
    for (final u in store.activeUsers) {
      final mine = store.tasks.where((t) => t.assigneeId == u.id).toList();
      DateTime? last = u.lastSeenAt;
      for (final a in store.activity) {
        if (a.actorId == u.id && (last == null || a.at.isAfter(last))) {
          last = a.at;
        }
      }
      rows.add(_Pulse(
        user: u,
        open: mine.where((t) => t.isOpen).length,
        done7: mine
            .where((t) =>
                t.completedAt != null && t.completedAt!.isAfter(weekAgo))
            .length,
        overdue: mine.where((t) => t.isOverdue(now)).length,
        videos: store.videos
            .where((v) => v.assigneeId == u.id && !v.isPublished)
            .length,
        callsToday: store.calls
            .where((c) => c.callerId == u.id && sameDay(c.at, now))
            .length,
        lastActive: last,
      ));
    }
    rows.sort((a, b) {
      final d = a.user.dept.index.compareTo(b.user.dept.index);
      return d != 0
          ? d
          : a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase());
    });

    Widget count(int v, {Color? alert}) => cellText(
          '$v',
          strong: v > 0,
          color: v == 0 ? C.faint : (alert ?? C.text),
        );

    return AppTable<_Pulse>(
      minWidth: 980,
      rowHeight: 58,
      rows: rows,
      onTap: (r) => showMemberProfile(context, r.user),
      columns: [
        Col('Member', flex: 3,
            (r) => UserLabel(r.user, size: 30, subtitle: r.user.title)),
        Col('Team', width: 140, (r) => DeptTag(r.user.dept)),
        Col('Open', width: 64, end: true, (r) => count(r.open)),
        Col('Done · 7d', width: 84, end: true,
            (r) => count(r.done7, alert: C.success)),
        Col('Overdue', width: 78, end: true,
            (r) => count(r.overdue, alert: C.danger)),
        Col('Videos', width: 70, end: true, (r) => count(r.videos)),
        Col('Calls today', width: 170, (r) {
          final callsMatter =
              r.user.dept == Dept.marketing || r.callsToday > 0;
          if (!callsMatter) return cellText('—', color: C.faint);
          final target = r.user.dailyCallTarget;
          final ratio = target == 0 ? 0.0 : r.callsToday / target;
          return Row(children: [
            SizedBox(
              width: 56,
              child: Text('${r.callsToday}/$target',
                  style: tx(13, w: FontWeight.w700)),
            ),
            Expanded(
              child: Bar(ratio,
                  color: ratio >= 1 ? C.success : C.marketing),
            ),
          ]);
        }),
        Col(
            'Last active',
            width: 110,
            (r) => cellText(r.lastActive == null ? '—' : ago(r.lastActive!),
                color: C.muted)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Needs attention
// ---------------------------------------------------------------------------

class _Alert {
  _Alert(this.icon, this.color, this.title, this.detail, this.onTap);

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final VoidCallback onTap;
}

class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention();

  static const _cap = 10;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final shell = ShellScope.of(context);
    final now = DateTime.now();
    final alerts = <_Alert>[];

    final pending = store.pendingUsers;
    if (pending.isNotEmpty) {
      alerts.add(_Alert(
        Icons.how_to_reg_outlined,
        C.brand,
        pending.length == 1
            ? '${pending.first.name} is waiting for approval'
            : '${pending.length} people are waiting for approval',
        store.isAdmin
            ? 'Approve them on the Team page'
            : 'An admin can approve them on the Team page',
        () => shell.go(Dest.team),
      ));
    }

    final fresh = store.inquiries.where((q) => q.isNew).length;
    if (fresh > 0) {
      alerts.add(_Alert(
        Icons.mark_email_unread_outlined,
        C.brand,
        '${plural(fresh, 'website enquiry', 'website enquiries')} to answer',
        'Convert to a lead or dismiss',
        () => shell.go(Dest.calls),
      ));
    }

    final overdue = store.tasks.where((t) => t.isOverdue(now)).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    for (final t in overdue) {
      final days = daysBetween(t.dueAt!, now);
      alerts.add(_Alert(
        Icons.warning_amber_rounded,
        C.danger,
        t.title,
        '${plural(days, 'day')} overdue · '
            '${t.assigneeId == null ? 'Unassigned' : store.nameOf(t.assigneeId)}',
        () => showTaskDialog(context, task: t),
      ));
    }

    final stuck = store.videos.where((v) => v.isStuck(now)).toList()
      ..sort((a, b) => a.stageSince.compareTo(b.stageSince));
    for (final v in stuck) {
      alerts.add(_Alert(
        Icons.hourglass_bottom_rounded,
        v.staleness(now) == 2 ? C.danger : C.warn,
        v.title,
        '${v.daysInStage(now)} days in ${v.stage.label} · '
            '${v.assigneeId == null ? 'Unassigned' : store.nameOf(v.assigneeId)}',
        () => showVideoDialog(context, video: v),
      ));
    }

    final late = <String, int>{};
    for (final l in store.leads.where((l) => l.followUpOverdue(now))) {
      late[l.ownerId] = (late[l.ownerId] ?? 0) + 1;
    }
    final owners = late.keys.toList()
      ..sort((a, b) => late[b]!.compareTo(late[a]!));
    for (final id in owners) {
      alerts.add(_Alert(
        Icons.event_busy_outlined,
        C.warn,
        '${store.nameOf(id)} has ${plural(late[id]!, 'overdue follow-up')}',
        'Leads waiting for a call back',
        () => shell.go(Dest.calls),
      ));
    }

    final shown = alerts.take(_cap).toList();
    final hidden = alerts.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel('Needs attention', count: alerts.length),
        Panel(
          padding: EdgeInsets.zero,
          child: alerts.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: Icons.verified_outlined,
                  title: 'All clear',
                  message:
                      'No overdue tasks, stuck videos or missed follow-ups '
                      'right now.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      ListRow(
                        divider: i < shown.length - 1 || hidden > 0,
                        onTap: shown[i].onTap,
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: tint(shown[i].color, 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(shown[i].icon,
                                size: 17,
                                color:
                                    Color.lerp(shown[i].color, C.ink, 0.2)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shown[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tx(14, w: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(shown[i].detail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tx(12.5, color: C.muted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: C.faint),
                        ]),
                      ),
                    if (hidden > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('+ $hidden more',
                              style: tx(13,
                                  w: FontWeight.w700, color: C.muted)),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Activity
// ---------------------------------------------------------------------------

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final items = store.activity.take(14).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Recent activity'),
        Panel(
          padding: EdgeInsets.zero,
          child: items.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: Icons.history_rounded,
                  title: 'Quiet so far',
                  message:
                      'As the team creates tasks, moves videos and logs '
                      'calls, it shows up here.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      ListRow(
                        divider: i < items.length - 1,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Avatar(store.userById(items[i].actorId), size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                      text: store.nameOf(items[i].actorId),
                                      style: tx(13.5, w: FontWeight.w700)),
                                  TextSpan(
                                      text: ' ${items[i].text}',
                                      style: tx(13.5, color: C.muted, h: 1.4)),
                                ]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(activityIcon(items[i].kind),
                                size: 14,
                                color: activityColor(items[i].kind)),
                            const SizedBox(width: 6),
                            Text(ago(items[i].at),
                                style: tx(12, color: C.faint)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
