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

    rust-overlay.url = "github:oxalica/rust-overlay";

    crane.url = "github:ipetkov/crane";

    flake-compat.flake = false;

    opam-repository.url = "github:ocaml/opam-repository";
    opam-repository.flake = false;

    mavryk.url = "gitlab:mavryk-network/mavryk-protocol";
    mavryk.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-utils, serokell-nix, nix, rust-overlay, crane, ... }:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    pkgs-unstable = import nixpkgs-unstable { system = "x86_64-linux"; overlays = [ rust-overlay.overlays.default ]; };
    pkgs-darwin = nixpkgs-unstable.legacyPackages."aarch64-darwin";
    protocols = nixpkgs.lib.importJSON ./protocols.json;
    meta = nixpkgs.lib.importJSON ./meta.json;

    mavryk = builtins.path {
      path = inputs.mavryk;
      name = "mavryk";
      # we exclude optional development packages
      filter = path: _: !(builtins.elem (baseNameOf path) [ "mavkit-dev-deps.opam" "mavryk-time-measurement.opam" ]);
    };

    toolchain-version = pkgs-unstable.lib.strings.trim (builtins.readFile "${mavryk}/rust-toolchain");

    rust-toolchain = pkgs-unstable.rust-bin.stable.${toolchain-version}.default;

    craneLib = (crane.mkLib pkgs-unstable).overrideToolchain (p: p.rust-bin.stable.${toolchain-version}.default);

    opam-repository = pkgs.stdenv.mkDerivation {
      name = "opam-repository";
      src = inputs.opam-repository;
      phases = [ "unpackPhase" "patchPhase" "installPhase" ];
      patchPhase = ''
        mkdir -p packages/mavkit-deps/mavkit-deps.dev
        cp ${mavryk}/opam/virtual/mavkit-deps.opam.locked packages/mavkit-deps/mavkit-deps.dev/opam

        # This package adds some constraints to the solution found by the opam solver.
        dummy_pkg=mavkit-dummy
        dummy_opam_dir="packages/$dummy_pkg/$dummy_pkg.dev"
        dummy_opam="$dummy_opam_dir/opam"
        mkdir -p "$dummy_opam_dir"
        echo 'opam-version: "2.0"' > "$dummy_opam"
        echo "depends: [ \"ocaml\" { = \"$ocaml_version\" } ]" >> "$dummy_opam"
        echo 'conflicts:[' >> "$dummy_opam"
        grep -r "^flags: *\[ *avoid-version *\]" -l packages |
          LC_COLLATE=C sort -u |
          while read -r f; do
            f=$(dirname "$f")
            f=$(basename "$f")
            p=$(echo "$f" | cut -d '.' -f '1')
            v=$(echo "$f" | cut -d '.' -f '2-')
            echo "\"$p\" {= \"$v\"}" >> $dummy_opam
          done
        # FIXME: https://gitlab.com/tezos/tezos/-/issues/5832
        # opam unintentionally picks up a windows dependency. We add a
        # conflict here to work around it.
        echo '"ocamlbuild" {= "0.14.2+win" }' >> $dummy_opam
        echo ']' >> "$dummy_opam"

        OPAMSOLVERTIMEOUT=600 ${pkgs.opam}/bin/opam admin filter --yes --resolve \
          "mavkit-deps,ocaml,ocaml-base-compiler,odoc<2.3.0,ledgerwallet-tezos,caqti-driver-postgresql,$dummy_pkg" \
          --environment "os=linux,arch=x86_64,os-family=debian"

        rm -rf packages/"$dummy_pkg" packages/mavkit-deps
      '';

      installPhase = ''
        mkdir -p $out
        cp -Lpr * $out
      '';
    };

    sources = { inherit mavryk opam-repository; };

    ocaml-overlay = import ./nix/build/ocaml-overlay.nix (inputs // { inherit sources protocols meta craneLib rust-toolchain; });
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
