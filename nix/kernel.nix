# ak-rex ClockworkPi kernel (rpi-6.12.y branch)
# Fork of raspberrypi/linux with uConsole drivers:
#   - panel-cwu50 (DSI display), ocp8178_bl (backlight)
#   - clockworkpi-uconsole-cm5.dtbo, clockworkpi-custom-battery.dtbo
#   - axp20x battery/power drivers enabled
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.uconsole;

  clockworkpiKernel =
    (pkgs.buildLinux {
      inherit (cfg.kernel) src version;
      modDirVersion = "${cfg.kernel.version}-v8-16k";
      defconfig = "bcm2712_defconfig";
      # Build with ONLY bcm2712_defconfig — do not merge NixOS common config.
      autoModules = false;
      # ARM64 RPi defconfig lacks many x86 options that NixOS common config
      # tries to set — tolerate mismatches (same as nixos-raspberrypi's linux-rpi.nix)
      ignoreConfigErrors = true;
    }).overrideAttrs (old: {
      # The RPi firmware checks for ${os_prefix}${overlay_prefix}README
      # before using os_prefix for overlay path resolution. Without this
      # file, the firmware silently ignores all dtoverlay= entries in
      # config.txt (overlays directory exists but firmware falls back to
      # looking at the non-existent root overlays/ directory).
      # This also enables the firmware's auto-application of bcm2712d0.dtbo
      # on D0 silicon (CM5), which corrects pinctrl register addresses.
      # See: raspberrypi/linux#3237, home-assistant/operating-system#3079
      postFixup =
        (old.postFixup or "")
        + ''
          touch "$out/dtbs/overlays/README"
        '';
    });
in {
  options.uconsole.kernel = {
    src = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fetchFromGitHub {
        owner = "ak-rex";
        repo = "ClockworkPi-linux";
        rev = "4b5b5fe35abbbf4193ddbeab149833172096066b";
        hash = "sha256-InyO2ChPqwqzP0PNoKNdYRXAAQ4VbSJrmEy8uif59fc=";
      };
      description = "Kernel source for the ClockworkPi uConsole (ak-rex fork).";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "6.12.67";
      description = "Kernel version string matching the source.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Override nixos-raspberrypi's default Pi 5 kernel with ak-rex fork
    boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor clockworkpiKernel);
  };
}
