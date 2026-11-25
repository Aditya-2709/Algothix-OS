# Algothix OS (ALX) Lite — User Guide (v1.1)

Algothix OS (ALX) Lite is a fast, terminal-first Debian 13 (`trixie`) coding OS tuned for 2–4 GB RAM x86_64 laptops.

> **Hardware tip:** ALX Lite runs on spinning HDDs with zram and BFQ scheduling, but upgrading an old laptop to an inexpensive SATA SSD is the single highest-impact speed upgrade you can make.

## 1. Installing from USB

1. Verify the downloaded ISO checksum:
   ```bash
   sha256sum -c SHA256SUMS
   ```
2. Flash the ISO to a USB stick (with Rufus in **DD Image mode** on Windows, or `dd` on Linux).
3. Boot from USB (BIOS or UEFI, Secure Boot OFF). If an older Intel GMA laptop shows a black screen, select **Safe Graphics (nomodeset)** from the boot menu.
4. Launch **Install Algothix OS (ALX) Lite** (`alx-calamares-launch`). Guided partitioning uses `ext4` with `noatime,commit=60`. On CPUs without AES-NI, LUKS encryption is automatically disabled.

## 2. Awesome WM Desktop Basics

- `Super + Enter` — Open terminal (`urxvt`)
- `Super + d` — Application launcher (`rofi`)
- `Super + e` — File manager (`pcmanfm`)
- `Super + ?` — Open the keybinding cheat-sheet (`alx-cheatsheet`)
- `Super + 1..5` — Switch tag (`1:term`, `2:code`, `3:web`, `4:ops`, `5:misc`)
- `Super + Shift + q` — Close focused window
- `Super + Shift + r` — Reload Awesome WM

## 3. Developer Toolchains & Optional Tools (`alx-setup`)

Install language stacks or optional cross-device tools on demand with cost estimates:

```bash
alx-setup list
alx-setup python --dry-run
alx-setup python
alx-setup localsend    # Optional Flutter LAN sharing (alx-profile-mid recommended)
alx-setup kdeconnect   # Optional minimal phone integration (LAN auto-discovery only)
```

## 4. Cross-Device Workspace (`alx-link`)

Pair two ALX laptops over **Tailscale** (default) or **WireGuard** (`network=wireguard` in `/etc/alx/link.conf`):

- On Laptop A: `alx-link pair --listen`
- On Laptop B: `alx-link pair <laptop-a-ip> --code <6-digit-pin>`

After pairing:
- `ssh <peer>` — Passwordless `ed25519` SSH
- `~/ALX-Sync` — Syncthing folder (runs at `Nice=10` / idle I/O priority, enabled only after pairing)
- `alx-link send <file> [peer]` — Taildrop (`tailscale file cp`) on Tailscale; `rsync`/`scp` over SSH on WireGuard
- `alx-link clip [peer]` — Push X11 clipboard text to peer over SSH
- `alx-link notify <peer> <msg>` — Send desktop notification (`notify-send`) to peer over SSH
- `alx-link run <peer> -- make -j4` — Offload builds inside remote `tmux`
- `alx-link status` / `alx-link unpair <peer>` — Check health or cleanly remove a peer

## 5. Health & Updates (`alx-doctor`, `alx-tune`, `alx-update`)

- `alx-doctor` (or `alx-doctor --json`) — Check profile, RAM, zram, `earlyoom`, disk, failed units, and top memory users.
- `sudo alx-tune --enable bluetooth` — Re-enable a disabled service (`bluetooth`, `cups`, `modem`, `avahi`).
- `sudo alx-update` — Updates packages when on AC power and idle.
