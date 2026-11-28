# Third-Party Packages (Outside Debian Stable)

Every package not provided by official Debian 13 (`trixie`) repositories is documented here with its upstream source, install method, and verification method.

## Active Third-Party Components (ALX Lite 1.2)

| Component | Purpose | Install Method | Verification |
|---|---|---|---|
| **Tailscale** | Default ALX Link mesh network & Taildrop | Official APT repo (`https://pkgs.tailscale.com/stable/debian trixie main`) via `0250-alx-tailscale.hook.chroot` | Official signing key (`trixie.noarmor.gpg`) |
| **Brave Browser** | Default web browser (replaces Firefox ESR) | Official APT repo (`https://brave-browser-apt-release.s3.brave.com/`) via `0260-alx-apps.hook.chroot` | Official keyring (`brave-browser-archive-keyring.gpg`) |
| **Visual Studio Code** | Preinstalled code editor (`code`) | Official Microsoft APT repo (`https://packages.microsoft.com/repos/code stable main`) via `0260-alx-apps.hook.chroot` | Official GPG key (`https://packages.microsoft.com/keys/microsoft.asc`) |
| **LocalSend** *(optional)* | Cross-platform LAN file sharing (`alx-setup localsend`) | GitHub release `v1.19.0`: `https://github.com/localsend/localsend/releases/download/v1.19.0/LocalSend-1.19.0-linux-x86-64.deb` | SHA-256: `f2cc2d1f8a2542799576e4c1cc61ed1f35c6a7dba2f375870e8500eab6fbfe66` |

## Optional Testing-Channel Components (Never Preinstalled on ISO)

| Component | Purpose | Upstream Source & Pin | License & Verification |
|---|---|---|---|
| **ALX Assistant** (`alx-assistant`) | Optional cloud-API desktop assistant (`alx-setup assistant`, `testing` channel only) | Fork of [EricTechPro/jarvis](https://github.com/EricTechPro/jarvis) pinned at commit `af7465f` (`Jarvis v0.2.12`), maintained in `https://github.com/Aditya-2709/Algothix-OS` (Modified by Algothix OS, 2026-11-28) | **AGPL-3.0** (upstream `LICENSE` and `THIRD_PARTY_NOTICES.md` preserved; original ALX SVG icon replaces all Ken Kai / Jarvis artwork; auto-updater stripped). **Maintainer Review Note:** Upstream includes proprietary `@anthropic-ai/claude-agent-sdk`; review license compatibility before promoting to `stable`. |
| **Bundled Node.js Runtime** (for `alx-assistant` sidecar) | Satisfies `engines.node >= 22` (Debian `trixie` ships `nodejs 20.19.2`) | Official Node.js `v24.22.2` linux-x64 tarball (`https://nodejs.org/dist/v24.22.2/node-v24.22.2-linux-x64.tar.xz`) | Verified against official `https://nodejs.org/dist/v24.22.2/SHASUMS256.txt` during `ci/prepare-alx-assistant-fork.sh` / CI build (exact SHA-256 recorded at build time; no unverified third-party installers). |

### Hardware & Size Impact Note
- Preinstalling **Brave Browser** (Chromium) and **VS Code** (Electron) increases ISO size by ~220–280 MB (may exceed the original 1.5 GB target) and uses significantly more RAM when open on 2–3 GB laptops (`alx-profile-low`). `zram` (50% RAM) and `earlyoom` remain active to prevent system freezes.
- **ALX Assistant** is **never** preinstalled on any ALX Lite ISO and is only installed on demand via `alx-setup assistant` (recommended for `alx-profile-mid` / 4 GB+ RAM only).
