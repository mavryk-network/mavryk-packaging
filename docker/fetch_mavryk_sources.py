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
subprocess.run(["opam", "admin", "cache"])

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
