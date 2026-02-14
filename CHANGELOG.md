# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-14

### Added

- **presswerk-core**: Shared types (14 public types), error handling, app config
- **presswerk-security**: age (X25519) encrypted storage, SHA-256 document integrity, Ed25519 TLS certificates, append-only SQLite audit trail
- **presswerk-document**: PDF read/merge/split/rotate/crop (lopdf + printpdf), image processing (resize, rotate, crop, grayscale, brightness), scanning pipeline with Canny edge detection, Hough line detection, perspective correction, binarisation, OCR via ocrs (pure Rust)
- **presswerk-print**: Full IPP/1.1 server (2,170 lines, RFC 8010/8011 compliant), IPP client (Print-Job, Get-Printer-Attributes, Get-Jobs, Cancel-Job), mDNS/DNS-SD printer discovery, persistent SQLite job queue
- **presswerk-bridge**: iOS native bridges (objc2 — UIPrintInteractionController, UIImagePickerController, UIDocumentPickerViewController, Security.framework Keychain, UIActivityViewController), Android native bridges (JNI — PrintManager, Intent ACTION_IMAGE_CAPTURE, Storage Access Framework, Android Keystore, Intent ACTION_SEND)
- **presswerk-app**: Dioxus 0.7 UI with 10 pages (Home, Print, Scan, Edit, TextEditor, Server, Jobs, Audit, Settings), bottom tab navigation, AppServices layer with in-memory fallback mode
- **Idris2 ABI proofs**: 5 proof files (Types, Protocol, Encryption, Layout, Bridge) — 0 Admitted, 0 believe_me
- **Zig FFI**: C-compatible exports (8 functions, 5 tests)
- **Benchmarks**: 7 criterion benchmarks (IPP parsing, response building, content hashing, encrypt/decrypt roundtrip, integrity hashing at 4 sizes, audit recording, perspective correction)
- **CI/CD**: 21 GitHub Actions workflows (CI, security scan, release, benchmarks, CodeQL, OpenSSF Scorecard, hypatia scan, mirror, quality, secret scanning)
- **Containerfile**: Multi-stage chainguard (wolfi-base) build, non-root runtime, health check
- **Trustfile**: 7-step security verification (ABI proofs, banned patterns, audit integrity, encryption safety, PQ readiness, hash compliance, policy hash)
- **Content-addressed document storage**: Deduplication via SHA-256 hash filenames

### Security

- 0 critical vulnerabilities (panic-attack scan)
- 0 dependency vulnerabilities (cargo audit)
- All `unsafe` blocks documented with `// SAFETY:` comments referencing Idris2 proofs
- No banned patterns: 0 `Admitted`, 0 `believe_me`, 0 `transmute`, 0 `unsafePerformIO`
- Append-only audit trail (no DELETE/UPDATE)
- Encryption key never persisted to disk

[0.1.0]: https://github.com/hyperpolymath/presswerk/releases/tag/v0.1.0
