{ config, lib, ... }:
let
  cfg = config.services.bird2;
in
{
  options.services.bird2 = {
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

    protocols =
      let
        protocolOption = lib.mkOption {
          type = with lib.types; attrsOf lines;
          default = { };
        };
      in
      {
        # List of all protocols: https://bird.network.cz/?get_doc&v=20&f=bird-6.html
        aggregator = protocolOption;
        babel = protocolOption;
        bfd = protocolOption;
        bgp = protocolOption;
        bmp = protocolOption;
        device = protocolOption;
        direct = protocolOption;
        kernel = protocolOption;
        l3vpn = protocolOption;
        mrt = protocolOption;
        ospfv2 = protocolOption;
        ospfv3 = protocolOption;
        perf = protocolOption;
        pipe = protocolOption;
        radv = protocolOption;
        rip = protocolOption;
        rpki = protocolOption;
        static = protocolOption;
      };
  };

  config = lib.mkIf cfg.enable {
    services.bird2 = {
      config =
        let
          protocols = lib.flatten (lib.mapAttrsToList
            (type: entries: lib.mapAttrsToList
              (name: conf: ''
                protocol ${if type == "ospfv2" then "ospf v2" else if type == "ospfv3" then "ospf v3" else type} ${name} {
                  ${conf}
                }
              '')
              entries)
            cfg.protocols);
        in
        #hostname ${cfg.hostName};
        ''
          router id ${cfg.routerId};

          ${builtins.concatStringsSep "\n" protocols}
        '';
    };
  };
}
