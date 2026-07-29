#!/bin/bash
set -euo pipefail

axis="${1:-}"
calculate_damping="${2:-1}"
classic_mode="${3:-0}"

if [[ "$axis" != "x" && "$axis" != "y" ]]; then
  echo "ResHelper: ERROR: expected axis x or y, got '$axis'"
  exit 1
fi
if [[ "$calculate_damping" != "0" && "$calculate_damping" != "1" ]]; then
  echo "ResHelper: ERROR: damping argument must be 0 or 1"
  exit 1
fi
if [[ "$classic_mode" != "0" ]]; then
  echo "ResHelper: ERROR: classic analysis is not enabled in this package"
  exit 1
fi

script_dir=$(dirname "$(realpath "$0")")
klipper_path=$(realpath "$script_dir/../..")
home_path=${klipper_path%/*}
config_path="$home_path/printer_data/config"
tmp_path=${TMPDIR:-/tmp}
res_data_path="$config_path/RES_DATA"

if [[ ! -d "$config_path" ]]; then
  echo "ResHelper: ERROR: config path does not exist: $config_path"
  exit 1
fi

shopt -s nullglob
csv_files=("$tmp_path"/resonances_"$axis"_*.csv)
if ((${#csv_files[@]} == 0)); then
  echo "ResHelper: ERROR: no resonance CSV found for the $axis axis in $tmp_path"
  exit 1
fi

csv_path=${csv_files[0]}
for candidate in "${csv_files[@]:1}"; do
  if [[ "$candidate" -nt "$csv_path" ]]; then
    csv_path=$candidate
  fi
done

if ! nix_bin=$(command -v nix); then
  nix_bin=/nix/var/nix/profiles/default/bin/nix
fi
if [[ ! -x "$nix_bin" ]]; then
  echo "ResHelper: ERROR: nix executable not found"
  exit 1
fi

echo "ResHelper: analyzing $(basename "$csv_path") with a Nix remote build"
analysis_result=$(
  "$nix_bin" build \
    --impure \
    -j0 \
    --no-link \
    --print-out-paths \
    -f "$script_dir/analysis.nix" \
    --argstr csvPath "$csv_path" \
    --argstr calibrateShaperPath "$klipper_path/scripts/calibrate_shaper.py" \
    --argstr shaperCalibratePath "$klipper_path/klippy/extras/shaper_calibrate.py" \
    --argstr shaperDefsPath "$klipper_path/klippy/extras/shaper_defs.py" \
    --argstr drSolverPath "$script_dir/dr_solver.py"
)

cat "$analysis_result/analysis.txt"

dr=NA
if [[ "$calculate_damping" == "1" ]]; then
  dr=$(<"$analysis_result/damping-ratio.txt")
  echo "ResHelper: damping ratio: $dr"
fi

mkdir -p "$res_data_path"
output_name="shaper_calibrate_${axis}-dr_${dr}-v$(date '+%Y%m%d_%H%M').png"
install -m644 "$analysis_result/shaper.png" "$res_data_path/$output_name"
echo "ResHelper: image generated: $res_data_path/$output_name"

archive_path="$tmp_path/rh-prev-run"
mkdir -p "$archive_path"
mv -f "$csv_path" "$archive_path/"

echo "ResHelper: finished"
