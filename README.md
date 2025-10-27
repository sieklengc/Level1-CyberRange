
# CyberRange Level 1


## ⭐ Star Wars Cyber Range

A themed capture-the-flag (CTF) environment built on Raspberry Pi.  
Participants complete challenges involving Linux basics, hashing, steganography, and user/group permissions — all wrapped in a Star Wars storyline.

---

## 🚀 Features
- Preconfigured users and groups: `jedi`, `rebel`, `sith`, `droid`.
- Shared drives for each group with hidden files.
- Competitor account: `CyberPlayer`.
- Challenges include:
  - Deciphering a ROT13 question.
  - Computing SHA-256 of a provided image.
  - Locating files with `grep`/`find`.
  - Brute forcing a password to access Darth Vader’s account.
  - Extracting a hidden stego message from a JPEG.
- Automated scoring agent with leaderboard integration.

---

## 📂 Repository Structure
- `setup_starwars_range.sh` — provisioning script to build the environment.  
- `sith_plan.txt` — storyline file hidden in Sith shared drive.  
- `alderaan.jpeg` — stego image containing a secret.  
- `StartHere.txt` — instructions for competitors.  
- `flag_vader_source.txt` — deployed as Vader’s flag + steg instructions.  
- `autograde_agent.py` — background scoring agent.  
- `autograde.service` / `autograde.timer` — systemd units for scheduling.  
- `answer_hashes.json` — **hashes-only** file used by the autograder.  

---

## 🏁 Getting Started (Players)
1. Log in as **CyberPlayer** (credentials provided during event).  
2. Open `StartHere.txt` on your Desktop.  
3. Follow the instructions, filling in the "Answer Here:" sections.  
4. Save as `answers.txt` on your Desktop.  
5. Progress is auto-graded and posted to the leaderboard.  

---

## ⚠️ Notes
- Passwords are intentionally weak (for crackability).  
- Do not reuse outside of this controlled CTF environment.  
- Admin setup and autograder instructions are provided separately (`README_Admin`).  

---

## 📜 License
MIT License (or add your chosen license here).
