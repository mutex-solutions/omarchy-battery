# Changelog

## 0.1.0

- Charge limit: stop charging at 60, 70, 80 or 90%, or Off (100%). Charging
  resumes 5 points below the limit (ThinkPad convention).
- Tap the tile to turn the limit on (the last value used) or off.
- Charge to 100% once: lifts the limit until the battery is full or
  unplugged, then puts it back by itself.
- Pause charging (firmware `inhibit-charge`) where the battery supports it.
- Page laid out like Omarchy's own battery panel; battery size, cycles and
  health alongside.
- Root helper + polkit action, installed once with scripts/install-helper.sh;
  allowed for the active session without a prompt.
