# Low-battery protection.
#
# The AXP228's hardware cutoff (V_OFF, programmed from the DT battery
# node's voltage-min-design) sits at 2.9 V.  Under load the CM5 browns
# out and wedges before the battery ever sags that far, leaving the
# PMIC with all rails enabled: backlight on, power LED green, and a
# charger that cycles against the wedged load without recovering —
# recoverable only by pulling the batteries.
#
# upowerd performs criticalPowerAction itself (no DE required), so an
# orderly poweroff runs axp20x_power_off(), the PMIC latches cleanly
# off, and charging while powered off works.
{
  config,
  lib,
  ...
}: let
  cfg = config.uconsole;
in {
  options.uconsole.lowBatteryShutdown = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Power off before the battery collapses.  The AXP228 fuel gauge
      only guarantees a clean shutdown path when the kernel initiates
      it; letting the battery run down wedges the PMIC in a state that
      requires physical battery removal.
    '';
  };

  config = lib.mkIf (cfg.enable && cfg.lowBatteryShutdown) {
    services.upower = {
      enable = true;
      usePercentageForPolicy = true;
      percentageLow = 15;
      percentageCritical = 10;
      # Margin above the gauge's jumpy near-empty region; the AXP228
      # percentage register is uncalibrated near 0%.
      percentageAction = 8;
      criticalPowerAction = "PowerOff";
    };
  };
}
