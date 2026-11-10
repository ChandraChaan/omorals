#!/usr/bin/env python3
"""Fill the LOCAL Firebase emulators with a demo team and sample work.

Only ever talks to localhost (Auth emulator :9099, Firestore emulator :8080).
It cannot touch the real project. Start the emulators first:

    firebase emulators:start --project omorals --only auth,firestore,hosting

then run:  python3 tool/seed_emulator.py

Demo sign-ins (emulator only) are printed at the end.
"""
import datetime as dt
import json
import random
import urllib.request

PROJECT = "omorals"
AUTH = "http://localhost:9099/identitytoolkit.googleapis.com/v1"
FS = f"http://localhost:8080/v1/projects/{PROJECT}/databases/(default)/documents"
ADMIN = {"Authorization": "Bearer owner", "Content-Type": "application/json"}
PASSWORD = "demo-pass-123"  # emulator-only test password
NOW = dt.datetime.now(dt.timezone.utc)
random.seed(7)


def call(url, body=None, headers=None, method=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers or {"Content-Type": "application/json"}, method=method)
    with urllib.request.urlopen(req, timeout=10) as res:
        return json.loads(res.read() or b"{}")


def val(v):
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, dt.datetime):
        return {"timestampValue": v.isoformat().replace("+00:00", "Z")}
    if isinstance(v, list):
        return {"arrayValue": {"values": [val(x) for x in v]}}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: val(x) for k, x in v.items()}}}
    return {"stringValue": str(v)}


def put(path, data):
    call(f"{FS}/{path}", {"fields": {k: val(v) for k, v in data.items()}}, ADMIN, "PATCH")


def add(collection, data):
    res = call(f"{FS}/{collection}", {"fields": {k: val(v) for k, v in data.items()}}, ADMIN, "POST")
    return res["name"].rsplit("/", 1)[1]


def ago(days=0, hours=0, minutes=0):
    return NOW - dt.timedelta(days=days, hours=hours, minutes=minutes)


