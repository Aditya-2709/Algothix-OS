# CHANGE-001: SDDM, Awesome WM, and Lightweight ALX Link

**Status:** In Progress | **Target Version:** Algothix OS (ALX) Lite 1.1

## Summary of Changes

1. **Display Manager:** Replace LightDM (`lightdm`, `lightdm-gtk-greeter`) with **SDDM** (`sddm`, X11-only, minimal Qt6 QML set, custom GPU-free `alx` theme using `#0B0D10` background, `#3DDC97` accent, `320px` centered login card, JetBrains Mono clock, session selector, power buttons, and ASCII `"ALX"` PNG wallpaper).
2. **Window Manager:** Replace i3 (`i3-wm`, `i3status`, `picom`, `alx-desktop-i3`) with **Awesome WM** (`awesome`, `alx-desktop-awesome`, plain Lua `rc.lua` using built-ins only, 5 tags, 28px top wibar with `/proc`/`sysfs` widgets polling ≥ 2s, PNG ASCII `"ALX"` wallpapers at 1366x768 / 1920x1080 / 1280x720 / 1024x768, updated `dunstrc`/`rofi`/GTK/`.Xresources`, and `Super+?` cheat-sheet).
3. **ALX Link Rewrite:** Lightweight stack with **no KDE Connect by default** and **no Input Leap / croc**:
   - Network: **Tailscale** (default) or **WireGuard** (`network=wireguard` fallback in `/etc/alx/link.conf`)
   - File send: **Taildrop** (`tailscale file cp`) on Tailscale; `scp`/`rsync` over SSH on WireGuard
   - Synced folders: **Syncthing** (`~/ALX-Sync`, `Nice=10`, `IOSchedulingClass=idle`, enabled only after pairing)
   - Clipboard & notifications: `xclip` (`alx-link clip`) and `notify-send` (`alx-link notify`) over SSH with remote `DISPLAY`/`XAUTHORITY` and `DBUS_SESSION_BUS_ADDRESS` resolution
   - Remote builds: SSH + `tmux` + `mosh` (`alx-link run`)
   - Firewall: `ufw` allows Syncthing (`22000/tcp`, `22000/udp`, `21027/udp`) and SSH (`22/tcp`) only on `tailscale0`/`wg0` (and LAN during pairing)
4. **Optional Installers (`alx-setup`):**
   - `alx-setup localsend`: Pinned official LocalSend `v1.19.0` `.deb` with SHA-256 verification, low-profile Flutter/GPU warning, and LAN-only UFW port `53317` helper.
   - `alx-setup kdeconnect`: Optional minimal `kdeconnect` install for phone integration (LAN auto-discovery only, not across Tailscale).

## Step 1 Audit — Files Mentioning Legacy Terms

Every file referencing `lightdm`, `i3`, `picom`, `input-leap`, `croc`, `kdeconnect`, or `alx-desktop-i3`:

- `README.md`
- `config/hooks/live/0200-alx-dev-setup.hook.chroot`
- `config/package-lists/alx-i3.list.chroot` (to be replaced by `alx-awesome.list.chroot`)
- `docs/DECISIONS.md`
- `docs/THIRD_PARTY.md`
- `docs/USER_GUIDE.md`
- `packages/alx-branding/usr/bin/alx-welcome`
- `packages/alx-desktop-i3/` (entire package — to be renamed to `packages/alx-desktop-awesome/`)
- `packages/alx-link/usr/bin/alx-link`
- `packages/alx-link/usr/lib/alx-link/alx-link-core.py`
- `packages/alx-link/usr/share/man/man1/alx-link.1`
- `packages/alx-tune/usr/sbin/alx-tune`
- `tests/hardware/HARDWARE_TEST.md`
- `tests/qemu/smoke-boot.expect`
- `tests/unit/alx-link.bats`
- `tests/unit/alx-m2.bats`

## Execution Order (1 Commit per Step)

1. **Step 1:** Audit & commit `docs/CHANGE-001.md` + sync prior build/lint fixes.
2. **Step 2:** Add SDDM, minimal Qt6 QML deps, custom `alx` SDDM theme (`alx-branding`), `/etc/sddm.conf.d/alx.conf`, and live autologin hook.
3. **Step 3:** Rename `alx-desktop-i3` → `alx-desktop-awesome`, generate 4 PNG ASCII `"ALX"` wallpapers, author plain-Lua `rc.lua`, port keybindings/cheatsheet, update palette (`#0B0D10` / `#3DDC97`), replace `alx-i3.list.chroot` with `alx-awesome.list.chroot`.
4. **Step 4:** Rewrite `packages/alx-link` (Tailscale/WireGuard, Taildrop/`scp`/`rsync`, `clip`, `notify`, `run`, `status`, `unpair`, conditional Syncthing, `ufw` rules; remove Input Leap & `croc`).
5. **Step 5:** Add `alx-setup localsend` (pinned v1.19.0 + SHA-256) and `alx-setup kdeconnect` (minimal, LAN-only note) with cost estimates & `--dry-run`.
6. **Step 6:** Configure Tailscale official Debian `trixie` apt repo (`config/archives/`) and update `docs/THIRD_PARTY.md`.
7. **Step 7:** Update `bats` tests, QEMU scripts, `README.md`, `USER_GUIDE.md`, `ADMIN_GUIDE.md`, `HARDWARE_TEST.md`, `ansible/`, `ci/`, `DECISIONS.md`, `os-release` (v1.1), and run full verification.
