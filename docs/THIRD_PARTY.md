# Third-Party Packages (Outside Debian Stable)

Every package not provided by official Debian 13 (`trixie`) repositories is documented here with its upstream source, install method, version pin, and verification method.

## Active Third-Party Components (ALX Lite 1.1)

| Component | Purpose | Install Method | Version / Pin | Verification / Checksum |
|---|---|---|---|---|
| **Tailscale** | Default ALX Link mesh network & Taildrop (`tailscale file cp`) | Official APT repo (`https://pkgs.tailscale.com/stable/debian trixie main`) via `config/archives/tailscale.list.chroot` | Tracked on `stable` (`trixie` repo; pin via `/etc/apt/preferences.d/` for frozen fleet builds) | Official APT signing key fetched by `ci/fetch-tailscale-key.sh` from `https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg` |
| **LocalSend** *(optional)* | Cross-platform LAN file sharing (`alx-setup localsend`, `alx-profile-mid` recommended) | Direct official GitHub release `.deb`: `https://github.com/localsend/localsend/releases/download/v1.19.0/LocalSend-1.19.0-linux-x86-64.deb` | `1.19.0` | SHA-256: `f2cc2d1f8a2542799576e4c1cc61ed1f35c6a7dba2f375870e8500eab6fbfe66` (verified by `alx-setup localsend` via `sha256sum -c` before install) |

### LocalSend on `alx-profile-low` (Honest Assessment)
- LocalSend is a **Flutter** application. Under software rendering on Intel GMA (Dell Vostro 1015, 2–3 GB RAM), Flutter UIs consume ~120–250 MB RAM and can feel sluggish or fail to accelerate smoothly.
- Therefore LocalSend is **not preinstalled**; it is optional via `alx-setup localsend` (with a low-profile warning) and recommended for `alx-profile-mid` (4+ GB RAM). On `alx-profile-low`, prefer `alx-link send` (Taildrop or `rsync`/`scp`).

### Removed / Not Used
- **Input Leap:** Removed in CHANGE-001 (not packaged in Debian `trixie` main; keyboard/mouse sharing dropped from ALX Lite v1.1).
- **croc:** Removed in CHANGE-001 (replaced by Taildrop on Tailscale and `rsync`/`scp` over SSH on WireGuard).
- **KDE Connect:** Available directly from Debian 13 (`trixie`) `main` (`kdeconnect`), **not** third-party — kept optional via `alx-setup kdeconnect` (LAN auto-discovery only, not across Tailscale).
