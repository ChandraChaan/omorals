import 'package:flutter_test/flutter_test.dart';
import 'package:omorals/models.dart';

void main() {
  final now = DateTime(2026, 11, 10, 15, 30);

  Task task({
    DateTime? dueAt,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? createdAt,
  }) =>
      Task(
        id: 't',
        title: 'Edit episode 12',
        dept: Dept.youtube,
        status: status,
        priority: priority,
        reporterId: 'owner',
        dueAt: dueAt,
        createdAt: createdAt ?? now,
        updatedAt: now,
      );

  Video video(VideoStage stage, DateTime since) => Video(
        id: 'v',
        title: 'Tenali Rama',
        series: 'History',
        stage: stage,
        stageSince: since,
        createdBy: 'owner',
        createdAt: since,
        updatedAt: since,
      );

  Lead lead({LeadStatus status = LeadStatus.contacted, DateTime? next}) => Lead(
        id: 'l',
        name: 'Ravi',
        phone: '98480 12345',
        status: status,
        ownerId: 'agent',
        nextFollowUpAt: next,
        createdAt: now,
        updatedAt: now,
      );

  CallLog call(CallOutcome outcome,
          {int minutes = 2, String notes = '', DateTime? at}) =>
      CallLog(
        id: 'c',
        leadId: 'l',
        leadName: 'Ravi',
        phone: '98480 12345',
        callerId: 'agent',
        outcome: outcome,
        durationMin: minutes,
        notes: notes,
        at: at ?? now,
      );

  group('leadStatusAfterCall', () {
    test('decisive outcomes map directly', () {
      expect(leadStatusAfterCall(LeadStatus.fresh, CallOutcome.interested),
          LeadStatus.interested);
      expect(leadStatusAfterCall(LeadStatus.contacted, CallOutcome.callback),
          LeadStatus.followUp);
      expect(leadStatusAfterCall(LeadStatus.followUp, CallOutcome.converted),
          LeadStatus.won);
      expect(
          leadStatusAfterCall(LeadStatus.interested, CallOutcome.notInterested),
          LeadStatus.lost);
      expect(leadStatusAfterCall(LeadStatus.fresh, CallOutcome.wrongNumber),
          LeadStatus.lost);
    });

    test('neutral outcomes only advance a new lead', () {
      for (final o in [
        CallOutcome.connected,
        CallOutcome.noAnswer,
        CallOutcome.busy,
      ]) {
        expect(leadStatusAfterCall(LeadStatus.fresh, o), LeadStatus.contacted);
        expect(leadStatusAfterCall(LeadStatus.interested, o),
            LeadStatus.interested);
        expect(
            leadStatusAfterCall(LeadStatus.followUp, o), LeadStatus.followUp);
        expect(leadStatusAfterCall(LeadStatus.won, o), LeadStatus.won);
      }
    });

    test('a won deal is not demoted by a friendly call', () {
      expect(leadStatusAfterCall(LeadStatus.won, CallOutcome.interested),
          LeadStatus.won);
      expect(leadStatusAfterCall(LeadStatus.won, CallOutcome.callback),
          LeadStatus.won);
    });
  });

  group('task due dates', () {
    test('due today is not overdue, due yesterday is', () {
      expect(task(dueAt: DateTime(2026, 11, 10)).isOverdue(now), isFalse);
      expect(task(dueAt: DateTime(2026, 11, 10)).isDueToday(now), isTrue);
      expect(task(dueAt: DateTime(2026, 11, 9, 23, 59)).isOverdue(now), isTrue);
    });

    test('done or undated tasks are never overdue', () {
      expect(
          task(dueAt: DateTime(2026, 11, 1), status: TaskStatus.done)
              .isOverdue(now),
          isFalse);
      expect(task().isOverdue(now), isFalse);
    });

    test('sorts dated tasks first, then by priority', () {
      final undatedUrgent = task(priority: TaskPriority.urgent);
      final undatedLow = task(priority: TaskPriority.low);
      final soon = task(dueAt: DateTime(2026, 11, 11));
      final later = task(dueAt: DateTime(2026, 11, 20));
      final sorted = [undatedLow, later, undatedUrgent, soon]
        ..sort(compareTasksByDue);
      expect(sorted, [soon, later, undatedUrgent, undatedLow]);
    });
  });

  group('video staleness', () {
    test('counts whole calendar days in the current stage', () {
      final v = video(VideoStage.editing, DateTime(2026, 11, 7, 23));
      expect(v.daysInStage(now), 3);
      expect(video(VideoStage.editing, now).daysInStage(now), 0);
    });

    test('amber after 3 days, red after 7', () {
      expect(video(VideoStage.script, DateTime(2026, 11, 7)).staleness(now), 0);
      expect(video(VideoStage.script, DateTime(2026, 11, 6)).staleness(now), 1);
      expect(video(VideoStage.script, DateTime(2026, 11, 3)).staleness(now), 1);
      expect(video(VideoStage.script, DateTime(2026, 11, 2)).staleness(now), 2);
    });

    test('scheduled and published videos never go stale', () {
      final old = DateTime(2026, 9, 1);
      expect(video(VideoStage.scheduled, old).isStuck(now), isFalse);
      expect(video(VideoStage.published, old).isStuck(now), isFalse);
    });

    test('progress runs from 0 at idea to 1 at published', () {
      expect(video(VideoStage.idea, now).progress, 0);
      expect(video(VideoStage.published, now).progress, 1);
    });
  });

  group('lead follow-ups', () {
    test('due today counts as due but not overdue', () {
      final l = lead(next: DateTime(2026, 11, 10));
      expect(l.followUpDue(now), isTrue);
      expect(l.followUpOverdue(now), isFalse);
    });

    test('a past date is overdue; a future date is neither', () {
      expect(lead(next: DateTime(2026, 11, 8)).followUpOverdue(now), isTrue);
      expect(lead(next: DateTime(2026, 11, 12)).followUpDue(now), isFalse);
    });

    test('closed leads never need a follow-up', () {
      final l = lead(status: LeadStatus.won, next: DateTime(2026, 11, 1));
      expect(l.followUpDue(now), isFalse);
      expect(l.followUpOverdue(now), isFalse);
    });
  });

  group('call stats', () {
    test('connect rate, talk time and data quality', () {
      final stats = CallStats([
        call(CallOutcome.connected, minutes: 4, notes: 'Wants a quote Friday'),
        call(CallOutcome.noAnswer, minutes: 0),
        call(CallOutcome.interested, minutes: 6, notes: 'ok'),
        call(CallOutcome.converted, minutes: 10, notes: 'Signed the proposal'),
      ]);
      expect(stats.total, 4);
      expect(stats.connected, 3);
      expect(stats.connectRate, 0.75);
      expect(stats.interested, 1);
      expect(stats.converted, 1);
      expect(stats.talkMin, 20);
      expect(stats.dataQuality, 0.5);
    });

    test('empty stats do not divide by zero', () {
      final stats = CallStats(const []);
      expect(stats.connectRate, 0);
      expect(stats.dataQuality, 0);
    });

    test('buckets calls per day with today last', () {
      final days = callsPerDay([
        call(CallOutcome.connected),
        call(CallOutcome.busy, at: DateTime(2026, 11, 10, 9)),
        call(CallOutcome.busy, at: DateTime(2026, 11, 8, 18)),
        call(CallOutcome.busy, at: DateTime(2026, 10, 1)),
      ], now, days: 3);
      expect(days, [1, 0, 2]);
    });
  });

  group('parseLeadLines', () {
    test('reads name, phone and company; skips bad and duplicate lines', () {
      final result = parseLeadLines('''
Ravi Kumar, 98480 12345, Sri Sai Traders
Lakshmi Devi\t+91 90000-54321

No Phone Person
Ravi Again, 9848012345
''');
      expect(result.leads, hasLength(2));
      expect(result.skipped, 2);
      expect(result.leads[0].name, 'Ravi Kumar');
      expect(result.leads[0].phone, '98480 12345');
      expect(result.leads[0].company, 'Sri Sai Traders');
      expect(result.leads[1].phone, '+91 9000054321');
      expect(result.leads[1].company, isNull);
    });
  });

  group('parsing', () {
    test('unknown enum keys fall back safely', () {
      final u = AppUser.fromMap('u1', {'name': 'Sita', 'role': 'wizard'});
      expect(u.role, Role.member);
      expect(u.status, UserStatus.pending);
      expect(u.dailyCallTarget, kDefaultCallTarget);
      expect(u.initials, 'SI');
    });

    test('a missing server timestamp is treated as now', () {
      final before = DateTime.now();
      final c = CallLog.fromMap('c1', {'leadName': 'Ravi', 'at': null});
      expect(c.at.isBefore(before), isFalse);
    });

    test('guesses a service from website enquiry text', () {
      expect(LeadService.guess('Mobile app development'),
          LeadService.development);
      expect(LeadService.guess('YouTube channel'), LeadService.youtube);
      expect(LeadService.guess('Digital Marketing'), LeadService.marketing);
      expect(LeadService.guess(''), LeadService.other);
    });
  });
}
