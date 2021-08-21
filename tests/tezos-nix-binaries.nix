# SPDX-FileCopyrightText: 2020 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ
let
  nixpkgs = (import ../nix/nix/sources.nix).nixpkgs;
  pkgs = import ../nix/build/pkgs.nix {};
  inherit (pkgs.ocamlPackages) tezos-client tezos-admin-client tezos-node tezos-signer tezos-codec
    tezos-accuser-010-PtGRANAD tezos-baker-010-PtGRANAD tezos-endorser-010-PtGRANAD;
in import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }:
{
  nodes.machine = { ... }: {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 1024;
    environment.systemPackages = with pkgs; [
      libev
    ];
    security.pki.certificateFiles = [ ./ca.cert ];
    environment.sessionVariables.LD_LIBRARY_PATH =
      [ "${pkgs.ocamlPackages.hacl-star-raw}/lib/ocaml/4.10.0/site-lib/hacl-star-raw" ];
  };

  testScript = ''
    tezos_accuser = "${tezos-accuser-010-PtGRANAD}/bin/tezos-accuser-010-PtGRANAD"
    tezos_admin_client = "${tezos-admin-client}/bin/tezos-admin-client"
    tezos_baker = "${tezos-baker-010-PtGRANAD}/bin/tezos-baker-010-PtGRANAD"
    tezos_client = (
        "${tezos-client}/bin/tezos-client"
    )
    tezos_endorser = "${tezos-endorser-010-PtGRANAD}/bin/tezos-endorser-010-PtGRANAD"
    tezos_node = "${tezos-node}/bin/tezos-node"
    tezos_signer = (
        "${tezos-signer}/bin/tezos-signer"
    )
    tezos_codec = "${tezos-codec}/bin/tezos-codec"
    openssl = "${pkgs.openssl.bin}/bin/openssl"
    host_key = "${./host.key}"
    host_cert = "${./host.cert}"
    binaries = [
        tezos_accuser,
        tezos_admin_client,
        tezos_baker,
        tezos_client,
        tezos_endorser,
        tezos_node,
        tezos_signer,
        tezos_codec,
    ]
    ${builtins.readFile ./test_script.py}'';
})
