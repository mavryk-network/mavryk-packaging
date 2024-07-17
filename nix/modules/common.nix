# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

{ lib, pkgs, ... }:

with lib;
rec {
  sharedOptions = {

    logVerbosity = mkOption {
      type = types.enum [ "fatal" "error" "warning" "notice" "info" "debug" ];
      default = "warning";
      description = ''
        Level of logs verbosity. Possible values are:
        fatal, error, warn, notice, info or debug.
      '';
    };

  };

  daemonOptions = sharedOptions // {

    baseProtocols = mkOption {
      type = types.listOf (types.enum [ "PtBoreas"]);
      description = ''
        List of protocols for which daemons will be run.
      '';
      example = ["PtBoreas"];
    };

    rpcPort = mkOption {
      type = types.int;
      default = 8732;
      example = 8732;
      description = ''
        Mavkit node RPC port.
      '';
    };

    passwordFilename = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to the file with passwords that can be used to decrypt encrypted keys.
      '';
    };
  };

  genDaemonConfig = { instancesCfg, service-name, service-pkgs, service-start-script, service-prestart-script ? (_: "")}:
    mkIf (instancesCfg != {}) {
      users = mkMerge (flip mapAttrsToList instancesCfg (node-name: node-cfg: genUsers node-name ));
      systemd = mkMerge (flip mapAttrsToList instancesCfg (node-name: node-cfg:
        let mavkit-client = "${pkgs.mavkitPackages.mavkit-client}/bin/mavkit-client";
            passwordFilenameArg = if node-cfg.passwordFilename != null then "-f ${node-cfg.passwordFilename}" else "";
        in {
          services."mavryk-${node-name}-mavkit-${service-name}" = lib.recursiveUpdate (genSystemdService node-name node-cfg service-name) rec {
            bindsTo = [ "network.target" "mavryk-${node-name}-mavkit-node.service" ];
            after = bindsTo;
            path = with pkgs; [ curl ];
            preStart =
              ''
                while ! _="$(curl --silent http://localhost:${toString node-cfg.rpcPort}/chains/main/blocks/head/)"; do
                  echo "Trying to connect to mavkit-node"
                  sleep 1s
                done

                service_data_dir="$STATE_DIRECTORY/client/data"
                mkdir -p "$service_data_dir"

                # Generate or update service config file
                if [[ ! -f "$service_data_dir/config" ]]; then
                  ${mavkit-client} -d "$service_data_dir" -E "http://localhost:${toString node-cfg.rpcPort}" ${passwordFilenameArg} \
                  config init --output "$service_data_dir/config" >/dev/null 2>&1
                else
                  ${mavkit-client} -d "$service_data_dir" -E "http://localhost:${toString node-cfg.rpcPort}" ${passwordFilenameArg} \
                  config update >/dev/null 2>&1
                fi
              '' + service-prestart-script node-cfg;
            script = service-start-script node-cfg;
            serviceConfig = {
              Type = "forking";
            };
          };
      }));
    };

  genUsers = node-name: {
    groups."mavryk-${node-name}" = { };
    users."mavryk-${node-name}" = { group = "mavryk-${node-name}"; isNormalUser = true; };
  };

  genSystemdService = node-name: node-cfg: service-name: {
    inherit (node-cfg) enable;
    wantedBy = [ "multi-user.target" ];
    description = "Mavkit ${service-name}";
    environment = {
      MAVKIT_LOG = "* -> ${node-cfg.logVerbosity}";
    };
    serviceConfig = {
      User = "mavryk-${node-name}";
      Group = "mavryk-${node-name}";
      StateDirectory = "mavryk-${node-name}";
      Restart = "always";
      RestartSec = "10";
    };
  };

}
