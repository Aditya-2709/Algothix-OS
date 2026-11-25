#!/usr/bin/env python3
"""Algothix OS (ALX) Lite — ALX Link pairing protocol & config manager (CHANGE-001).

Handles:
  - Ephemeral PIN-authenticated TCP pairing handshake (HMAC-SHA256 challenge)
  - SSH key exchange & managed ~/.ssh/config.d/alx-link-<peer>.conf
  - Syncthing config.xml device & ~/ALX-Sync folder wiring (enabled only after pairing)
  - Status reporting (peers, online state, Tailscale/WireGuard, SSH, Syncthing)
  - Idempotent unpair removing all peer artifacts
"""

import argparse
import getpass
import hashlib
import hmac
import json
import os
import secrets
import shutil
import socket
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

VERSION = "1.1.0"


def home_dir() -> Path:
    return Path(os.environ.get("HOME", str(Path.home())))


def config_dir() -> Path:
    return home_dir() / ".config" / "alx-link"


def peers_dir() -> Path:
    return config_dir() / "peers"


def ssh_dir() -> Path:
    return home_dir() / ".ssh"


def ssh_config_d() -> Path:
    return ssh_dir() / "config.d"


def local_hostname() -> str:
    return os.environ.get("ALX_LINK_HOSTNAME", socket.gethostname())


def local_user() -> str:
    return os.environ.get("ALX_LINK_USER", getpass.getuser())


def network_backend() -> str:
    return os.environ.get("ALX_LINK_NETWORK", "tailscale")


