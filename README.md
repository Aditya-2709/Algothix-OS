# Algothix OS (ALX) Lite

A fast, lightweight, Debian 13 (`trixie`) Linux distribution for programming and multitasking on old hardware (2–4 GB RAM, 64-bit x86_64 CPU, HDD).

## Status

- **Base:** Debian 13 (`trixie`, amd64) with `main` and `non-free-firmware`
- **Milestones implemented:** M0 through M8 (v1.0 release-ready codebase)
- **License:** GPL-3.0-or-later (see `LICENSE`)

## Documentation

- [User Guide](docs/USER_GUIDE.md) — Installing, ALX-i3 keybindings, `alx-setup`, `alx-link`, `alx-doctor`, `alx-update`
- [Admin Guide](docs/ADMIN_GUIDE.md) — Multi-user isolation, optional SSSD, Ansible fleet roles, `reprepro` repo, security baseline
- [Architecture](docs/ARCHITECTURE.md) — Build pipeline and component design
- [Engineering Decisions](docs/DECISIONS.md) — Recorded PRD defaults and deviations
- [Third-Party Packages](docs/THIRD_PARTY.md) — Tracking for non-Debian components
- [Physical Hardware Test Checklist](tests/hardware/HARDWARE_TEST.md) — Dell Vostro 1015 & ASUS X541NA validation

## Repository Layout

- `auto/` — `live-build` entry scripts (`config`, `build`, `clean`)
- `config/` — `live-build` package lists, chroot hooks, includes, and BIOS/UEFI bootloader branding
- `packages/` — Debian source packages (`alx-base`, `alx-desktop-i3`, `alx-tune`, `alx-doctor`, `alx-setup`, `alx-update`, `alx-link`, `alx-branding`, `alx-installer-config`)
- `ansible/` — Fleet management playbook (`site.yml`) and roles (`base`, `users`, `link`, `hardening`)
- `tests/` — Unit (`bats`), QEMU smoke/link/install/multi-user/security tests, and physical hardware checklist
- `ci/` — Build, lint, environment setup, and GPG release signing scripts
- `.github/workflows/` — CI (`ci.yml`), nightly budget enforcement (`nightly.yml`), and tagged releases (`release.yml`)

## Quick Start

### 1. Prepare the build environment

Using Docker (recommended):

```bash
make docker-build
```

Or on a Debian 13 (`trixie`) host/VM:

```bash
sudo ./ci/setup-env.sh
```

### 2. Build, test, and sign

```bash
make help        # Show available targets
make lint        # Run shellcheck and lintian
make packages    # Build all ALX .deb packages into build/repo
make iso         # Build the bootable hybrid ISO (BIOS + UEFI)
make test        # Run bats unit tests and QEMU BIOS/UEFI smoke tests
make clean       # Clean build artifacts
```

Full end-to-end build and verification inside Docker:

```bash
docker run --rm --privileged -v "$(pwd):/src" -w /src alx-builder:trixie \
  bash -lc "make packages && make lint && make test-unit && make iso && make test-qemu"
```

### 3. Tagged Release

Push a `v*` tag (e.g., `git tag v1.0.0 && git push origin v1.0.0`) to trigger `.github/workflows/release.yml`, which builds and tests the ISO, generates `SHA256SUMS`, signs artifacts with GPG (when `ALX_GPG_PRIVATE_KEY` and `ALX_GPG_KEY_ID` are set), and publishes a GitHub Release.
