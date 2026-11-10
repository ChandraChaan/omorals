import 'package:flutter/material.dart';

import '../board.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

enum _TaskView { board, list }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskView _view = _TaskView.board;
  String _query = '';
  String? _projectId;
  Dept? _dept;
  String? _assigneeId;
  bool _onlyMine = false;

  bool _matches(Task t, String uid) {
    if (_projectId != null && t.projectId != _projectId) return false;
    if (_dept != null && t.dept != _dept) return false;
    if (_assigneeId != null && t.assigneeId != _assigneeId) return false;
    if (_onlyMine && t.assigneeId != uid) return false;
    if (_query.isNotEmpty &&
        !t.title.toLowerCase().contains(_query) &&
        !t.description.toLowerCase().contains(_query)) {
      return false;
    }
    return true;
  }

  static int _boardOrder(Task a, Task b) {
    if (a.status == TaskStatus.done && b.status == TaskStatus.done) {
      return (b.completedAt ?? b.updatedAt)
          .compareTo(a.completedAt ?? a.updatedAt);
    }
    final p = b.priority.index.compareTo(a.priority.index);
    return p != 0 ? p : compareTasksByDue(a, b);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final visible = store.tasks.where((t) => _matches(t, store.uid)).toList();
    final open = visible.where((t) => t.isOpen).length;
    final overdue = visible.where((t) => t.isOverdue(now)).length;
    final projects = store.liveProjects;
    final people = store.activeUsers;

    Widget body;
    if (!store.loaded('tasks')) {
      body = Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter(context)),
        child: const SkeletonList(rows: 6, height: 64),
      );
    } else if (store.tasks.isEmpty) {
      body = EmptyState(
        icon: Icons.view_kanban_outlined,
        title: 'No tasks yet',
        message:
            'Create the first task and assign it to someone. It shows up on '
            'their “My work” page straight away.',
        actionLabel: 'New task',
        onAction: () => showTaskDialog(context),
      );
    } else if (_view == _TaskView.board) {
      body = Board<TaskStatus, Task>(
        columns: TaskStatus.values,
        titleOf: (s) => s.label,
        colorOf: taskStatusColor,
        itemsOf: (s) =>
            visible.where((t) => t.status == s).toList()..sort(_boardOrder),
        cardBuilder: (context, t) => TaskCard(t),
        canDrag: store.canEditTask,
        onMove: (t, s) => store.setTaskStatus(t, s),
        onAdd: (s) => showTaskDialog(context, status: s),
      );
    } else {
      body = _TaskList(tasks: visible);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Tasks',
          subtitle: overdue > 0
              ? '$open open · $overdue overdue'
              : '$open open across ${plural(projects.length, 'project')}',
          actions: [
            Segmented<_TaskView>(
              values: _TaskView.values,
              selected: _view,
              labelOf: (v) => v == _TaskView.board ? 'Board' : 'List',
              iconOf: (v) => v == _TaskView.board
                  ? Icons.view_kanban_outlined
                  : Icons.format_list_bulleted_rounded,
              onChanged: (v) => setState(() => _view = v),
            ),
            OutlinedButton.icon(
              onPressed: () => showAppDialog<void>(context,
                  maxWidth: 640, builder: (_) => const ProjectsDialog()),
              icon: const Icon(Icons.folder_outlined, size: 18, color: C.text),
              label: const Text('Projects'),
            ),
            FilledButton.icon(
              onPressed: () => showTaskDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New task'),
            ),
          ],
        ),
        FilterBar(children: [
          SearchBox(
            hint: 'Search tasks',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          FilterMenu<String>(
            label: 'Project',
            value: _projectId,
            options: [for (final p in projects) p.id],
            textOf: (id) => store.projectById(id)?.name ?? 'Project',
            onChanged: (v) => setState(() => _projectId = v),
          ),
          FilterMenu<Dept>(
            label: 'Team',
            value: _dept,
            options: Dept.values,
            textOf: (d) => d.label,
            onChanged: (v) => setState(() => _dept = v),
          ),
          FilterMenu<String>(
            label: 'Assignee',
            value: _assigneeId,
            options: [for (final u in people) u.id],
            textOf: store.nameOf,
            onChanged: (v) => setState(() => _assigneeId = v),
          ),
          ToggleChip(
            label: 'Only mine',
            selected: _onlyMine,
            onChanged: (v) => setState(() => _onlyMine = v),
          ),
        ]),
        Expanded(child: body),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cards, rows and small task widgets
// ---------------------------------------------------------------------------

class DueChip extends StatelessWidget {
  const DueChip(this.task, {super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final due = task.dueAt;
    if (due == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final color = task.isOverdue(now)
        ? C.danger
        : task.isDueToday(now)
            ? C.warn
            : C.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          fmtDue(due),
          style: tx(12.5,
              w: color == C.muted ? FontWeight.w600 : FontWeight.w700,
              color: color == C.warn ? Color.lerp(C.warn, C.ink, 0.3)! : color),
        ),
      ],
    );
  }
}

