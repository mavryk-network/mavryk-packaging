#!/usr/bin/env ruby

# SPDX-FileCopyrightText: 2023 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykSmartRollupNode < Formula
  @all_bins = []

  class << self
    attr_accessor :all_bins
  end
  homepage "https://gitlab.com/mavryk-network/mavryk-protocol"

  url "https://gitlab.com/mavryk-network/mavryk-protocol.git", :tag => "v20.2-rc1-mavryk", :shallow => false

  version "v20.2-rc1"

  build_dependencies = %w[pkg-config coreutils autoconf rsync wget rustup-init cmake opam]
  build_dependencies.each do |dependency|
    depends_on dependency => :build
  end

  dependencies = %w[gmp hidapi libev protobuf sqlite libffi mavryk-sapling-params]
  dependencies.each do |dependency|
    depends_on dependency
  end
  desc "Mavryk smart contract rollup node"

  bottle do
    root_url "https://github.com/mavryk-network/mavryk-packaging/releases/download/#{MavrykSmartRollupNode.version}/"
    sha256 cellar: :any, arm64_sonoma: "9aa370cead9f66be6e860b6213d2cb77b5f4ec6dfc587fc51ec246f810ee1732"
    sha256 cellar: :any, monterey: "0419e3c9d463e3d782d6f6aec028f73a14efc42c8a1e6896b2e14e15c8615c2f"
  end

  def make_deps
    ENV.deparallelize
    ENV["CARGO_HOME"]="./.cargo"
    # Disable usage of instructions from the ADX extension to avoid incompatibility
    # with old CPUs, see https://gitlab.com/dannywillems/ocaml-bls12-381/-/merge_requests/135/
    ENV["BLST_PORTABLE"]="yes"
    # Force linker to use libraries from the current brew installation.
    # Workaround for https://github.com/mavryk-network/mavryk-packaging/issues/700
    ENV["LDFLAGS"] = "-L#{HOMEBREW_PREFIX}/lib"
    # Here is the workaround to use opam 2.0.9 because Mavryk is currently not compatible with opam 2.1.0 and newer
    arch = RUBY_PLATFORM.include?("arm64") ? "arm64" : "x86_64"
    system "rustup-init", "--default-toolchain", "1.71.1", "-y"
    system "opam", "init", "--bare", "--debug", "--auto-setup", "--disable-sandboxing"
    system [". .cargo/env",  "make build-deps"].join(" && ")
  end

  def install_template(dune_path, exec_path, name)
    bin.mkpath
    self.class.all_bins << name
    system ["eval $(opam env)", "dune build #{dune_path}", "cp #{exec_path} #{name}"].join(" && ")
    bin.install name
    ln_sf "#{bin}/#{name}", "#{bin}/#{name.gsub("mavkit", "mavryk")}"
  end

  def install
    startup_contents =
      <<~EOS
      #!/usr/bin/env bash

      set -euo pipefail

      node="#{bin}/mavkit-smart-rollup-node"

      "$node" init "$ROLLUP_MODE" config \
          for "$ROLLUP_ALIAS" \
          --rpc-addr "$ROLLUP_NODE_RPC_ENDPOINT" \
          --force

      "$node" --endpoint "$NODE_RPC_SCHEME://$NODE_RPC_ADDR" \
          run "$ROLLUP_MODE" for "$ROLLUP_ALIAS"
      EOS
    File.write("mavryk-smart-rollup-node-start", startup_contents)
    bin.install "mavryk-smart-rollup-node-start"
    make_deps
    install_template "src/bin_smart_rollup_node/main_smart_rollup_node.exe",
                     "_build/default/src/bin_smart_rollup_node/main_smart_rollup_node.exe",
                     "mavkit-smart-rollup-node"
  end

  service do
    run opt_bin/"mavryk-smart-rollup-node-start"
    require_root true
    environment_variables MAVRYK_CLIENT_DIR: var/"lib/mavryk/client", NODE_RPC_ENDPOINT: "http://localhost:8732", ROLLUP_NODE_RPC_ENDPOINT: "127.0.0.1:8472", ROLLUP_MODE: "observer", ROLLUP_ALIAS: "rollup"
    keep_alive true
    log_path var/"log/mavryk-smart-rollup-node.log"
    error_log_path var/"log/mavryk-smart-rollup-node.log"
  end

  def post_install
    mkdir "#{var}/lib/mavryk/client"
  end
end
