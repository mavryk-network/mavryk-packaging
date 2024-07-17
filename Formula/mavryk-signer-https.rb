# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykSignerHttps < Formula
  url "file:///dev/null"
  version "v20.1-rc1"

  depends_on "mavryk-signer"

  desc "Meta formula that provides backround mavryk-signer service that runs over https"

  def install
    startup_contents =
      <<~EOS
      #!/usr/bin/env bash

      set -euo pipefail

      signer="/usr/local/bin/mavkit-signer"

      if [[ -n $PIDFILE ]]; then
        pid_file_args=("--pid-file" "$PIDFILE")
      else
        pid_file_args=()
      fi

      if [[ -n $MAGIC_BYTES ]]; then
        magic_bytes_args=("--magic-bytes" "$MAGIC_BYTES")
      else
        magic_bytes_args=()
      fi

      if [[ -n $CHECK_HIGH_WATERMARK ]]; then
        check_high_watermark_args=("--check-high-watermark")
      else
        check_high_watermark_args=()
      fi

      "$signer" -d "$MAVRYK_CLIENT_DIR" launch https signer "$CERT_PATH" "$KEY_PATH" --address "$ADDRESS" --port "$PORT" \
        ${pid_file_args[@]+"${pid_file_args[@]}"} ${magic_bytes_args[@]+"${magic_bytes_args[@]}"} \
        ${check_high_watermark_args[@]+"${check_high_watermark_args[@]}"} "$@"
    EOS
    File.write("mavryk-signer-https-start", startup_contents)
    bin.install "mavryk-signer-https-start"
  end

  service do
    run opt_bin/"mavryk-signer-https-start"
    require_root true
    environment_variables MAVRYK_CLIENT_DIR: var/"lib/mavryk/client", ADDRESS: "127.0.0.1", PORT:"8080", PIDFILE: "", MAGIC_BYTES: "", CHECK_HIGH_WATERMARK: "", CERT_PATH: "", KEY_PATH: ""
    log_path var/"log/mavryk-signer-https.log"
    error_log_path var/"log/mavryk-signer-https.log"
  end

  def post_install
    mkdir "#{var}/lib/mavryk/signer-https"
  end
end
