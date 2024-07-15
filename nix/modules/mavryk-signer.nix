# SPDX-FileCopyrightText: 2021 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

{config, lib, pkgs, ...}:

with lib;

let
  mavkit-signer-launch = "${pkgs.mavkitPackages.mavkit-signer}/bin/mavkit-signer launch";
  common = import ./common.nix { inherit lib; inherit pkgs; };
  cfg = config.services.mavkit-signer;
  instanceOptions = types.submodule ( {...} : {
    options = common.sharedOptions // {

      enable = mkEnableOption "Mavkit signer service";

      networkProtocol = mkOption {
        type = types.enum [ "http" "https" "tcp" "unix" ];
        description = ''
          Network protocol version. Supports http, https, tcp and unix.
        '';
        example = "http";
      };

      netAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "127.0.0.1";
        description = ''
          Mavkit signer net address.
        '';
      };

      netPort = mkOption {
        type = types.int;
        default = 8080;
        example = 8080;
        description = ''
          Mavkit signer net port.
        '';
      };

      certPath = mkOption {
        type = types.str;
        default = null;
        description = ''
          Path of the SSL certificate to use for https Mavkit signer.
        '';
      };

      keyPath = mkOption {
        type = types.str;
        default = null;
        description = ''
          Key path to use for https Mavkit signer.
        '';
      };

      unixSocket = mkOption {
        type = types.str;
        default = null;
        description = ''
          Socket to use for Mavkit signer running over UNIX socket.
        '';
      };

      timeout = mkOption {
        type = types.int;
        default = 1;
        example = 1;
        description = ''
          Timeout for Mavkit signer.
        '';
      };

    };
  });
in {
  options.services.mavkit-signer = {
    instances = mkOption {
      type = types.attrsOf instanceOptions;
      description = "Configuration options";
      default = {};
    };
  };
  config = mkIf (cfg.instances != {}) {
    users = mkMerge (flip mapAttrsToList cfg.instances (node-name: node-cfg: common.genUsers node-name ));
    systemd = mkMerge (flip mapAttrsToList cfg.instances (node-name: node-cfg:
      let mavkit-signers = {
        "http" =
          "${mavkit-signer-launch} http signer --address ${node-cfg.netAddress} --port ${toString node-cfg.netPort}";
        "https" =
          "${mavkit-signer-launch} https signer ${node-cfg.certPath} ${node-cfg.keyPath} --address ${node-cfg.netAddress} --port ${toString node-cfg.netPort}";
        "tcp" =
          "${mavkit-signer-launch} socket signer --address ${node-cfg.netAddress} --port ${toString node-cfg.netPort} --timeout ${toString node-cfg.timeout}";
        "unix" =
          "${mavkit-signer-launch} local signer --socket ${node-cfg.unixSocket}";
      };
      in {
      services."mavryk-${node-name}-mavkit-signer" = common.genSystemdService node-name node-cfg "signer" // {
        after = [ "network.target" ];
        script = ''
          ${mavkit-signers.${node-cfg.networkProtocol}}
        '';
      };
    }));
  };
}
