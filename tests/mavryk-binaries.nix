# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

{ nixpkgs, pkgs, ... }:
{ path-to-binaries }@args:
let
in import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }: {
  name = "mavryk-binaries-test";
  nodes.machine = { ... }: {
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 1024;
    environment.sessionVariables.XDG_DATA_DIRS = [ "${pkgs.zcash-params}" ];
    security.pki.certificateFiles = [ ./ca.cert ];
  };

  testScript = ''
    path_to_binaries = "${path-to-binaries}"
    mavkit_accuser = f"{path_to_binaries}/mavkit-accuser-PtBoreas"
    mavkit_admin_client = f"{path_to_binaries}/mavkit-admin-client"
    mavkit_baker = f"{path_to_binaries}/mavkit-baker-PtBoreas"
    mavkit_client = f"{path_to_binaries}/mavkit-client"
    mavkit_node = f"{path_to_binaries}/mavkit-node"
    mavkit_signer = f"{path_to_binaries}/mavkit-signer"
    mavkit_codec = f"{path_to_binaries}/mavkit-codec"
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
}) args
