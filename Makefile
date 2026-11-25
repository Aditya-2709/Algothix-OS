SHELL := /bin/sh
.DEFAULT_GOAL := help

ISO_OUT ?= build/algothix-os-lite-amd64.iso
DOCKER_IMAGE ?= alx-builder:trixie

.PHONY: help docker-build lint packages iso test test-unit test-qemu clean

help: ## Show available make targets
	@echo "Algothix OS (ALX) Lite - Build Targets"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

docker-build: ## Build the Debian trixie build-environment Docker image
	docker build -t $(DOCKER_IMAGE) .

lint: ## Run shellcheck on all shell scripts and lintian on built packages
	./ci/lint.sh

packages: ## Build ALX .deb packages and publish to local reprepro apt repo
	./ci/build-packages.sh

iso: packages ## Build bootable hybrid ISO (BIOS + UEFI) via live-build
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: 'make iso' requires root privileges for live-build (run inside Docker or with sudo)." >&2; \
		exit 1; \
	fi
	./ci/fetch-tailscale-key.sh
	mkdir -p build config/packages.chroot
	cp -f build/debs/*.deb config/packages.chroot/
	lb clean --purge || true
	lb config
	lb build
	@if [ -f live-image-amd64.hybrid.iso ]; then \
		mv live-image-amd64.hybrid.iso $(ISO_OUT); \
		sha256sum $(ISO_OUT) > build/SHA256SUMS; \
		echo "Built ISO: $(ISO_OUT)"; \
	else \
		echo "ERROR: live-build did not produce live-image-amd64.hybrid.iso" >&2; \
		exit 1; \
	fi

test-unit: ## Run bats unit tests
	bats tests/unit/

test-qemu: ## Run QEMU BIOS and UEFI smoke tests against the built ISO
	./tests/qemu/smoke-boot.sh $(ISO_OUT)

test: lint test-unit test-qemu ## Run lint, bats unit tests, and QEMU smoke tests

clean: ## Clean live-build state, local repo, and built artifacts
	@if command -v lb >/dev/null 2>&1 && [ "$$(id -u)" -eq 0 ]; then \
		lb clean --purge || true; \
	fi
	rm -rf build config/packages.chroot/*.deb config/archives/tailscale.key.chroot \
		.build binary chroot cache local \
		live-image-* binary.* chroot.* \
		packages/*/debian/.debhelper packages/*/debian/files \
		packages/*/debian/*.substvars packages/*/debian/*.debhelper.log \
		packages/*/debian/alx-*
