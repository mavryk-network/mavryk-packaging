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
    ]
)
# NOTE: it's important to keep the `mavryk/.git` directory here, because the
# git tag is used to set the version in the Mavkit binaries.

subprocess.run(
    [
        "git",
        "clone",
        "https://gitlab.com/tezos/opam-repository.git",
        "opam-repository-tezos",
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

os.chdir("opam-repository-tezos")
subprocess.run(["git", "checkout", opam_repository_tag])
subprocess.run(["rm", "-rf", ".git"])
subprocess.run(["rm", "-r", "zcash-params"])
subprocess.run(["scripts/create_opam_repo.sh"])
subprocess.run(["mv", "opam-repository", ".."])
os.chdir("..")
subprocess.run(["rm", "-rf", "opam-repository-tezos"])
os.chdir("opam-repository")
subprocess.run(["opam", "admin", "cache"])
