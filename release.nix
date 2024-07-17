# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ

{ pkgs, sources, meta, protocols, ... }: { docker-binaries, docker-arm-binaries }:
let
  source = sources.mavryk;
  commonMeta = {
    version = with pkgs.lib.strings; removePrefix "v" (removePrefix "refs/tags/" meta.mavryk_ref);
    license = "MIT";
    dependencies = "";
    branchName = meta.mavryk_ref;
    licenseFile = "${source}/LICENSES/MIT.txt";
  } // meta;
  release = pkgs.callPackage ./mavryk-release.nix {
    binaries = docker-binaries;
    arm-binaries = docker-arm-binaries;
    inherit commonMeta protocols; inherit (pkgs.lib) replaceStrings;
  };

in release
