{
  description = "NixOS module for ClockworkPi uConsole (CM5) hardware support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = _: {
    nixosModules = {
      uconsole = import ./nix;
      default = import ./nix;
    };
  };
}
