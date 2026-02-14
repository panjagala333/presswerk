;; SPDX-License-Identifier: PMPL-1.0-or-later
(state (metadata (version "0.2.0") (last-updated "2026-02-14") (status active))
  (project-context
    (name "presswerk")
    (purpose "High-assurance local print router and server for iOS/Android")
    (completion-percentage 65))
  (components
    (component "presswerk-core" (status "complete") (description "Shared types, errors, config — 244-line types, 70-line errors"))
    (component "presswerk-security" (status "complete") (description "age encryption, SHA-256 integrity, Ed25519 certs, SQLite audit trail — 14 tests"))
    (component "presswerk-document" (status "complete") (description "PDF read/merge/split/rotate, image processing, scan enhancement, OCR — 7 tests"))
    (component "presswerk-print" (status "complete") (description "Full IPP/1.1 server (1936 lines), IPP client, mDNS discovery, SQLite job queue — 40 tests"))
    (component "presswerk-bridge" (status "unverified") (description "iOS objc2 (894 lines) + Android JNI (973 lines) — detailed but untested on device"))
    (component "presswerk-app" (status "functional") (description "Dioxus UI with 10 pages, routing, AppServices layer, settings"))
    (component "abi-proofs" (status "complete") (description "5 Idris2 files: Types, Protocol, Encryption, Layout, Bridge — no Admitted"))
    (component "ffi-zig" (status "complete") (description "C-compatible FFI with 5 tests — lifecycle, transitions, hash, version")))
  (metrics
    (rust-files 43)
    (rust-lines 10219)
    (idris2-files 5)
    (zig-files 3)
    (unit-tests 61)
    (clippy-warnings 0)
    (panic-attack-critical 0)
    (panic-attack-high 4)
    (panic-attack-medium 5))
  (current-position
    (phase "Phase 7 — Production Hardening")
    (milestone "Core implementation complete, formal verification done, doc storage implemented")
    (next-actions
      ("Test iOS bridge on device/simulator (requires macOS + Xcode)"
       "Test Android bridge on device/emulator (requires NDK)"
       "Add TLS to IPP server (rustls cert already generated)"
       "Add rate limiting to IPP server"
       "Apple Developer Team ID for iOS signing")))
  (blockers-and-issues
    (blocker "iOS bridge never compiled on target — need macOS + Xcode")
    (blocker "Android bridge never compiled on target — need NDK")
    (blocker "Dioxus.toml team_id empty — need Apple Developer account")
    (note "Desktop dev mode works via stub bridge")
    (note "All 4 panic-attack High findings are unavoidable FFI unsafe — covered by Bridge.idr proofs")))
