# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA
{ nixpkgs, pkgs, ... }:
let
  inherit (pkgs) system;

  mavkit-node = {
    enable = true;
    additionalOptions = [
      "--bootstrap-threshold=1"
      "--connections" "50"
    ];
  };

  mavkit-signer = {
    enable = true;
    networkProtocol = "http";
  };

  mavkit-accuser = {
    enable = true;
    baseProtocols = ["PtBoreas"];
  };

  mavkit-baker = {
    enable = true;
    baseProtocols = ["PtBoreas"];
    bakerAccountAlias = "baker";
    bakerSecretKey = "unencrypted:edsk3KaTNj1d8Xd3kMBrZkJrfkqsz4XwwiBXatuuVgTdPye2KpE98o";
  };
in
import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }:
{
  name = "mavryk-modules-test";
  machine = { ... }: {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 1024;

    nixpkgs.pkgs = pkgs;
    imports = [ ../nix/modules/mavryk-node.nix
                ../nix/modules/mavryk-signer.nix
                ../nix/modules/mavryk-accuser.nix
                ../nix/modules/mavryk-baker.nix
              ];

    services = {
      mavkit-node.instances.basenet = mavkit-node;
      mavkit-signer.instances.basenet = mavkit-signer;
      mavkit-accuser.instances.basenet = mavkit-accuser;
      mavkit-baker.instances.basenet = mavkit-baker;
    };

  };

  testScript = ''
    from typing import List

    start_all()

    services: List[str] = [
        ${if mavkit-node.enable then ''"mavkit-node",'' else ""}
        ${if mavkit-signer.enable then ''"mavkit-signer",'' else ""}
        ${if mavkit-accuser.enable then ''"mavkit-accuser",'' else ""}
        ${if mavkit-baker.enable then ''"mavkit-baker",'' else ""}
    ]

    for s in services:
        machine.wait_for_unit(f"mavryk-basenet-{s}.service")

    ${if mavkit-node.enable then ''
    with subtest("check mavkit-node rpc response"):
        machine.wait_for_open_port(8732)
        machine.wait_until_succeeds(
            "curl --silent http://localhost:8732/chains/main/blocks/head/header | grep level"
        )
    '' else ""}


    with subtest("service status sanity check"):
        for s in services:
            machine.succeed(f"systemctl status mavryk-basenet-{s}.service")
  '';
}) { inherit pkgs system; }