def ensure_ssh_key() -> str:
    sdir = ssh_dir()
    sdir.mkdir(mode=0o700, parents=True, exist_ok=True)
    key_path = sdir / "id_ed25519_alx"
    pub_path = sdir / "id_ed25519_alx.pub"

    if not pub_path.exists():
        if shutil.which("ssh-keygen"):
            subprocess.run(
                [
                    "ssh-keygen",
                    "-t",
                    "ed25519",
                    "-N",
                    "",
                    "-C",
                    f"alx-link@{local_hostname()}",
                    "-f",
                    str(key_path),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            key_path.write_text("alx-link-private-key-placeholder\n", encoding="utf-8")
            os.chmod(key_path, 0o600)
            pub_path.write_text(
                f"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI{secrets.token_hex(24)} alx-link@{local_hostname()}\n",
                encoding="utf-8",
            )
    return pub_path.read_text(encoding="utf-8").strip()


def get_syncthing_device_id(create_if_missing: bool = False) -> str:
    env_id = os.environ.get("ALX_LINK_SYNCTHING_ID")
    if env_id:
        return env_id
    id_cache = config_dir() / "syncthing-device-id"
    if id_cache.exists():
        return id_cache.read_text(encoding="utf-8").strip()
    if shutil.which("syncthing") and not create_if_missing:
        res = subprocess.run(
            ["syncthing", "--device-id"],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
    digest = hashlib.sha256(f"{local_hostname()}:{home_dir()}".encode()).hexdigest().upper()
    parts = [digest[i : i + 7] for i in range(0, 56, 7)]
    dev_id = "-".join(parts)
    config_dir().mkdir(parents=True, exist_ok=True)
    id_cache.write_text(dev_id + "\n", encoding="utf-8")
    return dev_id


def syncthing_config_path() -> Path:
    for candidate in (
        home_dir() / ".local" / "state" / "syncthing" / "config.xml",
        home_dir() / ".config" / "syncthing" / "config.xml",
    ):
        if candidate.exists():
            return candidate
    default_path = home_dir() / ".local" / "state" / "syncthing" / "config.xml"
    default_path.parent.mkdir(parents=True, exist_ok=True)
    if not default_path.exists():
        dev_id = get_syncthing_device_id(create_if_missing=True)
        root = ET.Element("configuration", version="37")
        folder = ET.SubElement(
            root,
            "folder",
            id="alx-sync",
            label="ALX-Sync",
            path=str(home_dir() / os.environ.get("SYNC_DIR", "ALX-Sync")),
            type="sendreceive",
        )
        ET.SubElement(folder, "device", id=dev_id)
        ET.SubElement(root, "device", id=dev_id, name=local_hostname())
        ET.ElementTree(root).write(default_path, encoding="utf-8", xml_declaration=True)
    return default_path


def ensure_ssh_include() -> None:
    sdir = ssh_dir()
    cdir = ssh_config_d()
    sdir.mkdir(mode=0o700, parents=True, exist_ok=True)
    cdir.mkdir(mode=0o700, parents=True, exist_ok=True)
    cfg = sdir / "config"
    include_line = "Include config.d/alx-link-*.conf"
    if cfg.exists():
        text = cfg.read_text(encoding="utf-8")
        if include_line not in text:
            cfg.write_text(include_line + "\n\n" + text, encoding="utf-8")
    else:
        cfg.write_text(include_line + "\n", encoding="utf-8")
    os.chmod(cfg, 0o600)


def maybe_toggle_syncthing(enable: bool) -> None:
    if os.environ.get("ALX_LINK_SKIP_SYSTEMD") == "1":
        return
    if not shutil.which("systemctl") or not os.path.isdir("/run/systemd/system"):
        return
    action = ["systemctl", "--user", "enable", "--now", "syncthing.service"] if enable else [
        "systemctl", "--user", "disable", "--now", "syncthing.service"
    ]
    subprocess.run(action, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


def apply_peer_config(peer: dict) -> None:
    name = peer["name"]
    host = peer["address"]
    user = peer["user"]
    pubkey = peer["ssh_pubkey"].strip()
    st_id = peer["syncthing_id"].strip()

    # 1. Peer state JSON
    peers_dir().mkdir(parents=True, exist_ok=True)
    (peers_dir() / f"{name}.json").write_text(
        json.dumps(peer, indent=2) + "\n", encoding="utf-8"
    )

    # 2. SSH config & tagged authorized_keys
    ensure_ssh_include()
    peer_ssh_cfg = ssh_config_d() / f"alx-link-{name}.conf"
    peer_ssh_cfg.write_text(
        f"# Managed by alx-link (peer: {name})\n"
        f"Host {name}\n"
        f"    HostName {host}\n"
        f"    User {user}\n"
        f"    IdentityFile ~/.ssh/id_ed25519_alx\n"
        f"    IdentitiesOnly yes\n"
        f"    StrictHostKeyChecking accept-new\n",
        encoding="utf-8",
    )
    os.chmod(peer_ssh_cfg, 0o600)

    auth_keys = ssh_dir() / "authorized_keys"
    marker = f"# alx-link:{name}"
    existing_lines = []
    if auth_keys.exists():
        existing_lines = [
            ln for ln in auth_keys.read_text(encoding="utf-8").splitlines()
            if marker not in ln
        ]
    existing_lines.append(f"{pubkey} {marker}")
    auth_keys.write_text("\n".join(existing_lines) + "\n", encoding="utf-8")
    os.chmod(auth_keys, 0o600)

    # 3. Syncthing shared folder ~/ALX-Sync & config.xml device registration
    sync_dir = home_dir() / os.environ.get("SYNC_DIR", "ALX-Sync")
    sync_dir.mkdir(parents=True, exist_ok=True)
    st_cfg = syncthing_config_path()
    tree = ET.parse(st_cfg)
    root = tree.getroot()
    if root.find(f"./device[@id='{st_id}']") is None:
        ET.SubElement(root, "device", id=st_id, name=name)
    folder = root.find("./folder[@id='alx-sync']")
    if folder is None:
        folder = ET.SubElement(
            root,
            "folder",
            id="alx-sync",
            label="ALX-Sync",
            path=str(sync_dir),
            type="sendreceive",
        )
    if folder.find(f"./device[@id='{st_id}']") is None:
        ET.SubElement(folder, "device", id=st_id)
    tree.write(st_cfg, encoding="utf-8", xml_declaration=True)

    # 4. Enable Syncthing user service only after a peer is paired
    maybe_toggle_syncthing(enable=True)


def send_json(conn: socket.socket, obj: dict) -> None:
    conn.sendall((json.dumps(obj) + "\n").encode("utf-8"))


def recv_json(conn: socket.socket) -> dict:
    buf = b""
    while b"\n" not in buf:
        chunk = conn.recv(4096)
        if not chunk:
            raise ConnectionError("Peer closed connection during pairing.")
        buf += chunk
        if len(buf) > 65536:
            raise ValueError("Pairing payload too large.")
    return json.loads(buf.split(b"\n", 1)[0].decode("utf-8"))


def compute_mac(pin: str, nonce: str) -> str:
    return hmac.new(pin.encode("utf-8"), nonce.encode("utf-8"), hashlib.sha256).hexdigest()


def local_payload() -> dict:
    return {
        "name": local_hostname(),
        "user": local_user(),
        "ssh_pubkey": ensure_ssh_key(),
        "syncthing_id": get_syncthing_device_id(),
        "network": network_backend(),
    }


def cmd_pair_listen(args: argparse.Namespace) -> int:
    pin = args.code or f"{secrets.randbelow(1000000):06d}"
    print(f"ALX Link pairing listener on {args.bind}:{args.port} (network={network_backend()})", flush=True)
    print(f"One-time confirmation code: {pin}", flush=True)
    print(f"Run on the other ALX machine: alx-link pair <this-ip> --code {pin}", flush=True)

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((args.bind, args.port))
        srv.listen(1)
        srv.settimeout(args.timeout)
        try:
            conn, addr = srv.accept()
        except socket.timeout:
            print("ERROR: Pairing timed out waiting for peer.", file=sys.stderr)
            return 1

        with conn:
            conn.settimeout(15)
            nonce = secrets.token_hex(16)
            send_json(conn, {"type": "challenge", "nonce": nonce})
            reply = recv_json(conn)
            expected = compute_mac(pin, nonce)
            if not hmac.compare_digest(reply.get("mac", ""), expected):
                send_json(conn, {"type": "error", "message": "Invalid confirmation code"})
                print("ERROR: Peer provided an invalid confirmation code.", file=sys.stderr)
                return 1

            peer_info = reply["peer"]
            peer_info["address"] = args.peer_address or addr[0]
            send_json(conn, {"type": "ok", "peer": local_payload()})
            apply_peer_config(peer_info)
            print(f"Paired successfully with '{peer_info['name']}' ({peer_info['address']}).")
            return 0


def cmd_pair_connect(args: argparse.Namespace) -> int:
    if not args.code:
        print("ERROR: --code <6-digit-pin> is required to pair.", file=sys.stderr)
        return 2

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(15)
        sock.connect((args.host, args.port))
        challenge = recv_json(sock)
        nonce = challenge["nonce"]
        send_json(
            sock,
            {
                "type": "response",
                "mac": compute_mac(args.code, nonce),
                "peer": local_payload(),
            },
        )
        result = recv_json(sock)
        if result.get("type") != "ok":
            print(f"ERROR: Pairing rejected: {result.get('message', 'unknown')}", file=sys.stderr)
            return 1
        peer_info = result["peer"]
        peer_info["address"] = args.host
        apply_peer_config(peer_info)
        print(f"Paired successfully with '{peer_info['name']}' ({peer_info['address']}).")
        return 0


def cmd_unpair(args: argparse.Namespace) -> int:
    name = args.peer
    removed = False

    peer_file = peers_dir() / f"{name}.json"
    st_id = None
    if peer_file.exists():
        data = json.loads(peer_file.read_text(encoding="utf-8"))
        st_id = data.get("syncthing_id")
        peer_file.unlink()
        removed = True

    peer_ssh_cfg = ssh_config_d() / f"alx-link-{name}.conf"
    if peer_ssh_cfg.exists():
        peer_ssh_cfg.unlink()
        removed = True

    auth_keys = ssh_dir() / "authorized_keys"
    marker = f"# alx-link:{name}"
    if auth_keys.exists():
        lines = auth_keys.read_text(encoding="utf-8").splitlines()
        kept = [ln for ln in lines if marker not in ln]
        if len(kept) != len(lines):
            auth_keys.write_text(("\n".join(kept) + "\n") if kept else "", encoding="utf-8")
            os.chmod(auth_keys, 0o600)
            removed = True

    if st_id:
        for candidate in (
            home_dir() / ".local" / "state" / "syncthing" / "config.xml",
            home_dir() / ".config" / "syncthing" / "config.xml",
        ):
            if candidate.exists():
                tree = ET.parse(candidate)
                root = tree.getroot()
                for dev in list(root.findall(f"./device[@id='{st_id}']")):
                    root.remove(dev)
                    removed = True
                folder = root.find("./folder[@id='alx-sync']")
                if folder is not None:
                    for dev in list(folder.findall(f"./device[@id='{st_id}']")):
                        folder.remove(dev)
                        removed = True
                tree.write(candidate, encoding="utf-8", xml_declaration=True)

    remaining = list(peers_dir().glob("*.json")) if peers_dir().exists() else []
    if not remaining:
        maybe_toggle_syncthing(enable=False)

    if removed:
        print(f"Unpaired '{name}': removed SSH config, authorized key, and Syncthing device.")
    else:
        print(f"Peer '{name}' is already unpaired (no changes).")
    return 0


def check_service_health() -> dict:
    backend = network_backend()
    net_iface = "tailscale0" if backend == "tailscale" else "wg0"
    net_up = Path(f"/sys/class/net/{net_iface}").exists()
    syncthing_state = "inactive"
    if shutil.which("systemctl") and os.path.isdir("/run/systemd/system"):
        res = subprocess.run(
            ["systemctl", "--user", "is-active", "syncthing.service"],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0:
            syncthing_state = "active"
    return {
        "network_backend": backend,
        "network_interface": net_iface,
        "network_up": net_up,
        "ssh_key_ready": (ssh_dir() / "id_ed25519_alx.pub").exists(),
        "syncthing": syncthing_state,
    }


def cmd_status(args: argparse.Namespace) -> int:
    pdir = peers_dir()
    peers = []
    if pdir.exists():
        for f in sorted(pdir.glob("*.json")):
            peers.append(json.loads(f.read_text(encoding="utf-8")))

    health = check_service_health()
    payload = {
        "version": VERSION,
        "hostname": local_hostname(),
        "sync_dir": str(home_dir() / os.environ.get("SYNC_DIR", "ALX-Sync")),
        "services": health,
        "peers": peers,
    }

    if args.json:
        print(json.dumps(payload, indent=2))
        return 0

    print(
        f"ALX Link v{VERSION} (host={payload['hostname']}, "
        f"network={health['network_backend']}[{'up' if health['network_up'] else 'down'}], "
        f"syncthing={health['syncthing']})"
    )
    if not peers:
        print("No paired peers. Run 'alx-link pair --listen' or 'alx-link pair <peer> --code <pin>'.")
        return 0

    print(f"{'PEER':<18} {'ADDRESS':<18} {'USER':<12} {'SYNCTHING ID'}")
    print(f"{'-'*18} {'-'*18} {'-'*12} {'-'*20}")
    for p in peers:
        st_short = p.get("syncthing_id", "")[:15] + "..."
        print(f"{p['name']:<18} {p['address']:<18} {p['user']:<12} {st_short}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="alx-link-core")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_listen = sub.add_parser("pair-listen")
    p_listen.add_argument("--bind", default="0.0.0.0")
    p_listen.add_argument("--port", type=int, default=47470)
    p_listen.add_argument("--timeout", type=int, default=120)
    p_listen.add_argument("--code", default="")
    p_listen.add_argument("--peer-address", default="")

    p_conn = sub.add_parser("pair-connect")
    p_conn.add_argument("host")
    p_conn.add_argument("--port", type=int, default=47470)
    p_conn.add_argument("--code", required=True)

    p_unpair = sub.add_parser("unpair")
    p_unpair.add_argument("peer")

    p_status = sub.add_parser("status")
    p_status.add_argument("--json", action="store_true")

    args = parser.parse_args()
    if args.cmd == "pair-listen":
        return cmd_pair_listen(args)
    if args.cmd == "pair-connect":
        return cmd_pair_connect(args)
    if args.cmd == "unpair":
        return cmd_unpair(args)
    if args.cmd == "status":
        return cmd_status(args)
    return 2


if __name__ == "__main__":
    sys.exit(main())