class ProjectTag extends StatelessWidget {
  const ProjectTag(this.task, {super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final project = StoreScope.of(context).projectById(task.projectId);
    if (project == null) return DeptTag(task.dept);
    return Tag(project.name, color: paletteColor(project.color));
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard(this.task, {super.key, this.showStatus = false});

  final Task task;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final done = task.status == TaskStatus.done;
    return Panel(
      radius: kRadiusSm + 2,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      onTap: () => showTaskDialog(context, task: task),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ProjectTag(task),
                ),
              ),
              const SizedBox(width: 8),
              PriorityMark(task.priority),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: tx(14,
                w: FontWeight.w600, color: done ? C.muted : C.text, h: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showStatus) ...[
                StatusPill(task),
                const SizedBox(width: 10),
              ],
              DueChip(task),
              if (task.dueAt != null && task.commentCount > 0)
                const SizedBox(width: 10),
              if (task.commentCount > 0) ...[
                const Icon(Icons.mode_comment_outlined,
                    size: 13, color: C.muted),
                const SizedBox(width: 4),
                Text('${task.commentCount}',
                    style: tx(12.5, w: FontWeight.w600, color: C.muted)),
              ],
              const Spacer(),
              Avatar(store.userById(task.assigneeId), size: 24),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status label that doubles as a quick-change menu for people who may edit.
class StatusPill extends StatelessWidget {
  const StatusPill(this.task, {super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final color = taskStatusColor(task.status);
    final canEdit = store.canEditTask(task);
    final pill = Container(
      height: 26,
      padding: EdgeInsets.only(left: 8, right: canEdit ? 2 : 8),
      decoration: BoxDecoration(
        color: tint(color, 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Dot(color, size: 7),
          const SizedBox(width: 6),
          Text(task.status.label,
              style: tx(12,
                  w: FontWeight.w700, color: Color.lerp(color, C.ink, 0.35)!)),
          if (canEdit)
            Icon(Icons.expand_more_rounded,
                size: 16, color: Color.lerp(color, C.ink, 0.35)),
        ],
      ),
    );
    if (!canEdit) return pill;
    return PopupMenuButton<TaskStatus>(
      tooltip: 'Change status',
      position: PopupMenuPosition.under,
      onSelected: (s) => store.setTaskStatus(task, s),
      itemBuilder: (_) => [
        for (final s in TaskStatus.values)
          PopupMenuItem(
            value: s,
            height: 40,
            child: Row(children: [
              Dot(taskStatusColor(s)),
              const SizedBox(width: 10),
              Text(s.label,
                  style: tx(14,
                      w: s == task.status
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ]),
          ),
      ],
      child: pill,
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final g = gutter(context);
    final sorted = [...tasks]..sort((a, b) {
        final s = a.status.index.compareTo(b.status.index);
        return s != 0 ? s : compareTasksByDue(a, b);
      });
    if (sorted.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Nothing matches',
        message: 'No tasks match these filters. Try clearing one of them.',
      );
    }
    if (isPhone(context)) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(g, 0, g, 24),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => TaskCard(sorted[i], showStatus: true),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(g, 0, g, 24),
      child: AppTable<Task>(
        shrinkWrap: false,
        minWidth: 860,
        rows: sorted,
        onTap: (t) => showTaskDialog(context, task: t),
        columns: [
          Col('Task', flex: 4, (t) => Row(children: [
                PriorityMark(t.priority),
                const SizedBox(width: 8),
                Expanded(child: cellText(t.title, strong: true)),
                if (t.commentCount > 0) ...[
                  const Icon(Icons.mode_comment_outlined,
                      size: 13, color: C.muted),
                  const SizedBox(width: 4),
                  Text('${t.commentCount}',
                      style: tx(12.5, color: C.muted)),
                ],
              ])),
          Col('Project', flex: 2, (t) => ProjectTag(t)),
          Col('Status', width: 140, (t) => StatusPill(t)),
          Col('Assignee', flex: 2,
              (t) => UserLabel(store.userById(t.assigneeId))),
          Col('Due', width: 110, (t) => DueChip(t)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Task dialog
// ---------------------------------------------------------------------------

Future<void> showTaskDialog(
  BuildContext context, {
  Task? task,
  TaskStatus? status,
  String? assigneeId,
}) =>
    showAppDialog<void>(
      context,
      maxWidth: 720,
      dismissible: false,
      builder: (_) => TaskDialog(
          task: task, initialStatus: status, initialAssignee: assigneeId),
    );

class TaskDialog extends StatefulWidget {
  const TaskDialog(
      {super.key, this.task, this.initialStatus, this.initialAssignee});

  final Task? task;
  final TaskStatus? initialStatus;
  final String? initialAssignee;

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late final TaskDraft _draft;
  late final TextEditingController _title;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    final store = StoreScope.read(context);
    final t = widget.task;
    _draft = t != null
        ? TaskDraft.of(t)
        : TaskDraft(
            dept: store.me?.dept ?? Dept.development,
            status: widget.initialStatus ?? TaskStatus.todo,
            assigneeId:
                widget.initialAssignee ?? (store.isManager ? null : store.uid),
          );
    _title = TextEditingController(text: _draft.title);
    _description = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    _draft
      ..title = _title.text
      ..description = _description.text;
    if (_draft.title.trim().isEmpty) {
      toast('Give the task a title first');
      return;
    }
    final t = widget.task;
    if (t == null) {
      store.createTask(_draft);
    } else {
      store.updateTask(t, _draft);
    }
    Navigator.pop(context);
  }

  Future<void> _delete(Task t) async {
    final store = StoreScope.read(context);
    final navigator = Navigator.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete this task?',
      message: '“${t.title}” and its comments will be removed for everyone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    store.deleteTask(t);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final original = widget.task;
    // Follow live updates (comment count, edits by others) while open.
    final live = original == null
        ? null
        : store.tasks.where((t) => t.id == original.id).firstOrNull ?? original;
    final canEdit = live == null || store.canEditTask(live);
    final projects = store.liveProjects;
    final projectIds = [
      for (final p in projects) p.id,
      if (_draft.projectId != null &&
          !projects.any((p) => p.id == _draft.projectId))
        _draft.projectId!,
    ];

    return DialogFrame(
      title: live == null ? 'New task' : 'Task',
      subtitle: live == null
          ? null
          : 'Created by ${store.nameOf(live.reporterId)} · ${fmtDay(live.createdAt)}'
              '${live.completedAt != null ? ' · Completed ${fmtDay(live.completedAt!)}' : ''}',
      leadingActions: [
        if (live != null && store.canDeleteTask(live))
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
          child: Text(canEdit ? 'Cancel' : 'Close'),
        ),
        if (canEdit)
          FilledButton(
            onPressed: _save,
            child: Text(live == null ? 'Create task' : 'Save changes'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canEdit)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: C.canvas,
                borderRadius: BorderRadius.circular(kRadiusSm),
                border: Border.all(color: C.hairline),
              ),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only the assignee, the reporter or a manager can edit '
                    'this task. You can still comment.',
                    style: tx(13, color: C.muted),
                  ),
                ),
              ]),
            ),
          TextField(
            controller: _title,
            enabled: canEdit,
            autofocus: live == null,
            style: tx(17, w: FontWeight.w700),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What needs doing?'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            enabled: canEdit,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'Add details, links or acceptance notes'),
          ),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Status',
              child: SelectField<TaskStatus>(
                enabled: canEdit,
                value: _draft.status,
                options: TaskStatus.values,
                textOf: (s) => s.label,
                leadingOf: (s) => Dot(taskStatusColor(s ?? TaskStatus.todo)),
                onChanged: (v) => setState(() => _draft.status = v!),
              ),
            ),
            Labeled(
              'Priority',
              child: SelectField<TaskPriority>(
                enabled: canEdit,
                value: _draft.priority,
                options: TaskPriority.values,
                textOf: (p) => p.label,
                leadingOf: (p) => PriorityMark(p ?? TaskPriority.medium),
                onChanged: (v) => setState(() => _draft.priority = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Assignee',
              child: SelectField<String>(
                enabled: canEdit,
                value: _draft.assigneeId,
                options: [for (final u in store.activeUsers) u.id],
                textOf: store.nameOf,
                leadingOf: (id) =>
                    Avatar(store.userById(id), size: 22, tooltip: false),
                noneLabel: 'Unassigned',
                onChanged: (v) => setState(() => _draft.assigneeId = v),
              ),
            ),
            Labeled(
              'Due date',
              child: IgnorePointer(
                ignoring: !canEdit,
                child: DateField(
                  value: _draft.dueAt,
                  hint: 'No due date',
                  onChanged: (v) => setState(() => _draft.dueAt = v),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Project',
              child: SelectField<String>(
                enabled: canEdit,
                value: _draft.projectId,
                options: projectIds,
                textOf: (id) => store.projectById(id)?.name ?? 'Project',
                leadingOf: (id) => Dot(id == null
                    ? C.hairlineStrong
                    : paletteColor(store.projectById(id)?.color ?? 0)),
                noneLabel: 'No project',
                onChanged: (v) => setState(() {
                  _draft.projectId = v;
                  final p = store.projectById(v);
                  if (p != null) _draft.dept = p.dept;
                }),
              ),
            ),
            Labeled(
              'Team',
              child: SelectField<Dept>(
                enabled: canEdit,
                value: _draft.dept,
                options: Dept.values,
                textOf: (d) => d.label,
                leadingOf: (d) => Dot(deptColor(d ?? Dept.development)),
                onChanged: (v) => setState(() => _draft.dept = v!),
              ),
            ),
          ]),
          if (live != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _Comments(task: live),
          ],
        ],
      ),
    );
  }
}

class _Comments extends StatefulWidget {
  const _Comments({required this.task});

  final Task task;

  @override
  State<_Comments> createState() => _CommentsState();
}

class _CommentsState extends State<_Comments> {
  late final Stream<List<TaskComment>> _stream =
      StoreScope.read(context).watchComments(widget.task.id);
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    StoreScope.read(context).addComment(widget.task, text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Comments', style: tx(14, w: FontWeight.w800)),
        const SizedBox(height: 12),
        StreamBuilder<List<TaskComment>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Comments could not be loaded.',
                  style: tx(13, color: C.muted));
            }
            final comments = snap.data;
            if (comments == null) return const SkeletonList(rows: 2, height: 36);
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('No comments yet. Start the conversation.',
                    style: tx(13, color: C.muted)),
              );
            }
            return Column(
              children: [
                for (final c in comments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Avatar(store.userById(c.authorId), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: Text(store.nameOf(c.authorId),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tx(13, w: FontWeight.w700)),
                                ),
                                const SizedBox(width: 8),
                                Text(ago(c.at),
                                    style: tx(12, color: C.faint)),
                              ]),
                              const SizedBox(height: 2),
                              SelectableText(c.text, style: tx(14, h: 1.45)),
                            ],
                          ),
                        ),
                        if (store.isManager || c.authorId == store.uid)
                          IconButton(
                            tooltip: 'Delete comment',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                store.deleteComment(widget.task, c),
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: C.faint),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration:
                    const InputDecoration(hintText: 'Write a comment'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              style: IconButton.styleFrom(
                backgroundColor: C.ink,
                foregroundColor: Colors.white,
                minimumSize: const Size(46, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusSm)),
              ),
              onPressed: _send,
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Projects
// ---------------------------------------------------------------------------

