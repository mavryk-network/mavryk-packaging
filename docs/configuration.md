<!--
   - SPDX-FileCopyrightText: 2022 Oxhead Alpha
   - SPDX-License-Identifier: LicenseRef-MIT-OA
   -->
# Systemd service options

The [`systemd` services](./systemd.md) provided by the packages here utilize
options to to define their behavior.

All these options are defined as environment variables and are located in files
in the `/etc/default` system directory.

## Changing options

Options can be modified by editing the configuration files.

For example, using the commonly pre-installed `nano` editor:
```sh
sudo nano /etc/default/mavryk-node-mainnet
```
can be used to modify the behavior of the `mainnet` mavryk node service (and not
only, see below).

Note that if a service is already running it will be necessary to restart it, e.g.
```sh
sudo systemctl restart mavryk-node-mainnet.service
```
in order for the changes to take effect.

In case you [set up baking using the `mavryk-setup`](./baking.md), running:
```sh
sudo systemctl restart mavryk-baking-<network>.service
```
will be sufficient, as all the services involved will be restarted.
Running again `mavryk-setup` and following the setup process is also an option.

## Utility node scripts

Installing packages on Ubuntu or Fedora will also install some utility scripts
for mavryk nodes: a `mavryk-node-<network>` for every currently supported Mavryk `<network>`.

Calling these scripts has the same effect as running `mavryk-node` with the env
variables in the `/etc/default/mavryk-node-<network>` given to it.

## Available options

Below is a list of all the environment variables that can affect the services.

Note that, because they are inter-connected, some changes affect multiple services.
For example, it's sufficient to change the node data directory option in the `node`
configuration file and the appropriate `baker`s and `baking` services will be
aware of the change as well.


