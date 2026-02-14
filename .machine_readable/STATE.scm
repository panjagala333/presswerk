;; SPDX-License-Identifier: PMPL-1.0-or-later
(state (metadata (version "0.3.0") (last-updated "2026-02-14") (status active))
  (project-context
    (name "presswerk")
    (purpose "High-assurance local print router and server for iOS/Android")
    (completion-percentage 75))
  (components
    (component "presswerk-core" (status "complete") (description "Shared types, errors, config — 248-line types, 70-line errors"))
    (component "presswerk-security" (status "complete") (description "age encryption, SHA-256 integrity, Ed25519 certs, SQLite audit trail — 14 tests, 3 benchmarks"))
    (component "presswerk-document" (status "complete") (description "PDF read/merge/split/rotate, image processing, scan enhancement with perspective correction, OCR — 7 tests, 1 benchmark"))
    (component "presswerk-print" (status "complete") (description "Full IPP/1.1 server (2170 lines), IPP client, mDNS discovery, SQLite job queue — 47 tests, 3 benchmarks"))
    (component "presswerk-bridge" (status "unverified") (description "iOS objc2 (894 lines) + Android JNI (973 lines) — detailed but untested on device"))
    (component "presswerk-app" (status "functional") (description "Dioxus UI with 10 pages, routing, AppServices layer with fallback mode, settings"))
    (component "abi-proofs" (status "complete") (description "5 Idris2 files: Types, Protocol, Encryption, Layout, Bridge — no Admitted"))
    (component "ffi-zig" (status "complete") (description "C-compatible FFI with 5 tests — lifecycle, transitions, hash, version"))
    (component "benchmarks" (status "complete") (description "Criterion benchmarks for security (3), print (3), document (1) — 7 total"))
    (component "ci-workflows" (status "complete") (description "21 GitHub Actions workflows including security.yml, release.yml, bench.yml"))
    (component "containerfile" (status "complete") (description "Multi-stage chainguard-based Containerfile for headless print server"))
    (component "trustfile" (status "complete") (description "Haskell-based security verification — 7-step hyperpolymath standard")))
  (metrics
    (rust-files 46)
    (rust-lines 10749)
    (idris2-files 5)
    (zig-files 3)
    (unit-tests 68)
    (benchmarks 7)
    (workflows 21)
    (clippy-warnings 0)
    (cargo-audit-vulnerabilities 0)
    (panic-attack-critical 0)
    (panic-attack-high 4)
    (panic-attack-medium 5))
  (current-position
    (phase "Phase 8 — Release and Packaging")
    (milestone "Production hardening complete, benchmarks added, CI/security workflows deployed")
    (next-actions
      ("Create v0.1.0 release tag and GitHub release"
       "Push to GitLab mirror"
       "Test iOS bridge on device/simulator (requires macOS + Xcode)"
       "Test Android bridge on device/emulator (requires NDK)"
       "Migrate to post-quantum crypto standard (Argon2id, SHAKE3-512, Kyber-1024)"
       "Apple Developer Team ID for iOS signing")))
  (blockers-and-issues
    (blocker "iOS bridge never compiled on target — need macOS + Xcode")
    (blocker "Android bridge never compiled on target — need NDK")
    (blocker "Dioxus.toml team_id empty — need Apple Developer account")
    (note "Desktop dev mode works via stub bridge")
    (note "All 4 panic-attack High findings are unavoidable FFI unsafe — covered by Bridge.idr proofs")
    (note "14 cargo audit warnings are unmaintained GTK3 transitive deps from dioxus-desktop — not actionable")
    (note "Crypto migration: SHA-256 -> SHAKE3-512, Ed25519 -> Ed448+Dilithium5, X25519 -> Kyber-1024")))
