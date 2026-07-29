{
  csvPath,
  calibrateShaperPath,
  shaperCalibratePath,
  shaperDefsPath,
  drSolverPath,
}: let
  pkgs = import <nixpkgs> {};
  python = pkgs.python3.withPackages (ps:
    with ps; [
      matplotlib
      numpy
    ]);
  importFile = name: path:
    builtins.path {
      inherit name;
      path = /. + path;
    };
  csv = importFile (builtins.baseNameOf csvPath) csvPath;
  calibrateShaper = importFile "calibrate_shaper.py" calibrateShaperPath;
  shaperCalibrate = importFile "shaper_calibrate.py" shaperCalibratePath;
  shaperDefs = importFile "shaper_defs.py" shaperDefsPath;
  drSolver = importFile "dr_solver.py" drSolverPath;
in
  pkgs.runCommand "reshelper-analysis-${builtins.baseNameOf csvPath}" {
    nativeBuildInputs = [python];
  } ''
    mkdir -p analyzer/extras "$out"
    cp ${calibrateShaper} analyzer/calibrate_shaper.py
    cp ${shaperCalibrate} analyzer/extras/shaper_calibrate.py
    cp ${shaperDefs} analyzer/extras/shaper_defs.py
    touch analyzer/extras/__init__.py

    substituteInPlace analyzer/calibrate_shaper.py \
      --replace-fail \
        'str(pathlib.Path(__file__).parent.parent)' \
        'str(pathlib.Path(__file__).parent)' \
      --replace-fail \
        'from klippy.extras import shaper_calibrate' \
        'from extras import shaper_calibrate'

    substituteInPlace analyzer/extras/shaper_calibrate.py \
      --replace-fail 'np.trapz' 'np.trapezoid'

    python analyzer/calibrate_shaper.py \
      ${csv} \
      --output "$out/shaper.png" \
      > "$out/analysis.txt"

    python ${drSolver} ${csv} > "$out/damping-ratio.txt"
  ''
