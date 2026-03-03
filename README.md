# nixos-uconsole

NixOS module for [ClockworkPi uConsole](https://www.clockworkpi.com/uconsole) hardware support with the CM5 (Lite) compute module. Provides the [ak-rex](https://github.com/ak-rex/ClockworkPi-linux) kernel fork (with panel-cwu50 DSI driver, backlight, battery/power drivers, and device tree overlays), RPi firmware configuration, automatic speaker/headphone GPIO switching, and optional [HackerGadgets](https://hackergadgets.com/) expansion board support (AIO v1, NVMe).

## Quick Start

> This module extends [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi), which provides the RPi 5 / CM5 boot infrastructure (firmware, config.txt generation, SD image).

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-uconsole = {
      url = "github:bryandph/nixos-uconsole";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixos-raspberrypi.follows = "nixos-raspberrypi";
      };
    };
  };

  outputs = { nixpkgs, nixos-raspberrypi, nixos-uconsole, ... }: {
    nixosConfigurations.uconsole = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        # nixos-raspberrypi base modules
        nixos-raspberrypi.lib.inject-overlays
        nixos-raspberrypi.nixosModules.raspberry-pi-5.base
        nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
        nixos-raspberrypi.nixosModules.raspberry-pi-5.bluetooth
        nixos-raspberrypi.nixosModules.sd-image

        # uConsole hardware support
        nixos-uconsole.nixosModules.uconsole
        {
          uconsole.enable = true;
          uconsole.aio.v1.enable = true; # if you have the AIO board
          uconsole.nvme.enable = true;   # if you have the NVMe adapter
        }

        # Your host config...
      ];
    };
  };
}
```

## Module Options

### Base

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `uconsole.enable` | bool | `false` | Enable uConsole hardware support |
| `uconsole.kernel.src` | package | ak-rex pinned commit | Kernel source derivation |
| `uconsole.kernel.version` | string | `"6.12.67"` | Kernel version string |
| `uconsole.audioSwitch.enable` | bool | `uconsole.enable` | Automatic speaker/headphone GPIO switching |

### AIO v1 Board

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `uconsole.aio.v1.enable` | bool | `false` | Enable HackerGadgets AIO v1 extension board |
| `uconsole.aio.v1.gps.enable` | bool | `aio.v1.enable` | GPS receiver on ttyAMA0 with PPS on GPIO6 |
| `uconsole.aio.v1.rtlsdr.enable` | bool | `aio.v1.enable` | RTL-SDR (RTL2832U + R860) USB dongle support |
| `uconsole.aio.v1.lora.enable` | bool | `aio.v1.enable` | SX1262 LoRa transceiver on SPI1 |
| `uconsole.aio.v1.rtc.enable` | bool | `aio.v1.enable` | PCF85063A real-time clock on I2C |

### NVMe Adapter

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `uconsole.nvme.enable` | bool | `false` | Enable PCIe x1 for HackerGadgets NVMe adapter + battery board |

## What's Included

- **Kernel** — ak-rex fork of `raspberrypi/linux` (`rpi-6.12.y` branch) with uConsole drivers: `panel-cwu50` (DSI display), `ocp8178_bl` (backlight), `clockworkpi-uconsole-cm5.dtbo`, `clockworkpi-custom-battery.dtbo`, and `axp20x` battery/power drivers.
- **Firmware config** — RPi `config.txt` entries for the uConsole display, audio remap, and CM5 device tree overlay.
- **Audio switch** — systemd service that polls GPIO to automatically toggle the speaker amplifier when headphones are inserted/removed.
- **Boot defaults** — Console on `tty1`, framebuffer rotation for the portrait-mounted display, I2C enabled, ZFS disabled, SD card root filesystem.
- **AIO v1 board** (optional) — GPS/GPSD with PPS, RTL-SDR with udev rules, LoRa SPI overlay, RTC with I2C overlay, and shared GPIO tools. Each component can be individually enabled/disabled.
- **NVMe adapter** (optional) — Enables PCIe x1 (`dtparam=pciex1`) for the [NVMe battery board](https://hackergadgets.com/products/nvme) connected through the [adapter board](https://hackergadgets.com/products/pre-order-adapter-board-for-uconsole-ugrade-kit). Disk layout (disko, etc.) is your responsibility.

## What's NOT Included

This module provides **uConsole hardware support only**. You'll need to add your own configuration for:

- WiFi/Bluetooth pairing
- Desktop environment (Hyprland, etc.)
- Disk layout (disko)
- User accounts and personal config
- Meshtastic/LoRa daemon configuration (the AIO module enables the SPI hardware only)

## Kernel Params and Serial Console

This module uses `lib.mkForce` on `boot.kernelParams` to set `console=tty1`. The uConsole has no serial debug header, and `nixos-raspberrypi`'s sd-image module adds `console=ttyAMA0` which would corrupt GPS NMEA data on the AIO board.

To add extra kernel params in your host config, also use `lib.mkForce` — NixOS merges all list definitions at the same priority:

```nix
boot.kernelParams = lib.mkForce [ "cfg80211.ieee80211_regdom=US" ];
```

## Hardware Compatibility

- **Tested:** CM5 Lite (BCM2712 D0 silicon)
- **Kernel:** Requires the [ak-rex ClockworkPi-linux](https://github.com/ak-rex/ClockworkPi-linux) fork — mainline and stock RPi kernels lack uConsole drivers
- **Boot:** Designed for use with [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) boot infrastructure
- **AIO board:** [HackerGadgets AIO v1](https://wiki.clockworkpi.com/uconsole/extension-board) — GPS, RTL-SDR, LoRa (SX1262), RTC
- **NVMe adapter:** [HackerGadgets NVMe battery board](https://hackergadgets.com/products/nvme) + [adapter board](https://hackergadgets.com/products/pre-order-adapter-board-for-uconsole-ugrade-kit) — M.2 NVMe via CM5 PCIe x1

## Upstream References

- [ak-rex/ClockworkPi-linux](https://github.com/ak-rex/ClockworkPi-linux) — kernel fork with uConsole drivers
- [clockworkpi/uConsole](https://github.com/clockworkpi/uConsole) — official hardware repo
- [nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) — NixOS RPi boot infrastructure
- [HackerGadgets AIO v1](https://wiki.clockworkpi.com/uconsole/extension-board) — extension board wiki
- [HackerGadgets NVMe battery board](https://hackergadgets.com/products/nvme) — NVMe expansion
- [HackerGadgets adapter board](https://hackergadgets.com/products/pre-order-adapter-board-for-uconsole-ugrade-kit) — carrier board PCIe adapter

## License

MIT
