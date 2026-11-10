import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'call_dialogs.dart';

enum _Tab {
  today('Today'),
  leads('Leads'),
  log('Call log'),
  scoreboard('Scoreboard'),
  enquiries('Website enquiries');

  const _Tab(this.label);
  final String label;
}

enum CallRange {
  today('Today', 1),
  week('7 days', 7),
  month('30 days', 30);

  const CallRange(this.label, this.days);
  final String label;
  final int days;

  bool contains(DateTime at, DateTime now) {
    final back = daysBetween(at, now);
    return back >= 0 && back < days;
  }
}

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  _Tab? _chosen;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    // Callers land on their day; managers from other teams on the scoreboard.
    final home = store.me?.dept == Dept.marketing || !store.isManager
        ? _Tab.today
        : _Tab.scoreboard;
    final wanted = _chosen ?? home;
    final tabs = [
      _Tab.today,
      _Tab.leads,
      _Tab.log,
      if (store.isManager) ...[_Tab.scoreboard, _Tab.enquiries],
    ];
    final tab = tabs.contains(wanted) ? wanted : _Tab.today;
    final callsToday = store.calls.where((c) => sameDay(c.at, now)).length;
    final newEnquiries = store.inquiries.where((q) => q.isNew).length;
    final g = gutter(context);
    final ready = store.loaded('leads') && store.loaded('calls');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Calls & leads',
          subtitle: store.isManager
              ? '${plural(callsToday, 'call')} logged by the team today'
              : '${plural(callsToday, 'call')} logged today',
          actions: [
            FilledButton.icon(
              onPressed: () => showLogCallDialog(context),
              icon: const Icon(Icons.add_call, size: 18),
              label: const Text('Log a call'),
            ),
          ],
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: C.hairline)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: g - 10),
            child: Row(
              children: [
                for (final t in tabs)
                  _TabButton(
                    label: t.label,
                    active: t == tab,
                    badge: t == _Tab.enquiries ? newEnquiries : 0,
                    onTap: () => setState(() => _chosen = t),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: !ready
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: g),
                  child: const SkeletonList(rows: 6, height: 56),
                )
              : AnimatedSwitcher(
                  duration: kMotion,
                  child: KeyedSubtree(
                    key: ValueKey(tab),
                    child: switch (tab) {
                      _Tab.today => const _TodayTab(),
                      _Tab.leads => const _LeadsTab(),
                      _Tab.log => const _LogTab(),
                      _Tab.scoreboard => const _ScoreboardTab(),
                      _Tab.enquiries => const _EnquiriesTab(),
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: kMotion,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? C.brand : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: tx(14,
                      w: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? C.text : C.muted)),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                CountPill(badge, color: C.brand),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today
// ---------------------------------------------------------------------------

/// Ring + headline for "calls today vs target". Shared with My work.
class CallTargetHero extends StatelessWidget {
  const CallTargetHero({super.key, this.showAction = true});

  /// Whether to include the big "Log a call" button.
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.me!;
    final now = DateTime.now();
    final made = store.calls
        .where((c) => c.callerId == me.id && sameDay(c.at, now))
        .length;
    final target = me.dailyCallTarget;
    final left = target - made;
    final hit = target > 0 && left <= 0;
    final summary = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Ring(
          value: target == 0 ? 0 : made / target,
          size: 88,
          stroke: 9,
          color: hit ? C.success : C.marketing,
          child: Text('$made', style: dx(26)),
        ),
        const SizedBox(width: 18),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CALLS TODAY', style: eyebrow()),
              const SizedBox(height: 6),
              Text(target > 0 ? '$made of $target' : '$made', style: dx(26)),
              const SizedBox(height: 4),
              Text(
                target == 0
                    ? 'No daily target set'
                    : hit
                        ? 'Target reached — great work'
                        : '$left to go to hit today’s target',
                style: tx(13.5,
                    w: FontWeight.w600, color: hit ? C.success : C.muted),
              ),
            ],
          ),
        ),
      ],
    );
    final action = FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(180, 54),
        textStyle: tx(15.5, w: FontWeight.w800),
      ),
      onPressed: () => showLogCallDialog(context),
      icon: const Icon(Icons.add_call, size: 20),
      label: const Text('Log a call'),
    );
    return Panel(
      padding: const EdgeInsets.all(20),
      child: !showAction
          ? Align(alignment: Alignment.centerLeft, child: summary)
          : isPhone(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: summary),
                    const SizedBox(height: 16),
                    action,
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: summary,
                      ),
                    ),
                    const SizedBox(width: 20),
                    action,
                  ],
                ),
    );
  }
}

