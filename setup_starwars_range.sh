#!/usr/bin/env bash
# setup_starwars_range.sh
# Deploy Star Wars CTF files and autograder from a package directory.
# Expects these files next to this script:
#   sith_plan.txt
#   alderaan.jpeg
#   StartHere.txt
#   flag_vader_source.txt
#   autograde_agent.py
#   autograde.service
#   autograde.timer
#   answer_hashes.json        # hashes-only file produced on instructor machine
# Run as root: sudo bash setup_starwars_range.sh

set -euo pipefail

# require root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)." >&2
  exit 1
fi

# required commands
for bin in useradd groupadd usermod chpasswd install getent chgrp chmod mkdir id cp chown tee systemctl; do
  command -v "$bin" >/dev/null 2>&1 || { echo "Missing required tool: $bin" >&2; exit 1; }
done

# optional ACL tool
HAVE_SETFACL=0
command -v setfacl >/dev/null 2>&1 && HAVE_SETFACL=1

# groups/users
GROUPS=(jedi rebel sith droid)
declare -A USER_GROUP=(
  [lskywalker1]=jedi [lorgana2]=rebel [hsolo3]=rebel [chewie4]=rebel
  [yoda5]=jedi [dvader6]=sith [r2d2_7]=droid [c3po8]=droid
  [okenobi9]=jedi [padme10]=rebel [anakin11]=sith [mwindu12]=jedi
  [qgonn13]=jedi [rey14]=jedi [finn15]=rebel [poe16]=rebel
)
declare -A USER_PASS=(
  [lskywalker1]=8963831018 [lorgana2]=7342900359 [hsolo3]=8869383291 [chewie4]=1572308735
  [yoda5]=0273674704 [dvader6]=3579403794 [r2d2_7]=4527644008 [c3po8]=2017616419
  [okenobi9]=2707856077 [padme10]=7603156447 [anakin11]=8725044272 [mwindu12]=9045489072
  [qgonn13]=3623088045 [rey14]=4570511710 [finn15]=4209534427 [poe16]=0131596652
)
declare -A GROUP_DRIVE=(
  [jedi]="/opt/starwars/Jedi_Temple"
  [rebel]="/opt/starwars/Rebel_Base"
  [sith]="/opt/starwars/Mustafar_Lair"
  [droid]="/opt/starwars/Droid_Bay"
)

# package paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SITH_PLAN="${SCRIPT_DIR}/sith_plan.txt"
SRC_ALDERAAN="${SCRIPT_DIR}/alderaan.jpeg"
SRC_STARTHERE="${SCRIPT_DIR}/StartHere.txt"
SRC_FLAG_SOURCE="${SCRIPT_DIR}/flag_vader_source.txt"
SRC_AUTOGRADE_AGENT="${SCRIPT_DIR}/autograde_agent.py"
SRC_SERVICE_UNIT="${SCRIPT_DIR}/autograde.service"
SRC_TIMER_UNIT="${SCRIPT_DIR}/autograde.timer"
SRC_HASHES_JSON="${SCRIPT_DIR}/answer_hashes.json"     # <-- hashes-only

# verify required files exist
missing=0
for f in "$SRC_SITH_PLAN" "$SRC_ALDERAAN" "$SRC_STARTHERE" "$SRC_FLAG_SOURCE" "$SRC_AUTOGRADE_AGENT" "$SRC_SERVICE_UNIT" "$SRC_TIMER_UNIT" "$SRC_HASHES_JSON"; do
  [[ -f "$f" ]] || { echo "ERROR: Missing required file: $f" >&2; missing=1; }
done
[[ $missing -eq 0 ]] || { echo "Place missing files next to the script and re-run." >&2; exit 2; }

# create groups
for g in "${GROUPS[@]}"; do
  getent group "$g" >/dev/null 2>&1 || { groupadd "$g"; echo "[+] group $g"; }
done

# shared drives
install -d -m 0755 /opt/starwars
for g in "${!GROUP_DRIVE[@]}"; do
  dir="${GROUP_DRIVE[$g]}"
  install -d -m 2770 "$dir"
  chgrp "$g" "$dir"
  if [[ $HAVE_SETFACL -eq 1 ]]; then
    setfacl -m g:"$g":rwx "$dir" || true
    setfacl -d -m g:"$g":rwx "$dir" || true
  fi
