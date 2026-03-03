# RPi firmware config.txt for uConsole CM5
# Configures DSI display, audio remap, and device tree overlays.
# AIO board overlays are conditionally added by aio-v1.nix.
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.uconsole.enable {
    # ── [all] section (structured config) ──────────────────────────────
    hardware.raspberry-pi.config.all = {
      options = {
        ignore_lcd = {
          enable = true;
          value = 1;
        };
        max_framebuffers = {
          enable = true;
          value = 2;
        };
        disable_overscan = {
          enable = true;
          value = 1;
        };
        # Disable auto-detect — uConsole has a custom DSI panel (panel-cwu50)
        # and no camera; probing for standard displays/cameras is unnecessary
        camera_auto_detect = {
          enable = true;
          value = 0;
        };
        display_auto_detect = {
          enable = true;
          value = 0;
        };
      };
      base-dt-params = {
        audio = {
          enable = true;
          value = "on";
        };
        ant2 = {
          enable = true;
        };
      };
      dt-overlays = {
        # Disable the Pi 4 vc4-kms-v3d overlay — incompatible with BCM2712.
        # On CM5, [all] and [pi5] both apply; we use vc4-kms-v3d-pi5 in [pi5].
        # Loading the Pi 4 version corrupts pinctrl register mappings on D0 silicon.
        vc4-kms-v3d.enable = false;
        audremap = {
          enable = true;
          params.pins_12_13 = {
            enable = true;
          };
        };
        # dwc2 is already added in [cm5] by nixos-raspberrypi — do not duplicate
        # in [all], as both sections apply on CM5 hardware.
      };
    };

    # ── [pi5] section (raw extra-config) ───────────────────────────────
    # Conditional sections are not supported by the structured config module.
    hardware.raspberry-pi.extra-config = ''
      [pi5]
      dtoverlay=clockworkpi-uconsole-cm5
      dtoverlay=vc4-kms-v3d-pi5,cma-384
      dtparam=pciex1
    '';
  };
}
