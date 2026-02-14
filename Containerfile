# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
#
# Presswerk — Multi-stage container build
#
# Build:   podman build -f Containerfile -t presswerk:latest .
# Run:     podman run --rm -p 631:631 presswerk:latest
# Seal:    selur seal presswerk:latest
# Sign:    cerro-torre sign presswerk:latest

# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

# Install Rust toolchain and system dependencies for Dioxus desktop/headless
RUN apk add --no-cache \
    rust \
    cargo \
    gcc \
    glibc-dev \
    pkgconf \
    openssl-dev \
    sqlite-dev \
    gtk+3.0-dev \
    webkit2gtk-dev \
    libxdo-dev \
    libsoup3-dev

WORKDIR /build
COPY . .

# Build only the library crates and the IPP server (headless mode)
# The full desktop UI requires display server — build presswerk-print only
# for containerised print server deployment
RUN cargo build --release \
    -p presswerk-core \
    -p presswerk-security \
    -p presswerk-document \
    -p presswerk-print

# Build the app binary (if desktop deps are available)
RUN cargo build --release -p presswerk-app 2>/dev/null || true

# ── Stage 2: Runtime ────────────────────────────────────────────────────────
FROM cgr.dev/chainguard/wolfi-base:latest AS runtime

# Minimal runtime deps (SQLite bundled in binary, no external libsqlite needed)
RUN apk add --no-cache \
    glibc \
    libgcc \
    openssl

# Non-root user for security
RUN adduser -D -h /app presswerk
USER presswerk
WORKDIR /app

# Copy built artifacts
COPY --from=builder --chown=presswerk:presswerk /build/target/release/presswerk-app ./presswerk 2>/dev/null || true
COPY --from=builder --chown=presswerk:presswerk /build/target/release/libpresswerk_print.rlib . 2>/dev/null || true

# Data directory for persistent storage (mount a volume here)
RUN mkdir -p /app/data

# IPP server port
EXPOSE 631

# Health check: IPP Get-Printer-Attributes
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -q --spider http://localhost:631/ipp/print || exit 1

# Default: start the print server
ENTRYPOINT ["./presswerk"]
CMD ["--headless", "--port", "631", "--data-dir", "/app/data"]

# ── Labels ──────────────────────────────────────────────────────────────────
LABEL org.opencontainers.image.title="Presswerk"
LABEL org.opencontainers.image.description="High-assurance local print router/server with IPP, mDNS, document scanning, and formal verification"
LABEL org.opencontainers.image.url="https://github.com/hyperpolymath/presswerk"
LABEL org.opencontainers.image.source="https://github.com/hyperpolymath/presswerk"
LABEL org.opencontainers.image.version="0.1.0"
LABEL org.opencontainers.image.licenses="PMPL-1.0-or-later"
LABEL org.opencontainers.image.authors="Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>"
LABEL org.opencontainers.image.vendor="hyperpolymath"