done

# users/passwords
for u in "${!USER_GROUP[@]}"; do
  g="${USER_GROUP[$u]}"; pw="${USER_PASS[$u]}"
  if id "$u" >/dev/null 2>&1; then
    cur=$(id -g "$u"); tgt=$(getent group "$g" | awk -F: '{print $3}')
    [[ "$cur" == "$tgt" ]] || usermod -g "$g" "$u"
  else
    useradd -m -s /bin/bash -g "$g" "$u"
  fi
  printf '%s:%s\n' "$u" "$pw" | chpasswd
done

# CyberPlayer
if ! id CyberPlayer >/dev/null 2>&1; then useradd -m -s /bin/bash CyberPlayer; fi
printf 'CyberPlayer:%s\n' 'SaveTheGalaxy^10' | chpasswd
usermod -aG jedi,rebel,sith,droid CyberPlayer

# dvader secrets
DV_SECRETS="/home/dvader6/secrets"
install -d -m 0700 -o dvader6 -g sith "$DV_SECRETS"

# CyberPlayer Desktop
CP_DESKTOP="/home/CyberPlayer/Desktop"
install -d -m 0755 -o CyberPlayer -g CyberPlayer "$CP_DESKTOP"

# copy challenge files
cp "$SRC_SITH_PLAN" "${GROUP_DRIVE[sith]}/sith_plan.txt"
chown root:sith "${GROUP_DRIVE[sith]}/sith_plan.txt"; chmod 0640 "${GROUP_DRIVE[sith]}/sith_plan.txt"

cp "$SRC_ALDERAAN" "$CP_DESKTOP/alderaan.jpeg"
chown CyberPlayer:CyberPlayer "$CP_DESKTOP/alderaan.jpeg"; chmod 0644 "$CP_DESKTOP/alderaan.jpeg"

cp "$SRC_STARTHERE" "$CP_DESKTOP/StartHere.txt"
chown CyberPlayer:CyberPlayer "$CP_DESKTOP/StartHere.txt"; chmod 0644 "$CP_DESKTOP/StartHere.txt"
cp "$CP_DESKTOP/StartHere.txt" /opt/starwars/StartHere.txt
chown CyberPlayer:CyberPlayer /opt/starwars/StartHere.txt; chmod 0644 /opt/starwars/StartHere.txt

# deploy flag file from source
cp "$SRC_FLAG_SOURCE" "$DV_SECRETS/flag_vader.txt"
chown dvader6:sith "$DV_SECRETS/flag_vader.txt"; chmod 0600 "$DV_SECRETS/flag_vader.txt"

# deploy autograder files
cp "$SRC_AUTOGRADE_AGENT" /opt/starwars/autograde_agent.py
chmod 755 /opt/starwars/autograde_agent.py; chown root:root /opt/starwars/autograde_agent.py

cp "$SRC_SERVICE_UNIT" /etc/systemd/system/autograde.service
cp "$SRC_TIMER_UNIT" /etc/systemd/system/autograde.timer
chmod 644 /etc/systemd/system/autograde.service /etc/systemd/system/autograde.timer

# --- copy hashes-only file
cp "$SRC_HASHES_JSON" /opt/starwars/answer_hashes.json
chown root:root /opt/starwars/answer_hashes.json
chmod 644 /opt/starwars/answer_hashes.json
echo "[ok] installed /opt/starwars/answer_hashes.json (hashes-only)"

# enable autograder timer (30s as per your timer unit)
systemctl daemon-reload
systemctl enable --now autograde.timer

# finalize perms on shared dirs
for g in "${!GROUP_DRIVE[@]}"; do
  chgrp "$g" "${GROUP_DRIVE[$g]}" || true
  chmod 2770 "${GROUP_DRIVE[$g]}" || true
done

echo "=== Setup complete ==="
echo "Deployed challenge files, autograder, and hashes-only table."
echo "Autograder timer active: $(systemctl is-enabled autograde.timer 2>/dev/null || true)"
