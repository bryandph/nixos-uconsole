# Speaker/headphone GPIO auto-switch for uConsole
# GPIO 10 = headphone detect (input): 0 = no headphone, 1 = headphone inserted
# GPIO 11 = speaker amplifier enable (output): 1 = on, 0 = off
# Reimplements clockworkpi-audio-patch.service from Debian using libgpiod
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.uconsole;

  uconsole-audio-switch = pkgs.writeShellApplication {
    name = "uconsole-audio-switch";
    runtimeInputs = with pkgs; [
      libgpiod
      coreutils
    ];
    text = ''
      CHIP="gpiochip4"
      HP_GPIO=10
      SPK_GPIO=11

      echo "uconsole-audio: starting speaker/headphone switch"

      while true; do
        val=$(gpioget --numeric -c "$CHIP" "$HP_GPIO")
        if [ "$val" = "0" ]; then
          gpioset -c "$CHIP" "$SPK_GPIO"=1  # no headphone — speaker on
        else
          gpioset -c "$CHIP" "$SPK_GPIO"=0  # headphone inserted — speaker off
        fi
        sleep 1
      done
    '';
  };
in {
  options.uconsole.audioSwitch.enable = lib.mkOption {
    type = lib.types.bool;
    default = cfg.enable;
    defaultText = lib.literalExpression "config.uconsole.enable";
    description = "Enable automatic speaker/headphone switching via GPIO.";
  };

  config = lib.mkIf (cfg.enable && cfg.audioSwitch.enable) {
    systemd.services.uconsole-audio-switch = {
      description = "uConsole speaker/headphone auto-switch via GPIO";
      after = ["systemd-modules-load.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${uconsole-audio-switch}/bin/uconsole-audio-switch";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
