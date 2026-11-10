import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models.dart';

/// Lets the store surface write failures without a BuildContext.
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void toast(String message) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

enum Phase { loading, signedOut, pending, disabled, active, failed }

typedef _Docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

// ---------------------------------------------------------------------------
// Editable field sets passed from dialogs to the store
// ---------------------------------------------------------------------------

class TaskDraft {
  TaskDraft({
    this.title = '',
    this.description = '',
    this.projectId,
    this.dept = Dept.development,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.assigneeId,
    this.dueAt,
  });

  factory TaskDraft.of(Task t) => TaskDraft(
        title: t.title,
        description: t.description,
        projectId: t.projectId,
        dept: t.dept,
        status: t.status,
        priority: t.priority,
        assigneeId: t.assigneeId,
        dueAt: t.dueAt,
      );

  String title;
  String description;
  String? projectId;
  Dept dept;
  TaskStatus status;
  TaskPriority priority;
  String? assigneeId;
  DateTime? dueAt;
}

class VideoDraft {
  VideoDraft({
    this.title = '',
    this.series = 'Bujji & Chinni Kathalu',
    this.format = VideoFormat.long,
    this.stage = VideoStage.idea,
    this.assigneeId,
    this.publishAt,
    this.youtubeUrl = '',
    this.notes = '',
  });

  factory VideoDraft.of(Video v) => VideoDraft(
        title: v.title,
        series: v.series,
        format: v.format,
        stage: v.stage,
        assigneeId: v.assigneeId,
        publishAt: v.publishAt,
        youtubeUrl: v.youtubeUrl ?? '',
        notes: v.notes,
      );

  String title;
  String series;
  VideoFormat format;
  VideoStage stage;
  String? assigneeId;
  DateTime? publishAt;
  String youtubeUrl;
  String notes;
}

class LeadDraft {
  LeadDraft({
    this.name = '',
    this.phone = '',
    this.company = '',
    this.source = LeadSource.cold,
    this.service = LeadService.other,
    this.status = LeadStatus.fresh,
    required this.ownerId,
    this.nextFollowUpAt,
    this.notes = '',
    this.value,
  });

  factory LeadDraft.of(Lead l) => LeadDraft(
        name: l.name,
        phone: l.phone,
        company: l.company ?? '',
        source: l.source,
        service: l.service,
        status: l.status,
        ownerId: l.ownerId,
        nextFollowUpAt: l.nextFollowUpAt,
        notes: l.notes,
        value: l.value,
      );

  String name;
  String phone;
  String company;
  LeadSource source;
  LeadService service;
  LeadStatus status;
  String ownerId;
  DateTime? nextFollowUpAt;
  String notes;
  num? value;
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

class AppStore extends ChangeNotifier {
  AppStore() {
    _authSub = _auth.authStateChanges().listen(_onAuth);
  }

