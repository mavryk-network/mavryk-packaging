# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykNodeMainnet < Formula
  url "file:///dev/null"
  version "v20.1-2"

  depends_on "mavryk-node"

  desc "Meta formula that provides background mavryk-node service that runs on mainnet"

  def install
    startup_contents =
      <<~EOS
      #!/usr/bin/env bash

      set -euo pipefail

      node="/usr/local/bin/mavkit-node"
      # default location of the config file
      config_file="$MAVRYK_CLIENT_DIR/config.json"

      mkdir -p "$MAVRYK_CLIENT_DIR"
      if [[ ! -f "$config_file" ]]; then
          echo "Configuring the node..."
          "$node" config init \
                  --rpc-addr "$NODE_RPC_ADDR" \
                  --network=mainnet \
                  "$@"
      else
          echo "Updating the node configuration..."
          "$node" config update \
                  --rpc-addr "$NODE_RPC_ADDR" \
                  --network=mainnet \
                  "$@"
      fi

      # Launching the node
      if [[ -z "$CERT_PATH" || -z "$KEY_PATH" ]]; then
          exec "$node" run --config-file="$config_file"
      else
          exec "$node" run --config-file="$config_file" \
              --rpc-tls="$CERT_PATH","$KEY_PATH"
      fi
    EOS
    File.write("mavryk-node-mainnet-start", startup_contents)
    bin.install "mavryk-node-mainnet-start"
    print "Installing mavryk-node-mainnet service"
  end

  service do
    run opt_bin/"mavryk-node-mainnet-start"
    require_root true
    environment_variables MAVRYK_CLIENT_DIR: var/"lib/mavryk/client", NODE_RPC_ADDR: "127.0.0.1:8732", CERT_PATH: "", KEY_PATH: ""
    keep_alive true
    log_path var/"log/mavryk-node-mainnet.log"
    error_log_path var/"log/mavryk-node-mainnet.log"
  end

  def post_install
    mkdir_p "#{var}/lib/mavryk/node-mainnet"
    system "mavkit-node", "config", "init", "--data-dir" "#{var}/lib/mavryk/node-mainnet", "--network", "mainnet"
  end
end