class ProjectsDialog extends StatefulWidget {
  const ProjectsDialog({super.key});

  @override
  State<ProjectsDialog> createState() => _ProjectsDialogState();
}

class _ProjectsDialogState extends State<ProjectsDialog> {
  bool _editing = false;
  Project? _target;
  final _name = TextEditingController();
  final _client = TextEditingController();
  Dept _dept = Dept.development;
  int _color = 0;

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    super.dispose();
  }

  void _edit(Project? p) {
    final store = StoreScope.read(context);
    setState(() {
      _editing = true;
      _target = p;
      _name.text = p?.name ?? '';
      _client.text = p?.client ?? '';
      _dept = p?.dept ?? store.me?.dept ?? Dept.development;
      _color = p?.color ?? store.projects.length % C.palette.length;
    });
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      toast('Give the project a name');
      return;
    }
    StoreScope.read(context).saveProject(
      existing: _target,
      name: _name.text,
      dept: _dept,
      color: _color,
      client: _client.text,
    );
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final canManage = store.isManager;

    if (_editing) {
      return DialogFrame(
        title: _target == null ? 'New project' : 'Edit project',
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: _save,
            child: Text(_target == null ? 'Create project' : 'Save'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Labeled(
              'Name',
              child: TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(hintText: 'e.g. Client app v2'),
              ),
            ),
            const SizedBox(height: 16),
            Labeled(
              'Client',
              child: TextField(
                controller: _client,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    hintText: 'Optional — leave blank for internal work'),
              ),
            ),
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
              'Colour',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < C.palette.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _color = i),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: kMotion,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: C.palette[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i == _color ? C.ink : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: i == _color
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final projects = [...store.projects]..sort((a, b) {
        if (a.archived != b.archived) return a.archived ? 1 : -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return DialogFrame(
      title: 'Projects',
      subtitle: 'Group tasks by client or initiative and watch progress.',
      padding: EdgeInsets.zero,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (canManage)
          FilledButton.icon(
            onPressed: () => _edit(null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New project'),
          ),
      ],
      child: projects.isEmpty
          ? EmptyState(
              compact: true,
              icon: Icons.folder_outlined,
              title: 'No projects yet',
              message: canManage
                  ? 'Create a project to group related tasks and see how far '
                      'along each one is.'
                  : 'A manager can create projects to group related tasks.',
              actionLabel: canManage ? 'New project' : null,
              onAction: canManage ? () => _edit(null) : null,
            )
          : Column(
              children: [
                for (var i = 0; i < projects.length; i++)
                  _ProjectRow(
                    project: projects[i],
                    divider: i < projects.length - 1,
                    onEdit: canManage ? () => _edit(projects[i]) : null,
                  ),
              ],
            ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow(
      {required this.project, required this.divider, this.onEdit});

  final Project project;
  final bool divider;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final tasks = store.tasks.where((t) => t.projectId == project.id);
    final total = tasks.length;
    final done = tasks.where((t) => !t.isOpen).length;
    final color = paletteColor(project.color);
    return ListRow(
      divider: divider,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Opacity(
        opacity: project.archived ? 0.55 : 1,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Dot(color, size: 10),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tx(14.5, w: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    DeptTag(project.dept),
                    if (project.archived) ...[
                      const SizedBox(width: 6),
                      const Tag('Archived'),
                    ],
                  ]),
                  if (project.client != null) ...[
                    const SizedBox(height: 2),
                    Text(project.client!, style: tx(12.5, color: C.muted)),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: Bar(total == 0 ? 0 : done / total, color: color),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: Text(
                        total == 0
                            ? 'No tasks'
                            : '$done / $total · ${pct(done / total)}',
                        textAlign: TextAlign.end,
                        style: tx(12.5, w: FontWeight.w600, color: C.muted),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: project.archived ? 'Restore' : 'Archive',
                onPressed: () =>
                    store.setProjectArchived(project, !project.archived),
                icon: Icon(
                  project.archived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
