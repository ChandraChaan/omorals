import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

// ---------------------------------------------------------------------------
// Dates
// ---------------------------------------------------------------------------

/// Reads a Firestore timestamp-ish value. Returns null when absent.
DateTime? asDate(Object? v) => switch (v) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => null,
    };

/// Server timestamps are null in the first local snapshot; treat as "now".
DateTime asDateOrNow(Object? v) => asDate(v) ?? DateTime.now();

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whole calendar days from [from] to [to] (negative when [to] is earlier).
int daysBetween(DateTime from, DateTime to) =>
    (dayOf(to).difference(dayOf(from)).inHours / 24).round();

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

abstract interface class Keyed {
  String get key;
  String get label;
}

T enumByKey<T extends Keyed>(List<T> values, Object? key, T fallback) {
  for (final v in values) {
    if (v.key == key) return v;
  }
  return fallback;
}

enum Role implements Keyed {
  owner('owner', 'Owner'),
  admin('admin', 'Admin'),
  manager('manager', 'Manager'),
  member('member', 'Member');

  const Role(this.key, this.label);
  @override
  final String key;
  @override
  final String label;

  bool get isManager => this != Role.member;
  bool get isAdmin => this == Role.owner || this == Role.admin;
}

enum Dept implements Keyed {
  youtube('youtube', 'YouTube'),
  marketing('marketing', 'Marketing'),
  development('development', 'Development');

