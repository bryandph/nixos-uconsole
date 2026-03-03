{
  config,
  lib,
  ...
}: {
  imports = [
    ./kernel.nix
    ./firmware-config.nix
    ./audio-switch.nix
  ];

  options.uconsole.enable = lib.mkEnableOption "ClockworkPi uConsole hardware support";

  config = lib.mkIf config.uconsole.enable {
    boot = {
      kernelParams = lib.mkDefault [
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
