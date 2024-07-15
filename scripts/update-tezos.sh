#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

# This script fetches the latest tag from the https://gitlab.com/mavryk-network/mavryk-protocol/ repository,
# compares it with the version presented in the nix/nix/sources.json, and performs an
# update if the versions are different

set -e

git config user.name "MavrykCowbot" # necessary for pushing
git config user.email "info@mavryk.io"
git fetch --all

# Get latest tag from mavryk-network/mavryk-protocol
git clone https://gitlab.com/mavryk-network/mavryk-protocol.git upstream-repo
cd upstream-repo
latest_upstream_tag_hash="$(git rev-list --tags --max-count=1)"
latest_upstream_tag="$(git describe --tags "$latest_upstream_tag_hash")"
full_opam_repository_tag='' # will be set by version.sh
git checkout "$latest_upstream_tag"
source scripts/version.sh
# copying metadata from mavkit repo
cp script-inputs/released-executables ../docker/mavkit-executables
cp script-inputs/active_protocol_versions_without_number ../docker/active-protocols
cd ..
rm -rf upstream-repo

packaging_tag="$([[ "$latest_upstream_tag" =~ mavkit-(v.*) ]] && echo "${BASH_REMATCH[1]}")"

branch_name="auto/$packaging_tag-release"

our_mavryk_tag="$(jq -r '.mavryk_ref' meta.json | cut -d'/' -f3)"

new_meta=$(jq ".mavryk_ref=\"$latest_upstream_tag\"" meta.json)
echo "$new_meta" > meta.json

if [[ "$latest_upstream_tag" != "$our_mavryk_tag" ]]; then
  # If corresponding branch doesn't exist yet, then the release PR
  # wasn't created
  if ! git rev-parse --verify "$branch_name"; then
    git switch -c "$branch_name"
    echo "Updating Mavryk to $packaging_tag"

    ./scripts/update-input.py mavryk "$latest_upstream_tag_hash"
    ./scripts/update-input.py opam-repository "$full_opam_repository_tag"
    git commit -a -m "[Chore] Bump Mavryk sources to $packaging_tag" --gpg-sign="info@mavryk.io"

    ./scripts/update-brew-formulae.sh "$packaging_tag-1"
    git commit -a -m "[Chore] Update brew formulae for $packaging_tag" --gpg-sign="info@mavryk.io"

    sed -i 's/"release": "[0-9]\+"/"release": "1"/' ./meta.json
    # Update version of mavryk-baking package
    sed -i "s/version = .*/version = \"$packaging_tag\"/" ./baking/pyproject.toml
    # Commit may fail when release number wasn't updated since the last release
    git commit -a -m "[Chore] Reset release number for $packaging_tag" --gpg-sign="info@mavryk.io" || \
      (true; echo "release number wasn't updated")

    sed -i 's/letter_version *= *"[a-z]"/letter_version = ""/' ./docker/package/model.py
    # Commit may fail when the letter version wasn't updated since the last release
    git commit -a -m "[Chore] Reset letter_version for $packaging_tag" --gpg-sign="info@mavryk.io" || \
      (true; echo "letter_version wasn't reset")

    ./scripts/update-release-binaries.py
    pushd docker
    python3 -m package.update-test-binaries-list
    popd
    git commit -a -m "[Chore] Update release binaries for $packaging_tag" --gpg-sign="info@mavryk.io" || \
      (true; echo "lists of binaries and protocols weren't updated")

    git push --set-upstream origin "$branch_name"

    gh pr create -B master -t "[Chore] $packaging_tag release" -F .github/release_pull_request_template.md
  fi
else
  echo "Our version is the same as the latest tag in the upstream repository"
fi
