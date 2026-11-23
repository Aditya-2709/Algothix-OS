# Algothix OS (ALX) Lite — Architecture Overview

## Build Pipeline

```
packages/alx-*  -->  dpkg-buildpackage  -->  build/debs/*.deb  -->  reprepro (build/repo)
                                                   |
                                                   v
auto/ + config/  -------------------------->  live-build (lb build)  -->  build/algothix-os-lite-amd64.iso
                                                                                   |
                                                                                   v
                                                                      tests/qemu/smoke-boot.sh
                                                                     (BIOS + UEFI, 2 GB RAM, HDD)
```

## Milestone 1 Scope (`alx-base`)

- **Base OS:** Debian 13 (`trixie`), `amd64`, `main` + `non-free-firmware`.
- **Init & Boot:** `systemd`, `live-boot`, `live-config-systemd`, hybrid BIOS (`isolinux`) + UEFI (`grub-efi`) ISO.
- **APT defaults:** `APT::Install-Recommends "false"` enforced via `/etc/apt/apt.conf.d/90alx-no-recommends` (provided by `alx-base`).
- **Identity:** `/etc/os-release` (`NAME="Algothix OS"`, `ID=alx`, `ID_LIKE=debian`), hostname `alx`, branded GRUB/ISOLINUX menus with a `nomodeset` fallback.