| Variable                       | Location                        | Description                                                                              | Potentially affected services                                                                |
| ------------------------------ | ------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `NODE_RPC_SCHEME`              | `mavryk-accuser-<proto>`         | Scheme of the node RPC endpoint, e.g. `http`, `https`                                    | `mavryk-accuser-<proto>`                                                                      |
| `NODE_RPC_ADDR`                | `mavryk-accuser-<proto>`         | Address of the node RPC endpoint, e.g. `localhost:8732`, `node.example.org:8732`         | `mavryk-accuser-<proto>`                                                                      |
| `MAVRYK_CLIENT_DIR`             | `mavryk-accuser-<proto>`         | Path to the mavryk client data directory, e.g. `/var/lib/mavryk/.mavryk-client`             | `mavryk-accuser-<proto>`                                                                      |
| `MAVRYK_CLIENT_DIR`             | `mavryk-baker-<proto>`           | Mavryk client data directory, e.g. `/var/lib/mavryk/.mavryk-client`                         | `mavryk-baker-<proto>`                                                                        |
| `BAKER_ADDRESS_ALIAS`          | `mavryk-baker-<proto>`           | Alias of the address to be used for baking, e.g. `baker`                                 | `mavryk-baker-<proto>`                                                                        |
| `LIQUIDITY_BAKING_TOGGLE_VOTE` | `mavryk-baker-<proto>`           | Liquidity baking toggle vote to be cast while baking, e.g. `pass`, `on`, `off`           | `mavryk-baker-<proto>`                                                                        |
| `MAVRYK_NODE_DIR`               | `mavryk-baker-<proto>`           | Path to the mavryk node data directory, e.g. `/var/lib/mavryk/node`                        | `mavryk-baker-<proto>`                                                                        |
| `NODE_RPC_SCHEME`              | `mavryk-baker-<proto>`           | Scheme of the node RPC endpoint, e.g. `http`, `https`                                    | `mavryk-baker-<proto>`                                                                        |
| `NODE_RPC_ADDR`                | `mavryk-baker-<proto>`           | Address of the node RPC endpoint, e.g. `localhost:8732`, `node.example.org:8732`         | `mavryk-baker-<proto>`                                                                        |
| `MAVRYK_CLIENT_DIR`             | `mavryk-baking-custom@<network>` | Path to the mavryk client data directory, e.g. `/var/lib/mavryk/.mavryk-client`             | `mavryk-baking-custom@<network>`                                                              |
| `NODE_RPC_SCHEME`              | `mavryk-baking-custom@<network>` | Scheme of the node RPC endpoint, e.g. `http`, `https`                                    | `mavryk-baking-custom@<network>`                                                              |
| `BAKER_ADDRESS_ALIAS`          | `mavryk-baking-custom@<network>` | Alias of the address to be used for baking, e.g. `baker`.                                | `mavryk-baking-custom@<network>`                                                              |
| `LIQUIDITY_BAKING_TOGGLE_VOTE` | `mavryk-baking-custom@<network>` | Liquidity baking toggle vote to be cast while baking, e.g. `pass`, `on`, `off`           | `mavryk-baking-custom@<network>`                                                              |
| `MAVRYK_CLIENT_DIR`             | `mavryk-baking-<network>`        | Path to the mavryk client data directory, e.g. `/var/lib/mavryk/.mavryk-client`             | `mavryk-baking-<network>`, `mavryk-accuser-<proto>@<network>`, `mavryk-baker-<proto>@<network>` |
| `NODE_RPC_SCHEME`              | `mavryk-baking-<network>`        | Scheme of the node RPC endpoint, e.g. `http`, `https`                                    | `mavryk-baking-<network>`, `mavryk-accuser-<proto>@<network>`, `mavryk-baker-<proto>@<network>` |
| `BAKER_ADDRESS_ALIAS`          | `mavryk-baking-<network>`        | Alias of the address to be used for baking, e.g. `baker`.                                | `mavryk-baking-<network>`, `mavryk-accuser-<proto>@<network>`, `mavryk-baker-<proto>@<network>` |
| `LIQUIDITY_BAKING_TOGGLE_VOTE` | `mavryk-baking-<network>`        | Liquidity baking toggle vote to be cast while baking, e.g. `pass`, `on`, `off`           | `mavryk-baking-<network>`, `mavryk-accuser-<proto>@<network>`, `mavryk-baker-<proto>@<network>` |
| `NODE_RPC_ADDR`                | `mavryk-node-<network>`          | Address used by this node to serve the RPC, e.g. `127.0.0.1:8732`                        | `mavryk-node-<network>`, `mavryk-baking-<network>`, `mavryk-baker-<proto>@<network>`            |
| `CERT_PATH`                    | `mavryk-node-<network>`          | Path to the TLS certificate, e.g. `/var/lib/mavryk/.tls-certificate`                      | `mavryk-node-<network>`, `mavryk-baking-<network>`, `mavryk-baker-<proto>@<network>`            |
| `KEY_PATH`                     | `mavryk-node-<network>`          | Path to the TLS key, e.g. `/var/lib/mavryk/.tls-key`                                      | `mavryk-node-<network>`, `mavryk-baking-<network>`, `mavryk-baker-<proto>@<network>`            |
| `MAVRYK_NODE_DIR`               | `mavryk-node-<network>`          | Path to the mavryk node data directory, e.g. `/var/lib/mavryk/node`                        | `mavryk-node-<network>`, `mavryk-baking-<network>`, `mavryk-baker-<proto>@<network>`            |
| `NETWORK`                      | `mavryk-node-<network>`          | Name of the network that this node will run on, e.g. `mainnet`, `basenet`               | `mavryk-node-<network>`, `mavryk-baking-<network>`, `mavryk-baker-<proto>@<network>`            |
| `NODE_RPC_ADDR`                | `mavryk-node-custom@<network>`   | Address used by this node to serve the RPC, e.g. `127.0.0.1:8732`                        | `mavryk-baking-custom@<network>`, `mavryk-node-custom@<network>`                               |
| `CERT_PATH`                    | `mavryk-node-custom@<network>`   | Path to the TLS certificate, e.g. `/var/lib/mavryk/.tls-certificate`                      | `mavryk-baking-custom@<network>`, `mavryk-node-custom@<network>`                               |
| `KEY_PATH`                     | `mavryk-node-custom@<network>`   | Path to the TLS key, e.g. `/var/lib/mavryk/.tls-key`                                      | `mavryk-baking-custom@<network>`, `mavryk-node-custom@<network>`                               |
| `MAVRYK_NODE_DIR`               | `mavryk-node-custom@<network>`   | Path to the mavryk node data directory, e.g. `/var/lib/mavryk/node`                        | `mavryk-baking-custom@<network>`, `mavryk-node-custom@<network>`                               |
| `CUSTOM_NODE_CONFIG`           | `mavryk-node-custom@<network>`   | Path to the custom configuration file used by this node, e.g. `/var/lib/mavryk/node.json` | `mavryk-baking-custom@<network>`, `mavryk-node-custom@<network>`                               |
| `RESET_ON_STOP`                | `mavryk-node-custom@<network>`   | Whether the node should be reset when the node service is stopped, e.g. `true`           | `mavryk-baking-custom@<network>`, `mavryk-node-custom@<network>`                               |
| `MAVRYK_CLIENT_DIR`             | `mavryk-signer-<mode>`           | Path to the mavryk client data directory, e.g. `/var/lib/mavryk/.mavryk-client`             | `mavryk-signer-<mode>`                                                                        |
| `PIDFILE`                      | `mavryk-signer-<mode>`           | File in which to write the signer process id, e.g. `/var/lib/mavryk/.signer-pid`          | `mavryk-signer-<mode>`                                                                        |
| `MAGIC_BYTES`                  | `mavryk-signer-<mode>`           | Values allowed for the magic bytes.                                                      | `mavryk-signer-<mode>`                                                                        |
| `CHECK_HIGH_WATERMARK`         | `mavryk-signer-<mode>`           | Whether to apply the high watermark restriction or not, e.g. `true`                      | `mavryk-signer-<mode>`                                                                        |
| `CERT_PATH`                    | `mavryk-signer-http`             | Path to the TLS certificate, e.g. `/var/lib/mavryk/.tls-certificate`                      | `mavryk-signer-http`                                                                          |
| `KEY_PATH`                     | `mavryk-signer-http`             | Path to the TLS key, e.g. `/var/lib/mavryk/.tls-key`                                      | `mavryk-signer-http`                                                                          |
| `ADDRESS`                      | `mavryk-signer-http`             | Listening address or hostname for the signer, e.g. `localhost`                           | `mavryk-signer-http`                                                                          |
| `PORT`                         | `mavryk-signer-http`             | Listening HTTP port for the signer, e.g. `6732`                                          | `mavryk-signer-http`                                                                          |
| `CERT_PATH`                    | `mavryk-signer-https`            | Path to the TLS certificate, e.g. `/var/lib/mavryk/.tls-certificate`                      | `mavryk-signer-https`                                                                         |
| `KEY_PATH`                     | `mavryk-signer-https`            | Path to the TLS key, e.g. `/var/lib/mavryk/.tls-key`                                      | `mavryk-signer-https`                                                                         |
| `ADDRESS`                      | `mavryk-signer-https`            | Listening address or hostname for the signer, e.g. `localhost`                           | `mavryk-signer-https`                                                                         |
| `PORT`                         | `mavryk-signer-https`            | Listening HTTPS port for the signer, e.g. `443`                                          | `mavryk-signer-https`                                                                         |
| `ADDRESS`                      | `mavryk-signer-tcp`              | Listening address or hostname for the signer, e.g. `localhost`                           | `mavryk-signer-tcp`                                                                           |
| `PORT`                         | `mavryk-signer-tcp`              | Listening TCP port for the signer, e.g. `7732`                                           | `mavryk-signer-tcp`                                                                           |
| `TIMEOUT`                      | `mavryk-signer-tcp`              | Timeout used by the signer to close client connections (in seconds), e.g. `8`            | `mavryk-signer-tcp`                                                                           |
| `SOCKET`                       | `mavryk-signer-unix`             | Path to the local socket file, e.g. `/var/lib/mavryk/.mavryk-signer/socket`                | `mavryk-signer-unix`                                                                          |
| `MAVRYK_CLIENT_DIR`             | `mavryk-smart-rollup-node-<proto>`  | Path to the mavryk client data directory, e.g. `/var/lib/mavryk/.mavryk-client`             | `mavryk-smart-rollup-node-<proto>`                                                               |
| `NODE_RPC_SCHEME`              | `mavryk-smart-rollup-node-<proto>`  | Scheme of the node RPC endpoint, e.g. `http`, `https`                                    | `mavryk-smart-rollup-node-<proto>`                                                               |
| `NODE_RPC_ADDR`                | `mavryk-smart-rollup-node-<proto>`  | Address of the node RPC endpoint, e.g. `localhost:8732`, `node.example.org:8732`         | `mavryk-smart-rollup-node-<proto>`                                                               |
| `ROLLUP_NODE_RPC_ENDPOINT`     | `mavryk-smart-rollup-node-<proto>`  | Address of this rollup node RPC endpoint, e.g. `127.0.0.1:8472`                          | `mavryk-smart-rollup-node-<proto>`                                                               |
| `ROLLUP_MODE`                  | `mavryk-smart-rollup-node-<proto>`  | Rollup mode used by this node, e.g. `accuser`, `observer`, `batcher`                     | `mavryk-smart-rollup-node-<proto>`                                                               |
| `ROLLUP_ALIAS`                 | `mavryk-smart-rollup-node-<proto>`  | Alias of the address to be used for rollup, e.g. `rollup`                                | `mavryk-smart-rollup-node-<proto>`                                                               |
| `ROLLUP_OPERATORS`             | `mavryk-smart-rollup-node-<proto>`  | Operator address or alias for node operations in non-observer modes                     |`mavryk-smart-rollup-node-<proto>`|
| `ROLLUP_DATA_DIR`| `mavryk-smart-rollup-node-<proto>`  | Directory to store rollup data | `mavryk-smart-rollup-node-<proto>` |