  /// A signed-in, fully loaded store that never talks to Firebase, so widget
  /// tests can render screens from fixed data.
  @visibleForTesting
  AppStore.seeded({
    required AppUser this.me,
    this.users = const [],
    this.projects = const [],
    this.tasks = const [],
    this.videos = const [],
    this.activity = const [],
    this.leads = const [],
    this.calls = const [],
    this.inquiries = const [],
  }) : phase = Phase.active {
    _userIndex = {for (final u in users) u.id: u};
    _projectIndex = {for (final p in projects) p.id: p};
    _loaded.addAll(const [
      'users',
      'projects',
      'tasks',
      'videos',
      'activity',
      'leads',
      'calls',
      'inquiries',
    ]);
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _meSub;
  final _subs = <StreamSubscription<Object?>>[];
  final _loaded = <String>{};
  String? _signature;
  bool _bootstrapping = false;
  bool _touched = false;

  Phase phase = Phase.loading;
  User? authUser;
  AppUser? me;
  String? failure;

  /// Name typed on the sign-up form. `authStateChanges` fires before
  /// `updateDisplayName`, so the profile document reads it from here.
  String? pendingName;

  List<AppUser> users = const [];
  List<Project> projects = const [];
  List<Task> tasks = const [];
  List<Video> videos = const [];
  List<Activity> activity = const [];
  List<Lead> leads = const [];
  List<CallLog> calls = const [];
  List<Inquiry> inquiries = const [];

  Map<String, AppUser> _userIndex = const {};
  Map<String, Project> _projectIndex = const {};

  // ---- Selectors ----------------------------------------------------------

  String get uid => me?.id ?? authUser?.uid ?? '';
  bool get isManager => me?.role.isManager ?? false;
  bool get isAdmin => me?.role.isAdmin ?? false;
  bool get canVideos => isManager || me?.dept == Dept.youtube;
  bool get canCalls => isManager || me?.dept == Dept.marketing;

  /// True once the first snapshot of [collection] has arrived.
  bool loaded(String collection) => _loaded.contains(collection);

  AppUser? userById(String? id) => id == null ? null : _userIndex[id];
  Project? projectById(String? id) => id == null ? null : _projectIndex[id];
  String nameOf(String? id) => userById(id)?.name ?? 'Someone';

  List<AppUser> get activeUsers => users.where((u) => u.isActive).toList();
  List<AppUser> get pendingUsers =>
      users.where((u) => u.status == UserStatus.pending).toList();
  List<Project> get liveProjects =>
      projects.where((p) => !p.archived).toList();

  /// People who can hold leads and log calls.
  List<AppUser> get callers => activeUsers
      .where((u) => u.dept == Dept.marketing || u.role.isManager)
      .toList();

  bool canEditTask(Task t) =>
      isManager || t.assigneeId == uid || t.reporterId == uid;
  bool canDeleteTask(Task t) => isManager || t.reporterId == uid;

  List<String> get seriesOptions {
    final extra = videos.map((v) => v.series).toSet()
      ..removeAll(kDefaultSeries);
    return [...kDefaultSeries, ...extra.toList()..sort()];
  }

  // ---- Auth ---------------------------------------------------------------

  Future<void> _onAuth(User? user) async {
    await _meSub?.cancel();
    _meSub = null;
    _cancelData();
    authUser = user;
    me = null;
    failure = null;
    _bootstrapping = false;
    _touched = false;
    if (user == null) {
      pendingName = null;
      phase = Phase.signedOut;
      notifyListeners();
      return;
    }
    phase = Phase.loading;
    notifyListeners();
    _meSub = _db
        .collection('users')
        .doc(user.uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
      (snap) {
        final data = snap.data();
        if (data == null) {
          _bootstrap(user);
          return;
        }
        // A profile we have just written is not visible to the security
        // rules until the server accepts it; subscribing before that would
        // have every query rejected. Wait for the confirmed snapshot.
        if (me == null && snap.metadata.hasPendingWrites) return;
        final profile = AppUser.fromMap(snap.id, data);
        me = profile;
        phase = switch (profile.status) {
          UserStatus.pending => Phase.pending,
          UserStatus.disabled => Phase.disabled,
          UserStatus.active => Phase.active,
        };
        _syncSubscriptions();
        notifyListeners();
      },
      onError: (Object e) => _fail(e),
    );
  }

  void _fail(Object e) {
    debugPrint('Workspace error: $e');
    failure = e is FirebaseException && e.code == 'unavailable'
        ? 'We could not reach the server. Check your connection and try again.'
        : 'We could not load your profile. Please try again.';
    phase = Phase.failed;
    notifyListeners();
  }

  /// Creates the profile document on first sign-in. The first person ever to
  /// sign in claims the workspace and becomes its owner.
  Future<void> _bootstrap(User user) async {
    if (_bootstrapping) return;
    _bootstrapping = true;
    try {
      final typed = pendingName?.trim() ?? '';
      final name = typed.isNotEmpty
          ? typed
          : (user.displayName?.trim().isNotEmpty ?? false)
              ? user.displayName!.trim()
              : (user.email?.split('@').first ?? 'New teammate');
      Map<String, dynamic> profile(Role role, UserStatus status) => {
            'name': name,
            'email': user.email ?? '',
            'photoUrl': user.photoURL,
            'role': role.key,
            'dept': Dept.youtube.key,
            'status': status.key,
            'dailyCallTarget': kDefaultCallTarget,
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeenAt': FieldValue.serverTimestamp(),
          };
      final userRef = _db.collection('users').doc(user.uid);
      final wsRef = _db.collection('meta').doc('workspace');
      final ws = await wsRef.get();
      if (!ws.exists) {
        try {
          final batch = _db.batch()
            ..set(wsRef, {
              'ownerUid': user.uid,
              'name': 'OMorals Media',
              'createdAt': FieldValue.serverTimestamp(),
            })
            ..set(userRef, profile(Role.owner, UserStatus.active));
          await batch.commit();
          return;
        } on FirebaseException catch (e) {
          // Someone else claimed the workspace a moment earlier.
          if (e.code != 'permission-denied') rethrow;
        }
      } else if (ws.data()?['ownerUid'] == user.uid) {
        await userRef.set(profile(Role.owner, UserStatus.active));
        return;
      }
      await userRef.set(profile(Role.member, UserStatus.pending));
    } catch (e) {
      _fail(e);
    }
  }

  /// Re-runs profile loading after a failure.
  Future<void> retry() => _onAuth(_auth.currentUser);

  Future<void> signInWithGoogle() async {
    await _auth.signInWithPopup(GoogleAuthProvider());
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> signUpWithEmail(
      String name, String email, String password) async {
    pendingName = name.trim();
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user?.updateDisplayName(name.trim());
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  // ---- Subscriptions ------------------------------------------------------

  void _syncSubscriptions() {
    final m = me;
    final signature = (m == null || !m.isActive)
        ? null
        : '${m.id}|${m.role.key}|${m.dept.key}';
    if (signature == _signature) return;
    _cancelData();
    _signature = signature;
    if (m == null || signature == null) return;

    if (!_touched) {
      _touched = true;
      _db
          .collection('users')
          .doc(m.id)
          .update({'lastSeenAt': FieldValue.serverTimestamp()}).catchError(
              (Object e) => debugPrint('lastSeenAt: $e'));
    }

    _listen('users', _db.collection('users'), (docs) {
      users = [for (final d in docs) AppUser.fromMap(d.id, d.data())]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _userIndex = {for (final u in users) u.id: u};
    });
    _listen('projects', _db.collection('projects'), (docs) {
      projects = [for (final d in docs) Project.fromMap(d.id, d.data())]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _projectIndex = {for (final p in projects) p.id: p};
    });
    _listen('tasks', _db.collection('tasks'), (docs) {
      tasks = [for (final d in docs) Task.fromMap(d.id, d.data())]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    _listen('videos', _db.collection('videos'), (docs) {
      videos = [for (final d in docs) Video.fromMap(d.id, d.data())]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    _listen(
      'activity',
      _db.collection('activity').orderBy('at', descending: true).limit(40),
      (docs) {
        activity = [for (final d in docs) Activity.fromMap(d.id, d.data())];
      },
    );

    final manager = m.role.isManager;
    if (manager || m.dept == Dept.marketing) {
      final leadsRef = _db.collection('leads');
      _listen(
        'leads',
        manager ? leadsRef : leadsRef.where('ownerId', isEqualTo: m.id),
        (docs) {
          leads = [for (final d in docs) Lead.fromMap(d.id, d.data())]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        },
      );
      final callsRef = _db.collection('calls');
      final since = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 45)));
      _listen(
        'calls',
        manager
            ? callsRef.where('at', isGreaterThanOrEqualTo: since)
            : callsRef.where('callerId', isEqualTo: m.id),
        (docs) {
          calls = [for (final d in docs) CallLog.fromMap(d.id, d.data())]
            ..sort((a, b) => b.at.compareTo(a.at));
        },
      );
    }
    if (manager) {
      _listen('inquiries', _db.collection('inquiries'), (docs) {
        inquiries = [for (final d in docs) Inquiry.fromMap(d.id, d.data())]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    }
  }

  void _listen(
    String key,
    Query<Map<String, dynamic>> query,
    void Function(_Docs docs) apply,
  ) {
    _subs.add(query.snapshots().listen(
      (snap) {
        apply(snap.docs);
        _loaded.add(key);
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Listening to $key failed: $e');
        _loaded.add(key);
        notifyListeners();
      },
    ));
  }

  void _cancelData() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _loaded.clear();
    _signature = null;
    users = const [];
    projects = const [];
    tasks = const [];
    videos = const [];
    activity = const [];
    leads = const [];
    calls = const [];
    inquiries = const [];
    _userIndex = const {};
    _projectIndex = const {};
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _meSub?.cancel();
    _cancelData();
    super.dispose();
  }

  // ---- Write plumbing -----------------------------------------------------

  /// Runs a write and reports failures with a SnackBar. Local listeners see
  /// the change immediately, so callers don't need to await the result.
  Future<bool> _run(Future<void> Function() op, {String? done}) async {
    try {
      await op();
      if (done != null) toast(done);
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Write failed: ${e.code} ${e.message}');
      toast(switch (e.code) {
        'permission-denied' => "You don't have permission to do that",
        'unavailable' => 'You seem to be offline. Please try again.',
        _ => 'Something went wrong. Please try again.',
      });
      return false;
    } catch (e) {
      debugPrint('Write failed: $e');
      toast('Something went wrong. Please try again.');
      return false;
    }
  }

  void _log(WriteBatch batch, ActivityKind kind, String text) {
    batch.set(_db.collection('activity').doc(), {
      'actorId': uid,
      'text': text,
      'kind': kind.key,
      'at': FieldValue.serverTimestamp(),
    });
  }

  static Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);
  static String? _nullIfBlank(String s) => s.trim().isEmpty ? null : s.trim();

  // ---- Tasks --------------------------------------------------------------

  Map<String, dynamic> _taskFields(TaskDraft d) => {
        'title': d.title.trim(),
        'description': d.description.trim(),
        'projectId': d.projectId,
        'dept': d.dept.key,
        'status': d.status.key,
        'priority': d.priority.key,
        'assigneeId': d.assigneeId,
        'dueAt': _ts(d.dueAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Future<bool> createTask(TaskDraft d) => _run(() {
        final batch = _db.batch()
          ..set(_db.collection('tasks').doc(), {
            ..._taskFields(d),
            'reporterId': uid,
            'createdAt': FieldValue.serverTimestamp(),
            'completedAt':
                d.status == TaskStatus.done ? FieldValue.serverTimestamp() : null,
            'commentCount': 0,
          });
        final who = d.assigneeId == null || d.assigneeId == uid
            ? ''
            : ' for ${nameOf(d.assigneeId)}';
        _log(batch, ActivityKind.task, 'created task “${d.title.trim()}”$who');
        return batch.commit();
      });

  Future<bool> updateTask(Task t, TaskDraft d) => _run(() {
        final batch = _db.batch()
          ..update(_db.collection('tasks').doc(t.id), {
            ..._taskFields(d),
            if (d.status != t.status)
              'completedAt': d.status == TaskStatus.done
                  ? FieldValue.serverTimestamp()
                  : null,
          });
        if (d.status != t.status && d.status == TaskStatus.done) {
          _log(batch, ActivityKind.task, 'completed “${d.title.trim()}”');
        } else if (d.assigneeId != t.assigneeId && d.assigneeId != null) {
          _log(batch, ActivityKind.task,
              'assigned “${d.title.trim()}” to ${nameOf(d.assigneeId)}');
        }
        return batch.commit();
      });

  Future<bool> setTaskStatus(Task t, TaskStatus status) {
    if (t.status == status) return Future.value(true);
    return _run(() {
      final batch = _db.batch()
        ..update(_db.collection('tasks').doc(t.id), {
          'status': status.key,
          'completedAt':
              status == TaskStatus.done ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      if (status == TaskStatus.done) {
        _log(batch, ActivityKind.task, 'completed “${t.title}”');
      } else {
        _log(batch, ActivityKind.task,
            'moved “${t.title}” to ${status.label}');
      }
      return batch.commit();
    });
  }

  Future<bool> deleteTask(Task t) => _run(() async {
        final ref = _db.collection('tasks').doc(t.id);
        final comments = await ref.collection('comments').get();
        final batch = _db.batch();
        for (final c in comments.docs) {
          batch.delete(c.reference);
        }
        batch.delete(ref);
        await batch.commit();
      }, done: 'Task deleted');

  Stream<List<TaskComment>> watchComments(String taskId) => _db
      .collection('tasks')
      .doc(taskId)
      .collection('comments')
      .orderBy('at')
      .snapshots()
      .map((s) =>
          [for (final d in s.docs) TaskComment.fromMap(d.id, d.data())]);

  Future<bool> addComment(Task t, String text) => _run(() {
        final ref = _db.collection('tasks').doc(t.id);
        final batch = _db.batch()
          ..set(ref.collection('comments').doc(), {
            'authorId': uid,
            'text': text.trim(),
            'at': FieldValue.serverTimestamp(),
          });
        batch.update(ref, {'commentCount': FieldValue.increment(1)});
        return batch.commit();
      });

  Future<bool> deleteComment(Task t, TaskComment c) => _run(() {
        final ref = _db.collection('tasks').doc(t.id);
        final batch = _db.batch()
          ..delete(ref.collection('comments').doc(c.id));
        if (t.commentCount > 0) {
          batch.update(ref, {'commentCount': FieldValue.increment(-1)});
        }
        return batch.commit();
      });

  // ---- Projects -----------------------------------------------------------

  Future<bool> saveProject({
    Project? existing,
    required String name,
    required Dept dept,
    required int color,
    required String client,
  }) =>
      _run(() {
        final fields = {
          'name': name.trim(),
          'dept': dept.key,
          'color': color,
          'client': _nullIfBlank(client),
        };
        if (existing != null) {
          return _db.collection('projects').doc(existing.id).update(fields);
        }
        return _db.collection('projects').doc().set({
          ...fields,
          'archived': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

  Future<bool> setProjectArchived(Project p, bool archived) => _run(
        () => _db
            .collection('projects')
            .doc(p.id)
            .update({'archived': archived}),
        done: archived ? 'Project archived' : 'Project restored',
      );

  // ---- Videos -------------------------------------------------------------

  Map<String, dynamic> _stageEvent(VideoStage stage) =>
      {'stage': stage.key, 'by': uid, 'at': Timestamp.now()};

  Map<String, dynamic> _videoFields(VideoDraft d) => {
        'title': d.title.trim(),
        'series': d.series,
        'format': d.format.key,
        'assigneeId': d.assigneeId,
        'publishAt': _ts(d.publishAt),
        'youtubeUrl': _nullIfBlank(d.youtubeUrl),
        'notes': d.notes.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Future<bool> createVideo(VideoDraft d) => _run(() {
        final batch = _db.batch()
          ..set(_db.collection('videos').doc(), {
            ..._videoFields(d),
            'stage': d.stage.key,
            'stageSince': FieldValue.serverTimestamp(),
            'history': [_stageEvent(d.stage)],
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        _log(batch, ActivityKind.video,
            'added video “${d.title.trim()}” at ${d.stage.label}');
        return batch.commit();
      });

  Future<bool> updateVideo(Video v, VideoDraft d) => _run(() {
        final moved = d.stage != v.stage;
        final batch = _db.batch()
          ..update(_db.collection('videos').doc(v.id), {
            ..._videoFields(d),
            if (moved) ...{
              'stage': d.stage.key,
              'stageSince': FieldValue.serverTimestamp(),
              'history': FieldValue.arrayUnion([_stageEvent(d.stage)]),
            },
          });
        if (moved) {
          _log(batch, ActivityKind.video,
              'moved “${d.title.trim()}” to ${d.stage.label}');
        }
        return batch.commit();
      });

  Future<bool> moveVideo(Video v, VideoStage stage, {String? youtubeUrl}) {
    if (v.stage == stage) return Future.value(true);
    return _run(() {
      final url = youtubeUrl == null ? null : _nullIfBlank(youtubeUrl);
      final batch = _db.batch()
        ..update(_db.collection('videos').doc(v.id), {
          'stage': stage.key,
          'stageSince': FieldValue.serverTimestamp(),
          'history': FieldValue.arrayUnion([_stageEvent(stage)]),
          'updatedAt': FieldValue.serverTimestamp(),
          if (url != null) 'youtubeUrl': url,
        });
      _log(batch, ActivityKind.video,
          'moved “${v.title}” to ${stage.label}');
      return batch.commit();
    });
  }

  Future<bool> deleteVideo(Video v) => _run(
        () => _db.collection('videos').doc(v.id).delete(),
        done: 'Video deleted',
      );

  // ---- Leads --------------------------------------------------------------

  Map<String, dynamic> _leadFields(LeadDraft d) => {
        'name': d.name.trim(),
        'phone': cleanPhone(d.phone),
        'company': _nullIfBlank(d.company),
        'source': d.source.key,
        'service': d.service.key,
        'status': d.status.key,
        'ownerId': isManager ? d.ownerId : uid,
        'nextFollowUpAt': _ts(d.nextFollowUpAt),
        'notes': d.notes.trim(),
        'value': d.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Future<bool> createLead(LeadDraft d) => _run(() {
        final batch = _db.batch()
          ..set(_db.collection('leads').doc(), {
            ..._leadFields(d),
            'lastCallAt': null,
            'callCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        _log(batch, ActivityKind.lead, 'added lead ${d.name.trim()}');
        return batch.commit();
      });

  Future<bool> updateLead(Lead l, LeadDraft d) => _run(() {
        final batch = _db.batch()
          ..update(_db.collection('leads').doc(l.id), _leadFields(d));
        if (isManager && d.ownerId != l.ownerId) {
          _log(batch, ActivityKind.lead,
              'reassigned lead ${l.name} to ${nameOf(d.ownerId)}');
        } else if (d.status != l.status && d.status.isClosed) {
          _log(batch, ActivityKind.lead,
              'marked lead ${l.name} as ${d.status.label.toLowerCase()}');
        }
        return batch.commit();
      });

  Future<bool> deleteLead(Lead l) => _run(
        () => _db.collection('leads').doc(l.id).delete(),
        done: 'Lead deleted',
      );

  /// Bulk import. Firestore batches cap at 500 writes, so chunk well below.
  Future<bool> importLeads(
    List<ParsedLead> rows, {
    required String ownerId,
    required LeadSource source,
    required LeadService service,
  }) =>
      _run(() async {
        final owner = isManager ? ownerId : uid;
        for (var i = 0; i < rows.length; i += 400) {
          final chunk = rows.skip(i).take(400);
          final batch = _db.batch();
          for (final r in chunk) {
            batch.set(_db.collection('leads').doc(), {
              'name': r.name,
              'phone': r.phone,
              'company': r.company,
              'source': source.key,
              'service': service.key,
              'status': LeadStatus.fresh.key,
              'ownerId': owner,
              'nextFollowUpAt': null,
              'lastCallAt': null,
              'callCount': 0,
              'notes': '',
              'value': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          if (i == 0) {
            final n = rows.length;
            final who = owner == uid ? '' : ' for ${nameOf(owner)}';
            _log(batch, ActivityKind.lead,
                'imported $n ${n == 1 ? 'lead' : 'leads'}$who');
          }
          await batch.commit();
        }
      }, done: '${rows.length} ${rows.length == 1 ? 'lead' : 'leads'} imported');

  /// Saves a call together with its effect on the lead, atomically.
  /// Pass [lead] for an existing lead, or [newName]/[newPhone] to create one.
  Future<bool> logCall({
    Lead? lead,
    String newName = '',
    String newPhone = '',
    required CallOutcome outcome,
    required int durationMin,
    required String notes,
    DateTime? nextFollowUp,
  }) =>
      _run(() {
        final leadRef = lead == null
            ? _db.collection('leads').doc()
            : _db.collection('leads').doc(lead.id);
        final name = lead?.name ?? newName.trim();
        final phone = lead?.phone ?? cleanPhone(newPhone);
        final status =
            leadStatusAfterCall(lead?.status ?? LeadStatus.fresh, outcome);
        final followUp = status.isClosed ? null : _ts(nextFollowUp);
        final batch = _db.batch();
        if (lead == null) {
          batch.set(leadRef, {
            'name': name,
            'phone': phone,
            'company': null,
            'source': LeadSource.cold.key,
            'service': LeadService.other.key,
            'status': status.key,
            'ownerId': uid,
            'nextFollowUpAt': followUp,
            'lastCallAt': FieldValue.serverTimestamp(),
            'callCount': 1,
            'notes': '',
            'value': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          batch.update(leadRef, {
            'status': status.key,
            'nextFollowUpAt': followUp,
            'lastCallAt': FieldValue.serverTimestamp(),
            'callCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        batch.set(_db.collection('calls').doc(), {
          'leadId': leadRef.id,
          'leadName': name,
          'phone': phone,
          'callerId': uid,
          'outcome': outcome.key,
          'durationMin': durationMin,
          'notes': notes.trim(),
          'at': FieldValue.serverTimestamp(),
        });
        _log(batch, ActivityKind.call,
            'called $name — ${outcome.label.toLowerCase()}');
        return batch.commit();
      });

  // ---- Website enquiries --------------------------------------------------

  Future<bool> convertInquiry(Inquiry q, String ownerId) => _run(() {
        final batch = _db.batch()
          ..set(_db.collection('leads').doc(), {
            'name': q.name,
            'phone': q.contact,
            'company': null,
            'source': LeadSource.website.key,
            'service': LeadService.guess(q.service).key,
            'status': LeadStatus.fresh.key,
            'ownerId': ownerId,
            'nextFollowUpAt': Timestamp.fromDate(dayOf(DateTime.now())),
            'lastCallAt': null,
            'callCount': 0,
            'notes': q.message,
            'value': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          ..update(_db.collection('inquiries').doc(q.id),
              {'status': InquiryStatus.converted.key});
        _log(batch, ActivityKind.lead,
            'turned ${q.name}’s website enquiry into a lead for ${nameOf(ownerId)}');
        return batch.commit();
      }, done: 'Lead created for ${nameOf(ownerId)}');

  Future<bool> setInquiryStatus(Inquiry q, InquiryStatus status) => _run(
        () => _db
            .collection('inquiries')
            .doc(q.id)
            .update({'status': status.key}),
      );

  // ---- Team ---------------------------------------------------------------

  Future<bool> approveUser(AppUser u, Dept dept, Role role) => _run(() {
        final batch = _db.batch()
          ..update(_db.collection('users').doc(u.id), {
            'status': UserStatus.active.key,
            'dept': dept.key,
            'role': role.key,
          });
        _log(batch, ActivityKind.team,
            'welcomed ${u.name} to ${dept.label} as ${role.label.toLowerCase()}');
        return batch.commit();
      }, done: '${u.name} can now sign in');

  Future<bool> setUserStatus(AppUser u, UserStatus status) => _run(
        () => _db
            .collection('users')
            .doc(u.id)
            .update({'status': status.key}),
        done: status == UserStatus.disabled
            ? 'Access removed for ${u.name}'
            : 'Access restored for ${u.name}',
      );

  Future<bool> updateMember(
    AppUser u, {
    required String name,
    required String title,
    required String phone,
    required Role role,
    required Dept dept,
    required int dailyCallTarget,
  }) =>
      _run(
        () => _db.collection('users').doc(u.id).update({
          'name': name.trim(),
          'title': _nullIfBlank(title),
          'phone': _nullIfBlank(phone),
          // The owner's role is fixed by the security rules.
          'role': u.role == Role.owner ? Role.owner.key : role.key,
          'dept': dept.key,
          'dailyCallTarget': dailyCallTarget,
        }),
        done: 'Saved',
      );

  Future<bool> updateMyProfile({required String name, required String phone}) =>
      _run(
        () => _db.collection('users').doc(uid).update({
          'name': name.trim(),
          'phone': _nullIfBlank(phone),
        }),
        done: 'Profile updated',
      );
}

// ---------------------------------------------------------------------------
// Scope
// ---------------------------------------------------------------------------

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  /// Rebuilds the caller whenever the store changes.
  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// For callbacks: reads the store without subscribing.
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Friendly copy for FirebaseAuth errors.
String authMessage(Object e) {
  if (e is! FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }
  return switch (e.code) {
    'invalid-email' => 'That email address doesn’t look right.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'invalid-login-credentials' =>
      'Wrong email or password.',
    'email-already-in-use' =>
      'There is already an account with that email. Try signing in instead.',
    'weak-password' => 'Choose a password with at least 6 characters.',
    'too-many-requests' => 'Too many attempts. Please wait a minute and retry.',
    'network-request-failed' =>
      'No connection. Check your internet and try again.',
    'popup-blocked' =>
      'Your browser blocked the sign-in window. Allow pop-ups and retry.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' ||
    'web-context-cancelled' =>
      'Sign-in was cancelled.',
    'account-exists-with-different-credential' =>
      'That email is registered with a different sign-in method.',
    'operation-not-allowed' =>
      'This sign-in method isn’t enabled yet. Ask the workspace owner.',
    _ => 'Could not sign in. Please try again.',
  };
}
