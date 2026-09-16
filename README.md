# whatsapp-pwa-bridge

Makes `whatsapp://` links — the "Open app" button on every `wa.me` page — open in
the WhatsApp Web PWA window you already have running on Linux, instead of dying
in a *"No Apps available"* dialog.

## How it works

```
wa.me link  ->  xdg-open  ->  whatsapp-uri-handler   (rewrites to web.whatsapp.com/send?...)
                                    |
                              unix socket (0600)
                                    |
                           whatsapp-bridge-host      (native messaging)
                                    |
                              Chrome extension       (chrome.tabs.update on the PWA tab)
```

| Piece | Role |
|---|---|
| `bin/whatsapp-uri-handler` | rewrites `whatsapp://send?phone=…&text=…` into its `web.whatsapp.com` form and hands it to the socket |
| `share/whatsapp-uri-handler.desktop.in` | registers the handler for `x-scheme-handler/whatsapp` |
| `bin/whatsapp-bridge-host` | native messaging host; listens on the socket, forwards the URL to the extension |
| `share/com.fjaekel.whatsapp_bridge.json.in` | allowlists the host for this extension id |
| `extension/` | navigates the open PWA tab and focuses its window |

Group invites (`whatsapp://chat?code=…`) are translated too.

## Install

```bash
git clone git@github.com:fkjaekel/whatsapp-pwa-bridge.git
cd whatsapp-pwa-bridge
./install.sh
```

Then load the extension once: `chrome://extensions` → **Developer mode** →
**Load unpacked** → pick this checkout's `extension/` folder. The manifest pins a
public key, so the id stays `mkcgbebnofigbmjehjonacgdbookjfne` wherever you load
it from — which is what the native host allowlists.

Requires Linux, Google Chrome, python3, and the WhatsApp Web PWA installed
(`web.whatsapp.com` → install icon in the omnibox). `install.sh` reads the PWA's
app id from the `.desktop` file Chrome wrote when you installed it.

## Without the bridge running

The handler falls back to `--app=<url>`: the right chat opens, but in a Chrome
app window of its own. Nothing breaks — you just lose the window reuse.

## Why an extension is needed

Chrome exposes no command-line way to navigate an open PWA window:

- **"Open supported links in this app"** only captures links clicked inside web
  content. A URL handed to Chrome on the command line — which is what `xdg-open`
  does — always lands in a plain browser window.
- **`--app-id=<id>`** reuses the PWA window but ignores any URL you pass with it,
  including `--app-launch-url-for-shortcuts-menu-item`; it always opens the app's
  `start_url`.
- **`--app=<url>`** honours the URL but opens a separate app window, unrelated to
  the installed PWA.
- **`--remote-debugging-port`** is refused by Chrome 136+ on the default profile.

`chrome.tabs.update` from an extension is what is left.

## Notes

- The socket is a unix socket at `$XDG_RUNTIME_DIR/whatsapp-bridge.sock`, mode
  0600, and both ends drop anything that is not a `web`/`chat.whatsapp.com` URL.
  No TCP port is opened.
- WhatsApp restores a chat's saved draft over the link's `text=` parameter, so a
  prefilled message is dropped when that chat already has one.
- The extension's service worker is killed when idle; the host pings it every 20s
  and an alarm reconnects it, which is what keeps the bridge answering.
