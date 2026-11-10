import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tasks.dart';
import 'videos.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _query = '';
  Dept? _dept;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final g = gutter(context);
    final admin = store.isAdmin;
    final pending = store.pendingUsers;
    final disabled =
        store.users.where((u) => u.status == UserStatus.disabled).toList();
    final members = store.activeUsers.where((u) {
      if (_dept != null && u.dept != _dept) return false;
      if (_query.isEmpty) return true;
      return u.name.toLowerCase().contains(_query) ||
          u.email.toLowerCase().contains(_query) ||
          (u.title ?? '').toLowerCase().contains(_query);
    }).toList()
      ..sort((a, b) {
        final r = a.role.index.compareTo(b.role.index);
        return r != 0
            ? r
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(
          title: 'Team',
          subtitle: '${plural(store.activeUsers.length, 'member')}'
              '${pending.isNotEmpty ? ' · ${pending.length} waiting for approval' : ''}',
        ),
        if (!store.loaded('users'))
          Padding(
            padding: EdgeInsets.symmetric(horizontal: g),
            child: const SkeletonList(rows: 5, height: 58),
          )
        else ...[
          if (pending.isNotEmpty && store.isManager)
            Padding(
              padding: EdgeInsets.fromLTRB(g, 0, g, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel('Waiting for approval', count: pending.length),
                  Panel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < pending.length; i++)
                          _PendingRow(pending[i],
                              divider: i < pending.length - 1),
                      ],
                    ),
                  ),
                  if (!admin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Only the owner or an admin can approve new members.',
                        style: tx(12.5, color: C.muted),
                      ),
                    ),
                ],
              ),
            ),
          FilterBar(children: [
            SearchBox(
              hint: 'Search people',
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
            FilterMenu<Dept>(
              label: 'Team',
              value: _dept,
              options: Dept.values,
              textOf: (d) => d.label,
              onChanged: (v) => setState(() => _dept = v),
            ),
          ]),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: g),
            child: isPhone(context)
                ? Column(
                    children: [
                      for (final u in members)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MemberCard(u),
                        ),
                    ],
                  )
                : AppTable<AppUser>(
                    minWidth: 860,
                    rowHeight: 60,
                    rows: members,
                    onTap: (u) => showMemberProfile(context, u),
                    empty: const EmptyState(
                      compact: true,
                      icon: Icons.person_search_outlined,
                      title: 'No one matches',
                      message: 'Try a different name or clear the team filter.',
                    ),
                    columns: [
                      Col('Member', flex: 4,
                          (u) => UserLabel(u, size: 32, subtitle: u.email)),
                      Col('Role', width: 110,
                          (u) => Tag(u.role.label, color: roleColor(u.role))),
                      Col('Team', width: 140, (u) => DeptTag(u.dept)),
                      Col('Title', flex: 3,
                          (u) => cellText(u.title ?? '—',
                              color: u.title == null ? C.faint : C.text)),
                      Col('Call target', width: 100, end: true,
                          (u) => cellText(
                              u.dept == Dept.marketing
                                  ? '${u.dailyCallTarget}/day'
                                  : '—',
                              color: u.dept == Dept.marketing
                                  ? C.text
                                  : C.faint)),
                      if (admin)
                        Col('', width: 52, end: true,
                            (u) => IconButton(
                                  tooltip: 'Edit ${u.firstName}',
                                  onPressed: () => showMemberEditor(context, u),
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18),
                                )),
                    ],
                  ),
          ),
          if (admin && disabled.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(g, 28, g, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel('Access removed', count: disabled.length),
                  Panel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < disabled.length; i++)
                          ListRow(
                            divider: i < disabled.length - 1,
                            child: Row(children: [
                              Expanded(
                                child: Opacity(
                                  opacity: 0.6,
                                  child: UserLabel(disabled[i],
                                      size: 30, subtitle: disabled[i].email),
                                ),
                              ),
                              TextButton(
                                onPressed: () => store.setUserStatus(
                                    disabled[i], UserStatus.active),
                                child: const Text('Restore access'),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow(this.user, {required this.divider});

  final AppUser user;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return ListRow(
      divider: divider,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: UserLabel(user,
                size: 34,
                subtitle: '${user.email} · signed up ${ago(user.createdAt)}'),
          ),
          if (store.isAdmin)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: C.muted),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Reject ${user.name}?',
                      message:
                          'They won’t be able to open the workspace. You can '
                          'restore access later from this page.',
                      confirmLabel: 'Reject',
                      destructive: true,
                    );
                    if (ok) store.setUserStatus(user, UserStatus.disabled);
                  },
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () => showAppDialog<void>(context,
                      maxWidth: 480, builder: (_) => _ApproveDialog(user)),
                  child: const Text('Approve'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog(this.user);

  final AppUser user;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  Dept _dept = Dept.youtube;
  Role _role = Role.member;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    final u = widget.user;
    return DialogFrame(
      title: 'Approve ${u.firstName}',
      subtitle: u.email,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            store.approveUser(u, _dept, _role);
            Navigator.pop(context);
          },
          child: const Text('Approve'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Labeled(
            'Which team are they in?',
            child: ChipChoice<Dept>(
              values: Dept.values,
              selected: _dept,
              labelOf: (d) => d.label,
              colorOf: deptColor,
              iconOf: deptIcon,
              onChanged: (d) => setState(() => _dept = d),
            ),
          ),
          const SizedBox(height: 18),
          Labeled(
            'Role',
            child: ChipChoice<Role>(
              values: const [Role.member, Role.manager, Role.admin],
              selected: _role,
              labelOf: (r) => r.label,
              colorOf: roleColor,
              onChanged: (r) => setState(() => _role = r),
            ),
          ),
          const SizedBox(height: 12),
          _RoleHint(_role, _dept),
        ],
      ),
    );
  }
}

