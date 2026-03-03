{
  config,
  lib,
  ...
}: {
  imports = [
    ./kernel.nix
    ./firmware-config.nix
    ./audio-switch.nix
    ./aio-v1.nix
    ./nvme.nix
  ];

  options.uconsole.enable = lib.mkEnableOption "ClockworkPi uConsole hardware support";

  config = lib.mkIf config.uconsole.enable {
    boot = {
      # mkForce: uConsole has no serial debug header, so console=ttyAMA0
      # (added by nixos-raspberrypi sd-image) is never useful and would
      # corrupt GPS NMEA data on the AIO board.  Users can add extra
      # params with lib.mkForce — NixOS merges all same-priority lists.
      kernelParams = lib.mkForce [
        "console=tty1"
        "fbcon=rotate:1" # portrait-mounted DSI display
      ];

      kernelModules = ["i2c-dev"];

      # ZFS not needed on uConsole — avoid heavy build dependency
      supportedFilesystems.zfs = lib.mkForce false;
    };

    # SD card root — override with disko or custom fileSystems as needed
    fileSystems."/" = lib.mkDefault {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

    # I2C for RTC, sensors, etc.
    hardware.i2c.enable = true;
  };
}
