# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykSaplingParams < Formula
  homepage "https://github.com/mavryk-network/mavryk-packaging"
  
  url "https://gitlab.com/mavryk-network/opam-repository.git", :tag => "v9.4", :shallow => false

  version "v20.2-rc1"

  desc "Sapling params required at runtime by the Mavryk binaries"

  bottle do
    root_url "https://github.com/mavryk-network/mavryk-packaging/releases/download/#{MavrykSaplingParams.version}/"
    sha256 cellar: :any, monterey: "51253fd0d0fdb9c8e0adfdd753be4184d56ed53b64c5b79fb1010520f063961c"
  end

  def install
    share.mkpath
    share.install "zcash-params"
  end
end
