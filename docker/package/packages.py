# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA
import os, json, stat

from .meta import packages_meta

from .model import (
    AdditionalScript,
    MavrykBinaryPackage,
    MavrykSaplingParamsPackage,
    MavrykBakingServicesPackage,
)

from .systemd import Service, ServiceFile, SystemdUnit, Unit, Install
from collections import ChainMap

# Testnets are either supported by the mavryk-node directly or have known URL with
# the config
networks = {
    "mainnet": "mainnet",
    "basenet": "basenet",
    "boreasnet": "https://testnets.mavryk.network/basenet",
}
networks_protos = {
    "mainnet": ["PtBoreas"],
    "basenet": ["PtBoreas"],
    "boreasnet": ["PtBoreas"],
}

protocol_numbers = {
    "PtAtLas": "001",
    "PtBoreas": "002",
}

signer_units = [
    SystemdUnit(
        ServiceFile(
            Unit(
                after=["network.target"],
                description="Mavryk signer daemon running over TCP socket",
            ),
            Service(
                environment_files=["/etc/default/mavryk-signer-tcp"],
                exec_start="/usr/bin/mavryk-signer-start launch socket signer "
                + " --address ${ADDRESS} --port ${PORT} --timeout ${TIMEOUT}",
                state_directory="mavryk",
                user="mavryk",
            ),
            Install(wanted_by=["multi-user.target"]),
        ),
        suffix="tcp",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf",
        config_file_append=['ADDRESS="127.0.0.1"', 'PORT="8000"', 'TIMEOUT="1"'],
    ),
    SystemdUnit(
        ServiceFile(
            Unit(
                after=["network.target"],
                description="Mavryk signer daemon running over UNIX socket",
            ),
            Service(
                environment_files=["/etc/default/mavryk-signer-unix"],
                exec_start="/usr/bin/mavryk-signer-start launch local signer "
                + "--socket ${SOCKET}",
                state_directory="mavryk",
                user="mavryk",
            ),
            Install(wanted_by=["multi-user.target"]),
        ),
        suffix="unix",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf",
        config_file_append=['SOCKET=""'],
    ),
    SystemdUnit(
        ServiceFile(
            Unit(
                after=["network.target"],
                description="Mavryk signer daemon running over HTTP",
            ),
            Service(
                environment_files=["/etc/default/mavryk-signer-http"],
                exec_start="/usr/bin/mavryk-signer-start launch http signer "
                + "--address ${ADDRESS} --port ${PORT}",
                state_directory="mavryk",
                user="mavryk",
            ),
            Install(wanted_by=["multi-user.target"]),
        ),
        suffix="http",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf",
        config_file_append=[
            'CERT_PATH="',
            'KEY_PATH=""',
            'ADDRESS="127.0.0.1"',
            'PORT="8080"',
        ],
    ),
    SystemdUnit(
        ServiceFile(
            Unit(
                after=["network.target"],
                description="Mavryk signer daemon running over HTTPs",
            ),
            Service(
                environment_files=["/etc/default/mavryk-signer-https"],
                exec_start="/usr/bin/mavryk-signer-start launch https signer "
                + "${CERT_PATH} ${KEY_PATH} --address ${ADDRESS} --port ${PORT}",
                state_directory="mavryk",
                user="mavryk",
            ),
            Install(wanted_by=["multi-user.target"]),
        ),
        suffix="https",
        startup_script="mavryk-signer-start",
        config_file="mavryk-signer.conf",
        config_file_append=[
            'CERT_PATH="',
            'KEY_PATH=""',
            'ADDRESS="127.0.0.1"',
            'PORT="8080"',
        ],
    ),
]

postinst_steps_common = """
if [ -z $(getent passwd mavryk) ]; then
    useradd -r -s /bin/false -m -d /var/lib/mavryk mavryk
    chmod 0755 /var/lib/mavryk
fi
"""

ledger_udev_postinst = open(
    f"{os.path.dirname(__file__)}/scripts/udev-rules", "r"
).read()

