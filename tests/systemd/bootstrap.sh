#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2022 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

set -e

dpkg -i ./out/mavryk-client*~focal_amd64.deb
dpkg -i ./out/mavryk-baker*~focal_amd64.deb
dpkg -i ./out/mavryk-accuser*~focal_amd64.deb
dpkg -i ./out/mavryk-node*~focal_amd64.deb
dpkg -i ./out/mavryk-signer*~focal_amd64.deb
dpkg -i ./out/mavryk-baking*~focal_amd64.deb
