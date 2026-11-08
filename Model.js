.pragma library

// Pure battery logic, tested under node (tests/model.test.js). Inputs are the
// raw sysfs strings State.qml reads; nothing here touches the system.

var ICONS = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
var CHARGING = "󰂄"
var LIMITS = [60, 70, 80, 90, 100]

function parse(raw) {
  var out = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var t = lines[i].indexOf("\t")
    if (t > 0) out[lines[i].substring(0, t)] = lines[i].substring(t + 1).trim()
  }
  return out
}

function num(v) {
  var n = Number(v)
  return isFinite(n) && String(v).trim() !== "" ? n : -1
}

// "[auto] inhibit-charge force-discharge" -> "auto"
function behaviourOf(raw) {
  var m = /\[([^\]]+)\]/.exec(String(raw || ""))
  return m ? m[1] : ""
}

function supportsPause(raw) { return String(raw || "").indexOf("inhibit-charge") >= 0 }

// Where charging resumes for a given limit; must match the helper.
function startFor(end) { return end >= 100 ? 0 : end - 5 }

function icon(capacity, charging) {
  if (charging) return CHARGING
  var c = Math.max(0, Math.min(100, capacity))
  return ICONS[Math.round(c / 10)]
}

// The value Omarchy's own panel prints as "Charge limit": "85-90%".
function limitText(start, end) {
  if (end < 0) return "—"
  if (end >= 100) return "None"
  return (start > 0 ? start + "-" : "") + end + "%"
}

// One word for what the battery is doing, Omarchy-style.
function stateText(s) {
  if (s.paused) return "Paused"
  if (s.status === "Charging") return "Charging"
  if (s.status === "Full") return "Full"
  if (!s.onAC) return "Discharging"
  return s.end < 100 ? "Holding" : "Not charging"
}

// The tile's line: "89% · limit 90%".
function detail(s) {
  if (s.capacity < 0) return "No battery"
  var head = s.capacity + "%"
  if (s.restoreTo > 0) return head + " · to 100% once"
  if (s.paused) return head + " · paused"
  return head + (s.end >= 0 && s.end < 100 ? " · limit " + s.end + "%" : " · no limit")
}

// After "charge to 100% once": put the limit back once full, or unplugged.
function shouldRestore(s) {
  return s.restoreTo > 0 && (s.capacity >= 99 || s.status === "Full" || !s.onAC)
}

function health(full, design) {
  if (full <= 0 || design <= 0) return ""
  return Math.round(full / design * 100) + "%"
}

function wh(microWh) { return microWh > 0 ? Math.round(microWh / 1e6) + "Wh" : "—" }