packages = [
    {
        "mavryk-client": MavrykBinaryPackage(
            "mavryk-client",
            "CLI client for interacting with mavryk blockchain",
            meta=packages_meta,
            additional_native_deps=["mavryk-sapling-params", "udev"],
            postinst_steps=postinst_steps_common + ledger_udev_postinst,
            dune_filepath="src/bin_client/main_client.exe",
        )
    },
    {
        "mavryk-admin-client": MavrykBinaryPackage(
            "mavryk-admin-client",
            "Administration tool for the node",
            meta=packages_meta,
            dune_filepath="src/bin_client/main_admin.exe",
        )
    },
    {
        "mavryk-signer": MavrykBinaryPackage(
            "mavryk-signer",
            "A client to remotely sign operations or blocks",
            meta=packages_meta,
            additional_native_deps=["udev"],
            systemd_units=signer_units,
            postinst_steps=postinst_steps_common + ledger_udev_postinst,
            dune_filepath="src/bin_signer/main_signer.exe",
        )
    },
    {
        "mavryk-codec": MavrykBinaryPackage(
            "mavryk-codec",
            "A client to decode and encode JSON",
            meta=packages_meta,
            dune_filepath="src/bin_codec/codec.exe",
        )
    },
    {
        "mavryk-dac-client": MavrykBinaryPackage(
            "mavryk-dac-client",
            "A Data Availability Committee Mavryk client",
            meta=packages_meta,
            dune_filepath="src/bin_dac_client/main_dac_client.exe",
        )
    },
    {
        "mavryk-dac-node": MavrykBinaryPackage(
            "mavryk-dac-node",
            "A Data Availability Committee Mavryk node",
            meta=packages_meta,
            dune_filepath="src/bin_dac_node/main_dac.exe",
        )
    },
    {
        "mavryk-dal-node": MavrykBinaryPackage(
            "mavryk-dal-node",
            "A Data Availability Layer Mavryk node",
            meta=packages_meta,
            dune_filepath="src/bin_dal_node/main.exe",
        )
    },
    {
        "mavryk-smart-rollup-wasm-debugger": MavrykBinaryPackage(
            "mavryk-smart-rollup-wasm-debugger",
            "Smart contract rollup wasm debugger",
            meta=packages_meta,
            dune_filepath="src/bin_wasm_debugger/main_wasm_debugger.exe",
        )
    },
]


def mk_node_unit(
    suffix,
    config_file_append,
    desc,
    instantiated=False,
    dependencies_suffix=None,
):
    dependencies_suffix = suffix if dependencies_suffix is None else dependencies_suffix
    service_file = ServiceFile(
        Unit(
            after=["network.target", f"mavryk-baking-{dependencies_suffix}.service"],
            requires=[],
            description=desc,
            part_of=[f"mavryk-baking-{dependencies_suffix}.service"],
        ),
        Service(
            environment_files=[f"/etc/default/mavryk-node-{dependencies_suffix}"],
            exec_start="/usr/bin/mavryk-node-start",
            exec_start_pre=["/usr/bin/mavryk-node-prestart"],
            timeout_start_sec="2400s",
            state_directory="mavryk",
            user="mavryk",
            type_="notify",
            notify_access="all",
        ),
        Install(wanted_by=["multi-user.target"]),
    )
    return SystemdUnit(
        suffix=suffix,
        service_file=service_file,
        startup_script="mavryk-node-start",
        prestart_script="mavryk-node-prestart",
        instances=[] if instantiated else None,
        config_file="mavryk-node.conf",
        config_file_append=config_file_append,
    )


node_units = []
node_postinst_steps = postinst_steps_common
node_additional_scripts = []
for network, network_config in networks.items():
    config_file_append = [
        f'MAVRYK_NODE_DIR="/var/lib/mavryk/node-{network}"',
        f'NETWORK="{network_config}"',
    ]
    node_units.append(
        mk_node_unit(
            suffix=network,
            config_file_append=config_file_append,
            desc=f"Mavryk node {network}",
        )
    )
    node_additional_scripts.append(
        AdditionalScript(
            name=f"mavkit-node-{network}",
            symlink_name=f"mavryk-node-{network}",
            local_file_name="mavkit-node-wrapper",
            transform=lambda x, network=network: x.replace("{network}", network),
        )
    )
    node_postinst_steps += f"""
mkdir -p /var/lib/mavryk/node-{network}
[ ! -f /var/lib/mavryk/node-{network}/config.json ] && mavkit-node config init --data-dir /var/lib/mavryk/node-{network} --network {network_config}
chown -R mavryk:mavryk /var/lib/mavryk/node-{network}
"""

