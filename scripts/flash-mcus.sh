#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
python="${KLIPPER_ENV:-$HOME/klippy-env}/bin/python"
flashtool="$root/scripts/flashtool.py"

"$python" "$flashtool" \
  -d /dev/serial/by-id/usb-*_stm32f407xx_*-if00 \
  -f "$root/firmwares/mcu.bin"

"$python" "$flashtool" -d /dev/ttyS4 -b 500000 -r
"$python" "$flashtool" \
  -d /dev/ttyS4 \
  -b 500000 \
  -f "$root/firmwares/thr.bin"

"$python" "$flashtool" \
  -d /dev/serial/by-id/usb-*_stm32f401xc_*-if00 \
  -f "$root/firmwares/mmu.bin"
