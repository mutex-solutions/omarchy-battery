# Battery

Battery charge limit for Omarchy, as a [Deck](https://github.com/mutex-solutions/omarchy-deck)
section or a bar widget. Omarchy's own battery panel *shows* the charge limit;
this one changes it.

- **Tile:** percentage and the limit. **Tap** turns the limit on (the last value
  you used) or off; **hold** opens the page.
- **Page:** laid out like Omarchy's battery panel, plus a **Charge limit** row —
  60 · 70 · 80 · 90 · Off — **100% once** (lifts the limit until the battery is
  full or unplugged, then restores it) and **Pause charging** (hold the current
  level, where the firmware supports `inhibit-charge`).

Charging resumes 5 points below the limit, so a laptop that lives on AC is not
topped up every few minutes.

## Requirements

A laptop whose kernel driver exposes
`/sys/class/power_supply/BAT*/charge_control_end_threshold` — ThinkPads
(`thinkpad_acpi`), many ASUS, some Dell/HP/Framework. Without it the page says
so. Checked on a ThinkPad P1 Gen 7.

## Install

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-battery
bash ~/.config/omarchy/plugins/mutex-solutions.battery/scripts/install-helper.sh   # once, needs sudo
```

then add it to Deck from **Sections** (or `deck-add-section
https://github.com/mutex-solutions/omarchy-battery`), or enable the bar widget.

Writing a threshold needs root. `install-helper.sh` installs
`/usr/local/libexec/omarchy-battery-limit` and the polkit action
`com.mutex-solutions.battery.limit`, which lets the **active local session** run
that one program **without a prompt**: it only takes a limit of 50-100 or
pausing charging, so the worst a caller can do is charge to 100% or hold the
current level. Remove with `install-helper.sh --remove`.

## How it is built

| File | Role |
| --- | --- |
| `State.qml` | reads sysfs every 15 s, calls the helper, runs the "100% once" watch |
| `Model.js` | pure logic (text, icons, restore rule), tested under node |
| `deck/Section.qml`, `deck/Page.qml` | Deck tile and page |
| `Panel.qml` | standalone bar widget |
| `system/` | the root helper and the polkit action |

`bash scripts/validate.sh` runs the checks.

## Licence

MIT. See [LICENSE](LICENSE).