# Add custom config service
custom_node_unit = mk_node_unit(
    suffix="custom",
    config_file_append=[
        'MAVRYK_NODE_DIR="/var/lib/mavryk/node-custom"',
        'CUSTOM_NODE_CONFIG=""',
    ],
    desc="Mavryk node with custom config",
)
custom_node_unit.poststop_script = "mavryk-node-custom-poststop"
node_units.append(custom_node_unit)
node_postinst_steps += "mkdir -p /var/lib/mavryk/node-custom\n"
# Add instantiated custom config service
custom_node_instantiated = mk_node_unit(
    suffix="custom",
    config_file_append=[
        "MAVRYK_NODE_DIR=/var/lib/mavryk/node-custom@%i",
        "CUSTOM_NODE_CONFIG=",
        'RESET_ON_STOP=""',
    ],
    desc="Mavryk node with custom config",
    instantiated=True,
    dependencies_suffix="custom@%i",
)
custom_node_instantiated.poststop_script = "mavryk-node-custom-poststop"
node_units.append(custom_node_instantiated)


packages.append(
    {
        "mavryk-node": MavrykBinaryPackage(
            "mavryk-node",
            "Entry point for initializing, configuring and running a Mavryk node",
            meta=packages_meta,
            systemd_units=node_units,
            postinst_steps=node_postinst_steps,
            additional_native_deps=[
                "mavryk-sapling-params",
                "curl",
                {"ubuntu": "netbase"},
            ],
            additional_scripts=node_additional_scripts,
            dune_filepath="src/bin_node/main.exe",
        )
    }
)

protocols_json = json.load(
    open(f"{os.path.dirname( __file__)}/../../protocols.json", "r")
)

active_protocols = protocols_json["active"]

daemons = ["baker", "accuser"]

daemon_decs = {
    "baker": "daemon for baking",
    "accuser": "daemon for accusing",
}

daemon_postinst_common = (
    postinst_steps_common
    + """
mkdir -p /var/lib/mavryk/.mavryk-client
chown -R mavryk:mavryk /var/lib/mavryk/.mavryk-client
"""
)


for proto in active_protocols:
    proto_snake_case = protocol_numbers[proto] + "_" + proto
    daemons_instances = [
        network for network, protos in networks_protos.items() if proto in protos
    ]
    baker_startup_script = f"/usr/bin/mavryk-baker-{proto.lower()}-start"
    accuser_startup_script = f"/usr/bin/mavryk-accuser-{proto.lower()}-start"
    service_file_baker = ServiceFile(
        Unit(after=["network.target"], description="Mavryk baker"),
        Service(
            # The node settings for a generic baker are defined in its own
            # 'EnvironmentFile', as we can't tell the network from the protocol
            # alone, nor what node this might connect to
            environment_files=[f"/etc/default/mavryk-baker-{proto}"],
            environment=[f"PROTOCOL={proto}"],
            exec_start_pre=[
                "+/usr/bin/setfacl -m u:mavryk:rwx /run/systemd/ask-password"
            ],
            exec_start=baker_startup_script,
            exec_stop_post=["+/usr/bin/setfacl -x u:mavryk /run/systemd/ask-password"],
            state_directory="mavryk",
            user="mavryk",
            type_="forking",
            keyring_mode="shared",
        ),
        Install(wanted_by=["multi-user.target"]),
    )
    service_file_baker_instantiated = ServiceFile(
        Unit(
            after=[
                "network.target",
                "mavryk-node-%i.service",
                "mavryk-baking-%i.service",
            ],
            requires=["mavryk-node-%i.service"],
            part_of=["mavryk-baking-%i.service"],
            description="Instantiated mavryk baker daemon service",
        ),
        Service(
            environment_files=[
                "/etc/default/mavryk-baking-%i",
                "/etc/default/mavryk-node-%i",
            ],
            environment=[f"PROTOCOL={proto}"],
            exec_start=baker_startup_script,
            state_directory="mavryk",
            user="mavryk",
            restart="on-failure",
            type_="forking",
            keyring_mode="shared",
        ),
        Install(wanted_by=["multi-user.target"]),
    )
    service_file_accuser = ServiceFile(
        Unit(after=["network.target"], description="Mavryk accuser"),
        Service(
            environment_files=[f"/etc/default/mavryk-accuser-{proto}"],
            environment=[f"PROTOCOL={proto}"],
            exec_start=accuser_startup_script,
            state_directory="mavryk",
            user="mavryk",
        ),
        Install(wanted_by=["multi-user.target"]),
    )
    service_file_accuser_instantiated = ServiceFile(
        Unit(
            after=[
                "network.target",
                "mavryk-node-%i.service",
                "mavryk-baking-%i.service",
            ],
            requires=["mavryk-node-%i.service"],
            part_of=["mavryk-baking-%i.service"],
            description="Instantiated mavryk accuser daemon service",
        ),
        Service(
            environment_files=["/etc/default/mavryk-baking-%i"],
            environment=[f"PROTOCOL={proto}"],
            exec_start=accuser_startup_script,
            state_directory="mavryk",
            user="mavryk",
            restart="on-failure",
        ),
        Install(wanted_by=["multi-user.target"]),
    )
    packages.append(
        {
            f"mavryk-baker-{proto}": MavrykBinaryPackage(
                f"mavryk-baker-{proto}",
                "Daemon for baking",
                meta=packages_meta,
                systemd_units=[
                    SystemdUnit(
                        service_file=service_file_baker,
                        startup_script=baker_startup_script.split("/")[-1],
                        startup_script_source="mavryk-baker-start",
                        config_file="mavryk-baker.conf",
                    ),
                    SystemdUnit(
                        service_file=service_file_baker_instantiated,
                        startup_script=baker_startup_script.split("/")[-1],
                        startup_script_source="mavryk-baker-start",
                        instances=daemons_instances,
                    ),
                ],
                target_proto=proto,
                postinst_steps=daemon_postinst_common,
                additional_native_deps=[
                    "mavryk-sapling-params",
                    "mavryk-client",
                    "acl",
                    "udev",
                ],
                dune_filepath=f"src/proto_{proto_snake_case}/bin_baker/main_baker_{proto_snake_case}.exe",
            )
        }
    )
    packages.append(
        {
            f"mavryk-accuser-{proto}": MavrykBinaryPackage(
                f"mavryk-accuser-{proto}",
                "Daemon for accusing",
                meta=packages_meta,
                systemd_units=[
                    SystemdUnit(
                        service_file=service_file_accuser,
                        startup_script=accuser_startup_script.split("/")[-1],
                        startup_script_source="mavryk-accuser-start",
                        config_file="mavryk-accuser.conf",
                    ),
                    SystemdUnit(
                        service_file=service_file_accuser_instantiated,
                        startup_script=accuser_startup_script.split("/")[-1],
                        startup_script_source="mavryk-accuser-start",
                        instances=daemons_instances,
                    ),
                ],
                target_proto=proto,
                additional_native_deps=["udev"],
                postinst_steps=daemon_postinst_common,
                dune_filepath=f"src/proto_{proto_snake_case}/bin_accuser/main_accuser_{proto_snake_case}.exe",
            )
        }
    )

