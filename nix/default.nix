# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

{ sources, pkgs, protocols, patches ? [ ], ... }:
let
  source = sources.mavryk;
  release-binaries = import ./build/release-binaries.nix protocols;
in {
  mavkit-binaries = builtins.listToAttrs (map (meta: {
    inherit (meta) name;
    value = pkgs.mavkitPackages.${meta.name} // { inherit meta; };
  }) release-binaries);

  mavryk-binaries = builtins.listToAttrs (map (meta:
    let
      newMeta = meta // { name = builtins.replaceStrings [ "mavkit" ] [ "mavryk" ] meta.name; };
    in {
      inherit (newMeta) name;
      value = { inherit newMeta; } // (pkgs.mavkitPackages.${meta.name}.overrideAttrs (pkg: {
        inherit (newMeta) name;
        postInstall = ''
          ln -s $out/bin/${meta.name} $out/bin/${newMeta.name}
        '';
    }));
  }) release-binaries);
}
