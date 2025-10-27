#!/usr/bin/env python3
"""
generate_hashes.py
Read instructor_answers.txt and write /opt/starwars/answer_hashes.json with SHA-256 hashes ONLY.

Usage:
  sudo python3 generate_hashes.py /path/to/instructor_answers.txt

Output JSON shape (no plaintext answers):
  {
    "1": "56a3a46a3b...2255",
    "2": "9b64002f70...1b90",
    "3": "25c7761e7b...6bba",
    "4": "a63534eb38...53ec",
    "5": "53088e1adf...d055"
  }
"""
import sys, os, re, json, hashlib

# Normalize: trim and collapse internal whitespace; preserve case for flags.
def normalize(s: str) -> str:
    s = s.strip()
    s = re.sub(r'\s+', ' ', s)
    return s

# SHA-256 hex of normalized string.
def h(s: str) -> str:
    return hashlib.sha256(s.encode('utf-8')).hexdigest()

def main():
    if len(sys.argv) != 2:
        print("Usage: sudo python3 generate_hashes.py /path/to/instructor_answers.txt")
        sys.exit(1)

    inst = sys.argv[1]
    if not os.path.isfile(inst):
        print("File not found:", inst)
        sys.exit(2)

    with open(inst, 'r', encoding='utf-8') as f:
        text = f.read()

    answers = {}
    for q in range(1, 6):
        m = re.search(rf'^\s*{q}\)\s*(.+)$', text, flags=re.MULTILINE)
        if not m:
            print(f"Warning: missing answer for {q}; writing empty hash.")
            answers[str(q)] = ""
        else:
            answers[str(q)] = m.group(1).strip()

    # Hash-only output
    out = { str(q): h(normalize(answers[str(q)])) for q in range(1, 6) }

    os.makedirs("/opt/starwars", exist_ok=True)
    with open("/opt/starwars/answer_hashes.json", "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2)
    os.chmod("/opt/starwars/answer_hashes.json", 0o644)
    print("Wrote hashes-only to /opt/starwars/answer_hashes.json")

if __name__ == "__main__":
    main()
