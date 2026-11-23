# Third-Party Packages (Outside Debian Stable)

Every package not provided by official Debian stable (`trixie`) repositories must be documented here with its upstream source, install method, version pin, and SHA-256 checksum before being added to any ALX package or ISO build.

## Current Status (M0 / M1 / M2)

No third-party packages are included in M0, M1, or M2. All packages in `alx-base.list.chroot`, `alx-i3.list.chroot`, `alx-dev.list.chroot`, and the build environment come exclusively from official Debian 13 (`trixie`) `main` and `non-free-firmware` repositories.

> Note: `lazygit` was verified to be available in official Debian 13 (`trixie`) `main` and therefore does not require a third-party binary.

## Planned Third-Party Components (Future Milestones)

The following components will be pinned and checksummed here when their respective milestones begin:

| Component | Target Milestone | Planned Install Method | Version Pin | SHA-256 Checksum |
|---|---|---|---|---|
| `mise` | M4 (ALX Setup) | Upstream release binary / apt repo | TBD in M4 | TBD in M4 |
| `tailscale` | M5 (ALX Link) | Official Tailscale Debian `trixie` apt repo (signed keyring) | TBD in M5 | TBD in M5 |
| `croc` | M5 (ALX Link) | Verify Debian `trixie` availability first; else upstream release | TBD in M5 | TBD in M5 |
| `input-leap` | M5 (ALX Link) | Not in Debian `trixie` main; upstream `.deb` or pinned source build | TBD in M5 | TBD in M5 |
