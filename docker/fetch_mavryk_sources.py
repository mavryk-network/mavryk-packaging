#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2023 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

import subprocess
import os
import re
import shutil
import json
import time

with open("meta.json") as f:
    mavkit_version = json.loads(f.read()).get("mavryk_ref", "mavkit-v20.2-rc3")

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
