<!--
   - SPDX-FileCopyrightText: 2022 Oxhead Alpha
   - SPDX-License-Identifier: LicenseRef-MIT-OA
   -->

# Voting with voting wizard

This document explains how one can test voting via voting wizard on during all possible
amendment periods.

## Prerequisites

1) Install `mavryk-baking` package should on your system.
2) Create a temporary directory where the node's data directory and the local-chain will reside:

```bash
mkdir -m 777 /tmp/voting
cd /tmp/voting
git clone https://gitlab.com/morley-framework/local-chain
```

## Test scenario workflow

1) Generate a pair of keys associated with `baker` alias:

    ```bash
    sudo -u mavryk mavryk-client gen keys baker
    ```

    If you want to use your ledger device for voting, you should import its encrypted private key instead:

    First, run this command:

    ```
    sudo -u mavryk mavryk-client list connected ledgers
    ```

    This will display some instructions to import the Ledger encrypted private key. Then run

    ```
    sudo -u mavryk mavryk-client import secret key baker ledger://XXXXXXXXXX
    ```

    And confirm providing the public key using the prompt on the ledger device.

2) In a separate terminal start a [voting scenario script](https://gitlab.com/morley-framework/local-chain#voting-scenario) from the local-chain repo.

    This script will provide you a path to the node config that will be used by the custom baking service.

3) Provide address generated on the first step to the `voting.py` script. This address will receive some amount of XTZ.

4) Create environment files for the custom baking service that will be used by the voting wizard:

    ```bash
    sudo cp /etc/default/mavryk-node-custom@ /etc/default/mavryk-node-custom@voting
    sudo cp /etc/default/mavryk-baking-custom@ /etc/default/mavryk-baking-custom@voting
    ```

    Edit the node environment file with the config provided by the voting script on the second step:

    ```
    NODE_RPC_ADDR="127.0.0.1:8732"
    CERT_PATH=""
    KEY_PATH=""
    MAVRYK_NODE_DIR=/tmp/voting/node-custom
    CUSTOM_NODE_CONFIG=/tmp/voting/local-chain/voting-config.json
    RESET_ON_STOP=""
    ```

    Additionally, you can set `RESET_ON_STOP="true"` to enable automatic node directory removal which will
    be triggered once custom baking service will be stopped.

5) Start custom baking service:

    ```bash
    sudo systemctl start mavryk-baking-custom@voting
    ```

    Note that `mavryk-node` service may take some time to generate a fresh identity and start.

    To check the status of the node service run:

    ```bash
    systemctl status mavryk-node-custom@voting
    ```

6) Register `baker` key as delegate once `mavryk-node` is up and running:

    ```bash
    sudo -u mavryk mavryk-client register key baker as delegate
    ```

7) After that `voting.py` will start going through the voting cycle.

    The script will stop at the beginning of each voting period that requires voting and ask you to vote.

    Launch the wizard by running:

    ```bash
    mavryk-vote --network voting
    ```

    Under normal conditions, you won't have to adjust any information about your baking service.
    Confirm the information and submit your vote.

    Once you'll vote, you should prompt the `voting.py` script to continue going through the voting cycle.

8) Stop custom baking service once voting cycle is over:

    ```bash
    sudo systemctl stop mavryk-baking-custom@voting
    ```
