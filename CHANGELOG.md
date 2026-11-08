# Changelog

## 0.1.0

- Two fields: **Stop charging at** (50-100%) and **Start charging below**
  (0 to stop-5, "Always" at 0), each a − / + stepper in 5s; start never
  reaches stop. **Limit on / off** button; off = stop at 100%.
- Tap the tile to turn the limit on (the last stop/start used) or off.
- Charge to 100% once: lifts the limit until the battery is full or
  unplugged, then puts it back by itself.
- Pause charging (firmware `inhibit-charge`) where the battery supports it.
- Page laid out like Omarchy's own battery panel; battery size, cycles and
  health alongside.
- Root helper + polkit action, installed once with scripts/install-helper.sh;
  allowed for the active session without a prompt.
