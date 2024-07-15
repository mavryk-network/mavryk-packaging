# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

# TODO: once there is a new release of opam-repository this should be updated
class MavrykSaplingParams < Formula
  url "https://gitlab.com/tezos/opam-repository.git", :tag => "v8.2"
  homepage "https://github.com/mavryk-network/mavryk-packaging"

  version "v8.2-3"

  desc "Sapling params required at runtime by the Mavryk binaries"

  bottle do
    root_url "https://github.com/mavryk-network/mavryk-packaging/releases/download/#{MavrykSaplingParams.version}/"
    sha256 cellar: :any, mojave: "4e89932b0626cffe80214ba45342280c340b34c58ebbf7c3e0185a6d4662732d"
    sha256 cellar: :any, catalina: "5f7a5687d67051eafcfb7cb5ac542143a325a135403daeca6595602bfd400441"
  end

  def install
    share.mkpath
    share.install "zcash-params"
  end
end
