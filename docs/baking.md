<!--
   - SPDX-FileCopyrightText: 2021 Oxhead Alpha
   - SPDX-License-Identifier: LicenseRef-MIT-OA
   -->
# Baking with mavryk-packaging on Ubuntu and Raspberry Pi OS

[⏩ Quick Start](#quick-start)

Mavryk-packaging provides an easy way to install and set up the infrastructure for
interacting with the Mavryk blockchain.

This article provides a step-by-step guide for setting up a baking instance for
Mavryk on Ubuntu or Raspberry Pi OS.

However, a CLI wizard utility is provided for an easy, interactive setup.
It is the recommended way at the moment to set up a baking instance.

## Prerequisites

### Raspberry Pi system

To bake on a Raspberry Pi you will need a device that has at least 4 GB of RAM
and an arm64 processor; for example a Raspberry Pi 4B.

You will also need to run the [64bit version of the Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit),
that you can use by following the [installation instructions](https://www.raspberrypi.com/documentation/computers/getting-started.html#installing-the-operating-system).

### Installation

In order to run a baking instance, you'll need the following Mavryk binaries:
`mavryk-client`, `mavryk-node`, `mavryk-baker-<proto>`.

The currently supported protocol is `PtBoreas` (used on `boreasnet`, is going to be used on `basenet`, and `mainnet`).
Also, note that the corresponding packages have protocol
suffix in lowercase, e.g. the list of available baker packages can be found
[here](https://launchpad.net/~mavrykdynamics/+archive/ubuntu/mavryk/+packages?field.name_filter=mavryk-baker&field.status_filter=published).

The most convenient way to orchestrate all these binaries is to use the `mavryk-baking`
package, which provides predefined services for running baking instances on different
networks.

This package also provides a `mavryk-setup` CLI utility, designed to
query all necessary configuration options and use the answers to automatically set up
a baking instance.

#### Add repository

On Ubuntu:

```
# Add PPA with Mavryk binaries
sudo add-apt-repository ppa:mavrykdynamics/mavryk
```

Alternatively, use packages with release-candidate Mavryk binaries:
```
# Or use PPA with release-candidate Mavryk binaries
sudo add-apt-repository ppa:mavrykdynamics/mavryk-rc
```

On Raspberry Pi OS:

```
# Install software properties commons
sudo apt-get install software-properties-common
# Add PPA with Mavryk binaries
sudo add-apt-repository 'deb http://ppa.launchpad.net/mavrykdynamics/mavryk/ubuntu focal main'
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 37B8819B7D0D183812DCA9A8CE5A4D8933AE7CBB
```

#### Install packages

```
sudo apt-get update
sudo apt-get install mavryk-baking
```

Packages for `mavryk-node` and `mavryk-baker-<proto>` provide
systemd units for running the corresponding binaries in the background, these units
are orchestrated by the `mavryk-baking-<network>` units.

## Packages and protocols updates

In order to have a safe transition during a new protocol activation on mainnet,
it's required to run two sets of daemons: for the current and for the upcoming protocol.

`mavryk-baking` package aims to provide such a setup. This package is updated some time before
the new protocol is activated (usually 1-2 weeks) to run daemons for two protocols. Once the new
protocol is activated, the `mavryk-baking` package is updated again to stop running daemons for the old protocol.

## Using the wizard

If at this point you want to set up the baking instance, or just a node, using the wizard, run:

```
mavryk-setup
```

This wizard closely follows this guide, so for most setups it won't be necessary to follow
the rest of this guide.

## Setting up baking service

By default `mavryk-baking-<network>.service` will be using:
* `/var/lib/mavryk/.mavryk-client` as the `mavryk-client` data directory
* `/var/lib/mavryk/node-<network>` as the `mavryk-node` data directory
* `http://localhost:8732` as the `mavryk-node` RPC address.

## Bootstrapping the node

A fully-synced local `mavryk-node` is required for running a baking instance.

By default, service with `mavryk-node` will start to bootstrap from scratch,
which will take a significant amount of time.
In order to avoid this, we suggest bootstrapping from a snapshot instead.

Snapshots can be downloaded from the following websites:
* [Lambs on acid](https://lambsonacid.nl/)
* [Tzinit](https://snapshots.eu.tzinit.org/)

Download the snapshot for the desired network. We recommend to use rolling snapshots. This is
the smallest and the fastest mode that is sufficient for baking (you can read more about other
`mavryk-node` history modes [here](https://protocol.mavryk.org/user/history_modes.html#history-modes)).

All commands within the service are run under the `mavryk` user.

The `mavryk-node` package provides `mavryk-node-<network>` aliases that are equivalent to
running `mavryk-node` with [the service options](./configuration.md).

In order to import the snapshot, run the following command:
```
sudo -u tezos mavryk-node-<network> snapshot import <path to the snapshot file>
```

## Setting up baker key

Note that account activation from JSON file and baker registering require
running a fully-bootstrapped `mavryk-node`. In order to start node service do the following:
```
sudo systemctl start mavryk-node-<network>.service
```

Even after the snapshot import the node can still be out of sync and may require
some additional time to completely bootstrap.

In order to check whether the node is bootstrapped and wait in case it isn't,
you can use `mavryk-client`:
```
sudo -u tezos mavryk-client bootstrapped
```

By default `mavryk-baking-<network>.service` will use the `baker` alias for the
key that will be used for baking and attesting.

### Setting the Liquidity Baking toggle vote option

Since `PtJakart`, the `--liquidity-baking-toggle-vote` command line option for
`mavryk-baker` is now mandatory. In our systemd services, it is set to `pass` by
default.
You can change it as desired in [the service config file](./configuration.md).

You can also use the [Setup Wizard](#using-the-wizard) which will handle everything for you.

<a name="import"></a>
### Importing the baker key

Import your baker secret key to the data directory. There are multiple ways to import
the key:

1) The secret key is stored on a ledger.

Open the Mavryk Baking app on your ledger and run the following
to import the key:
```
sudo -u tezos mavryk-client import secret key baker <ledger-url>
```
Apart from importing the key, you'll also need to set it up for baking. Open the Mavryk
Baking app on your ledger and run the following:
```
sudo -u tezos mavryk-client setup ledger to bake for baker
```

2) You know either the unencrypted or password-encrypted secret key for your address.

In order to import such a key, run:
```
sudo -u tezos mavryk-client import secret key baker <secret-key>
```

1) Alternatively, you can generate a fresh baker key and fill it using faucet from https://teztnets.com.

In order to generate a fresh key run:
```
sudo -u tezos mavryk-client gen keys baker
```
The newly generated address will be displayed as a part of the command output.

Then visit https://teztnets.com and fill the address with at least 6000 XTZ on the desired testnet.

<a name="registration"></a>
### Registering the baker
Once the key is imported, you'll need to register your baker. If you imported your key
using a ledger, open a Mavryk Wallet or Mavryk Baking app on your ledger again. In any
case, run the following command:
```
sudo -u tezos mavryk-client register key baker as delegate
```

Check a blockchain explorer (e.g. https://tzkt.io/ or https://tzstats.com/) to see the baker status and
baking rights of your account.

## Starting baking instance

Once the key is imported and the baker registered, you can start your baking instance:
```
sudo systemctl start mavryk-baking-<network>.service
```

This service will trigger the following services to start:
* `mavryk-node-<network>.service`
* `mavryk-baker-<proto>@<network>.service`

Once services have started, you can check their logs via `journalctl`:
```
journalctl -f _UID=$(id tezos -u)
```
This command will show logs for all services that are using the `mavryk` user.

You'll see the following messages in the logs in case everything has started
successfully:
```
Baker started.
```

To stop the baking instance run:
```
sudo systemctl stop mavryk-baking-<network>.service
```

## Advanced baking instance setup

These services have several options that can be modified to change their behavior.
See [the dedicated documentation](./configuration.md) for more information on
how to do that.

### Using a custom chain

In case you want to set up a baking instance on a custom chain instead of relying on mainnet
or official testnets, you can do so:

1. Create a config file for future custom baking instance:
  ```bash
  sudo cp /etc/default/mavryk-baking-custom@ /etc/default/mavryk-baking-custom@<chain-name>
  ```
2. [Edit the `mavryk-baking-custom@<chain-name>` configuration](./configuration.md)
 and set the `CUSTOM_NODE_CONFIG` variable to the path to your config file.
3. Start custom baking service:
  ```bash
  sudo systemctl start mavryk-baking-custom@<chain-name>
  ```
4. Check that all parts are indeed running:
  ```bash
  systemctl status mavryk-node-custom@<chain-name>
  systemctl status mavryk-baker-ptkathma@custom@<chain-name>.service
```

If at any point after that you want to reset the custom baking service, you can set
`RESET_ON_STOP` to `true` [in the `mavryk-baking-custom@<chain-name>` configuration](./configuration.md) and run:

```bash
sudo systemctl stop mavryk-baking-custom@voting
```

Manually resetting is possible through:

1. Removing the custom chain node directory, `/var/lib/mavryk/node-custom@<chain-name>` by default.
2. Deleting `blocks`, `nonces`, and `attestations` from the `mavryk-client` data directory,
  `/var/lib/mavryk/.mavryk-client` by default.

## Quick Start

<details>
 <summary>
   <em>Optional</em> Create new Ubuntu virtual machine...
 </summary>

A quick way to spin up a fresh Ubuntu virtual machine is
to use [Multipass](https://multipass.run/) (reduce disk if this is
to be used with a test network or a mainnet node in rolling history mode):

```
multipass launch --cpus 2 --disk 100G --mem 4G --name mavryk
```

and then log in:

```
multipass shell mavryk
```

> Note that on Windows and MacOS this VM will not have access to USB and
> thus is not suitable for using with Ledger Nano S.

</details>

1) Install `mavryk-baking` package following [these instructions](#add-repository).

2) Run `mavryk-setup` and follow the instructions there.

<details>
 <summary>
  <em>Optional</em> Allow RPC access from virtual machine's host...
 </summary>

[Update the `mavryk-node-<network>` service configuration](./configuration.md)
and set the `NODE_RPC_ADDR` to `0.0.0.0:8732`.

Then restart the service:
```
sudo systemctl restart mavryk-node-<network>
```

</details>
