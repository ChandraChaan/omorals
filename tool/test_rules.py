#!/usr/bin/env python3
"""Check the Firestore security rules against the LOCAL emulators.

Signs in as the demo users created by tool/seed_emulator.py and tries things
each role should and should not be able to do. Exits non-zero on any surprise.

    firebase emulators:start --project omorals --only auth,firestore,hosting
    python3 tool/seed_emulator.py
    python3 tool/test_rules.py
"""
import datetime as dt
import json
import sys
import urllib.error
import urllib.request

PROJECT = "omorals"
AUTH = "http://localhost:9099/identitytoolkit.googleapis.com/v1"
FS = f"http://localhost:8080/v1/projects/{PROJECT}/databases/(default)/documents"
PASSWORD = "demo-pass-123"  # emulator-only, same as seed_emulator.py
failures = []


def http(method, url, body=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            return res.status, json.loads(res.read() or b"{}")
    except urllib.error.HTTPError as err:
        return err.code, {}


def sign_in(name):
    _, res = http("POST", f"{AUTH}/accounts:signInWithPassword?key=demo",
                  {"email": f"{name}@omorals.test", "password": PASSWORD, "returnSecureToken": True})
    return res["idToken"], res["localId"]


def s(v):
    return {"stringValue": v}


def ts(d):
    return {"timestampValue": d.isoformat().replace("+00:00", "Z")}


def query(token, collection, field=None, value=None):
    q = {"from": [{"collectionId": collection}]}
    if field:
        q["where"] = {"fieldFilter": {"field": {"fieldPath": field}, "op": "EQUAL", "value": s(value)}}
    code, res = http("POST", f"{FS}:runQuery", {"structuredQuery": q}, token)
    docs = [r["document"] for r in res if "document" in r] if isinstance(res, list) else []
    return code, docs


def check(label, got, want):
    ok = got == want
    print(f"  {'ok  ' if ok else 'FAIL'} {label}" + ("" if ok else f"  (got {got}, wanted {want})"))
    if not ok:
        failures.append(label)


def main():
    now = dt.datetime.now(dt.timezone.utc)
    owner, owner_id = sign_in("owner")
    manager, _ = sign_in("priya")
    editor, editor_id = sign_in("arjun")
    caller, caller_id = sign_in("kiran")
    caller2, caller2_id = sign_in("divya")
    dev, dev_id = sign_in("rahul")
    pending, pending_id = sign_in("newjoiner")

    print("Pending sign-up")
    check("cannot list tasks", query(pending, "tasks")[0], 403)
    check("cannot list team", query(pending, "users")[0], 403)
    check("can read own profile", http("GET", f"{FS}/users/{pending_id}", token=pending)[0], 200)
    check("cannot activate themselves", http("PATCH", f"{FS}/users/{pending_id}?updateMask.fieldPaths=status", {"fields": {"status": s("active")}}, pending)[0], 403)

    print("Members")
    check("see tasks", query(editor, "tasks")[0], 200)
    check("cannot promote themselves", http("PATCH", f"{FS}/users/{editor_id}?updateMask.fieldPaths=role", {"fields": {"role": s("admin")}}, editor)[0], 403)
    check("can edit own name", http("PATCH", f"{FS}/users/{editor_id}?updateMask.fieldPaths=name", {"fields": {"name": s("Arjun Varma")}}, editor)[0], 200)
    check("cannot create a project", http("POST", f"{FS}/projects", {"fields": {"name": s("x")}}, editor)[0], 403)
    check("cannot create a task as someone else", http("POST", f"{FS}/tasks", {"fields": {"title": s("x"), "reporterId": s(owner_id)}}, editor)[0], 403)
    code, task = http("POST", f"{FS}/tasks", {"fields": {"title": s("Rules test task"), "reporterId": s(editor_id), "assigneeId": s(editor_id), "status": s("todo")}}, editor)
    check("can create own task", code, 200)
    task_path = task.get("name", "").split("/documents/")[-1]
    check("another member cannot edit that task", http("PATCH", f"{FS}/{task_path}?updateMask.fieldPaths=status", {"fields": {"status": s("done")}}, dev)[0], 403)
    check("a manager can edit that task", http("PATCH", f"{FS}/{task_path}?updateMask.fieldPaths=status", {"fields": {"status": s("review")}}, manager)[0], 200)
    check("reporter can delete it", http("DELETE", f"{FS}/{task_path}", token=editor)[0], 200)

    print("YouTube pipeline")
    _, videos = query(editor, "videos")
    video_path = videos[0]["name"].split("/documents/")[-1]
    check("youtube member can move a video", http("PATCH", f"{FS}/{video_path}?updateMask.fieldPaths=stage", {"fields": {"stage": s("review")}}, editor)[0], 200)
    check("developer cannot move a video", http("PATCH", f"{FS}/{video_path}?updateMask.fieldPaths=stage", {"fields": {"stage": s("idea")}}, dev)[0], 403)
    check("member cannot delete a video", http("DELETE", f"{FS}/{video_path}", token=editor)[0], 403)

    print("Leads and calls")
    check("caller cannot list every lead", query(caller, "leads")[0], 403)
    code, mine = query(caller, "leads", "ownerId", caller_id)
    check("caller lists own leads", (code, len(mine) > 0), (200, True))
    check("caller cannot list a colleague's leads", query(caller, "leads", "ownerId", caller2_id)[0], 403)
    check("editor cannot list leads", query(editor, "leads", "ownerId", editor_id)[0], 403)
    check("manager lists every lead", query(manager, "leads")[0], 200)
    lead_path = mine[0]["name"].split("/documents/")[-1]
    check("caller cannot hand their lead to someone else", http("PATCH", f"{FS}/{lead_path}?updateMask.fieldPaths=ownerId", {"fields": {"ownerId": s(caller2_id)}}, caller)[0], 403)
    check("caller cannot delete a lead", http("DELETE", f"{FS}/{lead_path}", token=caller)[0], 403)

    call = {"leadId": s("x"), "leadName": s("x"), "callerId": s(caller_id), "outcome": s("connected"), "notes": s("")}
    check("caller cannot back-date a call", http("POST", f"{FS}/calls", {"fields": {**call, "at": ts(now - dt.timedelta(days=2))}}, caller)[0], 403)
    check("caller cannot log a call as a colleague", http("POST", f"{FS}/calls", {"fields": {**call, "callerId": s(caller2_id), "at": ts(now)}}, caller)[0], 403)
    code, own_calls = query(caller, "calls", "callerId", caller_id)
    check("caller lists own calls", code, 200)
    if own_calls:
        call_path = own_calls[0]["name"].split("/documents/")[-1]
        check("caller cannot edit a logged call", http("PATCH", f"{FS}/{call_path}?updateMask.fieldPaths=outcome", {"fields": {"outcome": s("converted")}}, caller)[0], 403)
        check("caller cannot delete a logged call", http("DELETE", f"{FS}/{call_path}", token=caller)[0], 403)
    check("caller cannot see a colleague's calls", query(caller, "calls", "callerId", caller2_id)[0], 403)
    check("manager sees every call", query(manager, "calls")[0], 200)
    check("caller cannot read website enquiries", query(caller, "inquiries")[0], 403)
    check("manager reads website enquiries", query(manager, "inquiries")[0], 200)

    print("Admin")
    check("manager cannot change roles", http("PATCH", f"{FS}/users/{dev_id}?updateMask.fieldPaths=role", {"fields": {"role": s("manager")}}, manager)[0], 403)
    check("owner approves a pending member", http("PATCH", f"{FS}/users/{pending_id}?updateMask.fieldPaths=status", {"fields": {"status": s("active")}}, owner)[0], 200)
    check("owner cannot create a second owner", http("PATCH", f"{FS}/users/{dev_id}?updateMask.fieldPaths=role", {"fields": {"role": s("owner")}}, owner)[0], 403)
    check("nobody can take over the workspace", http("PATCH", f"{FS}/meta/workspace?updateMask.fieldPaths=ownerUid", {"fields": {"ownerUid": s(editor_id)}}, editor)[0], 403)
    http("PATCH", f"{FS}/users/{pending_id}?updateMask.fieldPaths=status", {"fields": {"status": s("pending")}}, owner)

    print()
    if failures:
        print(f"{len(failures)} check(s) failed")
        return 1
    print("All rule checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
