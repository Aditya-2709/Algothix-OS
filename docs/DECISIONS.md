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
- **Rationale:** `reprepro` is lightweight, stateless-friendly (single directory, no daemon), and available in Debian `trixie`. Copying `.deb` files into `config/packages.chroot/` keeps offline/local chroot installation simple in M1 while `build/repo` establishes the apt repository structure required for M7/M8 fleet distribution.

## DEC-004: Bootloaders and serial console parameters
- **Milestone:** M1
- **Decision:** Configure `live-build` with `--bootloaders "syslinux,grub-efi"` (`iso-hybrid`) and append `console=tty0 console=ttyS0,115200n8` to the default live kernel command line. Include a `nomodeset` fallback entry in both ISOLINUX and GRUB menus.
- **Rationale:** `syslinux` (ISOLINUX) provides BIOS boot and `grub-efi` provides UEFI boot in a single hybrid ISO. Adding `console=ttyS0,115200n8` after `console=tty0` preserves normal VGA output on physical laptops while enabling headless serial-console automated smoke testing in QEMU (`-nographic -serial stdio`). The `nomodeset` entry mitigates Intel GMA graphics quirks per PRD Section 13.

## DEC-005: Live session console login vs. installed password policy
- **Milestone:** M1
- **Decision:** In the live ISO, `live-config` handles the ephemeral live session user (`alx`) with console autologin disabled on `ttyS0` or standard live-boot login (`alx` / `live`) only in the ephemeral live environment; no password is set in `/etc/shadow` by ALX packages or hooks, preserving FR-7.3 ("No default passwords") for installed systems.
- **Rationale:** Allows automated QEMU smoke testing to log into the live ISO via serial console and verify `/etc/os-release`, `systemd-analyze`, and `free -m` without baking static passwords into installed systems.
