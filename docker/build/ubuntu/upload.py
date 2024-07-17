#! /usr/bin/env python3
# SPDX-FileCopyrightText: 2023 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

import os
import re
import sys
import json
import subprocess
import argparse
from dataclasses import dataclass
from typing import List, Optional

sys.path.append("docker/build")
from util.upload import *


def upload_ubuntu(args: Arguments):

    with open("dput.cfg", "w") as dput_cfg:
        dput_cfg.write(
            f"""
[DEFAULT]
login	 = *
method = ftp
hash = md5
allow_unsigned_uploads = 0
allow_dcut = 0
run_lintian = 0
run_dinstall = 0
check_version = 0
scp_compress = 0
post_upload_command	=
pre_upload_command =
passive_ftp = 1
default_host_main	=
allowed_distributions	= (?!UNRELEASED)

[mavryk-mavrykdynamics]
fqdn      = ppa.launchpad.net
method    = ftp
incoming  = ~mavrykdynamics/ubuntu/mavryk
login     = anonymous

[mavryk-rc-mavrykdynamics]
fqdn        = ppa.launchpad.net
method      = ftp
incoming    = ~mavrykdynamics/ubuntu/mavryk-rc
login       = anonymous

[mavryk-test-mavrykdynamics]
fqdn        = ppa.launchpad.net
method      = ftp
incoming    = ~mavrykdynamics/ubuntu/mavryk-test
login       = anonymous
    """
        )

    mavkit_version = os.getenv("MAVKIT_VERSION", None)

    if args.test:
        launchpad_ppa = "mavryk-test-mavrykdynamics"
    elif re.search("v.*-rc[0-9]*", mavkit_version):
        launchpad_ppa = "mavryk-rc-mavrykdynamics"
    else:
        launchpad_ppa = "mavryk-mavrykdynamics"

    source_packages_path = args.directory

    packages = get_artifact_list(args)

    for f in filter(lambda x: x.endswith(".changes"), packages):
        subprocess.check_call(
            f"execute-dput -c dput.cfg {launchpad_ppa} {f}",
            shell=True,
        )


def main(args: Optional[Arguments] = None):

    parser.set_defaults(os="ubuntu")

    if args is None:
        args = fill_args(parser.parse_args())

    upload_ubuntu(args)


if __name__ == "__main__":
    main()
