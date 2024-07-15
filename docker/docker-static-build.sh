#! /usr/bin/env bash

# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

# This script builds static mavryk-binaries using custom alpine image.
# It expects docker or podman to be installed and configured.

set -euo pipefail

if [ -z ${MAVKIT_EXECUTABLES+x} ]; then

    readarray -t binaries < ./mavkit-executables

    MAVKIT_EXECUTABLES="$( IFS=$' '; echo "${binaries[*]}" )"
else
    IFS=' ' read -r -a binaries <<< "$MAVKIT_EXECUTABLES"
fi

if [[ "${USE_PODMAN-}" == "True" ]]; then
    virtualisation_engine="podman"
else
    virtualisation_engine="docker"
fi

arch="host"

if [[ -n "${1-}" ]]; then
    arch="$1"
fi

if [[ $arch == "host" ]]; then
    docker_file=build/Dockerfile
elif [[ $arch == "aarch64" ]]; then
    docker_file=build/Dockerfile.aarch64
else
    echo "Unsupported architecture: $arch"
    echo "Only 'host' and 'aarch64' are currently supported"
    exit 1
fi

if [[ $arch == "aarch64" && $(uname -m) != "x86_64" ]]; then
    echo "Compiling for aarch64 is supported only from aarch64 and x86_64"
fi

"$virtualisation_engine" build -t alpine-mavryk -f "$docker_file" --build-arg=MAVKIT_VERSION="$MAVKIT_VERSION" --build-arg=MAVKIT_EXECUTABLES="$MAVKIT_EXECUTABLES" .
container_id="$("$virtualisation_engine" create alpine-mavryk)"
for b in "${binaries[@]}"; do
    "$virtualisation_engine" cp "$container_id:/mavryk/$b" "$b"
done
"$virtualisation_engine" rm -v "$container_id"
