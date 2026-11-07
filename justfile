# Task runner for the rust-agents-template repo.
# `just` (no arguments) lists all recipes.

default:
    @just --list

# One-time setup per clone: activate git hooks + install missing check tools.
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    git config core.hooksPath githooks
    echo "hooksPath -> githooks"
    for tool in cargo-machete cargo-audit cargo-outdated cargo-deny; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "ok:      $tool"
        else
            echo "install: $tool"
            cargo install "$tool" --locked
        fi
    done
    echo "setup complete"

# Auto-fix formatting across the workspace.
fmt:
    cargo fmt --all

# Run tests (cargo-nextest when installed, otherwise cargo test).
test:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    if command -v cargo-nextest >/dev/null 2>&1; then
        cargo nextest run
    else
        cargo test
    fi

# Run only the release review (githooks/pre-tag) without creating a tag.
tag-check:
    githooks/pre-tag

# Release review + create the local annotated v* tag for Cargo.toml's version.
# Pushing the tag is the deliberate release act — the review fires again inside
# pre-push; see AGENTS.md §5 and docs/release.md.
tag:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    version=$(sed -n 's/^version = "\([^"]*\)"/\1/p' Cargo.toml | head -1)
    githooks/pre-tag --tag "v${version}"
    git tag -a "v${version}" -m "v${version}"
    echo "tagged v${version} — push it deliberately: git push origin v${version}"

# Deterministic gates for CI and release preflight: no Git context, no network audit.
verify:
    cargo fmt --all -- --check
    githooks/check-docs
    cargo clippy --all-targets --all-features -- -D warnings
    cargo test --locked

# Build the release profile (LTO/panic=abort/strip are exercised here).
build-release:
    cargo build --release --locked

# Build the static musl binary and the scratch GHCR image, then smoke-test it.
# Linux only: requires musl-gcc (musl-tools) and docker or podman.
# IMAGE overrides the image tag (default: <package>:dev); CONTAINER_ENGINE picks
# docker/podman; SOURCE_URL sets the OCI source label.
image:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"

    if ! command -v musl-gcc >/dev/null 2>&1; then
        echo "image: musl-gcc not found; install musl-tools (Linux)" >&2
        exit 1
    fi

    engine="${CONTAINER_ENGINE:-}"
    if [ -z "$engine" ]; then
        if command -v docker >/dev/null 2>&1; then
            engine=docker
        elif command -v podman >/dev/null 2>&1; then
            engine=podman
        else
            echo "image: neither docker nor podman found" >&2
            exit 1
        fi
    fi

    package="$(sed -n 's/^name = "\([^"]*\)"/\1/p' Cargo.toml | head -1)"
    image="${IMAGE:-${package}:dev}"

    rustup target add x86_64-unknown-linux-musl
    cargo build --release --locked --target x86_64-unknown-linux-musl
    mkdir -p bin/amd64
    cp "target/x86_64-unknown-linux-musl/release/${package}" bin/amd64/

    "$engine" build --build-arg TARGETARCH=amd64 \
        --build-arg "BIN=${package}" \
        --build-arg "SOURCE_URL=${SOURCE_URL:-}" \
        -f Containerfile -t "$image" .
    "$engine" run --rm "$image" | grep -q 'Hello, world!'
    echo "image ok: $image"

# Dependency policy: unused dependencies + advisories/licenses. `just setup` installs the tools.
deps:
    cargo machete
    cargo audit
    cargo deny check

# Advisory-only freshness check; not part of the blocking chain.
freshness:
    cargo outdated --root-deps-only

# Self-test the docs-alignment gate: a broken mirror must fail.
docs-gate-selfcheck:
    tests/check-docs.sh

# Run the full local check chain (pre-commit + pre-push hooks).
check:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    githooks/pre-commit
    githooks/pre-push
