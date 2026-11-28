# Engineering Decisions Log (ALX Lite)

This file records architectural choices, defaults chosen from the PRD, and any deviations made during implementation.

---

## DEC-001: Base distribution — Debian 13 (`trixie`) amd64
- **Milestone:** M0 / M1
- **Decision:** Target Debian 13 (`trixie`, current Debian stable) `amd64` with archive areas `main non-free-firmware`.
- **Rationale:** Matches PRD Section 5 and Section 13 default. All base, desktop, dev, and build-tool packages are verified against Debian `trixie`.

## DEC-002: Non-free firmware inclusion
- **Milestone:** M1
- **Decision:** Include `non-free-firmware` archive area and ship `firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`, and `firmware-misc-nonfree` alongside `firmware-linux-free`.
- **Rationale:** Target laptops (Dell Vostro 1015, ASUS X541NA) require binary firmware for Wi-Fi and Ethernet out of the box.

## DEC-003: Local APT repository tool — `reprepro`
- **Milestone:** M0
- **Decision:** Use `reprepro` to publish locally built `.deb` packages into `build/repo`, and copy built `.deb` files into `config/packages.chroot/` during `make iso`.

## DEC-004: Bootloaders and serial console parameters
- **Milestone:** M1
- **Decision:** Configure `live-build` with `--bootloaders "syslinux,grub-efi"` (`iso-hybrid`), append `console=tty0 console=ttyS0,115200n8`, and include a `nomodeset` fallback entry in both ISOLINUX and GRUB menus.

## DEC-005: Live session user creation (`user-setup`)
- **Milestone:** M1 / v1.0.1
- **Decision:** Explicitly include `user-setup` in `alx-base.list.chroot` because `--apt-recommends false` otherwise omits it and prevents `live-config` from creating the `alx` live user.

## DEC-006: Default X11 terminal — `rxvt-unicode` (`urxvt`) instead of `alacritty`
- **Milestone:** M2
- **Decision:** Use `rxvt-unicode` (`urxvt`) with `xterm` fallback instead of `alacritty`.
- **Rationale:** Avoids OpenGL 3.3 startup failures on Core 2 / Intel GMA GPUs (Dell Vostro 1015).

## DEC-007: `network-manager-applet` instead of `network-manager-gnome`
- **Milestone:** M2
- **Decision:** List `network-manager-applet` directly in `alx-awesome.list.chroot` (non-transitional package in Debian `trixie`).

## DEC-008: `lazygit` from Debian `trixie` main
- **Milestone:** M2
- **Decision:** Install `lazygit` directly from Debian 13 (`trixie`) `main`.

## DEC-009: Dark theme and font set
- **Milestone:** M2 / CHANGE-001
- **Decision:** Use `Arc-Dark` + `Papirus-Dark` + `JetBrains Mono` + `Noto Sans`, unified with the CHANGE-001 obsidian/mint palette (`#0B0D10` background, `#13171D` surface, `#1F2630` border, `#E6EDF3` text, `#3DDC97` accent).

## DEC-010: Display Manager — SDDM (X11-only) replacing LightDM
- **Change:** CHANGE-001
- **Decision:** Replace `lightdm` and `lightdm-gtk-greeter` with `sddm` + minimal Qt6 QML modules (`qml6-module-qtquick`, `qml6-module-qtquick-controls`, `qml6-module-qtquick-layouts`), using a custom GPU-free `alx` QML theme (`GreeterEnvironment=QT_QUICK_BACKEND=software`, `DisplayServer=x11`). Autologin is enabled only for the live ISO via `99-alx-live-autologin.conf` and removed post-install by Calamares.
- **Trade-off / Risk:** SDDM pulls Qt6 Quick runtime (~30–50 MB more disk and slightly higher greeter RAM than LightDM GTK, though SDDM's greeter exits after login so idle session RAM stays low). Software rendering guarantees compatibility on Intel GMA and headless QEMU.

## DEC-011: Window Manager — Awesome WM replacing i3, PNG ASCII wallpapers
- **Change:** CHANGE-001
- **Decision:** Rename `alx-desktop-i3` to `alx-desktop-awesome`, replace `i3-wm`/`i3status`/`picom`/`feh` with `awesome` (plain Lua `rc.lua` using built-ins only, 5 tags, 28px top wibar with `/proc` and `/sys` widgets polling ≥ 2s, no compositor by default), and replace the SVG wallpaper with 4 optimized PNG ASCII `"ALX"` wallpapers (`1024x768`, `1280x720`, `1366x768`, `1920x1080`) set via `gears.wallpaper`.

## DEC-012: ALX Link Rewrite & Rejected Alternatives (Input Leap, croc, KDE Connect default)
- **Change:** CHANGE-001
- **Decision:** Rewrite `alx-link` around **Tailscale** (default) or **WireGuard** (`network=wireguard` fallback), **Taildrop** (`tailscale file cp`) or **`rsync`/`scp`** over SSH, **Syncthing** (user service at `Nice=10` / `IOSchedulingClass=idle`, enabled only after pairing), **`xclip`** (`alx-link clip` with remote `DISPLAY`/`XAUTHORITY`), **`notify-send`** (`alx-link notify` with remote `DBUS_SESSION_BUS_ADDRESS`), and SSH + `tmux` + `mosh` (`alx-link run`). Scope `ufw` rules for Syncthing (`22000/tcp+udp`, `21027/udp`) and SSH (`22/tcp`) strictly to `tailscale0`/`wg0`.
- **Rejected Alternatives:**
  - **Input Leap:** Not packaged in Debian `trixie` main and adds GUI/Qt maintenance overhead; removed completely.
  - **croc:** Not in Debian `trixie` main; redundant once Taildrop and `rsync`/`scp` over SSH are available; removed completely.
  - **KDE Connect as default:** Pulls heavy Qt/KF6 dependencies and only auto-discovers on the local LAN (does not work across Tailscale); moved to optional `alx-setup kdeconnect` for phone integration only.

## DEC-013: Optional LocalSend (`v1.19.0`) and KDE Connect (`alx-setup`)
- **Change:** CHANGE-001
- **Decision:** Provide `alx-setup localsend` (pinned GitHub release `v1.19.0` `.deb` with SHA-256 verification and LAN-only UFW port `53317/tcp+udp`) and `alx-setup kdeconnect` (`--no-install-recommends`, LAN-only phone sync). LocalSend is a Flutter app and is warned/discouraged on `alx-profile-low` (Intel GMA / 2–3 GB RAM).

## DEC-014: Optional ALX Assistant (`testing` Channel Only) & Rejected Alternatives
- **Decision:** Package `alx-assistant` (forked from `EricTechPro/jarvis` @ `af7465f`, AGPL-3.0) strictly as an optional on-demand package installed via `alx-setup assistant` from the ALX APT `testing` channel only, recommended for `alx-profile-mid` (4 GB+ RAM), using cloud APIs with the user's own key.
- **Rejected Alternatives:**
  - **Preinstalling on ALX Lite ISO:** Violates the 450 MB idle RAM / 1.5–2.0 GB ISO budgets and pulls WebKitGTK + bundled Node.js v24 (~180–260 MB disk, 220–550 MB active RAM) onto 2 GB laptops that cannot comfortably run it.
  - **Local LLMs (Ollama / llama.cpp):** Unusable on Core 2 / Celeron N3350 with 2–4 GB RAM and no discrete GPU; would immediately exhaust RAM and trigger `earlyoom`.
  - **Wayland build:** ALX Lite is X11-only (`SDDM` + `Awesome WM` without a compositor); Wayland portals and compositors are out of scope.
