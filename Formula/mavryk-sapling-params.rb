# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykSaplingParams < Formula
  url "https://gitlab.com/tezos/opam-repository.git", :tag => "v8.2"
  homepage "https://github.com/mavryk-network/mavryk-packaging"

  version "v20.2-rc1"

  desc "Sapling params required at runtime by the Mavryk binaries"

  def install
    share.mkpath
    share.install "zcash-params"
  end
end
