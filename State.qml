import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as M

// Battery state, shared by the tile, the page and the bar widget.
//
// Reading needs no privilege: sysfs is world-readable, re-read every 15 s
// (the section stays loaded with the panel closed, which is also what lets
// "charge to 100% once" put the limit back by itself). Writing goes through
// pkexec + /usr/local/libexec/omarchy-battery-limit, allowed for the active
// session without a prompt by polkit (see system/).
Item {
  id: s

  readonly property string helper: "/usr/local/libexec/omarchy-battery-limit"
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/deck"

  // sysfs
  property bool present: false        // a battery with a writable-in-principle end threshold
  property int capacity: -1
  property string status: ""
  property bool onAC: false
  property int start: -1
  property int end: -1
  property string behaviourRaw: ""
  property double energyFull: -1
  property double energyDesign: -1
  property int cycles: -1
  property bool helperReady: false

  // remembered
  property int savedLimit: 80          // what a tap turns the limit back on to
  property int restoreTo: 0            // >0 while "charge to 100% once" runs
  property bool prefsLoaded: false

  property bool busy: false
  property string error: ""

  readonly property bool paused: M.behaviourOf(behaviourRaw) === "inhibit-charge"
  readonly property bool canPause: M.supportsPause(behaviourRaw)
  readonly property bool limitOn: end >= 0 && end < 100
  readonly property bool charging: status === "Charging"
  readonly property var snapshot: ({ capacity: capacity, status: status, onAC: onAC, start: start,
                                     end: end, paused: paused, restoreTo: restoreTo })

  // Deck's five
  readonly property bool active: limitOn
  readonly property string label: "Battery"
  readonly property string icon: M.icon(capacity, charging)
  readonly property string detail: present ? M.detail(snapshot) : "No charge limit here"

  function refresh() { if (!readProc.running) readProc.running = true }

  // Tap: limit on (to the remembered value) <-> off.
  function toggle() {
    if (!present) return
    if (limitOn) setLimit(100)
    else setLimit(savedLimit)
  }

  function setLimit(n) {
    if (n < 100) savedLimit = n
    restoreTo = 0
    savePrefs()
    run(["limit", String(n)])
  }

  function chargeFullOnce() {
    if (!limitOn) return
    restoreTo = end
    savePrefs()
    run(["limit", "100"])
  }

  function cancelFullOnce() {
    var back = restoreTo > 0 ? restoreTo : savedLimit
    restoreTo = 0
    savePrefs()
    run(["limit", String(back)])
  }

  function setPaused(on) { run(["behaviour", on ? "inhibit-charge" : "auto"]) }

  function run(args) {
    if (!helperReady || writeProc.running) return
    error = ""
    busy = true
    writeProc.command = ["pkexec", s.helper].concat(args)
    writeProc.running = true
  }

  function savePrefs() {
    prefsFile.setText(JSON.stringify({ savedLimit: savedLimit, restoreTo: restoreTo }))
  }

  Process {
    id: readProc
    command: ["bash", "-c",
      "b=''; for d in /sys/class/power_supply/BAT*; do [ -e \"$d/charge_control_end_threshold\" ] && { b=$d; break; }; done; " +
      "[ -n \"$b\" ] || { echo none; exit 0; }; " +
      "for f in capacity status charge_control_start_threshold charge_control_end_threshold charge_behaviour energy_full energy_full_design cycle_count; do " +
      "printf '%s\\t%s\\n' \"$f\" \"$(cat \"$b/$f\" 2>/dev/null)\"; done; " +
      "ac=0; for a in /sys/class/power_supply/*/online; do [ \"$(cat \"$a\" 2>/dev/null)\" = 1 ] && ac=1; done; printf 'ac\\t%s\\n' $ac; " +
      "[ -x " + s.helper + " ] && [ -f /usr/share/polkit-1/actions/com.mutex-solutions.battery.limit.policy ] && h=1 || h=0; printf 'helper\\t%s\\n' $h"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "")
        if (raw.trim() === "none") { s.present = false; return }
        var p = M.parse(raw)
        s.present = M.num(p.charge_control_end_threshold) > 0
        s.capacity = M.num(p.capacity)
        s.status = p.status || ""
        s.onAC = p.ac === "1"
        s.start = M.num(p.charge_control_start_threshold)
        s.end = M.num(p.charge_control_end_threshold)
        s.behaviourRaw = p.charge_behaviour || ""
        s.energyFull = M.num(p.energy_full)
        s.energyDesign = M.num(p.energy_full_design)
        s.cycles = M.num(p.cycle_count)
        s.helperReady = p.helper === "1"
        if (s.prefsLoaded && M.shouldRestore(s.snapshot)) {
          var back = s.restoreTo
          s.restoreTo = 0
          s.savePrefs()
          s.run(["limit", String(back)])
        }
      }
    }
  }

  Process {
    id: writeProc
    stderr: StdioCollector { id: writeErr; waitForEnd: true }
    onExited: function(code) {
      s.busy = false
      if (code !== 0) s.error = String(writeErr.text || "").trim() || ("could not change the limit (" + code + ")")
      settle.restart()
    }
  }

  // sysfs reflects a write at once, but give the firmware a beat.
  Timer { id: settle; interval: 300; onTriggered: s.refresh() }
  Timer { interval: 15000; running: true; repeat: true; onTriggered: s.refresh() }

  FileView {
    id: prefsFile
    path: s.stateDir + "/battery.json"
    printErrors: false
    onLoaded: {
      try {
        var v = JSON.parse(text()) || {}
        if (Number(v.savedLimit) >= 50 && Number(v.savedLimit) < 100) s.savedLimit = Number(v.savedLimit)
        s.restoreTo = Number(v.restoreTo) > 0 ? Number(v.restoreTo) : 0
      } catch (e) {
      }
      s.prefsLoaded = true
    }
    onLoadFailed: s.prefsLoaded = true
  }

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", s.stateDir]
    onExited: s.refresh()
  }

  Component.onCompleted: mkdirProc.running = true
}
