#!/usr/bin/env python3
"""
Autograde agent:
- Parse player answers file on Desktop
- Normalize and hash each answer
- Compare to expected hashes in /opt/starwars/answer_hashes.json
- Compute score (10 pts per correct)
- POST result to leaderboard server URL (configurable)

Install path: /opt/starwars/autograde_agent.py
Systemd unit provided runs this via timer every 5 minutes.

Note: this script uses only Python standard library for portability.
"""
import os
import re
import json
import time
import hashlib
import urllib.request
import urllib.error
from datetime import datetime

# Config: leaderboard endpoint (replace with your server)
LEADERBOARD_URL = "https://example-leaderboard.example.org/submit"  # <--- change this

# Paths
EXPECTED_HASHES_FILE = "/opt/starwars/answer_hashes.json"
LOG_FILE = "/var/log/starwars_autograde.log"
PLAYER_DESKTOP_ANSWERS = "/home/CyberPlayer/Desktop/answers.txt"
PLAYER_DESKTOP_STARTHERE = "/home/CyberPlayer/Desktop/StartHere.txt"

# Normalize an answer string before hashing:
# - strip leading/trailing whitespace
# - collapse internal whitespace to single spaces
# - preserve case
def normalize_answer(ans: str) -> str:
    ans = ans.strip()
    ans = re.sub(r'\s+', ' ', ans)
    return ans

# Compute sha256 hex digest
def sha256_hex(s: str) -> str:
    return hashlib.sha256(s.encode('utf-8')).hexdigest()

# Read the expected hashes JSON produced by generate_hashes.py
def load_expected_hashes():
    if not os.path.isfile(EXPECTED_HASHES_FILE):
        raise FileNotFoundError(f"Expected hashes file missing: {EXPECTED_HASHES_FILE}")
    with open(EXPECTED_HASHES_FILE, "r", encoding="utf-8") as fh:
        return json.load(fh)

# Parse answers from student file (answers.txt or StartHere.txt)
def parse_player_answers() -> dict:
    path = None
    if os.path.isfile(PLAYER_DESKTOP_ANSWERS):
        path = PLAYER_DESKTOP_ANSWERS
    elif os.path.isfile(PLAYER_DESKTOP_STARTHERE):
        path = PLAYER_DESKTOP_STARTHERE
    else:
        return {}

    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.readlines()

    # Try to capture answers for questions 1..5
    answers = {}
    text = "".join(lines)
    for q in range(1, 6):
        # Try: "1) <answer>" single-line
        m = re.search(r'^\s*' + re.escape(str(q)) + r'\)\s*(.+)$', text, flags=re.MULTILINE)
        if m:
            answers[str(q)] = m.group(1).strip()
            continue
        # Try: find line "Answer Here:" after the question
        q_re = re.escape(str(q)) + r'\)'
        m2 = re.search(q_re + r'[\s\S]{0,200}?Answer Here:\s*(.*)$', text, flags=re.MULTILINE)
        if m2:
            answers[str(q)] = m2.group(1).strip()
            continue
        # fallback: blank
        answers[str(q)] = ""

    return answers

# Logging helper
def log(msg: str):
    ts = datetime.utcnow().isoformat() + "Z"
    line = f"{ts} {msg}\n"
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as fh:
            fh.write(line)
    except Exception:
        pass

# Build and POST payload to leaderboard (retries built-in)
def post_to_leaderboard(payload: dict):
    data = json.dumps(payload).encode('utf-8')
    headers = {'Content-Type': 'application/json'}
    req = urllib.request.Request(LEADERBOARD_URL, data=data, headers=headers, method='POST')
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                body = resp.read().decode('utf-8', errors='ignore')
                log(f"POST ok, status={resp.status}, body={body}")
                return True
        except urllib.error.HTTPError as e:
            log(f"HTTPError posting to leaderboard: {e.code} {e.reason}")
        except urllib.error.URLError as e:
            log(f"URLError posting to leaderboard: {e}")
        except Exception as e:
            log(f"Unexpected error posting to leaderboard: {e}")
        time.sleep(2 ** attempt)
    return False

# Main grading routine
def grade_and_report():
    try:
        expected = load_expected_hashes()
    except FileNotFoundError as e:
        log(str(e))
        return

    player_answers = parse_player_answers()
    if not player_answers:
        log("No player answers file found; skipping.")
        return

    # Compare each question
    results = {}
    total_points = 0
    per_question_points = 10
    for q in map(str, range(1, 6)):
        student_raw = player_answers.get(q, "")
        student_norm = normalize_answer(student_raw)
        student_hash = sha256_hex(student_norm)
        expected_sha = expected.get(q, {}).get("sha256", "")
        correct = (student_hash == expected_sha)
        points = per_question_points if correct else 0
        results[q] = {
            "student_raw": student_raw,
            "normalized": student_norm,
            "student_sha256": student_hash,
            "expected_sha256": expected_sha,
            "correct": correct,
            "points": points
        }
        total_points += points

    # Prepare payload
    payload = {
        "player": "CyberPlayer",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "score": total_points,
        "max_score": per_question_points * 5,
        "breakdown": results
    }

    # Write a local log copy
    log(f"Scored player: {payload['player']} score={payload['score']}/{payload['max_score']}")

    # Attempt to send
    sent = post_to_leaderboard(payload)
    if not sent:
        log("Failed to post to leaderboard after retries.")

def main():
    try:
        grade_and_report()
    except Exception as e:
        log(f"Uncaught exception in autograde agent: {e}")

if __name__ == "__main__":
    main()
