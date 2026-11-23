# Engineering Decisions Log (ALX Lite)

This file records architectural choices, defaults chosen from the PRD, and any deviations made during implementation.

---

## DEC-001: Base distribution — Debian 13 (`trixie`) amd64
- **Milestone:** M0 / M1
- **Decision:** Target Debian 13 (`trixie`, current Debian stable) `amd64` with archive areas `main non-free-firmware`.
- **Rationale:** Matches PRD Section 5 and Section 13 default. All `alx-base` and build-tool packages (`live-build`, `debootstrap`, `reprepro`, `zram-tools`, `earlyoom`, `ufw`, `unattended-upgrades`, `apparmor`, `ovmf`, `qemu-system-x86`, `bats`, `shellcheck`, `lintian`, and `firmware-*` packages) were verified to exist in Debian `trixie`.
- **Fallback:** If a `live-build` blocker appears during build on `trixie`, fall back to `bookworm` by overriding `ALX_DEBIAN_DIST=bookworm` in `auto/config` and recording the blocker here.

## DEC-002: Non-free firmware inclusion
- **Milestone:** M1
- **Decision:** Include `non-free-firmware` archive area and ship `firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`, and `firmware-misc-nonfree` alongside `firmware-linux-free`.
- **Rationale:** Per PRD Section 13 (Risks), target laptops (Dell Vostro 1015, ASUS X541NA) require binary firmware for Intel/Realtek/Atheros Wi-Fi and Ethernet chips. Including `non-free-firmware` is the PRD default so live and installed sessions have working networking out of the box.

## DEC-003: Local APT repository tool — `reprepro`
- **Milestone:** M0
- **Decision:** Use `reprepro` to publish locally built `.deb` packages into `build/repo`, and copy built `.deb` files into `config/packages.chroot/` during `make iso`.
- **Rationale:** `reprepro` is lightweight, stateless-friendly (single directory, no daemon), and available in Debian `trixie`. Copying `.deb` files into `config/packages.chroot/` keeps offline/local chroot installation simple while `build/repo` establishes the apt repository structure required for M7/M8 fleet distribution.

## DEC-004: Bootloaders and serial console parameters
- **Milestone:** M1
- **Decision:** Configure `live-build` with `--bootloaders "syslinux,grub-efi"` (`iso-hybrid`) and append `console=tty0 console=ttyS0,115200n8` to the default live kernel command line. Include a `nomodeset` fallback entry in both ISOLINUX and GRUB menus.
- **Rationale:** `syslinux` (ISOLINUX) provides BIOS boot and `grub-efi` provides UEFI boot in a single hybrid ISO. Adding `console=ttyS0,115200n8` after `console=tty0` preserves normal VGA output on physical laptops while enabling headless serial-console automated smoke testing in QEMU (`-nographic -serial stdio`). The `nomodeset` entry mitigates Intel GMA graphics quirks per PRD Section 13.

## DEC-005: Live session console login vs. installed password policy
- **Milestone:** M1
- **Decision:** In the live ISO, `live-config` handles the ephemeral live session user (`alx`) with standard live-boot login (`alx` / `live`) only in the ephemeral live environment; no password is set in `/etc/shadow` by ALX packages or hooks, preserving FR-7.3 ("No default passwords") for installed systems.
- **Rationale:** Allows automated QEMU smoke testing to log into the live ISO via serial console and verify `/etc/os-release`, `systemd-analyze`, and `free -m` without baking static passwords into installed systems.

## DEC-006: Default X11 terminal — `rxvt-unicode` (`urxvt`) instead of `alacritty`
- **Milestone:** M2
- **Decision:** Use `rxvt-unicode` (`urxvt`) as the default terminal in ALX-i3, with `xterm` as fallback, instead of `alacritty`.
- **Rationale:** `alacritty` requires OpenGL 3.3+, which fails to launch on Core 2 / Intel GMA GPUs (such as the target Dell Vostro 1015). `rxvt-unicode` is pure X11, uses ~4–8 MB RAM, renders JetBrains Mono cleanly via Xft, and works reliably on both Intel GMA and software rendering in QEMU.

## DEC-007: `network-manager-applet` instead of `network-manager-gnome`
- **Milestone:** M2
- **Decision:** List `network-manager-applet` directly in `alx-i3.list.chroot` instead of `network-manager-gnome`.
- **Rationale:** In Debian 13 (`trixie`), `network-manager-gnome` is a transitional package pointing to `network-manager-applet` and `nm-connection-editor`. Using `network-manager-applet` directly avoids transitional package bloat.

## DEC-008: `lazygit` from Debian `trixie` main; `input-leap` deferred to M5
- **Milestone:** M2
- **Decision:** Install `lazygit` directly from Debian `trixie` (`main`), and defer `input-leap` to M5 (ALX Link).
- **Rationale:** Verified that `lazygit` is packaged in Debian 13 (`trixie`), removing the need for an upstream binary. `input-leap` is not present as a binary package in Debian `trixie` main; its upstream Debian package or build method will be pinned and checksummed in `docs/THIRD_PARTY.md` during M5.

## DEC-009: Dark theme and icon set — `arc-theme` (Arc-Dark) + `papirus-icon-theme` (Papirus-Dark)
- **Milestone:** M2
- **Decision:** Use `Arc-Dark` for GTK2/GTK3/LightDM and `Papirus-Dark` for icons, paired with `JetBrains Mono` (terminal/bar) and `Noto Sans` (UI) via `fonts-jetbrains-mono` and `fonts-noto-core`.
- **Rationale:** All four packages are in Debian `trixie` `main`, keep installed size small, and provide a cohesive dark developer aesthetic (FR-2.5).
