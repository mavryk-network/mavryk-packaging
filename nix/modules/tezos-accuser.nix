# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

{config, lib, pkgs, ...}:

with lib;

let
  mavkit-accuser-pkgs = {
    "PtBoreas" =
      "${pkgs.mavkitPackages.mavkit-accuser-PtBoreas}/bin/mavkit-accuser-PtBoreas";
  };
  cfg = config.services.mavkit-accuser;
  common = import ./common.nix { inherit lib; inherit pkgs; };
  instanceOptions = types.submodule ( {...} : {
    options = common.daemonOptions // {

      enable = mkEnableOption "Mavkit accuser service";

    };
  });

in {
  options.services.mavkit-accuser = {
    instances = mkOption {
      type = types.attrsOf instanceOptions;
      description = "Configuration options";
      default = {};
    };
  };
  config =
    let accuser-start-script = node-cfg: concatMapStringsSep "\n" (baseProtocol:
      ''
        ${mavkit-accuser-pkgs.${baseProtocol}} -d "$STATE_DIRECTORY/client/data" \
        -E "http://localhost:${toString node-cfg.rpcPort}" \
        run "$@" &
      '') node-cfg.baseProtocols;
    in common.genDaemonConfig {
      instancesCfg = cfg.instances;
      service-name = "accuser";
      service-pkgs = mavkit-accuser-pkgs;
      service-start-script = accuser-start-script;
    };
}
