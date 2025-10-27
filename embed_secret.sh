#!/usr/bin/env bash
# embed_secret.sh
# Embed a secret message into alderaan.jpeg using steghide and replace the original file.
# Run this from the directory that contains alderaan.jpeg (e.g., /home/CyberPlayer/Desktop).
# NOTE: This writes a backup alderaan.jpeg.bak and replaces alderaan.jpeg with the stego version.

set -euo pipefail

COVER="alderaan.jpeg"
TMP_SECRET=".__secret.txt"
OUT_STEGO="alderaan_stego.jpg"
BACKUP="${COVER}.bak"
STEGHIDE_PASS='FLAG{VADER_DOMINION_1977}'

# 1) Ensure the cover file exists
if [[ ! -f "$COVER" ]]; then
  echo "ERROR: Cover file not found: $COVER" >&2
  exit 2
fi

# 2) Install steghide if missing (Debian-based)
if ! command -v steghide >/dev/null 2>&1; then
  echo "steghide not found — installing (apt-get). You may be prompted for sudo."
  sudo apt-get update
  sudo apt-get install -y steghide
fi

# 3) Create temporary secret file
cat > "$TMP_SECRET" <<'EOF'
My Secret is that I am Luke Skywalker's Father.
EOF

# 4) Backup original image
cp --preserve=mode,ownership,timestamps "$COVER" "$BACKUP"
echo "Backed up original to $BACKUP"

# 5) Embed secret into the image with steghide
steghide embed -cf "$COVER" -ef "$TMP_SECRET" -sf "$OUT_STEGO" -p "$STEGHIDE_PASS"

# 6) Replace original with stego file
mv -f "$OUT_STEGO" "$COVER"
echo "Replaced $COVER with stego image (embedded secret)."

# 7) Fix ownership/permissions to match backup
if [[ -f "$BACKUP" ]]; then
  if command -v stat >/dev/null 2>&1; then
    owner=$(stat -c "%u:%g" "$BACKUP" 2>/dev/null || true)
    if [[ -n "$owner" ]]; then
      chown "$owner" "$COVER" 2>/dev/null || true
    fi
  fi
fi

# 8) Cleanup
shred -u -z "$TMP_SECRET" 2>/dev/null || rm -f "$TMP_SECRET"
echo "Cleaned up temporary secret file."

echo
echo "IMPORTANT:"
echo " - Password used for embedding: $STEGHIDE_PASS"
echo " - Original image backup is at: $BACKUP"
echo
