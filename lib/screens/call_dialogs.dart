import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// Shared lead / call widgets
// ---------------------------------------------------------------------------

class LeadStatusTag extends StatelessWidget {
  const LeadStatusTag(this.status, {super.key});

  final LeadStatus status;

  @override
  Widget build(BuildContext context) =>
      Tag(status.label, color: leadStatusColor(status));
}

class OutcomeTag extends StatelessWidget {
  const OutcomeTag(this.outcome, {super.key});

  final CallOutcome outcome;

  @override
  Widget build(BuildContext context) => Tag(outcome.label,
      color: outcomeColor(outcome), icon: outcomeIcon(outcome));
}

/// "Today" / "2d overdue" / date, coloured by urgency.
class FollowUpLabel extends StatelessWidget {
  const FollowUpLabel(this.lead, {super.key});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final at = lead.nextFollowUpAt;
    if (at == null || lead.status.isClosed) {
      return Text('—', style: tx(13.5, color: C.faint));
    }
    final now = DateTime.now();
    final late = daysBetween(at, now);
    final color = late > 0
        ? C.danger
        : late == 0
            ? Color.lerp(C.warn, C.ink, 0.3)!
            : C.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_repeat_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          late > 0 ? '${late}d overdue' : fmtDue(at),
          style: tx(12.5,
              w: late >= 0 ? FontWeight.w700 : FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

/// One call in a timeline or recent-calls list.
class CallTile extends StatelessWidget {
  const CallTile(this.call,
      {super.key, this.showLead = true, this.showAgent = false, this.divider = true});

  final CallLog call;
  final bool showLead;
  final bool showAgent;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final color = outcomeColor(call.outcome);
    return ListRow(
      divider: divider,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint(color, 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(outcomeIcon(call.outcome),
                size: 16, color: Color.lerp(color, C.ink, 0.25)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      showLead ? call.leadName : call.outcome.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tx(14, w: FontWeight.w700),
                    ),
                  ),
                  if (showLead) ...[
                    const SizedBox(width: 8),
                    Text(call.outcome.label,
                        style: tx(12.5,
                            w: FontWeight.w700,
                            color: Color.lerp(color, C.ink, 0.25)!)),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  call.notes.trim().isEmpty ? 'No notes' : call.notes.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tx(13,
                      color: call.notes.trim().isEmpty ? C.faint : C.muted,
                      h: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtWhen(call.at), style: tx(12.5, color: C.muted)),
              const SizedBox(height: 2),
              Text(
                [
                  if (showAgent) store.nameOf(call.callerId),
                  fmtMinutes(call.durationMin),
                ].join(' · '),
                style: tx(12.5, color: C.faint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log a call
// ---------------------------------------------------------------------------

Future<void> showLogCallDialog(BuildContext context, {Lead? lead}) =>
    showAppDialog<void>(
      context,
      maxWidth: 560,
      dismissible: false,
      builder: (_) => LogCallDialog(lead: lead),
    );

class LogCallDialog extends StatefulWidget {
  const LogCallDialog({super.key, this.lead});

  final Lead? lead;

  @override
  State<LogCallDialog> createState() => _LogCallDialogState();
}

class _LogCallDialogState extends State<LogCallDialog> {
  Lead? _lead;
  bool _adding = false;
  String _query = '';
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _minutes = TextEditingController(text: '1');
  final _notes = TextEditingController();
  CallOutcome? _outcome;
  DateTime? _followUp;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _minutes.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _pickOutcome(CallOutcome o) {
    setState(() {
      _outcome = o;
      if (!o.reached) _minutes.text = '0';
      if (o.reached && _minutes.text == '0') _minutes.text = '1';
      if (o == CallOutcome.callback && _followUp == null) {
        _followUp = dayOf(DateTime.now()).add(const Duration(days: 1));
      }
    });
  }

  void _save() {
    final store = StoreScope.read(context);
    final outcome = _outcome;
    if (_lead == null) {
      if (!_adding) {
        toast('Choose who you called');
        return;
      }
      if (_name.text.trim().isEmpty ||
          phoneDigits(_phone.text).length < 6) {
        toast('Add the lead’s name and phone number');
        return;
      }
    }
    if (outcome == null) {
      toast('Pick how the call went');
      return;
    }
    store.logCall(
      lead: _lead,
      newName: _name.text,
      newPhone: _phone.text,
      outcome: outcome,
      durationMin: (int.tryParse(_minutes.text) ?? 0).clamp(0, 600),
      notes: _notes.text,
      nextFollowUp: _followUp,
    );
    Navigator.pop(context);
    toast('Call logged');
  }

  List<Lead> _candidates(AppStore store) {
    final now = DateTime.now();
    final q = _query.toLowerCase();
    final qDigits = phoneDigits(_query);
    final list = store.leads.where((l) {
      if (q.isEmpty) return !l.status.isClosed;
      return l.name.toLowerCase().contains(q) ||
          (l.company ?? '').toLowerCase().contains(q) ||
          (qDigits.length >= 3 && phoneDigits(l.phone).contains(qDigits));
    }).toList();
    int rank(Lead l) =>
        (l.ownerId == store.uid ? 0 : 2) + (l.followUpDue(now) ? 0 : 1);
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : b.updatedAt.compareTo(a.updatedAt);
    });
    return list.take(isPhone(context) ? 3 : 5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final lead = _lead;
    final now = dayOf(DateTime.now());
    final noteLength = _notes.text.trim().length;
    final closing = _outcome != null &&
        leadStatusAfterCall(lead?.status ?? LeadStatus.fresh, _outcome!)
            .isClosed;

    Widget who;
    if (lead != null) {
      who = Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: C.canvas,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(color: C.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(lead.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tx(15, w: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    LeadStatusTag(lead.status),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    [lead.phone, if (lead.company != null) lead.company!]
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(13, color: C.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Call ${lead.phone}',
              onPressed: () => dial(lead.phone),
              icon: const Icon(Icons.call_rounded, size: 18, color: C.marketing),
            ),
            TextButton(
              onPressed: () => setState(() => _lead = null),
              child: const Text('Change'),
            ),
          ],
        ),
      );
    } else if (_adding) {
      who = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldRow(children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone number'),
            ),
          ]),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: C.muted),
              onPressed: () => setState(() => _adding = false),
              child: const Text('Choose an existing lead instead'),
            ),
          ),
        ],
      );
    } else {
      final candidates = _candidates(store);
      who = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: SearchBox(
                width: null,
                hint: 'Search name, company or number',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => setState(() {
                _adding = true;
                final digits = phoneDigits(_query);
                if (digits.length >= 6) {
                  _phone.text = cleanPhone(_query);
                } else {
                  _name.text = _query;
                }
              }),
              icon: const Icon(Icons.add_rounded, size: 18, color: C.text),
              label: const Text('New'),
            ),
          ]),
          const SizedBox(height: 8),
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _query.isEmpty
                    ? 'No open leads yet. Tap “New” to add who you called.'
                    : 'No lead matches “$_query”. Tap “New” to add them.',
                style: tx(13, color: C.muted),
              ),
            )
          else
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusSm),
                border: Border.all(color: C.hairline),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < candidates.length; i++)
                    ListRow(
                      divider: i < candidates.length - 1,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      onTap: () => setState(() => _lead = candidates[i]),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(candidates[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tx(14, w: FontWeight.w700)),
                              Text(
                                [
                                  candidates[i].phone,
                                  if (candidates[i].company != null)
                                    candidates[i].company!,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tx(12.5, color: C.muted),
                              ),
                            ],
                          ),
                        ),
                        if (candidates[i].followUpDue(DateTime.now()))
                          FollowUpLabel(candidates[i])
                        else
                          LeadStatusTag(candidates[i].status),
                      ]),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    return DialogFrame(
      title: 'Log a call',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Save call'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Labeled('Who did you call?', child: who),
          const SizedBox(height: 18),
          Labeled(
            'How did it go?',
            child: ChipChoice<CallOutcome>(
              values: CallOutcome.values,
              selected: _outcome,
              labelOf: (o) => o.label,
              colorOf: outcomeColor,
              iconOf: outcomeIcon,
              onChanged: _pickOutcome,
            ),
          ),
          const SizedBox(height: 18),
          Labeled(
            'Duration (minutes)',
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: TextField(
                    controller: _minutes,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: tx(15, w: FontWeight.w700),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final m in const [1, 2, 5, 10, 15])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _QuickChip(
                              label: '${m}m',
                              selected: _minutes.text == '$m',
                              onTap: () =>
                                  setState(() => _minutes.text = '$m'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Labeled(
            'Notes',
            child: TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  hintText: 'What was said? What happens next?'),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(
              noteLength >= kGoodNoteLength
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              size: 14,
              color: noteLength >= kGoodNoteLength ? C.success : C.faint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                noteLength >= kGoodNoteLength
                    ? 'Nice — this call counts towards your data quality.'
                    : 'A short note (10+ characters) keeps your data quality up.',
                style: tx(12, color: C.muted),
              ),
            ),
          ]),
          if (!closing) ...[
            const SizedBox(height: 18),
            Labeled(
              'Next follow-up',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DateField(
                    value: _followUp,
                    hint: 'No follow-up',
                    allowPast: false,
                    onChanged: (v) => setState(() => _followUp = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final (label, days) in const [
                      ('Tomorrow', 1),
                      ('In 3 days', 3),
                      ('Next week', 7),
                    ])
                      _QuickChip(
                        label: label,
                        selected: _followUp != null &&
                            daysBetween(now, _followUp!) == days,
                        onTap: () => setState(
                            () => _followUp = now.add(Duration(days: days))),
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: kMotion,
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? C.ink : C.canvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? C.ink : C.hairline),
          ),
          child: Text(label,
              style: tx(13,
                  w: FontWeight.w700,
                  color: selected ? Colors.white : C.text)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lead dialog (add / detail)
// ---------------------------------------------------------------------------

Future<void> showLeadDialog(BuildContext context, {Lead? lead}) =>
    showAppDialog<void>(
      context,
      maxWidth: 720,
      dismissible: false,
      builder: (_) => LeadDialog(lead: lead),
    );

class LeadDialog extends StatefulWidget {
  const LeadDialog({super.key, this.lead});

  final Lead? lead;

  @override
  State<LeadDialog> createState() => _LeadDialogState();
}

class _LeadDialogState extends State<LeadDialog> {
  late final LeadDraft _draft;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _company;
  late final TextEditingController _value;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final store = StoreScope.read(context);
    final l = widget.lead;
    _draft = l != null ? LeadDraft.of(l) : LeadDraft(ownerId: store.uid);
    _name = TextEditingController(text: _draft.name);
    _phone = TextEditingController(text: _draft.phone);
    _company = TextEditingController(text: _draft.company);
    _value = TextEditingController(
        text: _draft.value == null ? '' : _draft.value!.round().toString());
    _notes = TextEditingController(text: _draft.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    _draft
      ..name = _name.text
      ..phone = _phone.text
      ..company = _company.text
      ..value = int.tryParse(_value.text)
      ..notes = _notes.text;
    if (_draft.name.trim().isEmpty || phoneDigits(_draft.phone).length < 6) {
      toast('A lead needs a name and a phone number');
      return;
    }
    if (_draft.status.isClosed) _draft.nextFollowUpAt = null;
    final l = widget.lead;
    if (l == null) {
      store.createLead(_draft);
    } else {
      store.updateLead(l, _draft);
    }
    Navigator.pop(context);
  }

  Future<void> _delete(Lead l) async {
    final store = StoreScope.read(context);
    final navigator = Navigator.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Delete this lead?',
      message: '${l.name} will be removed. Calls already logged stay in the '
          'call log.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    store.deleteLead(l);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final original = widget.lead;
    final live = original == null
        ? null
        : store.leads.where((l) => l.id == original.id).firstOrNull ?? original;
    final history = live == null
        ? const <CallLog>[]
        : store.calls.where((c) => c.leadId == live.id).toList();
    final owners = [
      for (final u in store.callers) u.id,
      if (!store.callers.any((u) => u.id == _draft.ownerId)) _draft.ownerId,
    ];

    return DialogFrame(
      title: live == null ? 'New lead' : live.name,
      subtitle: live == null
          ? null
          : 'Added ${fmtDay(live.createdAt)} · ${plural(live.callCount, 'call')}'
              '${live.lastCallAt != null ? ' · last ${ago(live.lastCallAt!)}' : ''}',
      leadingActions: [
        if (live != null && store.isManager)
          IconButton(
            tooltip: 'Delete lead',
            onPressed: () => _delete(live),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: C.danger),
          ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(live == null ? 'Add lead' : 'Save changes'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (live != null) ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => dial(live.phone),
                  icon: const Icon(Icons.call_rounded,
                      size: 18, color: C.marketing),
                  label: Text('Call ${live.phone}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: C.ink),
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    showLogCallDialog(navigator.context, lead: live);
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Log a call'),
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ],
          FieldRow(children: [
            Labeled(
              'Name',
              child: TextField(
                controller: _name,
                autofocus: live == null,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            Labeled(
              'Phone',
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Company',
              child: TextField(
                controller: _company,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Optional'),
              ),
            ),
            Labeled(
              'Deal value (INR)',
              child: TextField(
                controller: _value,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(hintText: 'Optional'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Status',
              child: SelectField<LeadStatus>(
                value: _draft.status,
                options: LeadStatus.values,
                textOf: (s) => s.label,
                leadingOf: (s) =>
                    Dot(leadStatusColor(s ?? LeadStatus.fresh)),
                onChanged: (v) => setState(() => _draft.status = v!),
              ),
            ),
            Labeled(
              'Next follow-up',
              child: DateField(
                value: _draft.status.isClosed ? null : _draft.nextFollowUpAt,
                hint: _draft.status.isClosed ? 'Closed' : 'No follow-up',
                onChanged: (v) => setState(() => _draft.nextFollowUpAt = v),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FieldRow(children: [
            Labeled(
              'Interested in',
              child: SelectField<LeadService>(
                value: _draft.service,
                options: LeadService.values,
                textOf: (s) => s.label,
                onChanged: (v) => setState(() => _draft.service = v!),
              ),
            ),
            Labeled(
              'Source',
              child: SelectField<LeadSource>(
                value: _draft.source,
                options: LeadSource.values,
                textOf: (s) => s.label,
                onChanged: (v) => setState(() => _draft.source = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Labeled(
            'Owner',
            child: SelectField<String>(
              enabled: store.isManager,
              value: _draft.ownerId,
              options: owners,
              textOf: store.nameOf,
              leadingOf: (id) =>
                  Avatar(store.userById(id), size: 22, tooltip: false),
              onChanged: (v) => setState(() => _draft.ownerId = v!),
            ),
          ),
          const SizedBox(height: 16),
          Labeled(
            'Notes',
            child: TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'Background, requirements, budget…'),
            ),
          ),
          if (live != null) ...[
            const SizedBox(height: 24),
            Text('Call timeline', style: tx(14, w: FontWeight.w800)),
            const SizedBox(height: 10),
            if (history.isEmpty)
              Text(
                live.callCount == 0
                    ? 'No calls logged for this lead yet.'
                    : 'Earlier calls by other agents aren’t shown here.',
                style: tx(13, color: C.muted),
              )
            else
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border: Border.all(color: C.hairline),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < history.length; i++)
                      CallTile(
                        history[i],
                        showLead: false,
                        showAgent: true,
                        divider: i < history.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paste leads
// ---------------------------------------------------------------------------

class PasteLeadsDialog extends StatefulWidget {
  const PasteLeadsDialog({super.key});

  @override
  State<PasteLeadsDialog> createState() => _PasteLeadsDialogState();
}

class _PasteLeadsDialogState extends State<PasteLeadsDialog> {
  final _text = TextEditingController();
  LeadImport _parsed = const LeadImport([], 0);
  String? _ownerId;
  LeadSource _source = LeadSource.cold;
  LeadService _service = LeadService.other;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final owner = _ownerId ?? store.uid;
    final count = _parsed.leads.length;
    return DialogFrame(
      title: 'Paste leads',
      subtitle: 'One per line: Name, Phone, Company',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: count == 0
              ? null
              : () {
                  store.importLeads(
                    _parsed.leads,
                    ownerId: owner,
                    source: _source,
                    service: _service,
                  );
                  Navigator.pop(context);
                },
          child: Text(count == 0 ? 'Import' : 'Import ${plural(count, 'lead')}'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 7,
            maxLines: 12,
            style: tx(13.5, h: 1.5),
            onChanged: (v) => setState(() => _parsed = parseLeadLines(v)),
            decoration: const InputDecoration(
              hintText: 'Ravi Kumar, 98480 12345, Sri Sai Traders\n'
                  'Lakshmi Devi, 90000 54321\n'
                  '…or paste rows straight from a spreadsheet',
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(
              count > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 16,
              color: count > 0 ? C.success : C.faint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                count == 0 && _parsed.skipped == 0
                    ? 'Leads are checked as you paste.'
                    : '${plural(count, 'lead')} ready'
                        '${_parsed.skipped > 0 ? ' · ${plural(_parsed.skipped, 'line')} skipped (missing phone or duplicate)' : ''}',
                style: tx(13, w: FontWeight.w600, color: C.muted),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          if (store.isManager) ...[
            Labeled(
              'Assign to',
              child: SelectField<String>(
                value: owner,
                options: [for (final u in store.callers) u.id],
                textOf: store.nameOf,
                leadingOf: (id) =>
                    Avatar(store.userById(id), size: 22, tooltip: false),
                onChanged: (v) => setState(() => _ownerId = v),
              ),
            ),
            const SizedBox(height: 16),
          ],
          FieldRow(children: [
            Labeled(
              'Source',
              child: SelectField<LeadSource>(
                value: _source,
                options: LeadSource.values,
                textOf: (s) => s.label,
                onChanged: (v) => setState(() => _source = v!),
              ),
            ),
            Labeled(
              'Interested in',
              child: SelectField<LeadService>(
                value: _service,
                options: LeadService.values,
                textOf: (s) => s.label,
                onChanged: (v) => setState(() => _service = v!),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Convert a website enquiry
// ---------------------------------------------------------------------------

class ConvertInquiryDialog extends StatefulWidget {
  const ConvertInquiryDialog({super.key, required this.inquiry});

  final Inquiry inquiry;

  @override
  State<ConvertInquiryDialog> createState() => _ConvertInquiryDialogState();
}

class _ConvertInquiryDialogState extends State<ConvertInquiryDialog> {
  String? _ownerId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final q = widget.inquiry;
    final callers = store.callers;
    final marketing = callers.where((u) => u.dept == Dept.marketing).toList();
    final owner = _ownerId ??
        (marketing.isNotEmpty ? marketing.first.id : store.uid);
    return DialogFrame(
      title: 'Convert to lead',
      subtitle: '${q.name} · ${q.contact}',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            store.convertInquiry(q, owner);
            Navigator.pop(context);
          },
          child: const Text('Create lead'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (q.message.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.canvas,
                borderRadius: BorderRadius.circular(kRadiusSm),
                border: Border.all(color: C.hairline),
              ),
              child: Text(q.message, style: tx(13.5, color: C.muted, h: 1.5)),
            ),
            const SizedBox(height: 16),
          ],
          Labeled(
            'Who should follow up?',
            child: SelectField<String>(
              value: owner,
              options: [for (final u in callers) u.id],
              textOf: store.nameOf,
              leadingOf: (id) =>
                  Avatar(store.userById(id), size: 22, tooltip: false),
              onChanged: (v) => setState(() => _ownerId = v),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'The lead lands in their follow-ups for today, with the enquiry '
            'message saved as a note.',
            style: tx(12.5, color: C.muted, h: 1.45),
          ),
        ],
      ),
    );
  }
}