class _RoleHint extends StatelessWidget {
  const _RoleHint(this.role, this.dept);

  final Role role;
  final Dept dept;

  @override
  Widget build(BuildContext context) {
    final text = switch (role) {
      Role.owner => 'The owner has full control of the workspace.',
      Role.admin =>
        'Admins see everything and can approve people, change roles and '
            'set call targets.',
      Role.manager =>
        'Managers see every team’s tasks, videos, leads and the call '
            'scoreboard, and can manage projects.',
      Role.member => switch (dept) {
          Dept.youtube =>
            'Members of YouTube see tasks and the video pipeline.',
          Dept.marketing =>
            'Members of Marketing see tasks plus their own leads and calls.',
          Dept.development => 'Members of Development see tasks and projects.',
        },
    };
    return Text(text, style: tx(12.5, color: C.muted, h: 1.45));
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard(this.user);

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      onTap: () => showMemberProfile(context, user),
      child: Row(
        children: [
          Avatar(user, size: 40, tooltip: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(14.5, w: FontWeight.w700)),
                if (user.title != null)
                  Text(user.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tx(12.5, color: C.muted)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Tag(user.role.label, color: roleColor(user.role)),
                  DeptTag(user.dept),
                  if (user.dept == Dept.marketing)
                    Tag('${user.dailyCallTarget} calls/day'),
                ]),
              ],
            ),
          ),
          if (store.isAdmin)
            IconButton(
              tooltip: 'Edit ${user.firstName}',
              onPressed: () => showMemberEditor(context, user),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit member (admins)
// ---------------------------------------------------------------------------

Future<void> showMemberEditor(BuildContext context, AppUser user) =>
    showAppDialog<void>(context,
        maxWidth: 560, builder: (_) => _MemberEditor(user));

class _MemberEditor extends StatefulWidget {
  const _MemberEditor(this.user);

  final AppUser user;

  @override
  State<_MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends State<_MemberEditor> {
  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _phone;
  late final TextEditingController _target;
  late Role _role;
  late Dept _dept;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u.name);
    _title = TextEditingController(text: u.title ?? '');
    _phone = TextEditingController(text: u.phone ?? '');
    _target = TextEditingController(text: '${u.dailyCallTarget}');
    _role = u.role;
    _dept = u.dept;
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _phone.dispose();
    _target.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      toast('A name is required');
      return;
    }
    StoreScope.read(context).updateMember(
      widget.user,
      name: _name.text,
      title: _title.text,
      phone: _phone.text,
      role: _role,
      dept: _dept,
      dailyCallTarget:
          (int.tryParse(_target.text) ?? kDefaultCallTarget).clamp(0, 999),
    );
    Navigator.pop(context);
  }

  Future<void> _remove() async {
    final store = StoreScope.read(context);
    final navigator = Navigator.of(context);
    final u = widget.user;
    final ok = await confirmDialog(
      context,
      title: 'Remove ${u.name}’s access?',
      message:
          'They’ll be signed out of the workspace straight away. Their tasks, '
          'videos and call history stay as they are.',
      confirmLabel: 'Remove access',
      destructive: true,
    );
    if (!ok) return;
    store.setUserStatus(u, UserStatus.disabled);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final u = widget.user;
    final isOwner = u.role == Role.owner;
    final isSelf = u.id == store.uid;
    return DialogFrame(
      title: 'Edit ${u.firstName}',
      subtitle: u.email,
      leadingActions: [
        if (!isOwner && !isSelf)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: C.danger),
            onPressed: _remove,
            child: const Text('Remove access'),
          ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldRow(children: [
            Labeled(
              'Name',
              child: TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            Labeled(
              'Job title',
              child: TextField(
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(hintText: 'e.g. Video editor'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Phone',
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Optional'),
              ),
            ),
            Labeled(
              'Daily call target',
              child: TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Labeled(
            'Team',
            child: ChipChoice<Dept>(
              values: Dept.values,
              selected: _dept,
              labelOf: (d) => d.label,
              colorOf: deptColor,
              iconOf: deptIcon,
              onChanged: (d) => setState(() => _dept = d),
            ),
          ),
          const SizedBox(height: 16),
          Labeled(
            'Role',
            child: isOwner
                ? Row(children: [
                    Tag('Owner', color: roleColor(Role.owner)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The workspace owner’s role can’t be changed.',
                        style: tx(12.5, color: C.muted),
                      ),
                    ),
                  ])
                : ChipChoice<Role>(
                    values: const [Role.member, Role.manager, Role.admin],
                    selected: _role,
                    labelOf: (r) => r.label,
                    colorOf: roleColor,
                    onChanged: (r) => setState(() => _role = r),
                  ),
          ),
          if (!isOwner) ...[
            const SizedBox(height: 12),
            _RoleHint(_role, _dept),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member profile
// ---------------------------------------------------------------------------

Future<void> showMemberProfile(BuildContext context, AppUser user) =>
    showAppDialog<void>(context,
        maxWidth: 640, builder: (_) => _MemberProfile(user.id));

class _MemberProfile extends StatelessWidget {
  const _MemberProfile(this.userId);

  final String userId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final u = store.userById(userId);
    if (u == null) {
      return const DialogFrame(
        title: 'Member',
        child: EmptyState(
          compact: true,
          icon: Icons.person_off_outlined,
          title: 'No longer here',
          message: 'This person is no longer part of the workspace.',
        ),
      );
    }
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final theirs = store.tasks.where((t) => t.assigneeId == u.id).toList();
    final open = theirs.where((t) => t.isOpen).toList()
      ..sort(compareTasksByDue);
    final done7 = theirs
        .where((t) => t.completedAt != null && t.completedAt!.isAfter(weekAgo))
        .length;
    final overdue = open.where((t) => t.isOverdue(now)).length;
    final videos = store.videos
        .where((v) => v.assigneeId == u.id && !v.isPublished)
        .toList();
    // Call data is only loaded for managers, or for your own calls.
    final canSeeCalls = store.isManager || (u.id == store.uid && store.canCalls);
    final calls = store.calls.where((c) => c.callerId == u.id).toList();
    final week = callsPerDay(calls, now, days: 7);
    final weekStats =
        CallStats(calls.where((c) => daysBetween(c.at, now) < 7));
    final showCalls =
        canSeeCalls && (u.dept == Dept.marketing || calls.isNotEmpty);

    return DialogFrame(
      title: u.name,
      subtitle: u.title ?? u.email,
      actions: [
        if (store.isAdmin)
          OutlinedButton.icon(
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              showMemberEditor(navigator.context, u);
            },
            icon: const Icon(Icons.edit_outlined, size: 18, color: C.text),
            label: const Text('Edit'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(u, size: 56, tooltip: false),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      Tag(u.role.label, color: roleColor(u.role)),
                      DeptTag(u.dept),
                      if (!u.isActive) Tag(u.status.label, color: C.danger),
                    ]),
                    const SizedBox(height: 8),
                    SelectableText(
                      [u.email, if (u.phone != null) u.phone!].join(' · '),
                      style: tx(13, color: C.muted),
                    ),
                    if (u.lastSeenAt != null)
                      Text('Last seen ${ago(u.lastSeenAt!)}',
                          style: tx(12.5, color: C.faint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _Stat('Open tasks', '${open.length}')),
            const SizedBox(width: 10),
            Expanded(
                child: _Stat('Done · 7 days', '$done7', color: C.success)),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat('Overdue', '$overdue',
                  color: overdue > 0 ? C.danger : C.text),
            ),
          ]),
          const SizedBox(height: 24),
          Text('Open tasks', style: tx(14, w: FontWeight.w800)),
          const SizedBox(height: 10),
          if (open.isEmpty)
            Text('Nothing assigned right now.', style: tx(13, color: C.muted))
          else
            _Boxed(children: [
              for (var i = 0; i < open.length; i++)
                ListRow(
                  divider: i < open.length - 1,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: () => showTaskDialog(context, task: open[i]),
                  child: Row(children: [
                    PriorityMark(open[i].priority),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(open[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tx(13.5, w: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    DueChip(open[i]),
                    const SizedBox(width: 10),
                    Tag(open[i].status.label,
                        color: taskStatusColor(open[i].status)),
                  ]),
                ),
            ]),
          if (videos.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Videos they’re holding', style: tx(14, w: FontWeight.w800)),
            const SizedBox(height: 10),
            _Boxed(children: [
              for (var i = 0; i < videos.length; i++)
                ListRow(
                  divider: i < videos.length - 1,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: store.canVideos
                      ? () => showVideoDialog(context, video: videos[i])
                      : null,
                  child: Row(children: [
                    Expanded(
                      child: Text(videos[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tx(13.5, w: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    StageAge(videos[i], short: true),
                    const SizedBox(width: 10),
                    Tag(videos[i].stage.label,
                        color: stageColor(videos[i].stage)),
                  ]),
                ),
            ]),
          ],
          if (showCalls) ...[
            const SizedBox(height: 24),
            Text('Calls · last 7 days', style: tx(14, w: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusSm),
                border: Border.all(color: C.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      _Inline('Calls', '${weekStats.total}'),
                      _Inline('Connect rate',
                          weekStats.total == 0 ? '—' : pct(weekStats.connectRate)),
                      _Inline('Converted', '${weekStats.converted}'),
                      _Inline('Talk time', fmtMinutes(weekStats.talkMin)),
                      _Inline('Data quality',
                          weekStats.total == 0 ? '—' : pct(weekStats.dataQuality)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MiniBars(week, height: 64, target: u.dailyCallTarget),
                  const SizedBox(height: 6),
                  Text('Dashed line: daily target of ${u.dailyCallTarget}',
                      style: tx(11.5, color: C.faint)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Boxed extends StatelessWidget {
  const _Boxed({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(color: C.hairline),
        ),
        child: Column(children: children),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color = C.text});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.canvas,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(color: C.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(12, w: FontWeight.w600, color: C.muted)),
            const SizedBox(height: 4),
            Text(value, style: dx(24, color: color)),
          ],
        ),
      );
}

class _Inline extends StatelessWidget {
  const _Inline(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: tx(11.5, w: FontWeight.w600, color: C.muted)),
          const SizedBox(height: 2),
          Text(value, style: dx(18)),
        ],
      );
}
