// Receives URLs from the native host (fed by the whatsapp:// handler) and opens
// them in the WhatsApp Web PWA tab that is already open, instead of spawning a
// new window.
const HOST = "com.fjaekel.whatsapp_bridge";
const ALLOWED = /^https:\/\/(web|chat)\.whatsapp\.com\//;
const PWA_TAB = "https://web.whatsapp.com/*";

let port = null;

async function openInPwa(url) {
  if (!ALLOWED.test(url)) return false;
  const tabs = await chrome.tabs.query({ url: PWA_TAB });
  if (!tabs.length) return false;
  // Prefer an app window (the installed PWA) over a plain browser tab.
  const wins = await chrome.windows.getAll({ populate: false });
  const kind = Object.fromEntries(wins.map((w) => [w.id, w.type]));
  const tab = tabs.find((t) => kind[t.windowId] === "app") || tabs[0];
  await chrome.tabs.update(tab.id, { url, active: true });
  await chrome.windows.update(tab.windowId, { focused: true });
  return true;
}

function connect() {
  if (port) return;
  try {
    port = chrome.runtime.connectNative(HOST);
  } catch (e) {
    port = null;
    return;
  }
  port.onMessage.addListener(async (msg) => {
    if (!msg || msg.type !== "open" || typeof msg.url !== "string") return;
    const done = await openInPwa(msg.url);
    // No PWA open: hand it back so the host opens an app window instead.
    if (!done) port.postMessage({ type: "fallback", url: msg.url });
  });
  port.onDisconnect.addListener(() => {
    port = null;
  });
}

// The service worker is killed when idle; the alarm revives it and reconnects
// the host, whose periodic ping keeps it alive in between.
chrome.alarms.create("keepalive", { periodInMinutes: 0.5 });
chrome.alarms.onAlarm.addListener(connect);
chrome.runtime.onStartup.addListener(connect);
chrome.runtime.onInstalled.addListener(connect);
connect();
