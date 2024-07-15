# SPDX-FileCopyrightText: 2022 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

{
  description = "The mavryk-packaging flake";

  nixConfig.flake-registry = "https://github.com/serokell/flake-registry/raw/master/flake-registry.json";

  inputs = {

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs.url = "github:serokell/nixpkgs";

    nix.url = "github:nixos/nix";

    opam-nix.url = "github:tweag/opam-nix";

    flake-compat.flake = false;

    opam-repository.url = "github:ocaml/opam-repository";
    opam-repository.flake = false;

    mavryk.url = "gitlab:mavryk-network/mavryk-protocol";
    mavryk.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-utils, serokell-nix, nix, ... }:
  let
    pkgs-darwin = nixpkgs-unstable.legacyPackages."aarch64-darwin";
    protocols = nixpkgs.lib.importJSON ./protocols.json;
    meta = nixpkgs.lib.importJSON ./meta.json;

    mavryk = builtins.path {
      path = inputs.mavryk;
      name = "mavryk";
      # we exclude optional development packages
      filter = path: _: !(builtins.elem (baseNameOf path) [ "mavkit-dev-deps.opam" "mavryk-time-measurement.opam" ]);
    };
    sources = { inherit mavryk; inherit (inputs) opam-repository; };

    ocaml-overlay = import ./nix/build/ocaml-overlay.nix (inputs // { inherit sources protocols meta; });
  in pkgs-darwin.lib.recursiveUpdate
  {
      nixosModules = {
        mavryk-node = import ./nix/modules/mavryk-node.nix;
        mavryk-accuser = import ./nix/modules/mavryk-accuser.nix;
        mavryk-baker = import ./nix/modules/mavryk-baker.nix;
        mavryk-signer = import ./nix/modules/mavryk-signer.nix;
      };

      devShells."aarch64-darwin".autorelease-macos =
        import ./scripts/macos-shell.nix { pkgs = pkgs-darwin; };

      overlays.default = final: prev: nixpkgs.lib.composeManyExtensions [
        ocaml-overlay
        (final: prev: { inherit (inputs) serokell-nix; })
      ] final prev;
  } (flake-utils.lib.eachSystem [
      "x86_64-linux"
    ] (system:
    let

      overlay = final: prev: {
        inherit (inputs) serokell-nix;
        nix = nix.packages.${system}.default;
        zcash-params = callPackage ./nix/build/zcash.nix {};
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          overlay
          serokell-nix.overlay
          ocaml-overlay
        ];
      };

      unstable = import nixpkgs-unstable {
        inherit system;
        overlays = [(_: _: { nix = nix.packages.${system}.default; })];
      };

      callPackage = pkg: input:
        import pkg (inputs // { inherit sources protocols meta pkgs; } // input);

      inherit (callPackage ./nix {}) mavkit-binaries mavryk-binaries;

      release = callPackage ./release.nix {};

    in {

      legacyPackages = unstable;

      inherit release;

      packages = mavkit-binaries // mavryk-binaries
        // { default = pkgs.linkFarmFromDrvs "binaries" (builtins.attrValues mavkit-binaries); };

      devShells = {
        buildkite = callPackage ./.buildkite/shell.nix {};
        autorelease = callPackage ./scripts/shell.nix {};
        docker-mavryk-packages = callPackage ./shell.nix {};
      };

      checks = {
        mavryk-nix-binaries = callPackage ./tests/mavryk-nix-binaries.nix {};
        mavryk-modules = callPackage ./tests/mavryk-modules.nix {};
      };

      binaries-test = callPackage ./tests/mavryk-binaries.nix {};
    }));
}
