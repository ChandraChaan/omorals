import 'package:omorals/models.dart';
import 'package:omorals/store.dart';

/// A small but realistic workspace used by widget tests.
AppStore seededStore({String as = 'owner'}) {
  final now = DateTime.now();
  DateTime ago(int days, [int hours = 0]) =>
      now.subtract(Duration(days: days, hours: hours));
  DateTime ahead(int days) => now.add(Duration(days: days));

  AppUser user(String id, String name, Role role, Dept dept,
          {String? title,
          UserStatus status = UserStatus.active,
          int target = 40}) =>
      AppUser(
        id: id,
        name: name,
        email: '$id@omorals.test',
        title: title,
        role: role,
        dept: dept,
        status: status,
        dailyCallTarget: target,
        createdAt: ago(60),
        lastSeenAt: ago(0, 2),
      );

  final users = [
    user('owner', 'Chandra Sekhar', Role.owner, Dept.youtube, title: 'Founder'),
    user('lead', 'Anitha Reddy', Role.manager, Dept.marketing,
        title: 'Marketing lead'),
    user('editor', 'Kiran Varma', Role.member, Dept.youtube,
        title: 'Video editor'),
    user('writer', 'Sravani Devi', Role.member, Dept.youtube,
        title: 'Script writer'),
    user('caller', 'Ravi Teja', Role.member, Dept.marketing,
        title: 'Tele-caller', target: 30),
    user('caller2', 'Lakshmi Priya', Role.member, Dept.marketing,
        title: 'Tele-caller'),
    user('dev', 'Arjun Rao', Role.member, Dept.development,
        title: 'Flutter developer'),
    user('newbie', 'Pavan Kumar', Role.member, Dept.youtube,
        status: UserStatus.pending),
    user('gone', 'Old Intern', Role.member, Dept.development,
        status: UserStatus.disabled),
  ];

  final projects = [
    Project(
        id: 'p1',
        name: 'Clinic booking app',
        dept: Dept.development,
        color: 0,
        client: 'Sai Clinics',
        createdAt: ago(40)),
    Project(
        id: 'p2',
        name: 'Diwali campaign',
        dept: Dept.marketing,
        color: 3,
        createdAt: ago(20)),
    Project(
        id: 'p3',
        name: 'Channel growth',
        dept: Dept.youtube,
        color: 1,
        createdAt: ago(30)),
  ];

  var n = 0;
  Task task(String title, TaskStatus status,
          {String? project,
          Dept dept = Dept.development,
          String? assignee,
          TaskPriority priority = TaskPriority.medium,
          DateTime? due,
          int comments = 0}) =>
      Task(
        id: 't${n++}',
        title: title,
        description: 'Details for $title',
        projectId: project,
        dept: dept,
        status: status,
        priority: priority,
        assigneeId: assignee,
        reporterId: 'owner',
        dueAt: due,
        createdAt: ago(10 - n % 5),
        updatedAt: ago(1),
        completedAt: status == TaskStatus.done ? ago(2) : null,
        commentCount: comments,
      );

  final tasks = [
    task('Design appointment booking flow', TaskStatus.inProgress,
        project: 'p1',
        assignee: 'dev',
        priority: TaskPriority.high,
        due: ahead(2),
        comments: 3),
    task('Set up push notifications', TaskStatus.todo,
        project: 'p1', assignee: 'dev', due: ago(2)),
    task('Fix login crash on older Android phones', TaskStatus.review,
        project: 'p1',
        assignee: 'dev',
        priority: TaskPriority.urgent,
        due: now),
    task('Publish release notes', TaskStatus.done,
        project: 'p1', assignee: 'dev'),
    task('Write Diwali offer call script', TaskStatus.todo,
        project: 'p2',
        dept: Dept.marketing,
        assignee: 'caller',
        priority: TaskPriority.high,
        due: ahead(1)),
    task('Clean up the October lead sheet', TaskStatus.inProgress,
        project: 'p2',
        dept: Dept.marketing,
        assignee: 'caller2',
        due: ago(1),
        comments: 1),
    task('Thumbnail A/B test for History series', TaskStatus.todo,
        project: 'p3',
        dept: Dept.youtube,
        assignee: 'editor',
        priority: TaskPriority.low),
    task('Plan November upload calendar', TaskStatus.inProgress,
        project: 'p3',
        dept: Dept.youtube,
        assignee: 'owner',
        priority: TaskPriority.high,
        due: ahead(3)),
    task('Record voiceover for Tenali Rama episode', TaskStatus.review,
        dept: Dept.youtube, assignee: 'writer', due: ahead(1)),
    task('Renew domain and hosting', TaskStatus.done,
        assignee: 'owner', priority: TaskPriority.low),
    task('Collect client testimonials', TaskStatus.todo,
        dept: Dept.marketing, due: ahead(6)),
  ];

  Video video(String title, String series, VideoStage stage, int daysIn,
          {String? assignee,
          VideoFormat format = VideoFormat.long,
          DateTime? publish,
          String? url}) =>
      Video(
        id: 'v${n++}',
        title: title,
        series: series,
        format: format,
        stage: stage,
        assigneeId: assignee,
        publishAt: publish,
        youtubeUrl: url,
        notes: '',
        stageSince: ago(daysIn),
        history: [
          StageEvent(stage: VideoStage.idea, by: 'owner', at: ago(daysIn + 6)),
          if (stage != VideoStage.idea)
            StageEvent(stage: stage, by: assignee ?? 'owner', at: ago(daysIn)),
        ],
        createdBy: 'owner',
        createdAt: ago(daysIn + 6),
        updatedAt: ago(daysIn),
      );

  final videos = [
    video('The clever crow and the pot', 'Bujji & Chinni Kathalu',
        VideoStage.idea, 1),
    video('Why is the sky blue?', 'Tinku Adige Prashnalu', VideoStage.idea, 9,
        assignee: 'writer', format: VideoFormat.short),
    video('Sri Krishnadevaraya — the golden age', 'History',
        VideoStage.script, 2,
        assignee: 'writer', publish: ahead(12)),
    video('The honest woodcutter', 'Bujji & Chinni Kathalu',
        VideoStage.voiceover, 5,
        assignee: 'writer', publish: ahead(8)),
    video('Tenali Rama and the thieves', 'History', VideoStage.editing, 4,
        assignee: 'editor', publish: ahead(5)),
    video('Chittilata learns to share', 'Chittilata', VideoStage.editing, 8,
        assignee: 'editor', format: VideoFormat.short),
    video('The lion and the mouse', 'Bujji & Chinni Kathalu',
        VideoStage.thumbnail, 1,
        assignee: 'editor', publish: ahead(3)),
    video('How do aeroplanes fly?', 'Tinku Adige Prashnalu', VideoStage.review,
        2,
        assignee: 'owner', publish: ahead(2)),
    video('Kakatiya dynasty in ten minutes', 'History', VideoStage.scheduled,
        1,
        assignee: 'owner', publish: ahead(1), url: 'https://youtu.be/abc'),
    video('The thirsty crow', 'Bujji & Chinni Kathalu', VideoStage.published,
        3,
        assignee: 'editor', publish: ago(3), url: 'https://youtu.be/def'),
    video('Chittilata and the rain', 'Chittilata', VideoStage.published, 12,
        assignee: 'editor',
        format: VideoFormat.short,
        publish: ago(12),
        url: 'https://youtu.be/ghi'),
  ];

  Lead lead(String id, String name, String phone, LeadStatus status,
          String owner,
          {String? company, DateTime? next, int calls = 0}) =>
      Lead(
        id: id,
        name: name,
        phone: phone,
        company: company,
        source: LeadSource.cold,
        service: LeadService.development,
        status: status,
        ownerId: owner,
        nextFollowUpAt: next,
        lastCallAt: calls == 0 ? null : ago(1),
        callCount: calls,
        notes: '',
        createdAt: ago(14),
        updatedAt: ago(1),
      );

  final leads = [
    lead('l1', 'Suresh Babu', '98480 12345', LeadStatus.followUp, 'caller',
        company: 'Sri Sai Traders', next: now, calls: 2),
    lead('l2', 'Padma Latha', '90000 54321', LeadStatus.interested, 'caller',
        company: 'Padma Boutique', next: ago(2), calls: 3),
    lead('l3', 'Venkat Rao', '99123 45678', LeadStatus.fresh, 'caller'),
    lead('l4', 'Nagarjuna Stores', '97000 11223', LeadStatus.contacted,
        'caller',
        next: ahead(2), calls: 1),
    lead('l5', 'Bhavani Textiles', '96666 77889', LeadStatus.won, 'caller2',
        company: 'Bhavani Textiles', calls: 4),
    lead('l6', 'Ramesh Chowdary', '95555 00112', LeadStatus.followUp,
        'caller2',
        next: ago(1), calls: 2),
    lead('l7', 'Sunitha Kitchens', '94444 33221', LeadStatus.lost, 'caller2',
        calls: 1),
    lead('l8', 'Gopal Electronics', '93333 99887', LeadStatus.fresh, 'lead'),
  ];

  const outcomes = CallOutcome.values;
  final calls = <CallLog>[
    for (var i = 0; i < 46; i++)
      CallLog(
        id: 'c$i',
        leadId: leads[i % leads.length].id,
        leadName: leads[i % leads.length].name,
        phone: leads[i % leads.length].phone,
        callerId: i % 3 == 0 ? 'caller2' : 'caller',
        outcome: outcomes[i % outcomes.length],
        durationMin: outcomes[i % outcomes.length].reached ? 2 + i % 6 : 0,
        notes: i % 4 == 0 ? '' : 'Asked for a quote, call back after lunch',
        at: ago(i ~/ 6, i % 5),
      ),
  ];

  calls.sort((a, b) => b.at.compareTo(a.at));

  final inquiries = [
    Inquiry(
      id: 'q1',
      name: 'Mahesh',
      contact: '98765 43210',
      service: 'Mobile app',
      message: 'We need a delivery app for our restaurant in Vijayawada.',
      status: InquiryStatus.fresh,
      createdAt: ago(0, 3),
    ),
    Inquiry(
      id: 'q2',
      name: 'Divya',
      contact: 'divya@example.com',
      service: 'YouTube',
      message: 'Can you produce kids stories for our school channel?',
      status: InquiryStatus.converted,
      createdAt: ago(3),
    ),
  ];

  final activity = [
    Activity(
        id: 'a1',
        actorId: 'editor',
        text: 'moved “Tenali Rama and the thieves” to Editing',
        kind: ActivityKind.video,
        at: ago(0, 1)),
    Activity(
        id: 'a2',
        actorId: 'caller',
        text: 'called Suresh Babu — call back',
        kind: ActivityKind.call,
        at: ago(0, 2)),
    Activity(
        id: 'a3',
        actorId: 'dev',
        text: 'completed “Publish release notes”',
        kind: ActivityKind.task,
        at: ago(1)),
    Activity(
        id: 'a4',
        actorId: 'lead',
        text: 'imported 24 leads for Ravi Teja',
        kind: ActivityKind.lead,
        at: ago(2)),
    Activity(
        id: 'a5',
        actorId: 'owner',
        text: 'welcomed Arjun Rao to Development as member',
        kind: ActivityKind.team,
        at: ago(5)),
  ];

  final me = users.firstWhere((u) => u.id == as);
  final manager = me.role.isManager;
  return AppStore.seeded(
    me: me,
    users: users,
    projects: projects,
    tasks: tasks,
    videos: videos,
    activity: activity,
    // Mirror the security rules: members only load their own leads and calls.
    leads: manager
        ? leads
        : me.dept == Dept.marketing
            ? leads.where((l) => l.ownerId == me.id).toList()
            : const [],
    calls: manager
        ? calls
        : me.dept == Dept.marketing
            ? calls.where((c) => c.callerId == me.id).toList()
            : const [],
    inquiries: manager ? inquiries : const [],
  );
}
