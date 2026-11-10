import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calls.dart';
import 'my_work.dart';
import 'overview.dart';
import 'tasks.dart';
import 'team.dart';
import 'videos.dart';

enum Dest {
  overview('Overview', 'Overview', Icons.space_dashboard_outlined),
  myWork('My work', 'My work', Icons.task_alt_rounded),
  tasks('Tasks', 'Tasks', Icons.view_kanban_outlined),
  videos('Videos', 'Videos', Icons.movie_outlined),
  calls('Calls & leads', 'Calls', Icons.headset_mic_outlined),
  team('Team', 'Team', Icons.groups_2_outlined);

  const Dest(this.label, this.short, this.icon);
  final String label;
  final String short;
  final IconData icon;
}

/// Lets any screen jump to another destination (e.g. a KPI card → Tasks).
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.go, required super.child});

  final void Function(Dest dest) go;

  static ShellScope of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellScope>()!;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initial});

  /// Destination to open first; defaults to the first one the user may see.
  final Dest? initial;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late Dest? _chosen = widget.initial;

  void _go(Dest d) => setState(() => _chosen = d);

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.me;
    if (me == null) return const SizedBox.shrink();

    final allowed = [
      if (store.isManager) Dest.overview,
      Dest.myWork,
      Dest.tasks,
      if (store.canVideos) Dest.videos,
      if (store.canCalls) Dest.calls,
      Dest.team,
    ];
    var current = _chosen ?? allowed.first;
    if (!allowed.contains(current)) current = Dest.myWork;

    final now = DateTime.now();
    final badges = <Dest, _Badge>{};
    final myOpen =
        store.tasks.where((t) => t.isOpen && t.assigneeId == me.id).length;
    if (myOpen > 0) badges[Dest.myWork] = _Badge(myOpen, false);
    if (store.canCalls) {
      final due = store.leads
          .where((l) => l.ownerId == me.id && l.followUpDue(now))
          .length;
      final fresh = store.inquiries.where((q) => q.isNew).length;
      if (due + fresh > 0) badges[Dest.calls] = _Badge(due + fresh, true);
    }
    if (store.isAdmin && store.pendingUsers.isNotEmpty) {
      badges[Dest.team] = _Badge(store.pendingUsers.length, true);
    }

    final page = AnimatedSwitcher(
      duration: kMotion,
      child: KeyedSubtree(
        key: ValueKey(current),
        child: switch (current) {
          Dest.overview => const OverviewScreen(),
          Dest.myWork => const MyWorkScreen(),
          Dest.tasks => const TasksScreen(),
          Dest.videos => const VideosScreen(),
          Dest.calls => const CallsScreen(),
          Dest.team => const TeamScreen(),
        },
      ),
    );

    return ShellScope(
      go: _go,
      child: Scaffold(
        backgroundColor: C.canvas,
        body: isWide(context)
            ? Row(
                children: [
                  _Sidebar(
                    allowed: allowed,
                    current: current,
                    badges: badges,
                    onSelect: _go,
                  ),
                  Expanded(child: page),
                ],
              )
            : Column(
                children: [
                  const _TopBar(),
                  Expanded(child: page),
                  _BottomNav(
                    allowed: allowed,
                    current: current,
                    badges: badges,
                    onSelect: _go,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Badge {
  const _Badge(this.count, this.urgent);
  final int count;
  final bool urgent;
}

// ---------------------------------------------------------------------------
// Sidebar (wide)
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.allowed,
    required this.current,
    required this.badges,
    required this.onSelect,
  });

  final List<Dest> allowed;
  final Dest current;
  final Map<Dest, _Badge> badges;
  final ValueChanged<Dest> onSelect;

  @override
  Widget build(BuildContext context) {
    final me = StoreScope.of(context).me!;
    return Container(
      width: 248,
      color: C.ink,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 16, 26),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wordmark(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final d in allowed)
                    _NavItem(
                      dest: d,
                      active: d == current,
                      badge: badges[d],
                      onTap: () => onSelect(d),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SideLink(
                icon: Icons.arrow_outward_rounded,
                label: 'Back to website',
                onTap: backToWebsite,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Divider(color: C.inkLine),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _UserMenu(
                child: _HoverInk(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Avatar(me, size: 32, tooltip: false),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(me.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tx(13.5,
                                      w: FontWeight.w700, color: C.onInk)),
                              Text('${me.role.label} · ${me.dept.label}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tx(12, color: C.onInkMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.unfold_more_rounded,
                            size: 16, color: C.onInkMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverInk extends StatefulWidget {
  const _HoverInk({required this.child, this.active = false});

  final Widget child;
  final bool active;

  @override
  State<_HoverInk> createState() => _HoverInkState();
}

class _HoverInkState extends State<_HoverInk> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: kMotion,
        decoration: BoxDecoration(
          color: widget.active
              ? C.inkRaised
              : (_hover ? C.inkRaised.withValues(alpha: 0.6) : C.ink),
          borderRadius: BorderRadius.circular(kRadiusSm),
        ),
        child: widget.child,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.dest,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final Dest dest;
  final bool active;
  final VoidCallback onTap;
  final _Badge? badge;

  @override
  Widget build(BuildContext context) {
    final b = badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        button: true,
        selected: active,
        label: dest.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: _HoverInk(
            active: active,
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: kMotion,
                    width: 3,
                    height: active ? 18 : 0,
                    margin: const EdgeInsets.only(right: 9),
                    decoration: BoxDecoration(
                      color: C.brand,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Icon(dest.icon,
                      size: 19, color: active ? C.brand : C.onInkMuted),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      dest.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tx(14,
                          w: active ? FontWeight.w700 : FontWeight.w600,
                          color: active ? C.onInk : C.onInkMuted),
                    ),
                  ),
                  if (b != null)
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: b.urgent ? C.brand : C.inkLine,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${b.count}',
                        textAlign: TextAlign.center,
                        style: tx(11.5,
                            w: FontWeight.w800,
                            color: b.urgent ? Colors.white : C.onInkMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideLink extends StatelessWidget {
  const _SideLink(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _HoverInk(
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 16, color: C.onInkMuted),
              const SizedBox(width: 11),
              Text(label,
                  style: tx(13, w: FontWeight.w600, color: C.onInkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phone chrome
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final me = StoreScope.of(context).me!;
    return Container(
      color: C.ink,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Wordmark(size: 20),
              const Spacer(),
              _UserMenu(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Avatar(me, size: 30, tooltip: false),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.allowed,
    required this.current,
    required this.badges,
    required this.onSelect,
  });

  final List<Dest> allowed;
  final Dest current;
  final Map<Dest, _Badge> badges;
  final ValueChanged<Dest> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final d in allowed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: d == current,
                    label: d.label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(d),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: kMotion,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: d == current
                                      ? tint(C.brand, 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(d.icon,
                                    size: 21,
                                    color:
                                        d == current ? C.brand : C.muted),
                              ),
                              if (badges[d]?.urgent ?? false)
                                const Positioned(
                                  right: 8,
                                  top: 2,
                                  child: Dot(C.brand, size: 8),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d.short,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tx(10.5,
                                w: d == current
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: d == current ? C.text : C.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account menu & profile
// ---------------------------------------------------------------------------

enum _Account { profile, website, signOut }

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    final me = store.me!;
    return PopupMenuButton<_Account>(
      tooltip: 'Account',
      offset: const Offset(0, -8),
      constraints: const BoxConstraints(minWidth: 232),
      onSelected: (a) {
        switch (a) {
          case _Account.profile:
            showAppDialog<void>(context,
                maxWidth: 460, builder: (_) => const _ProfileDialog());
          case _Account.website:
            backToWebsite();
          case _Account.signOut:
            store.signOut();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(me.name, style: tx(14, w: FontWeight.w700)),
              Text(me.email, style: tx(12.5, color: C.muted)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        _item(_Account.profile, Icons.person_outline_rounded, 'Edit profile'),
        _item(_Account.website, Icons.arrow_outward_rounded, 'Back to website'),
        _item(_Account.signOut, Icons.logout_rounded, 'Sign out'),
      ],
      child: child,
    );
  }

  PopupMenuItem<_Account> _item(_Account v, IconData icon, String text) =>
      PopupMenuItem(
        value: v,
        height: 42,
        child: Row(children: [
          Icon(icon, size: 18, color: C.muted),
          const SizedBox(width: 10),
          Text(text, style: tx(14)),
        ]),
      );
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog();

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final me = StoreScope.read(context).me!;
    _name = TextEditingController(text: me.name);
    _phone = TextEditingController(text: me.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.me;
    if (me == null) return const SizedBox.shrink();
    return DialogFrame(
      title: 'Your profile',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) {
              toast('Your name can’t be empty');
              return;
            }
            store.updateMyProfile(name: _name.text, phone: _phone.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(me, size: 52, tooltip: false),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.email, style: tx(14, w: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      Tag(me.role.label, color: roleColor(me.role)),
                      DeptTag(me.dept),
                      if (me.title != null) Tag(me.title!),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Labeled(
            'Name',
            child: TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 16),
          Labeled(
            'Phone',
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your role, team and call target are managed by an admin.',
            style: tx(12.5, color: C.muted),
          ),
        ],
      ),
    );
  }
}
