#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2023 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

import subprocess
import os
import re
import shutil

mavkit_version = os.getenv("MAVKIT_VERSION", None)

if not mavkit_version:
    raise Exception("Environment variable MAVKIT_VERSION is not set.")

subprocess.run(
    [
        "git",
        "clone",
        "--branch",
        mavkit_version,
        "https://gitlab.com/mavryk-network/mavryk-protocol.git",
        "--depth",
        "1",
        "mavryk"
    ]
)
# NOTE: it's important to keep the `mavryk/.git` directory here, because the
# git tag is used to set the version in the Mavkit binaries.

subprocess.run(
    [
        "git",
        "clone",
        "https://gitlab.com/mavryk-network/opam-repository.git",
        "opam-repository-mavryk",
    ]
)

opam_repository_tag = (
    subprocess.run(
        ". ./mavryk/scripts/version.sh; echo $opam_repository_tag",
        stdout=subprocess.PIPE,
        shell=True,
    )
    .stdout.decode()
    .strip()
)

os.chdir("opam-repository-mavryk")
subprocess.run(["git", "checkout", opam_repository_tag])
subprocess.run(["rm", "-rf", ".git"])
subprocess.run(["rm", "-r", "zcash-params"])
subprocess.run(["scripts/create_opam_repo.sh"])
subprocess.run(["mv", "opam-repository", ".."])
os.chdir("..")
subprocess.run(["rm", "-rf", "opam-repository-mavryk"])
os.chdir("opam-repository")
# Vendor every dependency source into opam-repository/cache so the
# network-less Launchpad builders can build offline. Some upstreams
# (notably camlcity.org) are flaky, so retry a few times before giving up.
import time

cache_attempts = 5
for attempt in range(1, cache_attempts + 1):
    cache_result = subprocess.run(
        ["opam", "admin", "cache"], capture_output=True, text=True
    )
    print(cache_result.stdout)
    if cache_result.stderr:
        print(cache_result.stderr)
    if cache_result.returncode == 0:
        break
    print(
        f"WARNING: 'opam admin cache' attempt {attempt}/{cache_attempts} "
        f"failed (exit {cache_result.returncode})."
    )
    if attempt < cache_attempts:
        time.sleep(15)
else:
    raise Exception(
        "FATAL: 'opam admin cache' failed to vendor all dependency sources "
        f"after {cache_attempts} attempts. The Launchpad build runs without "
        "network access, so every source must be cached here. See the output "
        "above for the package(s) whose download failed."
    )

# Fix tezos-rust-libs: GitLab regenerates ZIP archives with different hashes,
# so opam admin cache fails checksum verification. Download it manually and
# place it in the cache with the expected hash-based path.
import hashlib
rust_libs_url = "https://gitlab.com/tezos/tezos-rust-libs/-/archive/v1.6/tezos-rust-libs-v1.6.zip"
rust_libs_file = "/tmp/tezos-rust-libs-v1.6.zip"
subprocess.run(["wget", "-q", "-O", rust_libs_file, rust_libs_url], check=True)
with open(rust_libs_file, "rb") as f:
    file_data = f.read()
actual_sha512 = hashlib.sha512(file_data).hexdigest()
actual_sha256 = hashlib.sha256(file_data).hexdigest()

# Place in cache under both hash schemes
for algo, hash_val in [("sha512", actual_sha512), ("sha256", actual_sha256)]:
    cache_dir = f"cache/{algo}/{hash_val[:2]}"
    os.makedirs(cache_dir, exist_ok=True)
    shutil.copy(rust_libs_file, f"{cache_dir}/{hash_val}")

# Update the opam file to use the correct checksums
import glob
opam_files = glob.glob("packages/tezos-rust-libs/*/opam")
for opam_file in opam_files:
    with open(opam_file, "r") as f:
        content = f.read()
    content = re.sub(r'sha512=[a-f0-9]+', f'sha512={actual_sha512}', content)
    content = re.sub(r'sha256=[a-f0-9]+', f'sha256={actual_sha256}', content)
    with open(opam_file, "w") as f:
        f.write(content)
    print(f"Updated checksums in {opam_file}")
    print(f"  sha512={actual_sha512}")
    print(f"  sha256={actual_sha256}")

# Regenerate the repo index after modifying opam files
subprocess.run(["opam", "admin", "index"], check=True)

# Fix ocamlfind: its upstream (download.camlcity.org) is an unreliable personal
# server, so `opam admin cache` intermittently fails to vendor it, which then
# breaks the network-less Launchpad build. Fetch the byte-identical archive
# from opam.ocaml.org's content-addressed cache (a reliable CDN), with the
# camlcity mirrors as fallback, and place it in the local cache under the
# hashes the opam file already expects. The checksums are unchanged, so the
# opam file needs no patching.
ocamlfind_md5 = "96c6ee50a32cca9ca277321262dbec57"
ocamlfind_sha512 = (
    "cfaf1872d6ccda548f07d32cc6b90c3aafe136d2aa6539e03143702171ee0199"
    "add55269bba894c77115535dc46a5835901a5d7c75768999e72db503bfd83027"
)
ocamlfind_file = "/tmp/findlib-1.9.6.tar.gz"
ocamlfind_sources = [
    f"https://opam.ocaml.org/cache/md5/{ocamlfind_md5[:2]}/{ocamlfind_md5}",
    "http://download.camlcity.org/download/findlib-1.9.6.tar.gz",
    "http://download2.camlcity.org/download/findlib-1.9.6.tar.gz",
]
for source in ocamlfind_sources:
    if subprocess.run(
        ["wget", "-q", "-t", "5", "--retry-connrefused", "-O", ocamlfind_file, source]
    ).returncode != 0:
        print(f"ocamlfind: download failed from {source}")
        continue
    with open(ocamlfind_file, "rb") as f:
        data = f.read()
    if (
        hashlib.md5(data).hexdigest() == ocamlfind_md5
        and hashlib.sha512(data).hexdigest() == ocamlfind_sha512
    ):
        print(f"ocamlfind: fetched verified archive from {source}")
        break
    print(f"ocamlfind: checksum mismatch from {source}, trying next source")
else:
    raise Exception(
        "FATAL: could not obtain a checksum-valid ocamlfind 1.9.6 archive "
        "from any known source; the Launchpad build would fail offline."
    )

# Place under both hash schemes the opam file lists (md5 and sha512)
for algo, hash_val in [("md5", ocamlfind_md5), ("sha512", ocamlfind_sha512)]:
    cache_dir = f"cache/{algo}/{hash_val[:2]}"
    os.makedirs(cache_dir, exist_ok=True)
    shutil.copy(ocamlfind_file, f"{cache_dir}/{hash_val}")
