# SPDX-FileCopyrightText: 2021-2022 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

{ sources, protocols, opam-nix, ... }:

self: super:
let
  pkgs = super;
in
with opam-nix.lib.${self.system}; let
  zcash-overlay = import ./zcash-overlay.nix;
  hacks = import ./hacks.nix;
  mavkitSourcesResolved =
    self.runCommand "resolve-mavkit-sources" {} ''
      cp --no-preserve=all -Lr ${sources.mavryk} $out
    '';
  mavkitScope = buildOpamProject' {
    repos = with sources; [opam-repository];
    recursive = true;
    resolveArgs = { };
  } mavkitSourcesResolved { };
in {
  mavkitPackages = (mavkitScope.overrideScope' (pkgs.lib.composeManyExtensions [
      (_: # Nullify all the ignored protocols so that we don't build them
        builtins.mapAttrs (name: pkg:
          if builtins.any
          (proto: !isNull (builtins.match ".*${proto}.*" name))
          protocols.ignored then
            null
          else
            pkg))
      hacks
      zcash-overlay
      (final: prev: {
        mavryk-rust-libs = prev.mavryk-rust-libs.overrideAttrs (drv: {
          postInstall =
            drv.postInstall + (let
              rust-types-h = pkgs.fetchurl {
                url = "https://gitlab.com/mavryk-network/mavryk-protocol-rust-libs/-/raw/v1.4/librustzcash/include/rust/types.h";
                sha256 = "sha256-Q2lEV7JfPpFwfS/fcV7HDbBUSIGovasr7/bcANRuMZA=";
              };
            in ''
              mkdir -p $out/include/rust
              cp ${rust-types-h} $out/include/rust/types.h
            '');
        });
      })
    ]));
}
