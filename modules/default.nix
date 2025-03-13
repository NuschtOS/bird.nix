{ config, lib, pkgs, ... }:
let
  bird = if lib.versionAtLeast lib.version "24.11" then "bird" else "bird2";
  cfg = config.services.${bird};
in
{
  options.services.${bird} = {
    # we do not wan't merged config's to result in multiple routerId's
    routerId = lib.mkOption {
      type = lib.types.str;
      description = "The router ID is a world-wide unique identification of your router, usually one of router's IPv4 addresses.";
    };

    # networking.domain has no default value...
    #hostName = lib.mkOption {
    #  type = lib.types.str;
    #  default = "${config.networking.hostName}.${config.networking.domain}";
    #};
  } // (
    let
      option = lib.mkOption {
        type = with lib.types; attrsOf lines;
        default = { };
      };
      options = {
        # List of all protocols: https://bird.network.cz/?get_doc&v=20&f=bird-6.html
        aggregator = option;
        babel = option;
        bfd = option;
        bgp = option;
        bmp = option;
        device = option;
        direct = option;
        kernel = option;
        l3vpn = option;
        mrt = option;
        perf = option;
        pipe = option;
        radv = option;
        rip = option;
        rpki = option;
        static = option;
      };
    in
    {
      templates = options;
      protocols = options // {
        # ospf does not support templates
        ospfv2 = option;
        ospfv3 = option;
      };
    }
  );

  config = lib.mkIf cfg.enable {
    services.${bird} = {
      config =
        let
          mkTemplate = { name, type, conf }: ''
            template ${type} ${name} {
              ${conf}
            }
          '';

          mkTemplates = templates: lib.flatten (lib.mapAttrsToList
            (type: entries:
              lib.mapAttrsToList
                (name: conf: mkTemplate { inherit name type conf; })
                entries)
            templates);

          mkProtocol = { name, type, conf }: ''
            protocol ${if type == "ospfv2" then "ospf v2" else if type == "ospfv3" then "ospf v3" else type} ${name} {
              ${conf}
            }
          '';

          mkProtocols = protocols: lib.flatten (lib.mapAttrsToList
            (type: entries:
              lib.mapAttrsToList
                (name: conf: mkProtocol { inherit name type conf; })
                entries)
            protocols);
        in
        #hostname ${cfg.hostName};
        ''
          router id ${cfg.routerId};

          ${builtins.concatStringsSep "\n" (mkTemplates cfg.templates)}
          ${builtins.concatStringsSep "\n" (mkProtocols cfg.protocols)}
        '';

      # not bird3 compatible, yet
      package = pkgs.bird2;
    };
  };
}
