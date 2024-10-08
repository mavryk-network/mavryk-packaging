# SPDX-FileCopyrightText: 2023 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

import subprocess
import sys
import json
import os


def test(binaries):
    subprocess.run("apt update -y", shell=True, capture_output=True)
    for binary in binaries:
        try:
            subprocess.run(
                f"apt install -y {binary.lower()}",
                shell=True,
                capture_output=True,
                check=True,
            )
            if binary != "mavryk-sapling-params" and binary != "mavryk-baking":
                print(f"{binary}: ", end="", flush=True)
                subprocess.check_call(
                    f"{binary.replace('mavryk', 'mavkit')} --version", shell=True
                )
        except Exception as e:
            print(f"Exception happened when trying to execute tests for {binary}.\n")
            raise e


if __name__ == "__main__":
    data = {}
    with open("/mavryk-packaging/binaries.json") as f:
        data = json.load(f)

    binaries = []
    is_released = os.environ["IS_RELEASED"]
    if is_released == "mavryk":
        binaries = data["released"]
    elif is_released == "mavryk-rc":
        binaries = data["candidates"]
    else:
        raise "Incorrect argument"

    test(binaries)
