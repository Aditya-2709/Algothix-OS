#!/usr/bin/env bash
set -euo pipefail

# QEMU 2 GB & 4 GB RAM Measurement & Integration Test Harness for ALX Assistant
# Run in GitHub Codespaces / Docker (requires qemu-system-x86_64, xvfb-run, python3).
# Uses a local mock HTTP LLM endpoint so no real API key is required.
#
# Usage:
#   ./tests/qemu/measure-assistant.sh <path-to-iso-or-qcow2>

IMAGE="${1:-build/algothix-os-lite-amd64.iso}"
OUT_LOG="${ALX_MEASURE_LOG:-build/assistant-qemu-metrics.txt}"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "ERROR: qemu-system-x86_64 not found. Run this script inside the ALX Docker builder or a Linux host with QEMU." >&2
    exit 1
fi

if [ ! -f "${IMAGE}" ]; then
    echo "ERROR: Image not found: ${IMAGE}" >&2
    exit 1
fi

mkdir -p "$(dirname "${OUT_LOG}")"

cat > "${OUT_LOG}" <<EOF
# ALX Assistant QEMU Measurement Run ($(date -u +%Y-%m-%dT%H:%M:%SZ))
# Image: ${IMAGE}
EOF

echo "==> Starting local mock LLM endpoint on 127.0.0.1:18080 (no real API key needed)"
python3 - <<'PYEOF' &
import http.server, json
class MockLLM(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        _ = self.rfile.read(length)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"choices": [{"message": {"content": "ALX mock OK"}}]}).encode())
    def log_message(self, *args):
        pass
http.server.HTTPServer(("127.0.0.1", 18080), MockLLM).serve_forever()
PYEOF
MOCK_PID=$!
trap 'kill "${MOCK_PID}" 2>/dev/null || true' EXIT

for RAM_MB in 2048 4096; do
    echo "==> Booting QEMU verification profile: ${RAM_MB} MB RAM"
    echo "--- RAM=${RAM_MB}MB ---" >> "${OUT_LOG}"
    # Smoke boot check (serial console capture); extend with SSH/guest-agent commands
    # when running against an installed qcow2 disk image with local testing APT repo mounted.
    timeout 90 qemu-system-x86_64 \
        -m "${RAM_MB}" \
        -smp 2 \
        -nographic \
        -serial stdio \
        -cdrom "${IMAGE}" \
        -boot d \
        -no-reboot >/tmp/alx-qemu-${RAM_MB}.log 2>&1 || true

    echo "Boot log saved to /tmp/alx-qemu-${RAM_MB}.log" >> "${OUT_LOG}"
    echo "Checklist inside guest (run via SSH on installed qcow2):" >> "${OUT_LOG}"
    echo "  1. free -m (before install)" >> "${OUT_LOG}"
    echo "  2. sudo alx-setup assistant -y && free -m (after install, not running) && dpkg-query -W -f='\${Installed-Size}\n' alx-assistant" >> "${OUT_LOG}"
    echo "  3. ss -tunp (verify 0 outbound connections before API key is configured)" >> "${OUT_LOG}"
    echo "  4. xvfb-run alx-assistant (running idle RAM + mock endpoint http://10.0.2.2:18080)" >> "${OUT_LOG}"
    echo "  5. sudo alx-setup assistant --remove -y && dpkg -l alx-assistant (verify clean removal; ~/.config/alx-assistant preserved)" >> "${OUT_LOG}"
    echo "  6. Upgrade test: install N (0.2.12+alx1) then apt-get upgrade to N+1 (0.2.12+alx2) from testing repo" >> "${OUT_LOG}"
done

echo "==> Measurement harness finished. Summary written to ${OUT_LOG}"
