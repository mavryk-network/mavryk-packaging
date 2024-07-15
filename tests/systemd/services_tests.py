# SPDX-FileCopyrightText: 2022 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

from pystemd.systemd1 import Unit
from subprocess import CalledProcessError
from time import sleep
from typing import List

from mavryk_baking.wizard_structure import (
    get_key_address,
    proc_call,
    replace_systemd_service_env,
    url_is_reachable,
)

import contextlib
import os.path


@contextlib.contextmanager
def unit(service_name: str):
    unit = Unit(service_name.encode(), _autoload=True)
    unit.Unit.Start("replace")
    while unit.Unit.ActiveState == b"activating":
        sleep(1)
    try:
        yield unit
    finally:
        unit.Unit.Stop("replace")
        while unit.Unit.ActiveState not in [b"failed", b"inactive"]:
            sleep(1)


@contextlib.contextmanager
def account(alias: str):
    # Generate baker key
    proc_call(f"sudo -u tezos mavkit-client gen keys {alias} --force")
    try:
        yield alias
    finally:
        proc_call(f"sudo -u tezos mavkit-client forget address {alias} --force")


def retry(action, name: str, retry_count: int = 20) -> bool:
    if action(name):
        return True
    elif retry_count == 0:
        return False
    else:
        sleep(5)
        return retry(action, name, retry_count - 1)


def check_running_process(process_name: str) -> bool:
    def check_process(process_name):
        try:
            proc_call(f"pgrep -f {process_name}")
            return True
        except CalledProcessError:
            return False

    return retry(check_process, process_name)


def check_active_service(service_name: str) -> bool:
    def check_service(service_name):
        try:
            proc_call(f"systemctl is-active --quiet {service_name}")
            return True
        except CalledProcessError:
            return False

    return retry(check_service, service_name)


def generate_identity(network):
    if not os.path.exists(f"/var/lib/mavryk/{network}/identity.json"):
        proc_call(
            f"sudo -u tezos mavkit-node identity generate 1 --data-dir /var/lib/mavryk/{network}"
        )


def node_service_test(network: str, rpc_endpoint="http://127.0.0.1:8732"):
    generate_identity(network)
    with unit(f"mavryk-node-{network}.service") as _:
        # checking that service started 'mavryk-node' process
        assert check_running_process("mavkit-node")
        # checking that node is able to respond on RPC requests
        assert retry(url_is_reachable, f"{rpc_endpoint}/chains/main/blocks/head")


def baking_service_test(network: str, protocols: List[str], baker_alias="baker"):
    with account(baker_alias) as _:
        generate_identity(network)
        with unit(f"mavryk-baking-{network}.service") as _:
            assert check_active_service(f"mavryk-node-{network}.service")
            assert check_running_process("mavkit-node")
            for protocol in protocols:
                assert check_active_service(
                    f"mavryk-baker-{protocol.lower()}@{network}.service"
                )
                assert check_running_process(f"mavkit-baker-{protocol}")


signer_unix_socket = '"/tmp/signer-socket"'

signer_backends = {
    "http": "http://localhost:8080/",
    "tcp": "tcp://localhost:8000/",
    "unix": f"unix:{signer_unix_socket}?pkh=",
}


def signer_service_test(service_type: str):
    with unit(f"mavryk-signer-{service_type}.service") as _:
        assert check_running_process(f"mavkit-signer")
        proc_call(
            "sudo -u tezos mavkit-signer -d /var/lib/mavryk/signer gen keys remote --force"
        )
        remote_key = get_key_address("-d /var/lib/mavryk/signer", "remote")[1]
        proc_call(
            f"mavkit-client import secret key remote-signer {signer_backends[service_type]}{remote_key} --force"
        )
        proc_call("mavkit-client --mode mockup sign bytes 0x1234 for remote-signer")


def test_node_mainnet_service():
    node_service_test("mainnet")


def test_baking_mainnet_service():
    baking_service_test("mainnet")


def test_node_boreasnet_service():
    node_service_test("boreasnet")


def test_baking_boreasnet_service():
    baking_service_test("boreasnet", ["PtBoreas"])


def test_http_signer_service():
    signer_service_test("http")


def test_tcp_signer_service():
    signer_service_test("tcp")


def test_standalone_accuser_service():
    with unit(f"mavryk-node-boreasnet.service") as _:
        with unit(f"mavryk-accuser-ptboreas.service") as _:
            assert check_running_process(f"mavkit-accuser-PtBoreas")


def test_unix_signer_service():
    replace_systemd_service_env("mavryk-signer-unix", "SOCKET", signer_unix_socket)
    signer_service_test("unix")


def test_standalone_baker_service():
    replace_systemd_service_env(
        "mavryk-baker-ptboreas",
        "MAVRYK_NODE_DIR",
        "/var/lib/mavryk/node-boreasnet",
    )
    with account("baker") as _:
        with unit(f"mavryk-node-boreasnet.service") as _:
            with unit(f"mavryk-baker-ptboreas.service") as _:
                assert check_active_service(f"mavryk-baker-ptboreas.service")
                assert check_running_process(f"mavkit-baker-PtBoreas")


def test_nondefault_node_rpc_endpoint():
    rpc_addr = "127.0.0.1:8735"
    replace_systemd_service_env("mavryk-node-boreasnet", "NODE_RPC_ADDR", rpc_addr)
    proc_call("cat /etc/default/mavryk-node-boreasnet")
    try:
        node_service_test("boreasnet", f"http://{rpc_addr}")
    finally:
        replace_systemd_service_env(
            "mavryk-node-boreasnet", "NODE_RPC_ADDR", "127.0.0.1:8732"
        )


def test_nondefault_baking_config():
    replace_systemd_service_env(
        "mavryk-baking-boreasnet", "BAKER_ADDRESS_ALIAS", "another_baker"
    )
    replace_systemd_service_env(
        "mavryk-baking-boreasnet", "LIQUIDITY_BAKING_TOGGLE_VOTE", "on"
    )
    baking_service_test("boreasnet", ["PtBoreas"], "another_baker")
