#!/usr/bin/env bash
#
# sync-images.sh — Weekly sync of LCC opening times images
#
# Compares each centre's opening-times image against the local copy in
# ./images/. If the source image has changed (hash differs), the local
# file is replaced with the fresh download.
#
# Schedule this once a week, e.g. via cron:
#   0 3 * * 1 /path/to/sync-images.sh   (every Monday at 03:00)
#
# On Windows, run from Git Bash / WSL, or use Task Scheduler:
#   Program: bash   Arguments: /c/path/to/sync-images.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="$SCRIPT_DIR/images"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$SCRIPT_DIR"

echo "=============================================="
echo " LCC Opening Times — Image Sync"
echo " Started: $(date)"
echo "=============================================="

mkdir -p "$IMAGES_DIR"

# centre_slug | source_url
CENTRES=(
  "vauxwest|https://londonclimbingcentres.co.uk/app/uploads/VWW-White-WEB-1024x294.png"
  "vauxeast|https://londonclimbingcentres.co.uk/app/uploads/VWE-White-WEB-1-1024x361.png"
  "harrowall|https://londonclimbingcentres.co.uk/app/uploads/HW-White-WEB-1024x350.png"
  "croywall|https://londonclimbingcentres.co.uk/app/uploads/CW-White-WEB-1024x468.png"
  "ravenswall|https://londonclimbingcentres.co.uk/app/uploads/RW-White-WEB-1024x287.png"
  "canarywall|https://londonclimbingcentres.co.uk/app/uploads/CNW-White-WEB-1024x346.png"
  "bethwall|https://londonclimbingcentres.co.uk/app/uploads/BW-White-WEB-1024x294.png"
  "eustonwall|https://londonclimbingcentres.co.uk/app/uploads/EW-White-WEB-1-1024x294.png"
)

changed=0
unchanged=0
failed=0

for entry in "${CENTRES[@]}"; do
  IFS='|' read -r slug url <<< "$entry"
  local_file="$IMAGES_DIR/${slug}.png"
  tmp_file="$TMP_DIR/${slug}.png"

  if curl -fsSL --retry 3 --max-time 60 -o "$tmp_file" "$url"; then
    if [[ -f "$local_file" ]]; then
      local_hash=$(sha256sum "$local_file" | awk '{print $1}')
      new_hash=$(sha256sum "$tmp_file" | awk '{print $1}')
      if [[ "$local_hash" == "$new_hash" ]]; then
        echo "  [ unchanged ] $slug"
        unchanged=$((unchanged + 1))
      else
        cp "$tmp_file" "$local_file"
        echo "  [ updated  ] $slug  (image changed)"
        changed=$((changed + 1))
      fi
    else
      cp "$tmp_file" "$local_file"
      echo "  [ new     ] $slug  (image downloaded)"
      changed=$((changed + 1))
    fi
  else
    echo "  [ failed   ] $slug  (could not download)"
    failed=$((failed + 1))
  fi
done

echo "=============================================="
echo " Summary:  $changed updated / $unchanged unchanged / $failed failed"
echo " Finished: $(date)"
echo "=============================================="

# Record the timestamp so the webpage can display it
SYNC_DATE_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SYNC_DATE_HUMAN="$(date -u +"%d %b %Y")"
echo "$SYNC_DATE_ISO" > "$SCRIPT_DIR/.last-sync"

# Inject the human-readable timestamp into index.html
if [ -f "$SCRIPT_DIR/index.html" ] && command -v sed >/dev/null 2>&1; then
  sed -i "s|Last synced: [^<]*|Last synced: $SYNC_DATE_HUMAN|" "$SCRIPT_DIR/index.html"
fi

echo ""
echo "Done."
