#!/usr/bin/env bash
# Wires this checkout into the desktop: the whatsapp:// handler, the native
# messaging host and the scheme registration. The extension itself is loaded by
# hand in chrome://extensions (see README).
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$HOME/.local/bin"
apps="$HOME/.local/share/applications"
hosts="$HOME/.config/google-chrome/NativeMessagingHosts"

app_id="$(sed -n 's/.*--app-id=\([a-p]\{32\}\).*/\1/p' \
  $(grep -l '^Name=WhatsApp' "$apps"/chrome-*.desktop 2>/dev/null || true) 2>/dev/null | head -1)"
if [ -z "$app_id" ]; then
  echo "WhatsApp Web PWA not found: install it from Chrome first (web.whatsapp.com > Install)." >&2
  exit 1
fi
ext_id="$(python3 "$repo/tools/extension-id.py" "$repo/extension/manifest.json")"

mkdir -p "$bin" "$apps" "$hosts"
ln -sfn "$repo/bin/whatsapp-uri-handler" "$bin/whatsapp-uri-handler"
ln -sfn "$repo/bin/whatsapp-bridge-host" "$bin/whatsapp-bridge-host"

sed -e "s|@HANDLER@|$bin/whatsapp-uri-handler|" \
    -e "s|@ICON@|chrome-$app_id-Default|" \
    -e "s|@APP_ID@|$app_id|" \
    "$repo/share/whatsapp-uri-handler.desktop.in" > "$apps/whatsapp-uri-handler.desktop"
sed -e "s|@HOST@|$bin/whatsapp-bridge-host|" \
    -e "s|@EXT_ID@|$ext_id|" \
    "$repo/share/com.fjaekel.whatsapp_bridge.json.in" > "$hosts/com.fjaekel.whatsapp_bridge.json"

xdg-mime default whatsapp-uri-handler.desktop x-scheme-handler/whatsapp
update-desktop-database "$apps" 2>/dev/null || true

echo "handler:   $(xdg-mime query default x-scheme-handler/whatsapp)"
echo "PWA id:    $app_id"
echo "extension: $ext_id  (load $repo/extension in chrome://extensions)"
