<!--
   - SPDX-FileCopyrightText: 2021 Oxhead Alpha
   - SPDX-License-Identifier: LicenseRef-MIT-OA
   -->
# Fedora Copr repository with `mavryk-*` binaries

If you are using Fedora you can use Copr in order to install `mavryk-*`
executables.
E.g. in order to install `mavryk-client` or a `mavryk-baker-<proto>` run the
following commands:
```
# use dnf
sudo dnf copr enable @MavrykDynamics/Mavryk
sudo dnf install mavryk-client
sudo dnf install mavryk-baker-PtBoreas

# or use yum
sudo yum copr enable @MavrykDynamics/Mavryk
sudo yum install mavryk-baker-PtBoreas
```
Once you install these packages, the commands `mavryk-*` and `mavkit-*` will be available.

## Using release-candidate packages

In order to use packages with the latest release-candidate Mavkit binaries,
use the `@MavrykDynamics/Mavryk-rc` project:
```
# use dnf
sudo dnf copr enable @MavrykDynamics/Mavryk-rc

# or use yum
sudo yum copr enable @MavrykDynamics/Mavryk-rc
```

## Systemd services from Fedora packages

Some of the packages provide background `systemd` services, you can read more about them
[here](./systemd.md#ubuntu-and-fedora).
