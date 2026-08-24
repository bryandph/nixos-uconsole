# uConsole CM5 kernel: nixos-raspberrypi's linux_rpi5 (same kernel as
# the rest of the Pi 5 fleet) plus an owned ClockworkPi patch series
# extracted from the ak-rex/ClockworkPi-linux fork (rpi-7.1.y branch,
# the consolidated state of the drivers) and rebased onto rpi-6.18.y:
#   0001  panel-cwu50 DSI panel driver (merged CM3/CM4/CM5 driver)
#   0002  ocp8178 1-wire backlight driver
#   0003  clockworkpi-uconsole-cm5 + clockworkpi-custom-battery overlays
#   0004  AXP228 power: fuel-gauge calibration + V_OFF plumbing
#         (axp20x_battery), VBUS path kick on AC plug events
#         (axp20x_ac_power), CHGLED preserve on power-off (mfd/axp20x)
{
  config,
  lib,
  pkgs,
  nixos-raspberrypi,
  ...
}: let
  cfg = config.uconsole;

  # Same package the raspberry-pi-5.base module installs, with one build
  # fixup: the RPi firmware checks for ${os_prefix}${overlay_prefix}README
  # before using os_prefix for overlay path resolution.  Without this
  # file, the firmware silently ignores all dtoverlay= entries in
  # config.txt.  This also enables the firmware's auto-application of
  # bcm2712d0.dtbo on D0 silicon (CM5), which corrects pinctrl register
  # addresses.  See: raspberrypi/linux#3237,
  # home-assistant/operating-system#3079
  kernelWithOverlayReadme =
    nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.linux_rpi5.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          touch "$out/dtbs/overlays/README"
        '';
    });
in {
  config = lib.mkIf cfg.enable {
    # mkForce over raspberry-pi-5.base's mkDefault of the same kernel
    boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor kernelWithOverlayReadme);

    boot.kernelPatches = [
      {
        name = "clockworkpi-panel-cwu50";
        patch = ./patches/0001-drm-panel-add-clockworkpi-cwu50.patch;
        structuredExtraConfig = with lib.kernel; {
          DRM_PANEL_CWU50 = module;
        };
      }
      {
        name = "clockworkpi-backlight-ocp8178";
        patch = ./patches/0002-backlight-add-ocp8178.patch;
        structuredExtraConfig = with lib.kernel; {
          BACKLIGHT_OCP8178 = module;
        };
      }
      {
        name = "clockworkpi-overlays";
        patch = ./patches/0003-overlays-add-clockworkpi-uconsole.patch;
      }
      {
        name = "clockworkpi-axp228-power";
        patch = ./patches/0004-power-axp20x-clockworkpi-uconsole.patch;
        # AXP228 PMIC stack (mirrors the fork's bcm2712_defconfig
        # additions): mfd + regulators built in so display/wifi rails
        # come up with the driver core; leaf drivers as modules.
        structuredExtraConfig = with lib.kernel; {
          MFD_AXP20X_I2C = yes;
          REGULATOR_AXP20X = yes;
          INPUT_AXP20X_PEK = yes;
          AXP20X_POWER = module;
          CHARGER_AXP20X = module;
          BATTERY_AXP20X = module;
          AXP20X_ADC = module;
        };
      }
    ];
  };
}
