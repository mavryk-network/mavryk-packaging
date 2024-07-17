<!--
   - SPDX-FileCopyrightText: 2022 Oxhead Alpha
   - SPDX-License-Identifier: LicenseRef-MIT-OA
   -->
# Release workflow

This document explains the steps and timings of the release process in `mavryk-packaging`.

The releasing process is almost fully automated, with the initial release PR being created
at most 4 hours after a new Mavkit release. The only steps that require manual intervention
are reviews of this initial PR and of the PR that updates macOS brew formulae.
This allows `mavryk-packaging` to closely follow Mavkit releases without large waiting times.

This process can be described by the following diagram:
```mermaid
graph TD;
   classDef CI fill:#d0ffb3,stroke:#000000,color:black
   classDef manually fill:#fbff82,stroke:#000000,color:black
   start(Start)-->check_mavkit_release{New Mavkit Release?}:::CI
   style start fill:#ffffff,stroke:#000000,color:black
   CI[Performed by CI]:::CI
   Manually[Performed manually]:::manually
   check_mavkit_release--No-->wait[Wait 4 hours]:::CI
   wait-->check_mavkit_release
   check_mavkit_release--Yes-->mavryk_packaging_release_PR[Create release PR in mavryk-packaging repo]:::CI
   mavryk_packaging_release_PR-->review_release_PR[Review and merge release PR]:::manually
   review_release_PR-->stable_release_check_1{Stable Mavkit release?}:::CI
   stable_release_check_1--Yes-->github_release[Create new Github release with static binaries]:::CI
   github_release-->publish_stable_native_packages[Publish native packages to the stable Launchpad PPA and Copr Project]:::CI
   github_release-->build_brew_bottles["Build Brew bottles, upload them to the created GitHub {pre-}release"]:::CI
   github_prerelease-->build_brew_bottles
   github_prerelease-->publish_RC_native_packages[Publish native packages to the RC Launchpad PPA and Copr Project]:::CI
   stable_release_check_1--No-->github_prerelease[Create new GitHub pre-release with static binaries]:::CI
   build_brew_bottles-->create_bottles_hashes_PR[Create PR to mavryk-packaging repo with formulae bottles' hashes update]:::CI
   create_bottles_hashes_PR-->review_bottles_hashes_PR[Review and merge formulae update PR]:::manually
   review_bottles_hashes_PR-->stable_release_check_2{Stable Mavkit release?}:::CI
   stable_release_check_2--Yes-->update_stable_mirror[Update stable mavryk-packaging mirror repository]:::CI
   stable_release_check_2--No-->update_RC_mirror[Update RC mavryk-packaging mirror repository]:::CI
```
