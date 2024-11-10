{ config, lib, ... }:
let
  cfg = config.services.bird2;
in
{
  options.services.bird2 = {
    routerId = lib.mkOption {
      type = lib.types.str;
      description = "The router ID is a world-wide unique identification of your router, usually one of router's IPv4 addresses.";
    };

    protocols = lib.mkOption {
      type = with lib.types; attrsOf str;
    };
  };

  config = lib.mkIf cfg.enable {
    services.bird2 = {
      config = ''
        router id ${cfg.routerId};

        ${builtins.concatStringsSep "\n" (builtins.attrValues
          (builtins.mapAttrs
            (name: conf: ''
              protocol ${name} {
                ${conf}
              }
            '') cfg.protocols))}
      '';
    };
  };
}
