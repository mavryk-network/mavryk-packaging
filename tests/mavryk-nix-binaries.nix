# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA
{ nixpkgs, pkgs, ... }:
let
  inherit (pkgs) system;
  inherit (pkgs.mavkitPackages)
    mavkit-client mavkit-admin-client mavkit-node mavkit-signer mavkit-codec
    mavkit-accuser-PtBoreas mavkit-baker-PtBoreas;
in import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }: {
  name = "mavryk-nix-binaries-test";
  nodes.machine = { ... }: {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 1024;
    environment.systemPackages = with pkgs; [ libev ];
    security.pki.certificateFiles = [ ./ca.cert ];
    environment.sessionVariables.LD_LIBRARY_PATH = [
      "${pkgs.ocamlPackages.hacl-star-raw}/lib/ocaml/4.12.0/site-lib/hacl-star-raw"
    ];
  };

  testScript = ''
    mavkit_accuser = "${mavkit-accuser-PtBoreas}/bin/mavkit-accuser-PtBoreas"
    mavkit_admin_client = "${mavkit-admin-client}/bin/mavkit-admin-client"
    mavkit_baker = "${mavkit-baker-PtBoreas}/bin/mavkit-baker-PtBoreas"
    mavkit_client = (
        "${mavkit-client}/bin/mavkit-client"
    )
    mavkit_node = "${mavkit-node}/bin/mavkit-node"
    mavkit_signer = (
        "${mavkit-signer}/bin/mavkit-signer"
    )
    mavkit_codec = "${mavkit-codec}/bin/mavkit-codec"
    openssl = "${pkgs.openssl.bin}/bin/openssl"
    host_key = "${./host.key}"
    host_cert = "${./host.cert}"
    binaries = [
        mavkit_accuser,
        mavkit_admin_client,
        mavkit_baker,
        mavkit_client,
        mavkit_node,
        mavkit_signer,
        mavkit_codec,
    ]
    ${builtins.readFile ./test_script.py}'';
}) { inherit pkgs system; }
