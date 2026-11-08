// node tests/model.test.js
const fs = require("fs"), path = require("path"), assert = require("assert"), vm = require("vm")
const src = fs.readFileSync(path.join(__dirname, "../Model.js"), "utf8").replace(/^\.pragma library\n/, "")
const M = {}; vm.runInNewContext(src, M)
let n = 0; const t = (name, fn) => { fn(); n++ }
const st = (o) => Object.assign({ capacity: 80, status: "Not charging", onAC: true, end: 90, start: 85, paused: false, restoreTo: 0 }, o)

t("parse sysfs lines", () => {
  const p = M.parse("capacity\t89\nstatus\tNot charging\nbad line\n")
  assert.equal(p.capacity, "89"); assert.equal(p.status, "Not charging"); assert.equal(p["bad line"], undefined)
})
t("num: empty is -1", () => { assert.equal(M.num(""), -1); assert.equal(M.num("85"), 85); assert.equal(M.num(undefined), -1) })
t("behaviour", () => {
  assert.equal(M.behaviourOf("[auto] inhibit-charge force-discharge"), "auto")
  assert.equal(M.behaviourOf("auto [inhibit-charge] force-discharge"), "inhibit-charge")
  assert.equal(M.supportsPause("[auto] inhibit-charge"), true)
  assert.equal(M.supportsPause(""), false)
})
t("start follows end like the helper", () => { assert.equal(M.startFor(80), 75); assert.equal(M.startFor(100), 0) })
t("limit text like Omarchy's panel", () => {
  assert.equal(M.limitText(85, 90), "85-90%"); assert.equal(M.limitText(0, 80), "80%")
  assert.equal(M.limitText(0, 100), "None"); assert.equal(M.limitText(-1, -1), "—")
})
t("state words", () => {
  assert.equal(M.stateText(st({})), "Holding")
  assert.equal(M.stateText(st({ status: "Charging" })), "Charging")
  assert.equal(M.stateText(st({ onAC: false, status: "Discharging" })), "Discharging")
  assert.equal(M.stateText(st({ paused: true })), "Paused")
  assert.equal(M.stateText(st({ end: 100 })), "Not charging")
})
t("tile detail", () => {
  assert.equal(M.detail(st({})), "80% · limit 90%")
  assert.equal(M.detail(st({ end: 100 })), "80% · no limit")
  assert.equal(M.detail(st({ restoreTo: 80 })), "80% · to 100% once")
  assert.equal(M.detail(st({ capacity: -1 })), "No battery")
})
t("charge-once restores when full or unplugged, not before", () => {
  assert.equal(M.shouldRestore(st({ restoreTo: 80, capacity: 95, status: "Charging" })), false)
  assert.equal(M.shouldRestore(st({ restoreTo: 80, capacity: 99 })), true)
  assert.equal(M.shouldRestore(st({ restoreTo: 80, status: "Full", capacity: 97 })), true)
  assert.equal(M.shouldRestore(st({ restoreTo: 80, onAC: false })), true)
  assert.equal(M.shouldRestore(st({ restoreTo: 0, capacity: 100 })), false)
})
t("icons and units", () => {
  assert.equal(M.icon(89, false), M.ICONS[9]); assert.equal(M.icon(0, false), M.ICONS[0])
  assert.equal(M.icon(40, true), M.CHARGING)
  assert.equal(M.health(86440000, 90000000), "96%"); assert.equal(M.wh(86440000), "86Wh")
})
t("stepping stop and start", () => {
  assert.deepEqual(M.stepStop(90, 85, 5), { stop: 95, start: 85 })
  assert.deepEqual(M.stepStop(100, 85, 5), { stop: 100, start: 85 })
  assert.deepEqual(M.stepStop(55, 50, -5), { stop: 50, start: 45 })
  assert.deepEqual(M.stepStop(50, 45, -5), { stop: 50, start: 45 })
  assert.deepEqual(M.stepStop(80, 75, -5), { stop: 75, start: 70 })   // start pulled down
  assert.deepEqual(M.stepStart(90, 85, 5), { stop: 90, start: 85 })   // capped at stop-5
  assert.deepEqual(M.stepStart(90, 60, 5), { stop: 90, start: 65 })
  assert.deepEqual(M.stepStart(90, 0, -5), { stop: 90, start: 0 })
})
console.log("model ok: " + n + " tests")
