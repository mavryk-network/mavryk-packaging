# SPDX-FileCopyrightText: 2024 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykBakerPtboreas < Formula
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

  dependencies = %w[gmp hidapi libev protobuf sqlite mavryk-sapling-params]
  dependencies.each do |dependency|
    depends_on dependency
  end
  desc "Daemon for baking"

  bottle do
    root_url "https://github.com/mavryk-network/mavryk-packaging/releases/download/#{MavrykBakerPtboreas.version}/"
    sha256 cellar: :any, arm64_sonoma: "43a74d065578e1ce94b1639a77246e5413a29a4ffbad5b8417bdc1ce044ae664"
    sha256 cellar: :any, arm64_sonoma: "87a3ae5d67d71bff01445060216d7d56e8ae0288440d30ebaceb38d982864c49"
    sha256 cellar: :any, monterey: "88983b11846d56d8087d600905b568511215a0653beaa2769adebe5aa79ad894"
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

      baker="#{bin}/mavkit-baker-PtBoreas"

      baker_config="$MAVRYK_CLIENT_DIR/config"
      mkdir -p "$MAVRYK_CLIENT_DIR"

      if [ ! -f "$baker_config" ]; then
          "$baker" --endpoint "$NODE_RPC_SCHEME://$NODE_RPC_ADDR" \
                  config init --output "$baker_config" >/dev/null 2>&1
      else
          "$baker" --endpoint "$NODE_RPC_SCHEME://$NODE_RPC_ADDR" \
                  config update >/dev/null 2>&1
      fi

      launch_baker() {
          exec "$baker" \
              --endpoint "$NODE_RPC_SCHEME://$NODE_RPC_ADDR" \
              run with local node "$MAVRYK_NODE_DIR" "$@"
      }

      if [[ -z "$BAKER_ACCOUNT" ]]; then
          launch_baker
      else
          launch_baker "$BAKER_ACCOUNT"
      fi
    EOS
    File.write("mavryk-baker-PtBoreas-start", startup_contents)
    bin.install "mavryk-baker-PtBoreas-start"
    make_deps
    install_template "src/proto_002_PtBoreas/bin_baker/main_baker_002_PtBoreas.exe",
                     "_build/default/src/proto_002_PtBoreas/bin_baker/main_baker_002_PtBoreas.exe",
                     "mavkit-baker-PtBoreas"
  end

  service do
    run opt_bin/"mavryk-baker-PtBoreas-start"
    require_root true
    environment_variables MAVRYK_CLIENT_DIR: var/"lib/mavryk/client", MAVRYK_NODE_DIR: "", NODE_RPC_SCHEME: "http", NODE_RPC_ADDR: "localhost:8732", BAKER_ACCOUNT: ""
    keep_alive true
    log_path var/"log/mavryk-baker-PtBoreas.log"
    error_log_path var/"log/mavryk-baker-PtBoreas.log"
  end

  def post_install
    mkdir "#{var}/lib/mavryk/client"
  end
end