packages.append(
    {
        "mavryk-sapling-params": MavrykSaplingParamsPackage(
            meta=packages_meta,
            params_revision="3ef5c6bed966e0e5b15ec7152bb32dbd85ff7e3b",
        )
    }
)

packages.append(
    {
        "mavryk-baking": MavrykBakingServicesPackage(
            target_networks=networks.keys(),
            network_protos=networks_protos,
            meta=packages_meta,
            additional_native_deps=[
                f"mavryk-baker-{proto}" for proto in active_protocols
            ]
            + ["mavryk-node", "acl", "wget"],
        )
    }
)


def mk_rollup_node():
    startup_script = f"/usr/bin/mavryk-smart-rollup-node-start"
    service_file = ServiceFile(
        Unit(after=["network.target"], description=f"Mavryk smart rollup node"),
        Service(
            environment_files=[f"/etc/default/mavryk-smart-rollup-node"],
            exec_start_pre=[
                "+/usr/bin/setfacl -m u:mavryk:rwx /run/systemd/ask-password"
            ],
            exec_start=startup_script,
            exec_stop_post=["+/usr/bin/setfacl -x u:mavryk /run/systemd/ask-password"],
            state_directory="mavryk",
            user="mavryk",
            type_="simple",
            keyring_mode="shared",
        ),
        Install(wanted_by=["multi-user.target"]),
    )
    systemd_units = [
        SystemdUnit(
            service_file=service_file,
            startup_script=startup_script.split("/")[-1],
            startup_script_source="mavryk-rollup-node-start",
            config_file="mavryk-rollup-node.conf",
        ),
    ]

    return {
        f"mavryk-smart-rollup-node": MavrykBinaryPackage(
            f"mavryk-smart-rollup-node",
            f"Mavryk smart rollup node",
            meta=packages_meta,
            systemd_units=systemd_units,
            additional_native_deps=[
                "mavryk-client",
                "mavryk-node",
                "mavryk-sapling-params",
            ],
            postinst_steps=daemon_postinst_common,
            dune_filepath="src/bin_smart_rollup_node/main_smart_rollup_node.exe",
        )
    }


packages.append(mk_rollup_node())

packages = dict(ChainMap(*packages))
