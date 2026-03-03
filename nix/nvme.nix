# HackerGadgets NVMe adapter + battery board — NVMe SSD via CM5 PCIe x1
# https://hackergadgets.com/products/nvme
# https://hackergadgets.com/products/pre-order-adapter-board-for-uconsole-ugrade-kit
{
  config,
  lib,
  ...
}: let
  cfg = config.uconsole.nvme;
in {
  options.uconsole.nvme.enable = lib.mkEnableOption ''
    HackerGadgets NVMe adapter + battery board.
    Enables PCIe x1 for the NVMe M.2 slot on the battery carrier board
  '';

  config = lib.mkIf cfg.enable {
    hardware.raspberry-pi.extra-config = ''
      [pi5]
      dtparam=pciex1
    '';
  };
}
