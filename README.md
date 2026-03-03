# nixos-uconsole

NixOS module for [ClockworkPi uConsole](https://www.clockworkpi.com/uconsole) hardware support with the CM5 (Lite) compute module. Provides the [ak-rex](https://github.com/ak-rex/ClockworkPi-linux) kernel fork (with panel-cwu50 DSI driver, backlight, battery/power drivers, and device tree overlays), RPi firmware configuration, and automatic speaker/headphone GPIO switching.

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
        { uconsole.enable = true; }

        # Your host config...
      ];
    };
  };
}
```

## Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `uconsole.enable` | bool | `false` | Enable uConsole hardware support |
| `uconsole.kernel.src` | package | ak-rex pinned commit | Kernel source derivation |
| `uconsole.kernel.version` | string | `"6.12.67"` | Kernel version string |
| `uconsole.audioSwitch.enable` | bool | `uconsole.enable` | Automatic speaker/headphone GPIO switching |

## What's Included

- **Kernel** — ak-rex fork of `raspberrypi/linux` (`rpi-6.12.y` branch) with uConsole drivers: `panel-cwu50` (DSI display), `ocp8178_bl` (backlight), `clockworkpi-uconsole-cm5.dtbo`, `clockworkpi-custom-battery.dtbo`, and `axp20x` battery/power drivers.
- **Firmware config** — RPi `config.txt` entries for the uConsole display, audio remap, and CM5 device tree overlay.
- **Audio switch** — systemd service that polls GPIO to automatically toggle the speaker amplifier when headphones are inserted/removed.
- **Boot defaults** — Console on `tty1`, framebuffer rotation for the portrait-mounted display, I2C enabled, ZFS disabled, SD card root filesystem.

## What's NOT Included

This module provides **base uConsole hardware support only**. You'll need to add your own configuration for:

- HackerGadgets AIO board (GPS/GPSD, RTL-SDR, LoRa, RTC)
- WiFi/Bluetooth pairing
- Desktop environment (Hyprland, etc.)
- Disk layout (disko)
- User accounts and personal config

## Hardware Compatibility

- **Tested:** CM5 Lite (BCM2712 D0 silicon)
- **Kernel:** Requires the [ak-rex ClockworkPi-linux](https://github.com/ak-rex/ClockworkPi-linux) fork — mainline and stock RPi kernels lack uConsole drivers
- **Boot:** Designed for use with [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) boot infrastructure

## Upstream References

- [ak-rex/ClockworkPi-linux](https://github.com/ak-rex/ClockworkPi-linux) — kernel fork with uConsole drivers
- [clockworkpi/uConsole](https://github.com/clockworkpi/uConsole) — official hardware repo
- [nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) — NixOS RPi boot infrastructure

## License

MIT
