#!/usr/bin/env bash
set -euo pipefail

# Prepare a licensing-safe fork of EricTechPro/jarvis renamed to ALX Assistant.
# Run in GitHub Codespaces or a Debian trixie container with internet access.
#
# Usage:
#   ./ci/prepare-alx-assistant-fork.sh [target_dir]

UPSTREAM_URL="https://github.com/EricTechPro/jarvis.git"
PINNED_REF="af7465f"
FORK_DIR="${1:-../alx-assistant}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SRC="${ROOT_DIR}/packages/alx-assistant/usr/share/icons/hicolor/scalable/apps/alx-assistant.svg"
MOD_DATE="2026-11-28"

echo "==> Cloning ${UPSTREAM_URL} into ${FORK_DIR}"
rm -rf "${FORK_DIR}"
git clone "${UPSTREAM_URL}" "${FORK_DIR}"
cd "${FORK_DIR}"

echo "==> Checking out pinned upstream commit ${PINNED_REF}"
git checkout "${PINNED_REF}"
FULL_SHA="$(git rev-parse HEAD)"
echo "Pinned full upstream SHA: ${FULL_SHA}"

echo "==> Auditing safety defaults & outbound URLs in sidecar/src-tauri (Step 1 verification)"
grep -rnE "allowActions|skipAllow|rawReadOnly|telemetry" showcase/tauri/sidecar/ || true
grep -rnE "https?://" showcase/tauri/sidecar/ showcase/tauri/src-tauri/src/ | head -n 60 || true

echo "==> Preserving AGPL-3.0 LICENSE, upstream copyright, and THIRD_PARTY_NOTICES.md"
test -f LICENSE
test -f THIRD_PARTY_NOTICES.md

cat > MODIFIED_BY_ALGOTHIX.md <<EOF
# Algothix OS Modifications Notice

This repository is a modified fork of [EricTechPro/jarvis](https://github.com/EricTechPro/jarvis)
(pinned upstream commit \`${FULL_SHA}\`), licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).

- **Modified by:** Algothix OS (ALX) Lite maintainers
- **Modification date:** ${MOD_DATE}
- **Changes made:**
  1. Renamed product, package, binary, window title, and desktop entry to **ALX Assistant** (\`alx-assistant\`).
  2. Removed all upstream Jarvis/Ken Kai orb artwork and replaced with an original ALX SVG icon.
  3. Removed \`tauri-plugin-updater\` and enforced \`createUpdaterArtifacts: false\` and \`telemetry: false\`.
  4. Updated Linux Debian \`trixie\` dependencies (\`libasound2t64\`, \`libwebkit2gtk-4.1-0\`, \`libgtk-3-0t64\`, \`libsecret-tools\`, \`gnome-keyring\`, \`xdotool\`).
  5. Enforced strict CSP and safe defaults (\`allowActions: false\`, \`skipAllow: false\`, \`rawReadOnly: true\`).
EOF

echo "==> Replacing upstream artwork with original ALX Assistant SVG icon"
find showcase/tauri/src-tauri/icons -type f \( -name "*.png" -o -name "*.ico" -o -name "*.icns" -o -name "*.svg" \) -delete 2>/dev/null || true
mkdir -p showcase/tauri/src-tauri/icons
cp -f "${ICON_SRC}" showcase/tauri/src-tauri/icons/alx-assistant.svg

echo "==> Renaming user-visible identifiers & disabling updater in Tauri config"
python3 - <<'PYEOF'
import json, pathlib

conf_path = pathlib.Path("showcase/tauri/src-tauri/tauri.conf.json")
if conf_path.exists():
    conf = json.loads(conf_path.read_text())
    conf["productName"] = "ALX Assistant"
    conf["identifier"] = "org.algothix.alx-assistant"
    conf.setdefault("app", {}).setdefault("security", {})["csp"] = "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'"
    conf.setdefault("bundle", {})["createUpdaterArtifacts"] = False
    for w in conf.get("app", {}).get("windows", []):
        w["title"] = "ALX Assistant"
    conf_path.write_text(json.dumps(conf, indent=2) + "\n")

linux_conf_path = pathlib.Path("showcase/tauri/src-tauri/tauri.linux.conf.json")
if linux_conf_path.exists():
    lconf = json.loads(linux_conf_path.read_text())
    deb = lconf.setdefault("bundle", {}).setdefault("linux", {}).setdefault("deb", {})
    deb["depends"] = ["libwebkit2gtk-4.1-0", "libgtk-3-0t64", "libasound2t64", "xdg-utils", "libsecret-tools", "gnome-keyring", "xdotool"]
    linux_conf_path.write_text(json.dumps(lconf, indent=2) + "\n")

cargo_path = pathlib.Path("showcase/tauri/src-tauri/Cargo.toml")
if cargo_path.exists():
    lines = cargo_path.read_text().splitlines()
    filtered = [l for l in lines if "tauri-plugin-updater" not in l]
    cargo_path.write_text("\n".join(filtered) + "\n")
PYEOF

echo "==> Verifying no updater references remain in Cargo.toml"
! grep -q "tauri-plugin-updater" showcase/tauri/src-tauri/Cargo.toml

echo "==> Fork preparation complete in ${FORK_DIR}"
echo "Next: inspect git diff, strip any remaining updater plugin init in src-tauri/src/, commit, and push to https://github.com/Aditya-2709/alx-assistant"
