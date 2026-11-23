# Algothix OS (ALX) Lite — User Guide

Algothix OS (ALX) Lite is a fast, terminal-first Debian 13 (`trixie`) coding OS tuned for 2–4 GB RAM x86_64 laptops.

> **Hardware tip:** ALX Lite runs on spinning HDDs with zram and BFQ scheduling, but upgrading an old laptop to an inexpensive SATA SSD is the single highest-impact speed upgrade you can make.

## 1. Installing from USB

1. Verify the downloaded ISO checksum:
   ```bash
   sha256sum -c SHA256SUMS
   ```
2. Flash the ISO to a USB stick (replace `/dev/sdX` with your USB device):
   ```bash
   sudo dd if=algothix-os-lite-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
3. Boot from USB (BIOS or UEFI). If an older Intel GMA laptop shows a black screen, select **Safe Graphics (nomodeset)** from the boot menu.
4. Launch **Install Algothix OS (ALX) Lite** (`alx-calamares-launch`). Guided partitioning uses `ext4` with `noatime,commit=60`. On CPUs without AES-NI, disk encryption is automatically disabled to avoid heavy CPU slowdowns.

## 2. ALX-i3 Desktop Basics

- `Super + Enter` — Open terminal (`urxvt`)
- `Super + d` — Application launcher (`rofi`)
- `Super + e` — File manager (`pcmanfm`)
- `Super + ?` — Open the keybinding cheat-sheet (`alx-cheatsheet`)
- `Super + 1..9` — Switch workspace (`1:term`, `2:code`, `3:web`)
- `Super + Shift + q` — Close focused window

## 3. Developer Toolchains (`alx-setup`)

ALX Lite ships with `git`, `build-essential`, `clang`, `cmake`, `gdb`, `neovim`, `micro`, `geany`, `tmux`, `zsh`, `lazygit`, `ripgrep`, `fzf`, `bat`, `fd`, `podman` (rootless), and `firefox-esr`.

Install additional language stacks on demand with cost estimates:

```bash
alx-setup list
alx-setup python --dry-run
alx-setup python
```

Available profiles: `python`, `node`, `go`, `rust`, `web`, `cpp`, `java`, and optional `editor-vscodium`.

## 4. Cross-Device Workspace (`alx-link`)

Pair two ALX laptops over LAN, WireGuard, or Tailscale:

- On Laptop A:
  ```bash
  alx-link pair --listen
  ```
- On Laptop B (enter the 6-digit confirmation code shown on Laptop A):
  ```bash
  alx-link pair <laptop-a-ip> --code <6-digit-pin>
  ```

After pairing:
- `ssh <peer>` — Passwordless ed25519 SSH
- `~/ALX-Sync` — Automatic Syncthing folder (runs at idle I/O priority)
- `alx-link send <file> <peer>` — Quick file transfer
- `alx-link clip <peer>` — Push X11 clipboard text to peer
- `alx-link run <peer> -- make -j4` — Offload heavy builds to a faster laptop inside `tmux`
- `alx-link status` / `alx-link unpair <peer>` — Inspect or cleanly remove a peer

## 5. Health & Updates (`alx-doctor`, `alx-tune`, `alx-update`)

- `alx-doctor` (or `alx-doctor --json`) — Check hardware profile, RAM, zram, `earlyoom`, disk space, failed units, and top memory processes.
- `sudo alx-tune --enable bluetooth` — Re-enable a disabled service (`bluetooth`, `cups`, `modem`, `avahi`).
- `sudo alx-update` — Updates packages when on AC power and idle (use `--force` to override).
