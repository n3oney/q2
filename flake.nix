{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    klipper = {
      url = "github:n3oney/qidi-q2-klipper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    happy-hare = {
      url = "github:Wazzup77/Happy-Hare/bunnybox";
      flake = false;
    };

    autopa = {
      url = "github:G0BL1N/autopa";
      flake = false;
    };

    shaketune = {
      url = "github:Frix-x/klippain-shaketune";
      flake = false;
    };

    reshelper = {
      url = "github:lhndo/ResHelper";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    klipper,
    autopa,
    shaketune,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    projectOwner = "n3oney";
    projectName = "q2";
    releaseVersion = "v0.0.${builtins.substring 0 12 self.lastModifiedDate}";
    assetName = "${projectName}.zip";
    releaseInfo = builtins.toJSON {
      project_name = projectName;
      project_owner = projectOwner;
      version = releaseVersion;
      asset_name = assetName;
    };
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        base = klipper.packages.${system}.kalico-bleeding-edge;

        happy-hare = pkgs.applyPatches {
          name = "happy-hare";
          src = inputs.happy-hare;
          patches = [./patches/happy-hare-kalico-extruder.patch];
        };

        reshelper = pkgs.applyPatches {
          name = "reshelper";
          src = inputs.reshelper;
          patches = [./patches/reshelper-runtime.patch];
        };

        package = pkgs.callPackage ./nix/with-klippy-extras.nix {
          name = "${base.name}-with-extras";
          src = base;
          extras = {
            mmu = "${happy-hare}/extras/mmu";
            "mmu_encoder.py" = "${happy-hare}/extras/mmu_encoder.py";
            "mmu_espooler.py" = "${happy-hare}/extras/mmu_espooler.py";
            "mmu_led_effect.py" = "${happy-hare}/extras/mmu_led_effect.py";
            "mmu_leds.py" = "${happy-hare}/extras/mmu_leds.py";
            "mmu_machine.py" = "${happy-hare}/extras/mmu_machine.py";
            "mmu_sensors.py" = "${happy-hare}/extras/mmu_sensors.py";
            "mmu_servo.py" = "${happy-hare}/extras/mmu_servo.py";
            autopa = "${autopa}/autopa";
            shaketune = "${shaketune}/shaketune";
          };
          scripts = {
            "flash-mcus.sh" = ./scripts/flash-mcus.sh;
            "flashtool.py" = "${klipper.packages.${system}.katapult-source}/scripts/flashtool.py";
          };
          files = {
            "klippy/plugins/shaper_calibrate_classic.py" = "${reshelper}/patches/dk_be/shaper_calibrate_classic.py";
            "scripts/calibrate_shaper_classic.py" = "${reshelper}/patches/dk_be/calibrate_shaper_classic.py";
            "scripts/reshelper/dr_solver.py" = "${reshelper}/dr_solver.py";
            "scripts/reshelper/gen.sh" = "${reshelper}/gen.sh";
          };
          requirements = builtins.filter builtins.pathExists [
            "${happy-hare}/requirements.txt"
            "${autopa}/requirements.txt"
            "${shaketune}/requirements.txt"
          ];
        };

        releaseZip = pkgs.stdenv.mkDerivation {
          pname = assetName;
          version = releaseVersion;

          dontUnpack = true;

          nativeBuildInputs = [pkgs.zip];
          installPhase = ''
            mkdir package
            cp -rL "${package}/." package/
            chmod -R u+rwX,go+rX package
            printf '%s\n' ${lib.escapeShellArg releaseInfo} > package/release_info.json

            find package -exec touch -h -d '@${toString self.lastModified}' {} +
            export TZ=UTC
            (
              cd package
              zip -r -X "$out" .
            )
          '';

          passthru.package = package;
        };
      in {
        kalico-bleeding-edge = package;
        zip = releaseZip;
        default = package;
      }
    );
  };
}
