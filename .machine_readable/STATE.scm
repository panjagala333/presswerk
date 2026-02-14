;; SPDX-License-Identifier: PMPL-1.0-or-later
(state (metadata (version "0.3.0") (last-updated "2026-02-14") (status active))
  (project-context
    (name "presswerk")
    (purpose "Print Doctor — high-assurance local print router for iOS/Android/Desktop")
    (completion-percentage 85))
  (components
    (component "presswerk-core" (status "complete") (description "Shared types with IPP conversion, errors with human messages, app config — 14 public types, ErrorClass, RetryPending"))
    (component "presswerk-security" (status "complete") (description "age encryption, SHA-256 integrity, Ed25519 certs, SQLite audit trail — 14 tests, 3 benchmarks"))
    (component "presswerk-document" (status "complete") (description "PDF read/merge/split/rotate, image processing, scan enhancement with perspective correction, OCR, format auto-conversion — 7 tests, 1 benchmark"))
    (component "presswerk-print" (status "complete") (description "IPP server/client, mDNS discovery, SQLite job queue, retry engine, circuit breaker, protocol downgrade (IPPS→IPP→LPR→Raw TCP), capabilities, diagnostics, network resilience, printer revival — 68 tests, 3 benchmarks"))
    (component "presswerk-bridge" (status "unverified") (description "iOS objc2 + Android JNI + 18 connection traits (USB, BT, NFC, WiFi Direct, FireWire, Lightning, Thunderbolt, Serial, Parallel, IR, iBeacon, LiFi, USB drive) — untested on device"))
    (component "presswerk-app" (status "functional") (description "Dioxus UI with Easy Mode (3-tap printing), Print Doctor wizard, 12+ pages, routing, AppServices layer"))
    (component "abi-proofs" (status "complete") (description "5 Idris2 files: Types, Protocol, Encryption, Layout, Bridge — no Admitted"))
    (component "ffi-zig" (status "complete") (description "C-compatible FFI with 5 tests — lifecycle, transitions, hash, version"))
    (component "benchmarks" (status "complete") (description "Criterion benchmarks for security (3), print (3), document (1) — 7 total"))
    (component "ci-workflows" (status "complete") (description "21 GitHub Actions workflows including security.yml, release.yml, bench.yml"))
    (component "containerfile" (status "complete") (description "Multi-stage chainguard-based Containerfile for headless print server (stapeln scheme)"))
    (component "trustfile" (status "complete") (description "Haskell-based security verification — 7-step hyperpolymath standard"))
    (component "specifications" (status "complete") (description "60+ printer interoperability specs in docs/specifications/PRINTER-SPECIFICATIONS.adoc")))
  (metrics
    (rust-files 58)
    (rust-lines 15000)
    (idris2-files 5)
    (zig-files 3)
    (unit-tests 68)
    (benchmarks 7)
    (workflows 21)
    (clippy-warnings 0)
    (cargo-audit-vulnerabilities 0)
    (panic-attack-critical 0)
    (panic-attack-high 5)
    (panic-attack-medium 4)
    (panic-attack-low 1)
    (panic-attack-total 12))
  (current-position
    (phase "Phase 9 — v0.3.0 Release")
    (milestone "v0.2 reliability hardening + v0.3 universal printer support complete")
    (next-actions
      ("Test iOS bridge on device/simulator (requires macOS + Xcode)"
       "Test Android bridge on device/emulator (requires NDK)"
       "Migrate to post-quantum crypto standard (Argon2id, SHAKE3-512, Kyber-1024)"
       "Apple Developer Team ID for iOS signing"
       "App store submission (iOS App Store + Google Play)")))
  (blockers-and-issues
    (blocker "iOS bridge never compiled on target — need macOS + Xcode")
    (blocker "Android bridge never compiled on target — need NDK")
    (blocker "Dioxus.toml team_id empty — need Apple Developer account")
    (note "Desktop dev mode works via stub bridge")
    (note "All 5 panic-attack High findings are unavoidable FFI unsafe — covered by Bridge.idr proofs")
    (note "2 Critical findings are in contractiles/trust/Trustfile.hs template — not app code")
    (note "cargo test --workspace requires libxdo-dev on Linux (Dioxus desktop dep)")
    (note "Crypto migration: SHA-256 -> SHAKE3-512, Ed25519 -> Ed448+Dilithium5, X25519 -> Kyber-1024")))
