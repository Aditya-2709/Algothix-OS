# Third-Party Packages (Outside Debian Stable)

Every package not provided by official Debian stable (`trixie`) repositories must be documented here with its upstream source, install method, version pin, and SHA-256 checksum before being added to any ALX package or ISO build.

## Current Status (M0 / M1)

No third-party packages are included in M0 or M1. All packages in `alx-base.list.chroot` and the build environment come exclusively from official Debian 13 (`trixie`) `main` and `non-free-firmware` repositories.

## Planned Third-Party Components (Future Milestones)

The following components from PRD Section 10 will be pinned and checksummed here when their respective milestones begin:

| Component | Target Milestone | Planned Install Method | Version Pin | SHA-256 Checksum |
|---|---|---|---|---|
| `tailscale` | M5 (ALX Link) | Official Tailscale Debian `trixie` apt repo (signed keyring) | TBD in M5 | TBD in M5 |
| `mise` | M4 (ALX Setup) | Upstream release binary / apt repo | TBD in M4 | TBD in M4 |
| `croc` | M5 (ALX Link) | Verify Debian `trixie` availability first; else upstream release | TBD in M5 | TBD in M5 |
| `lazygit` | M2 (ALX Dev) | Verify Debian `trixie` availability first; else upstream release | TBD in M2 | TBD in M2 |
