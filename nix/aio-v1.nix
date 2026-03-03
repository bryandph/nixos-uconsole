# HackerGadgets AIO v1 extension board — GPS, RTL-SDR, LoRa, RTC
# https://wiki.clockworkpi.com/uconsole/extension-board
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.uconsole.aio.v1;
in {
  options.uconsole.aio.v1 = {
    enable = lib.mkEnableOption "HackerGadgets AIO v1 extension board";

    gps.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = "GPS receiver on ttyAMA0 with PPS on GPIO6";
    };

    rtlsdr.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = "RTL-SDR (RTL2832U + R860) USB dongle support";
    };

    lora.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = "SX1262 LoRa transceiver on SPI1";
    };

    rtc.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      description = "PCF85063A real-time clock on I2C";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── Firmware overlays ([pi5] section) ────────────────────────────
    # Each component adds its DT overlays conditionally.
    # boot.kernelParams in default.nix uses mkForce to prevent
    # sd-image's console=ttyAMA0 from corrupting GPS NMEA data.
    hardware.raspberry-pi.extra-config = lib.concatStrings [
      (lib.optionalString cfg.gps.enable ''
        [pi5]
        dtparam=uart0
        dtoverlay=pps-gpio,gpiopin=6
      '')
      (lib.optionalString cfg.lora.enable ''
        [pi5]
        dtoverlay=spi1-1cs
      '')
      (lib.optionalString cfg.rtc.enable ''
        [pi5]
        dtoverlay=i2c-rtc,pcf85063a,i2c_csi_dsi0
      '')
    ];

    # ── GPS + RTL-SDR services ───────────────────────────────────────
    # UART0 (ttyAMA0) carries NMEA data; PPS on GPIO6 for time sync.
    # RTL-SDR udev rules loaded from package; mkDefault lets the radio
    # module take precedence if both are enabled.
    services = {
      gpsd = lib.mkIf cfg.gps.enable {
        enable = true;
        devices = ["/dev/ttyAMA0"];
        listenany = true;
        nowait = true;
      };
      udev = {
        extraRules = lib.mkIf cfg.gps.enable ''
          KERNEL=="ttyAMA0", SYMLINK+="gps0", MODE="0666"
          KERNEL=="pps0", SYMLINK+="gpspps0", MODE="0666"
        '';
        packages =
          lib.mkIf cfg.rtlsdr.enable (lib.mkDefault [pkgs.rtl-sdr]);
      };
    };

    # ── RTL-SDR kernel blacklist ─────────────────────────────────────
    # Blacklist DVB driver so the userspace rtl-sdr driver can claim
    # the device. mkDefault lets the radio module take precedence if
    # both are enabled (radio module may blacklist additional modules).
    boot.blacklistedKernelModules =
      lib.mkIf cfg.rtlsdr.enable (lib.mkDefault ["dvb_usb_rtl28xxu"]);

    # ── Packages ──────────────────────────────────────────────────────
    environment.systemPackages =
      [pkgs.libgpiod]
      ++ lib.optionals cfg.gps.enable [pkgs.pps-tools pkgs.gpsd]
      ++ lib.optionals cfg.rtlsdr.enable [pkgs.rtl-sdr]
      ++ lib.optionals cfg.rtc.enable [pkgs.i2c-tools];
  };
}