def main():
    # wipe previous emulator data so the script can be re-run
    call(f"http://localhost:8080/emulator/v1/projects/{PROJECT}/databases/(default)/documents", method="DELETE", headers=ADMIN)
    call(f"http://localhost:9099/emulator/v1/projects/{PROJECT}/accounts", method="DELETE", headers=ADMIN)

    people = [
        ("owner@omorals.test", "Chandra", "owner", "youtube", "Founder", "active"),
        ("priya@omorals.test", "Priya Reddy", "manager", "youtube", "Channel manager", "active"),
        ("arjun@omorals.test", "Arjun Varma", "member", "youtube", "Video editor", "active"),
        ("sneha@omorals.test", "Sneha Rao", "member", "youtube", "Script writer", "active"),
        ("kiran@omorals.test", "Kiran Kumar", "member", "marketing", "Tele-caller", "active"),
        ("divya@omorals.test", "Divya Nair", "member", "marketing", "Tele-caller", "active"),
        ("rahul@omorals.test", "Rahul Shetty", "member", "development", "Flutter developer", "active"),
        ("newjoiner@omorals.test", "Meena Iyer", "member", "marketing", "", "pending"),
    ]
    uid = {}
    for email, name, role, dept, title, status in people:
        res = call(f"{AUTH}/accounts:signUp?key=demo", {"email": email, "password": PASSWORD, "displayName": name, "returnSecureToken": True})
        uid[email.split("@")[0]] = res["localId"]
        put(f"users/{res['localId']}", {
            "name": name, "email": email, "role": role, "dept": dept, "title": title, "status": status,
            "dailyCallTarget": 40, "createdAt": ago(days=30), "lastSeenAt": ago(hours=random.randint(0, 20)),
        })
    put("meta/workspace", {"ownerUid": uid["owner"], "name": "OMorals Media", "createdAt": ago(days=30)})

    # projects
    projects = {}
    for key, name, dept, color, client in [
        ("channel", "Original Morals channel", "youtube", 0, ""),
        ("clinic", "Sunrise Clinic campaign", "marketing", 1, "Sunrise Clinic"),
        ("site", "OMorals website", "development", 2, ""),
        ("app", "Kirana billing app", "development", 3, "Sri Lakshmi Stores"),
    ]:
        projects[key] = add("projects", {"name": name, "dept": dept, "color": color, "client": client, "archived": False, "createdAt": ago(days=28)})

    # tasks
    tasks = [
        ("Write script: Why did the Chola navy vanish?", "channel", "youtube", "in_progress", "high", "sneha", 2),
        ("Record voice-over for Bujji & Chinni Ep 9", "channel", "youtube", "todo", "medium", "priya", 3),
        ("Edit Tinku Adige Prashnalu Ep 5 (Comets)", "channel", "youtube", "review", "high", "arjun", 0),
        ("Design 3 thumbnail options for Nanda Empire", "channel", "youtube", "todo", "urgent", "arjun", -1),
        ("Update channel banner and playlists", "channel", "youtube", "done", "low", "priya", -4),
        ("Call back 25 clinic leads from Friday", "clinic", "marketing", "in_progress", "high", "kiran", 0),
        ("Prepare weekly report for Sunrise Clinic", "clinic", "marketing", "todo", "medium", "divya", 1),
        ("Launch Instagram reel ads, set daily budget", "clinic", "marketing", "review", "medium", "divya", -2),
        ("Clean up duplicate leads in the sheet import", "clinic", "marketing", "done", "low", "kiran", -3),
        ("Contact form: send enquiries to workspace", "site", "development", "done", "high", "rahul", -5),
        ("Add case studies section to website", "site", "development", "todo", "medium", "rahul", 6),
        ("Billing screen: GST invoice PDF", "app", "development", "in_progress", "urgent", "rahul", 1),
        ("Play Store listing and screenshots", "app", "development", "todo", "medium", "rahul", 9),
        ("Fix crash on barcode scan (Android 15)", "app", "development", "review", "high", "rahul", -1),
    ]
    for title, proj, dept, status, priority, who, due in tasks:
        add("tasks", {
            "title": title, "description": "", "projectId": projects[proj], "dept": dept, "status": status,
            "priority": priority, "assigneeId": uid[who], "reporterId": uid["owner"],
            "dueAt": ago(days=-due), "createdAt": ago(days=random.randint(3, 12)), "updatedAt": ago(hours=random.randint(1, 60)),
            "completedAt": ago(days=random.randint(0, 5)) if status == "done" else None, "commentCount": 0,
        })

    # videos
    stages = ["idea", "script", "voiceover", "editing", "thumbnail", "review", "scheduled", "published"]
    videos = [
        ("Why did the Chola navy vanish?", "History", "long", "script", "sneha", 1, 6),
        ("Bujji & Chinni Kathalu Ep 9: The Honest Potter", "Bujji & Chinni Kathalu", "long", "voiceover", "priya", 2, 5),
        ("Tinku Adige Prashnalu Ep 5: Comets", "Tinku Adige Prashnalu", "short", "editing", "arjun", 5, 3),
        ("The Old Lamp That Only Works at Dawn (re-edit)", "Bujji & Chinni Kathalu", "long", "editing", "arjun", 9, 2),
        ("Why did the Vijayanagara Empire fall?", "History", "long", "thumbnail", "arjun", 1, 2),
        ("Chittilata: rules in 60 seconds", "Chittilata", "short", "review", "priya", 0, 1),
        ("Why did the Satavahana dynasty fall?", "History", "long", "scheduled", "priya", 1, 1),
        ("Rainbow, explained", "Tinku Adige Prashnalu", "short", "idea", "sneha", 4, 12),
        ("Bujji & Chinni Kathalu Ep 10", "Bujji & Chinni Kathalu", "long", "idea", None, 6, 14),
        ("The Boy Who Carried the Sun | Ep 7", "Bujji & Chinni Kathalu", "long", "published", "priya", 3, -3),
        ("Why did the Nanda Empire fall?", "History", "long", "published", "priya", 4, -4),
    ]
    for title, series, fmt, stage, who, in_stage, publish_in in videos:
        idx = stages.index(stage)
        history = [{"stage": stages[i], "by": uid["priya"], "at": ago(days=in_stage + (idx - i) * 2)} for i in range(idx + 1)]
        add("videos", {
            "title": title, "series": series, "format": fmt, "stage": stage, "assigneeId": uid[who] if who else None,
            "publishAt": ago(days=-publish_in), "youtubeUrl": "", "notes": "", "stageSince": ago(days=in_stage),
            "history": history, "createdBy": uid["priya"], "createdAt": ago(days=in_stage + idx * 2 + 1), "updatedAt": ago(days=in_stage),
        })

    # leads + calls
    names = ["Sunrise Clinic", "Asha Boutique", "Vidya Coaching Centre", "Spice Route Restaurant", "GreenLeaf Organics",
             "Sri Sai Dental", "Urban Fitness Studio", "Pixel Print House", "Lotus Kids School", "Ravi Motors",
             "Bloom Salon", "TechNest Coworking", "Annapurna Caterers", "Shree Jewellers", "Metro Opticals", "Royal Furniture"]
    outcomes = ["connected", "no_answer", "busy", "callback", "interested", "not_interested", "converted", "connected", "no_answer", "interested"]
    status_for = {"interested": "interested", "callback": "follow_up", "converted": "won", "not_interested": "lost"}
    for i, name in enumerate(names):
        owner = "kiran" if i % 2 == 0 else "divya"
        n_calls = random.randint(0, 4)
        status, last = "new", None
        lead_id = add("leads", {
            "name": name, "phone": f"+91 9{random.randint(100000000, 999999999)}", "company": name,
            "source": random.choice(["website", "referral", "cold", "social", "ads"]),
            "service": random.choice(["youtube", "marketing", "development"]), "status": "new", "ownerId": uid[owner],
            "nextFollowUpAt": None, "lastCallAt": None, "callCount": 0, "notes": "", "value": random.choice([15000, 25000, 40000, 60000]),
            "createdAt": ago(days=random.randint(5, 20)), "updatedAt": ago(days=1),
        })
        for c in range(n_calls):
            outcome = random.choice(outcomes)
            at = ago(days=random.choice([0, 0, 0, 1, 2, 3, 5, 8]), hours=random.randint(0, 6), minutes=random.randint(0, 59))
            note = random.choice([
                "Spoke to the owner, wants pricing on WhatsApp.", "Asked to call after 5pm.", "Not reachable.",
                "Interested in a monthly social media package.", "Already working with another agency.", "", "ok",
                "Demo scheduled for Thursday 11am, send calendar invite.",
            ])
            add("calls", {
                "leadId": lead_id, "leadName": name, "phone": "", "callerId": uid[owner], "outcome": outcome,
                "durationMin": 0 if outcome in ("no_answer", "busy") else random.randint(1, 14), "notes": note, "at": at,
            })
            status = status_for.get(outcome, "contacted" if status == "new" else status)
            last = at if last is None or at > last else last
        if n_calls:
            follow = ago(days=random.choice([-2, -1, 0, 0, 1])) if status in ("follow_up", "interested", "contacted") else None
            put_fields = {"status": status, "lastCallAt": last, "callCount": n_calls, "nextFollowUpAt": follow}
            call(f"{FS}/leads/{lead_id}?" + "&".join(f"updateMask.fieldPaths={k}" for k in put_fields),
                 {"fields": {k: val(v) for k, v in put_fields.items()}}, ADMIN, "PATCH")

    add("inquiries", {"name": "Lakshmi Prasad", "contact": "lakshmi@example.com", "service": "development",
                      "message": "We need a booking app for our clinic. Can we talk this week?", "status": "new",
                      "source": "website", "createdAt": ago(hours=3)})
    for text, kind, who, h in [
        ("moved “Chittilata: rules in 60 seconds” to Review", "video", "priya", 2),
        ("logged a call with Sunrise Clinic: Interested", "call", "kiran", 3),
        ("completed “Contact form: send enquiries to workspace”", "task", "rahul", 20),
        ("created the task “Billing screen: GST invoice PDF”", "task", "owner", 26),
    ]:
        add("activity", {"actorId": uid[who], "text": text, "kind": kind, "at": ago(hours=h)})

    print("Seeded the local emulators.\n\nDemo sign-ins (emulator only), password for all:", PASSWORD)
    for email, name, role, dept, _title, status in people:
        print(f"  {email:28} {role:8} {dept:12} {status}")


if __name__ == "__main__":
    main()