/// A lead whose follow-up is due, with one-tap Call and Log.
class FollowUpRow extends StatelessWidget {
  const FollowUpRow(this.lead, {super.key, this.divider = true});

  final Lead lead;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      divider: divider,
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      onTap: () => showLeadDialog(context, lead: lead),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(14, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(children: [
                  FollowUpLabel(lead),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      lead.company ?? lead.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tx(12.5, color: C.muted),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Call ${lead.phone}',
            style: IconButton.styleFrom(
              backgroundColor: tint(C.marketing, 0.12),
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusSm)),
            ),
            onPressed: () => dial(lead.phone),
            icon: const Icon(Icons.call_rounded, size: 20, color: C.marketing),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(56, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () => showLogCallDialog(context, lead: lead),
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}

List<Lead> followUpsDue(AppStore store, DateTime now) =>
    store.leads.where((l) => l.ownerId == store.uid && l.followUpDue(now)).toList()
      ..sort((a, b) => a.nextFollowUpAt!.compareTo(b.nextFollowUpAt!));

class _TodayTab extends StatelessWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final mine = store.calls.where((c) => c.callerId == store.uid).toList();
    final stats = CallStats(mine.where((c) => sameDay(c.at, now)));
    final due = followUpsDue(store, now);
    final overdue = due.where((l) => l.followUpOverdue(now)).length;
    final recent = mine.take(8).toList();
    final g = gutter(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(g, 0, g, 32),
      children: [
        const CallTargetHero(showAction: false),
        const SizedBox(height: 12),
        if (isPhone(context))
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Total('Connect rate',
                    stats.total == 0 ? '—' : pct(stats.connectRate)),
                _Total('Talk time', fmtMinutes(stats.talkMin)),
                _Total('Follow-ups', '${due.length}',
                    color: overdue > 0 ? C.danger : C.text),
              ],
            ),
          )
        else
          ResponsiveGrid(
            minItemWidth: 160,
            children: [
              KpiCard(
                label: 'Connect rate',
                value: stats.total == 0 ? '—' : pct(stats.connectRate),
                icon: Icons.call_made_rounded,
                hint: '${stats.connected} of ${stats.total} reached',
              ),
              KpiCard(
                label: 'Talk time',
                value: fmtMinutes(stats.talkMin),
                icon: Icons.timer_outlined,
                hint: stats.connected == 0
                    ? 'No conversations yet'
                    : '${(stats.talkMin / stats.connected).toStringAsFixed(1)} min per conversation',
              ),
              KpiCard(
                label: 'Follow-ups due',
                value: '${due.length}',
                icon: Icons.event_repeat_rounded,
                color: overdue > 0 ? C.danger : C.text,
                hint: overdue > 0 ? '$overdue overdue' : 'Nothing overdue',
              ),
            ],
          ),
        const SizedBox(height: 28),
        SectionLabel('Follow-ups due', count: due.length),
        Panel(
          padding: EdgeInsets.zero,
          child: due.isEmpty
              ? const EmptyState(
                  compact: true,
                  icon: Icons.event_available_rounded,
                  title: 'You’re all caught up',
                  message:
                      'Set a follow-up date when you log a call and it will '
                      'appear here on the day.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < due.length; i++)
                      FollowUpRow(due[i], divider: i < due.length - 1),
                  ],
                ),
        ),
        const SizedBox(height: 28),
        const SectionLabel('My recent calls'),
        Panel(
          padding: EdgeInsets.zero,
          child: recent.isEmpty
              ? EmptyState(
                  compact: true,
                  icon: Icons.call_outlined,
                  title: 'No calls logged yet',
                  message:
                      'Log each call right after you hang up — it takes a few '
                      'seconds and keeps your numbers honest.',
                  actionLabel: 'Log a call',
                  onAction: () => showLogCallDialog(context),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      CallTile(recent[i], divider: i < recent.length - 1),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Leads
// ---------------------------------------------------------------------------

class _LeadsTab extends StatefulWidget {
  const _LeadsTab();

  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab> {
  String _query = '';
  LeadStatus? _status;
  String? _ownerId;
  LeadService? _service;

  bool _matches(Lead l) {
    if (_status != null && l.status != _status) return false;
    if (_ownerId != null && l.ownerId != _ownerId) return false;
    if (_service != null && l.service != _service) return false;
    if (_query.isEmpty) return true;
    final digits = phoneDigits(_query);
    return l.name.toLowerCase().contains(_query) ||
        (l.company ?? '').toLowerCase().contains(_query) ||
        (digits.length >= 3 && phoneDigits(l.phone).contains(digits));
  }

  void _paste() => showAppDialog<void>(context,
      maxWidth: 640,
      dismissible: false,
      builder: (_) => const PasteLeadsDialog());

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final g = gutter(context);
    final rows = store.leads.where(_matches).toList();

    Widget body;
    if (store.leads.isEmpty) {
      body = EmptyState(
        icon: Icons.contact_phone_outlined,
        title: 'No leads yet',
        message: store.isManager
            ? 'Add leads one by one, or paste a whole list and assign it to a '
                'caller in one go.'
            : 'Add the people you’re calling, or paste a list. Leads assigned '
                'to you by a manager appear here too.',
        actionLabel: 'Paste leads',
        onAction: _paste,
      );
    } else if (rows.isEmpty) {
      body = const EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Nothing matches',
        message: 'No leads match these filters. Try clearing one of them.',
      );
    } else if (isPhone(context)) {
      body = ListView.separated(
        padding: EdgeInsets.fromLTRB(g, 0, g, 24),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _LeadCard(rows[i]),
      );
    } else {
      body = Padding(
        padding: EdgeInsets.fromLTRB(g, 0, g, 24),
        child: AppTable<Lead>(
          shrinkWrap: false,
          minWidth: store.isManager ? 1040 : 880,
          rowHeight: 58,
          rows: rows,
          onTap: (l) => showLeadDialog(context, lead: l),
          columns: [
            Col('Lead', flex: 3, (l) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    cellText(l.name, strong: true),
                    if (l.company != null)
                      Text(l.company!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tx(12.5, color: C.muted)),
                  ],
                )),
            Col('Phone', width: 150, (l) => cellText(l.phone)),
            Col('Status', width: 120, (l) => LeadStatusTag(l.status)),
            Col('Service', width: 120,
                (l) => cellText(l.service.label, color: C.muted)),
            if (store.isManager)
              Col('Owner', flex: 2,
                  (l) => UserLabel(store.userById(l.ownerId))),
            Col('Calls', width: 64, end: true,
                (l) => cellText('${l.callCount}')),
            Col(
                'Last call',
                width: 110,
                (l) => cellText(
                    l.lastCallAt == null ? 'Never' : ago(l.lastCallAt!),
                    color: l.lastCallAt == null ? C.faint : C.muted)),
            Col('Follow-up', width: 130, (l) => FollowUpLabel(l)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(children: [
          SearchBox(
            hint: 'Search leads',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          FilterMenu<LeadStatus>(
            label: 'Status',
            value: _status,
            options: LeadStatus.values,
            textOf: (s) => s.label,
            onChanged: (v) => setState(() => _status = v),
          ),
          if (store.isManager)
            FilterMenu<String>(
              label: 'Owner',
              value: _ownerId,
              options: [for (final u in store.callers) u.id],
              textOf: store.nameOf,
              onChanged: (v) => setState(() => _ownerId = v),
            ),
          FilterMenu<LeadService>(
            label: 'Service',
            value: _service,
            options: LeadService.values,
            textOf: (s) => s.label,
            onChanged: (v) => setState(() => _service = v),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => showLeadDialog(context),
            icon: const Icon(Icons.person_add_alt_1_outlined,
                size: 16, color: C.text),
            label: const Text('Add lead'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: _paste,
            icon: const Icon(Icons.content_paste_rounded,
                size: 16, color: C.text),
            label: const Text('Paste leads'),
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(g, 0, g, 10),
          child: Text(
            '${plural(rows.length, 'lead')}'
            '${rows.length != store.leads.length ? ' of ${store.leads.length}' : ''}',
            style: tx(12.5, w: FontWeight.w600, color: C.muted),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard(this.lead);

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      onTap: () => showLeadDialog(context, lead: lead),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(14.5, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [lead.phone, if (lead.company != null) lead.company!]
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tx(12.5, color: C.muted),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  LeadStatusTag(lead.status),
                  const SizedBox(width: 10),
                  if (lead.nextFollowUpAt != null && !lead.status.isClosed)
                    FollowUpLabel(lead)
                  else
                    Text(plural(lead.callCount, 'call'),
                        style: tx(12.5, color: C.muted)),
                ]),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call ${lead.phone}',
            style: IconButton.styleFrom(
              backgroundColor: tint(C.marketing, 0.12),
              minimumSize: const Size(46, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusSm)),
            ),
            onPressed: () => dial(lead.phone),
            icon: const Icon(Icons.call_rounded, size: 20, color: C.marketing),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Call log
// ---------------------------------------------------------------------------

class _LogTab extends StatefulWidget {
  const _LogTab();

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  CallRange _range = CallRange.week;
  String? _agentId;
  CallOutcome? _outcome;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final g = gutter(context);
    final rows = store.calls.where((c) {
      if (!_range.contains(c.at, now)) return false;
      if (_agentId != null && c.callerId != _agentId) return false;
      if (_outcome != null && c.outcome != _outcome) return false;
      return true;
    }).toList();
    final stats = CallStats(rows);
    final manager = store.isManager;

    Widget body;
    if (rows.isEmpty) {
      body = EmptyState(
        icon: Icons.call_outlined,
        title: 'No calls in this view',
        message: store.calls.isEmpty
            ? 'Calls appear here as soon as they’re logged.'
            : 'Try a longer date range or clear the filters.',
        actionLabel: store.calls.isEmpty ? 'Log a call' : null,
        onAction:
            store.calls.isEmpty ? () => showLogCallDialog(context) : null,
      );
    } else if (isPhone(context)) {
      body = Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(g, 0, g, 10),
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Total('Calls', '${stats.total}'),
                  _Total('Connected', pct(stats.connectRate)),
                  _Total('Talk time', fmtMinutes(stats.talkMin)),
                  _Total('With notes', pct(stats.dataQuality)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(g, 0, g, 16),
              child: Panel(
                padding: EdgeInsets.zero,
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) => CallTile(
                    rows[i],
                    showAgent: manager,
                    divider: i < rows.length - 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      Widget total(String text) =>
          Text(text, style: tx(13.5, w: FontWeight.w800));
      body = Padding(
        padding: EdgeInsets.fromLTRB(g, 0, g, 24),
        child: AppTable<CallLog>(
          shrinkWrap: false,
          minWidth: manager ? 1020 : 860,
          rows: rows,
          columns: [
            Col('When', width: 140,
                (c) => cellText(fmtWhen(c.at), color: C.muted)),
            Col('Lead', flex: 3, (c) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    cellText(c.leadName, strong: true),
                    Text(c.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tx(12.5, color: C.muted)),
                  ],
                )),
            if (manager)
              Col('Agent', flex: 2,
                  (c) => UserLabel(store.userById(c.callerId))),
            Col('Outcome', width: 160, (c) => OutcomeTag(c.outcome)),
            Col('Duration', width: 90, end: true,
                (c) => cellText(fmtMinutes(c.durationMin))),
            Col(
                'Notes',
                flex: 4,
                (c) => cellText(
                    c.notes.trim().isEmpty ? 'No notes' : c.notes.trim(),
                    color: c.notes.trim().isEmpty ? C.faint : C.muted)),
          ],
          footer: [
            total('Totals'),
            total(plural(stats.total, 'call')),
            if (manager) const SizedBox.shrink(),
            total('${pct(stats.connectRate)} connected'),
            total(fmtMinutes(stats.talkMin)),
            total('${pct(stats.dataQuality)} with useful notes'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(children: [
          Segmented<CallRange>(
            values: CallRange.values,
            selected: _range,
            labelOf: (r) => r.label,
            onChanged: (r) => setState(() => _range = r),
          ),
          if (manager)
            FilterMenu<String>(
              label: 'Agent',
              value: _agentId,
              options: [for (final u in store.callers) u.id],
              textOf: store.nameOf,
              onChanged: (v) => setState(() => _agentId = v),
            ),
          FilterMenu<CallOutcome>(
            label: 'Outcome',
            value: _outcome,
            options: CallOutcome.values,
            textOf: (o) => o.label,
            onChanged: (v) => setState(() => _outcome = v),
          ),
        ]),
        Expanded(child: body),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.value, {this.color = C.text});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tx(11.5, w: FontWeight.w600, color: C.muted)),
          const SizedBox(height: 2),
          Text(value, style: dx(18, color: color)),
        ],
      );
}

// ---------------------------------------------------------------------------
// Scoreboard
// ---------------------------------------------------------------------------

class _AgentScore {
  _AgentScore(this.user, this.stats, this.leads, this.overdue, this.spark);

  final AppUser user;
  final CallStats stats;
  final int leads;
  final int overdue;
  final List<int> spark;
}

class _ScoreboardTab extends StatefulWidget {
  const _ScoreboardTab();

  @override
  State<_ScoreboardTab> createState() => _ScoreboardTabState();
}

class _ScoreboardTabState extends State<_ScoreboardTab> {
  CallRange _range = CallRange.today;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final g = gutter(context);

    final scores = <_AgentScore>[];
    for (final u in store.users) {
      final theirs = store.calls.where((c) => c.callerId == u.id).toList();
      final leads = store.leads.where((l) => l.ownerId == u.id).toList();
      final relevant = (u.isActive && u.dept == Dept.marketing) ||
          theirs.isNotEmpty ||
          leads.isNotEmpty;
      if (!relevant) continue;
      scores.add(_AgentScore(
        u,
        CallStats(theirs.where((c) => _range.contains(c.at, now))),
        leads.length,
        leads.where((l) => l.followUpOverdue(now)).length,
        callsPerDay(theirs, now),
      ));
    }
    scores.sort((a, b) => b.stats.total.compareTo(a.stats.total));
    final peak = scores.fold<int>(1, (m, s) => s.stats.total > m ? s.stats.total : m);
    final team = callsPerDay(store.calls, now);
    final teamTotal = team.fold<int>(0, (a, b) => a + b);
    final first = dayOf(now).subtract(Duration(days: team.length - 1));

    Widget count(int v, {Color? color}) => cellText('$v',
        color: color ?? (v == 0 ? C.faint : C.text), strong: v > 0);

    return ListView(
      padding: EdgeInsets.fromLTRB(g, 0, g, 32),
      children: [
        Panel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TEAM CALLS · LAST 14 DAYS', style: eyebrow()),
                        const SizedBox(height: 6),
                        Text('$teamTotal', style: dx(30)),
                      ],
                    ),
                  ),
                  Text('${(teamTotal / team.length).toStringAsFixed(1)} per day',
                      style: tx(13, w: FontWeight.w600, color: C.muted)),
                ],
              ),
              const SizedBox(height: 16),
              MiniBars(team, height: 96),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < team.length; i++)
                    Expanded(
                      child: Text(
                        '${first.add(Duration(days: i)).day}',
                        textAlign: TextAlign.center,
                        style: tx(10.5,
                            w: i == team.length - 1
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == team.length - 1 ? C.text : C.faint),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('By agent', style: tx(15, w: FontWeight.w800)),
            ),
            Segmented<CallRange>(
              values: CallRange.values,
              selected: _range,
              labelOf: (r) => r.label,
              onChanged: (r) => setState(() => _range = r),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTable<_AgentScore>(
          minWidth: 1100,
          rowHeight: 60,
          rows: scores,
          empty: const EmptyState(
            compact: true,
            icon: Icons.leaderboard_outlined,
            title: 'No callers yet',
            message:
                'Approve teammates into the Marketing team and their numbers '
                'will show up here.',
          ),
          columns: [
            Col('Agent', flex: 3,
                (s) => UserLabel(s.user, size: 28, subtitle: s.user.title)),
            Col('Calls', width: 130, (s) => Row(children: [
                  SizedBox(
                    width: 34,
                    child: Text('${s.stats.total}',
                        style: tx(14, w: FontWeight.w800)),
                  ),
                  Expanded(
                    child: Bar(s.stats.total / peak, color: C.marketing),
                  ),
                ])),
            Col('Connected', width: 90, end: true,
                (s) => count(s.stats.connected)),
            Col('Rate', width: 60, end: true,
                (s) => cellText(
                    s.stats.total == 0 ? '—' : pct(s.stats.connectRate),
                    color: s.stats.total == 0 ? C.faint : C.text)),
            Col('Interested', width: 90, end: true,
                (s) => count(s.stats.interested)),
            Col('Converted', width: 90, end: true,
                (s) => count(s.stats.converted,
                    color: s.stats.converted > 0 ? C.success : null)),
            Col('Talk time', width: 84, end: true,
                (s) => cellText(fmtMinutes(s.stats.talkMin))),
            Col('Leads', width: 60, end: true, (s) => count(s.leads)),
            Col('Overdue', width: 76, end: true,
                (s) => count(s.overdue, color: s.overdue > 0 ? C.danger : null)),
            Col('Data quality', width: 136, (s) {
              if (s.stats.total == 0) {
                return cellText('—', color: C.faint);
              }
              final q = s.stats.dataQuality;
              final color = q >= 0.8
                  ? C.success
                  : q >= 0.5
                      ? C.warn
                      : C.danger;
              return Row(children: [
                Expanded(child: Bar(q, color: color)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(pct(q),
                      textAlign: TextAlign.end,
                      style: tx(13, w: FontWeight.w700)),
                ),
              ]);
            }),
            Col('14 days', width: 104,
                (s) => MiniBars(s.spark, height: 28)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Data quality is the share of calls with a note of at least '
          '$kGoodNoteLength characters. Overdue counts follow-ups whose date has passed.',
          style: tx(12.5, color: C.muted, h: 1.45),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Website enquiries
// ---------------------------------------------------------------------------

class _EnquiriesTab extends StatefulWidget {
  const _EnquiriesTab();

  @override
  State<_EnquiriesTab> createState() => _EnquiriesTabState();
}

class _EnquiriesTabState extends State<_EnquiriesTab> {
  bool _showHandled = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final g = gutter(context);
    final rows =
        store.inquiries.where((q) => _showHandled || q.isNew).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(g, 0, g, 32),
      children: [
        Row(children: [
          Expanded(
            child: Text(
              'Messages sent from the contact form on the website.',
              style: tx(13.5, color: C.muted),
            ),
          ),
          const SizedBox(width: 12),
          ToggleChip(
            label: 'Show handled',
            selected: _showHandled,
            onChanged: (v) => setState(() => _showHandled = v),
          ),
        ]),
        const SizedBox(height: 16),
        if (!store.loaded('inquiries'))
          const SkeletonList(rows: 3, height: 110)
        else if (rows.isEmpty)
          Panel(
            child: EmptyState(
              compact: true,
              icon: Icons.mark_email_read_outlined,
              title: store.inquiries.isEmpty
                  ? 'No enquiries yet'
                  : 'Inbox zero',
              message: store.inquiries.isEmpty
                  ? 'When someone fills in the contact form on the website, '
                      'their message appears here.'
                  : 'Every website enquiry has been converted or dismissed.',
            ),
          )
        else
          for (final q in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EnquiryCard(q),
            ),
      ],
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard(this.inquiry);

  final Inquiry inquiry;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final q = inquiry;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(q.name, style: tx(15, w: FontWeight.w800)),
              SelectableText(q.contact,
                  style: tx(13.5, w: FontWeight.w600, color: C.muted)),
              if (q.service.trim().isNotEmpty)
                Tag(q.service, color: C.development),
              if (!q.isNew)
                Tag(
                  q.status.label,
                  color: q.status == InquiryStatus.converted
                      ? C.success
                      : C.muted,
                ),
              Text(ago(q.createdAt), style: tx(12.5, color: C.faint)),
            ],
          ),
          if (q.message.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            SelectableText(q.message.trim(),
                style: tx(14, color: C.text, h: 1.5)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (q.isNew) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => showAppDialog<void>(context,
                      maxWidth: 480,
                      builder: (_) => ConvertInquiryDialog(inquiry: q)),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('Convert to lead'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () =>
                      store.setInquiryStatus(q, InquiryStatus.dismissed),
                  child: const Text('Dismiss'),
                ),
              ] else if (q.status == InquiryStatus.dismissed)
                TextButton(
                  onPressed: () =>
                      store.setInquiryStatus(q, InquiryStatus.fresh),
                  child: const Text('Move back to new'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
