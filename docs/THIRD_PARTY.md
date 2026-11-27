# Third-Party Packages (Outside Debian Stable)

Every package not provided by official Debian 13 (`trixie`) repositories is documented here with its upstream source, install method, and verification method.

## Active Third-Party Components (ALX Lite 1.2)

| Component | Purpose | Install Method | Verification |
|---|---|---|---|
| **Tailscale** | Default ALX Link mesh network & Taildrop | Official APT repo (`https://pkgs.tailscale.com/stable/debian trixie main`) via `0250-alx-tailscale.hook.chroot` | Official signing key (`trixie.noarmor.gpg`) |
| **Brave Browser** | Default web browser (replaces Firefox ESR) | Official APT repo (`https://brave-browser-apt-release.s3.brave.com/`) via `0260-alx-apps.hook.chroot` | Official keyring (`brave-browser-archive-keyring.gpg`) |
| **Visual Studio Code** | Preinstalled code editor (`code`) | Official Microsoft APT repo (`https://packages.microsoft.com/repos/code stable main`) via `0260-alx-apps.hook.chroot` | Official GPG key (`https://packages.microsoft.com/keys/microsoft.asc`) |
| **LocalSend** *(optional)* | Cross-platform LAN file sharing (`alx-setup localsend`) | GitHub release `v1.19.0`: `https://github.com/localsend/localsend/releases/download/v1.19.0/LocalSend-1.19.0-linux-x86-64.deb` | SHA-256: `f2cc2d1f8a2542799576e4c1cc61ed1f35c6a7dba2f375870e8500eab6fbfe66` |

### Hardware & Size Impact Note
- Preinstalling **Brave Browser** (Chromium) and **VS Code** (Electron) increases ISO size by ~220–280 MB (may exceed the original 1.5 GB target) and uses significantly more RAM when open on 2–3 GB laptops (`alx-profile-low`). `zram` (50% RAM) and `earlyoom` remain active to prevent system freezes.
