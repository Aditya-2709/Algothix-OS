# Show ALX Lite first-boot welcome once per interactive login (FR-6.3)
if [ -n "${PS1:-}" ] && [ -t 1 ] && [ -n "${HOME:-}" ] && [ ! -f "${HOME}/.config/alx/welcomed" ]; then
    if command -v alx-welcome >/dev/null 2>&1; then
        alx-welcome
        mkdir -p "${HOME}/.config/alx" 2>/dev/null || true
        touch "${HOME}/.config/alx/welcomed" 2>/dev/null || true
    fi
fi
