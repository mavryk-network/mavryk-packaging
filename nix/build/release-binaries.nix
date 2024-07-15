# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

protocols:
let
  protocolsFormatted =
    builtins.concatStringsSep ", " (protocols.allowed ++ protocols.active);
in [
  {
    name = "mavkit-client";
    description = ''
      CLI client for interacting with mavkit blockchain and a basic wallet.
      For more information see - https://protocol.mavryk.org/introduction/howtouse.html#client
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-dac-client";
    description = "A Data Availability Committee Mavryk client";
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-admin-client";
    description = ''
      CLI administrator tool for peers management
      For more information please check - https://protocol.mavryk.org/user/various.html#mavkit-admin-client
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-node";
    description = ''
      Entry point for initializing, configuring and running a Mavkit node
      For more information please check - https://protocol.mavryk.org/introduction/howtouse.html#node
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-dac-node";
    description =''
      A Data Availability Committee Mavryk node.
      For more info on DAC please check https://research-development.nomadic-labs.com/introducing-data-availability-committees.html
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-dal-node";
    description =''
      A Data Availability Layer Mavryk node.
      For more info on DAL please check https://protocol.mavryk.org/shell/dal_overview.html
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-signer";
    description = ''
      A client to remotely sign operations or blocks.
      For more info please check - https://protocol.mavryk.org/user/key-management.html#signer
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-codec";
    description = ''
      A utility for documenting the data encodings and for performing data encoding/decoding.
      For more info please check - https://protocol.mavryk.org/introduction/howtouse.html#codec
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-smart-rollup-wasm-debugger";
    description = ''
      Debugger for smart rollup kernels
      For more info please check - https://protocol.mavryk.org/active/smart_rollups.html
    '';
    supports = protocolsFormatted;
  }
  {
    name = "mavkit-smart-rollup-node";
    description = ''
      Mavryk smart contract rollup node.
      For more info please check - https://protocol.mavryk.org/active/smart_rollups.html#tools
    '';
    supports = protocolsFormatted;
  }
] ++ builtins.concatMap (protocol: [
  {
    name = "mavkit-baker-${protocol}";
    description = ''
      Daemon for baking for ${protocol} protocol.
      For more info please check - https://protocol.mavryk.org/introduction/howtorun.html#baker
    '';
    supports = protocol;
  }
  {
    name = "mavkit-accuser-${protocol}";
    description = ''
      Daemon for accusing for ${protocol} protocol.
      For more info please check - https://protocol.mavryk.org/introduction/howtorun.html#accuser
    '';
    supports = protocol;
  }
]) protocols.active
