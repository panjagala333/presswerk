;; SPDX-License-Identifier: PMPL-1.0-or-later
(meta (metadata (version "0.1.0") (last-updated "2026-02-13"))
  (project-info (type "mobile-app") (languages (rust idris2 zig)) (license "PMPL-1.0-or-later"))
  (architecture-decisions
    (adr "ADR-001" (title "Dioxus for mobile UI") (status "accepted")
      (decision "Use Dioxus 0.7+ — pure Rust, React-like, mobile-native"))
    (adr "ADR-002" (title "age for encryption at rest") (status "accepted")
      (decision "Use age crate with X25519 passphrase-based key derivation"))
    (adr "ADR-003" (title "IPP server on port 631") (status "accepted")
      (decision "Phone as network printer via IPP + mDNS advertisement"))
    (adr "ADR-004" (title "Pure-Rust OCR via ocrs") (status "accepted")
      (decision "No C deps — ocrs ONNX-based pure Rust"))
    (adr "ADR-005" (title "SQLite for persistence") (status "accepted")
      (decision "rusqlite bundled for job queue + audit trail"))))
