{
  description = "NixOS module for ClockworkPi uConsole (CM5) hardware support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {nixpkgs, ...}: {
    nixosModules = {
      uconsole = import ./nix;
      default = import ./nix;
    };
  };
}
