#!/usr/bin/env python3
"""Refresh site/videos.json from the channel's public YouTube feed.

No API key needed. If the feed cannot be reached the existing file is kept,
so a deploy never fails because of YouTube.
"""
import json
import pathlib
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

CHANNEL_ID = "UCdBiq4YsDqFGBrX1s1JCc4w"
OUT = pathlib.Path(__file__).resolve().parent.parent / "site" / "videos.json"
NS = {"a": "http://www.w3.org/2005/Atom", "yt": "http://www.youtube.com/xml/schemas/2015"}


def main() -> int:
    url = f"https://www.youtube.com/feeds/videos.xml?channel_id={CHANNEL_ID}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (site build)"})
        with urllib.request.urlopen(req, timeout=20) as res:
            root = ET.fromstring(res.read())
    except Exception as err:  # network, HTTP or XML problem: keep what we have
        print(f"videos: feed not available ({err}); keeping existing {OUT.name}")
        return 0

    videos = []
    for entry in root.findall("a:entry", NS):
        vid = entry.findtext("yt:videoId", default="", namespaces=NS)
        title = entry.findtext("a:title", default="", namespaces=NS).strip()
        published = entry.findtext("a:published", default="", namespaces=NS)
        if re.fullmatch(r"[\w-]{6,20}", vid) and title:
            videos.append({"id": vid, "title": title, "published": published})

    if not videos:
        print("videos: feed was empty; keeping existing file")
        return 0

    OUT.write_text(json.dumps({"channel": CHANNEL_ID, "videos": videos[:15]}, ensure_ascii=False, indent=2) + "\n")
    print(f"videos: wrote {len(videos[:15])} videos to {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
