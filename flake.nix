{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    klipper = {
      url = "github:n3oney/qidi-q2-klipper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    happy-hare = {
      url = "github:moggieuk/Happy-Hare";
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
  };

  outputs = {
    nixpkgs,
    klipper,
    happy-hare,
    autopa,
    shaketune,
    ...
  }: let
    lib = nixpkgs.lib;
    forAllSystems = lib.genAttrs lib.systems.flakeExposed;
  in {
    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        base = klipper.packages.${system}.kalico-bleeding-edge;

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
          requirements = builtins.filter builtins.pathExists [
            "${happy-hare}/requirements.txt"
            "${autopa}/requirements.txt"
            "${shaketune}/requirements.txt"
          ];
        };
      in {
        kalico-bleeding-edge = package;
        default = package;
      }
    );
  };
}