  const Dept(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

enum UserStatus implements Keyed {
  pending('pending', 'Pending'),
  active('active', 'Active'),
  disabled('disabled', 'Disabled');

  const UserStatus(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

enum TaskStatus implements Keyed {
  todo('todo', 'To do'),
  inProgress('in_progress', 'In progress'),
  review('review', 'In review'),
  done('done', 'Done');

  const TaskStatus(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

enum TaskPriority implements Keyed {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  const TaskPriority(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

enum VideoStage implements Keyed {
  idea('idea', 'Idea'),
  script('script', 'Script'),
  voiceover('voiceover', 'Voiceover'),
  editing('editing', 'Editing'),
  thumbnail('thumbnail', 'Thumbnail'),
  review('review', 'Review'),
  scheduled('scheduled', 'Scheduled'),
  published('published', 'Published');

  const VideoStage(this.key, this.label);
  @override
  final String key;
  @override
  final String label;

  /// Stages where work is actively happening (and a video can get stuck).
  bool get inProduction =>
      this != VideoStage.scheduled && this != VideoStage.published;
}

enum VideoFormat implements Keyed {
  long('long', 'Long'),
  short('short', 'Short');

  const VideoFormat(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

enum LeadSource implements Keyed {
  website('website', 'Website'),
  referral('referral', 'Referral'),
  cold('cold', 'Cold call'),
  social('social', 'Social'),
  ads('ads', 'Ads'),
  other('other', 'Other');

  const LeadSource(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

enum LeadService implements Keyed {
  youtube('youtube', 'YouTube'),
  marketing('marketing', 'Marketing'),
  development('development', 'Development'),
  other('other', 'Other');

  const LeadService(this.key, this.label);
  @override
  final String key;
  @override
  final String label;

  /// Best-effort mapping of the free-text service on a website enquiry.
  static LeadService guess(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('youtube') || s.contains('video')) return youtube;
    if (s.contains('market') || s.contains('lead') || s.contains('call')) {
      return marketing;
    }
    if (s.contains('dev') || s.contains('app') || s.contains('web')) {
      return development;
    }
    return other;
  }
}

enum LeadStatus implements Keyed {
  fresh('new', 'New'),
  contacted('contacted', 'Contacted'),
  interested('interested', 'Interested'),
  followUp('follow_up', 'Follow up'),
  won('won', 'Won'),
  lost('lost', 'Lost');

  const LeadStatus(this.key, this.label);
  @override
  final String key;
  @override
  final String label;

  bool get isClosed => this == LeadStatus.won || this == LeadStatus.lost;
}

enum CallOutcome implements Keyed {
  connected('connected', 'Connected'),
  noAnswer('no_answer', 'No answer'),
  busy('busy', 'Busy'),
  callback('callback', 'Call back'),
  interested('interested', 'Interested'),
  notInterested('not_interested', 'Not interested'),
  converted('converted', 'Converted'),
  wrongNumber('wrong_number', 'Wrong number');

  const CallOutcome(this.key, this.label);
  @override
  final String key;
  @override
  final String label;

  /// Whether the caller actually reached the person.
  bool get reached => switch (this) {
        CallOutcome.noAnswer ||
        CallOutcome.busy ||
        CallOutcome.wrongNumber =>
          false,
        _ => true,
      };
}

enum InquiryStatus implements Keyed {
  fresh('new', 'New'),
  converted('converted', 'Converted'),
  dismissed('dismissed', 'Dismissed');

  const InquiryStatus(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

enum ActivityKind implements Keyed {
  task('task', 'Task'),
  video('video', 'Video'),
  call('call', 'Call'),
  lead('lead', 'Lead'),
  team('team', 'Team');

  const ActivityKind(this.key, this.label);
  @override
  final String key;
  @override
  final String label;
}

const kDefaultSeries = [
  'Bujji & Chinni Kathalu',
  'History',
  'Tinku Adige Prashnalu',
  'Chittilata',
  'Other',
];

const kDefaultCallTarget = 40;

/// A video is "stuck" (amber) after this many days in one stage…
const kStuckDays = 3;

/// …and in trouble (red) after this many.
const kVeryStuckDays = 7;

/// Notes this long (trimmed) count as a properly documented call.
const kGoodNoteLength = 10;

// ---------------------------------------------------------------------------
// Parsing helpers
// ---------------------------------------------------------------------------

String _str(Object? v, [String fallback = '']) => v is String ? v : fallback;

String? _strOrNull(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

// ---------------------------------------------------------------------------
// People
// ---------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.title,
    required this.role,
    required this.dept,
    required this.status,
    this.dailyCallTarget = kDefaultCallTarget,
    required this.createdAt,
    this.lastSeenAt,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> m) => AppUser(
        id: id,
        name: _str(m['name'], 'Teammate'),
        email: _str(m['email']),
        photoUrl: _strOrNull(m['photoUrl']),
        phone: _strOrNull(m['phone']),
        title: _strOrNull(m['title']),
        role: enumByKey(Role.values, m['role'], Role.member),
        dept: enumByKey(Dept.values, m['dept'], Dept.youtube),
        status: enumByKey(UserStatus.values, m['status'], UserStatus.pending),
        dailyCallTarget: _int(m['dailyCallTarget'], kDefaultCallTarget),
        createdAt: asDateOrNow(m['createdAt']),
        lastSeenAt: asDate(m['lastSeenAt']),
      );

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? title;
  final Role role;
  final Dept dept;
  final UserStatus status;
  final int dailyCallTarget;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  bool get isActive => status == UserStatus.active;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  String get initials => initialsOf(name);
}

String initialsOf(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return String.fromCharCodes(parts.first.runes.take(2)).toUpperCase();
  }
  return (String.fromCharCode(parts.first.runes.first) +
          String.fromCharCode(parts.last.runes.first))
      .toUpperCase();
}

// ---------------------------------------------------------------------------
// Projects & tasks
// ---------------------------------------------------------------------------

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.dept,
    required this.color,
    this.client,
    this.archived = false,
    required this.createdAt,
  });

  factory Project.fromMap(String id, Map<String, dynamic> m) => Project(
        id: id,
        name: _str(m['name'], 'Untitled project'),
        dept: enumByKey(Dept.values, m['dept'], Dept.development),
        color: _int(m['color']),
        client: _strOrNull(m['client']),
        archived: m['archived'] == true,
        createdAt: asDateOrNow(m['createdAt']),
      );

  final String id;
  final String name;
  final Dept dept;
  final int color;
  final String? client;
  final bool archived;
  final DateTime createdAt;
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.projectId,
    required this.dept,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.assigneeId,
    required this.reporterId,
    this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.commentCount = 0,
  });

  factory Task.fromMap(String id, Map<String, dynamic> m) => Task(
        id: id,
        title: _str(m['title'], 'Untitled task'),
        description: _str(m['description']),
        projectId: _strOrNull(m['projectId']),
        dept: enumByKey(Dept.values, m['dept'], Dept.development),
        status: enumByKey(TaskStatus.values, m['status'], TaskStatus.todo),
        priority: enumByKey(
            TaskPriority.values, m['priority'], TaskPriority.medium),
        assigneeId: _strOrNull(m['assigneeId']),
        reporterId: _str(m['reporterId']),
        dueAt: asDate(m['dueAt']),
        createdAt: asDateOrNow(m['createdAt']),
        updatedAt: asDateOrNow(m['updatedAt']),
        completedAt: asDate(m['completedAt']),
        commentCount: _int(m['commentCount']),
      );

  final String id;
  final String title;
  final String description;
  final String? projectId;
  final Dept dept;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final String reporterId;
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int commentCount;

  bool get isOpen => status != TaskStatus.done;

  /// A task is overdue once its due *day* has fully passed and it isn't done.
  bool isOverdue(DateTime now) =>
      isOpen && dueAt != null && dayOf(dueAt!).isBefore(dayOf(now));

  bool isDueToday(DateTime now) =>
      isOpen && dueAt != null && sameDay(dueAt!, now);
}

/// Orders open tasks the way people want to work them: dated first (soonest
/// at the top), then by priority, then newest.
int compareTasksByDue(Task a, Task b) {
  final ad = a.dueAt, bd = b.dueAt;
  if (ad != null && bd != null) {
    final c = ad.compareTo(bd);
    if (c != 0) return c;
  } else if (ad != null) {
    return -1;
  } else if (bd != null) {
    return 1;
  }
  final p = b.priority.index.compareTo(a.priority.index);
  if (p != 0) return p;
  return b.createdAt.compareTo(a.createdAt);
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.at,
  });

  factory TaskComment.fromMap(String id, Map<String, dynamic> m) =>
      TaskComment(
        id: id,
        authorId: _str(m['authorId']),
        text: _str(m['text']),
        at: asDateOrNow(m['at']),
      );

  final String id;
  final String authorId;
  final String text;
  final DateTime at;
}

// ---------------------------------------------------------------------------
// Videos
// ---------------------------------------------------------------------------

class StageEvent {
  const StageEvent({required this.stage, required this.by, required this.at});

  factory StageEvent.fromMap(Map<String, dynamic> m) => StageEvent(
        stage: enumByKey(VideoStage.values, m['stage'], VideoStage.idea),
        by: _str(m['by']),
        at: asDateOrNow(m['at']),
      );

  final VideoStage stage;
  final String by;
  final DateTime at;
}

class Video {
  const Video({
    required this.id,
    required this.title,
    required this.series,
    this.format = VideoFormat.long,
    this.stage = VideoStage.idea,
    this.assigneeId,
    this.publishAt,
    this.youtubeUrl,
    this.notes = '',
    required this.stageSince,
    this.history = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Video.fromMap(String id, Map<String, dynamic> m) {
    final raw = m['history'];
    final history = <StageEvent>[
      if (raw is List)
        for (final e in raw)
          if (e is Map) StageEvent.fromMap(Map<String, dynamic>.from(e)),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return Video(
      id: id,
      title: _str(m['title'], 'Untitled video'),
      series: _str(m['series'], 'Other'),
      format: enumByKey(VideoFormat.values, m['format'], VideoFormat.long),
      stage: enumByKey(VideoStage.values, m['stage'], VideoStage.idea),
      assigneeId: _strOrNull(m['assigneeId']),
      publishAt: asDate(m['publishAt']),
      youtubeUrl: _strOrNull(m['youtubeUrl']),
      notes: _str(m['notes']),
      stageSince: asDateOrNow(m['stageSince']),
      history: history,
      createdBy: _str(m['createdBy']),
      createdAt: asDateOrNow(m['createdAt']),
      updatedAt: asDateOrNow(m['updatedAt']),
    );
  }

  final String id;
  final String title;
  final String series;
  final VideoFormat format;
  final VideoStage stage;
  final String? assigneeId;
  final DateTime? publishAt;
  final String? youtubeUrl;
  final String notes;
  final DateTime stageSince;
  final List<StageEvent> history;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPublished => stage == VideoStage.published;

  /// 0..1 — how far along the pipeline the video is.
  double get progress => stage.index / (VideoStage.values.length - 1);

  int daysInStage(DateTime now) {
    final d = daysBetween(stageSince, now);
    return d < 0 ? 0 : d;
  }

  /// 0 = fine, 1 = amber (more than [kStuckDays]), 2 = red (more than
  /// [kVeryStuckDays]). Scheduled and published videos never go stale.
  int staleness(DateTime now) {
    if (!stage.inProduction) return 0;
    final d = daysInStage(now);
    if (d > kVeryStuckDays) return 2;
    if (d > kStuckDays) return 1;
    return 0;
  }

  bool isStuck(DateTime now) => staleness(now) > 0;
}

// ---------------------------------------------------------------------------
// Leads & calls
// ---------------------------------------------------------------------------

class Lead {
  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    this.company,
    this.source = LeadSource.cold,
    this.service = LeadService.other,
    this.status = LeadStatus.fresh,
    required this.ownerId,
    this.nextFollowUpAt,
    this.lastCallAt,
    this.callCount = 0,
    this.notes = '',
    this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lead.fromMap(String id, Map<String, dynamic> m) => Lead(
        id: id,
        name: _str(m['name'], 'Unnamed lead'),
        phone: _str(m['phone']),
        company: _strOrNull(m['company']),
        source: enumByKey(LeadSource.values, m['source'], LeadSource.other),
        service: enumByKey(LeadService.values, m['service'], LeadService.other),
        status: enumByKey(LeadStatus.values, m['status'], LeadStatus.fresh),
        ownerId: _str(m['ownerId']),
        nextFollowUpAt: asDate(m['nextFollowUpAt']),
        lastCallAt: asDate(m['lastCallAt']),
        callCount: _int(m['callCount']),
        notes: _str(m['notes']),
        value: m['value'] is num ? m['value'] as num : null,
        createdAt: asDateOrNow(m['createdAt']),
        updatedAt: asDateOrNow(m['updatedAt']),
      );

  final String id;
  final String name;
  final String phone;
  final String? company;
  final LeadSource source;
  final LeadService service;
  final LeadStatus status;
  final String ownerId;
  final DateTime? nextFollowUpAt;
  final DateTime? lastCallAt;
  final int callCount;
  final String notes;
  final num? value;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Follow-up scheduled for today or earlier on a lead that is still open.
  bool followUpDue(DateTime now) =>
      !status.isClosed &&
      nextFollowUpAt != null &&
      !dayOf(nextFollowUpAt!).isAfter(dayOf(now));

  /// Follow-up day has passed without a call.
  bool followUpOverdue(DateTime now) =>
      !status.isClosed &&
      nextFollowUpAt != null &&
      dayOf(nextFollowUpAt!).isBefore(dayOf(now));
}

class CallLog {
  const CallLog({
    required this.id,
    required this.leadId,
    required this.leadName,
    required this.phone,
    required this.callerId,
    required this.outcome,
    this.durationMin = 0,
    this.notes = '',
    required this.at,
  });

  factory CallLog.fromMap(String id, Map<String, dynamic> m) => CallLog(
        id: id,
        leadId: _str(m['leadId']),
        leadName: _str(m['leadName'], 'Unknown'),
        phone: _str(m['phone']),
        callerId: _str(m['callerId']),
        outcome:
            enumByKey(CallOutcome.values, m['outcome'], CallOutcome.connected),
        durationMin: _int(m['durationMin']),
        notes: _str(m['notes']),
        at: asDateOrNow(m['at']),
      );

  final String id;
  final String leadId;
  final String leadName;
  final String phone;
  final String callerId;
  final CallOutcome outcome;
  final int durationMin;
  final String notes;
  final DateTime at;

  bool get hasGoodNotes => notes.trim().length >= kGoodNoteLength;
}

/// Aggregates for a set of calls (one agent, one period).
class CallStats {
  CallStats(Iterable<CallLog> calls) {
    for (final c in calls) {
      total++;
      if (c.outcome.reached) connected++;
      if (c.outcome == CallOutcome.interested) interested++;
      if (c.outcome == CallOutcome.converted) converted++;
      if (c.hasGoodNotes) documented++;
      talkMin += c.durationMin;
    }
  }

  int total = 0;
  int connected = 0;
  int interested = 0;
  int converted = 0;
  int documented = 0;
  int talkMin = 0;

  double get connectRate => total == 0 ? 0 : connected / total;

  /// Share of calls with notes of [kGoodNoteLength]+ characters.
  double get dataQuality => total == 0 ? 0 : documented / total;
}

/// What a lead's status becomes after a call with the given [outcome].
///
/// Decisive outcomes map directly; neutral ones (connected / no answer /
/// busy) only move a brand-new lead to "contacted" and never pull a lead that
/// is further along backwards. A won deal is only reopened by an explicit
/// negative outcome.
LeadStatus leadStatusAfterCall(LeadStatus current, CallOutcome outcome) {
  switch (outcome) {
    case CallOutcome.converted:
      return LeadStatus.won;
    case CallOutcome.notInterested:
    case CallOutcome.wrongNumber:
      return LeadStatus.lost;
    case CallOutcome.interested:
      return current == LeadStatus.won ? current : LeadStatus.interested;
    case CallOutcome.callback:
      return current == LeadStatus.won ? current : LeadStatus.followUp;
    case CallOutcome.connected:
    case CallOutcome.noAnswer:
    case CallOutcome.busy:
      return current == LeadStatus.fresh ? LeadStatus.contacted : current;
  }
}

/// Counts calls per day for the [days] days ending on [now]'s day.
/// Index 0 is the oldest day; the last entry is today.
List<int> callsPerDay(Iterable<CallLog> calls, DateTime now, {int days = 14}) {
  final out = List<int>.filled(days, 0);
  for (final c in calls) {
    final back = daysBetween(c.at, now);
    if (back >= 0 && back < days) out[days - 1 - back]++;
  }
  return out;
}

class ParsedLead {
  const ParsedLead({required this.name, required this.phone, this.company});
  final String name;
  final String phone;
  final String? company;
}

class LeadImport {
  const LeadImport(this.leads, this.skipped);
  final List<ParsedLead> leads;

  /// Non-empty lines that could not be read (missing name or phone).
  final int skipped;
}

/// Parses pasted text, one lead per line: `Name, Phone, Company`.
/// Tabs work as separators too, so rows copied from a spreadsheet paste fine.
LeadImport parseLeadLines(String text) {
  final leads = <ParsedLead>[];
  final seen = <String>{};
  var skipped = 0;
  for (final raw in text.split(RegExp(r'[\r\n]+'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'[,\t;]')).map((p) => p.trim()).toList();
    final name = parts.first;
    final phone = parts.length > 1 ? cleanPhone(parts[1]) : '';
    if (name.isEmpty || phoneDigits(phone).length < 6) {
      skipped++;
      continue;
    }
    if (!seen.add(phoneDigits(phone))) {
      skipped++;
      continue;
    }
    final company = parts.skip(2).where((p) => p.isNotEmpty).join(', ');
    leads.add(ParsedLead(
      name: name,
      phone: phone,
      company: company.isEmpty ? null : company,
    ));
  }
  return LeadImport(leads, skipped);
}

/// Keeps digits, a leading + and single spaces.
String cleanPhone(String raw) {
  final t = raw.trim().replaceAll(RegExp(r'[^\d+ ]'), '');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String phoneDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

// ---------------------------------------------------------------------------
// Website enquiries & activity
// ---------------------------------------------------------------------------

class Inquiry {
  const Inquiry({
    required this.id,
    required this.name,
    required this.contact,
    required this.service,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory Inquiry.fromMap(String id, Map<String, dynamic> m) => Inquiry(
        id: id,
        name: _str(m['name'], 'Website visitor'),
        contact: _str(m['contact']),
        service: _str(m['service']),
        message: _str(m['message']),
        status:
            enumByKey(InquiryStatus.values, m['status'], InquiryStatus.fresh),
        createdAt: asDateOrNow(m['createdAt']),
      );

  final String id;
  final String name;
  final String contact;
  final String service;
  final String message;
  final InquiryStatus status;
  final DateTime createdAt;

  bool get isNew => status == InquiryStatus.fresh;
}

class Activity {
  const Activity({
    required this.id,
    required this.actorId,
    required this.text,
    required this.kind,
    required this.at,
  });

  factory Activity.fromMap(String id, Map<String, dynamic> m) => Activity(
        id: id,
        actorId: _str(m['actorId']),
        text: _str(m['text']),
        kind: enumByKey(ActivityKind.values, m['kind'], ActivityKind.task),
        at: asDateOrNow(m['at']),
      );

  final String id;
  final String actorId;
  final String text;
  final ActivityKind kind;
  final DateTime at;
}
