;; SPDX-License-Identifier: PMPL-1.0-or-later
(agentic (metadata (version "0.1.0") (last-updated "2026-02-14"))
  (agent-capabilities
    (capability "code-generation"
      (scope "crates/")
      (constraints ("must pass cargo clippy -- -D warnings"
                    "must pass cargo test --workspace"
                    "unsafe blocks require // SAFETY: comment"
                    "no banned patterns: believe_me, Admitted, transmute")))
    (capability "documentation"
      (scope ("README.adoc" ".machine_readable/" "ABI-FFI-README.md"))
      (constraints ("maintain SPDX headers"
                    "SCM files only in .machine_readable/")))
    (capability "formal-verification"
      (scope "src/abi/")
      (constraints ("no Admitted proofs"
                    "no believe_me"
                    "all proofs must be total")))
    (capability "security-scanning"
      (tool "panic-attack assail .")
      (expected-baseline "0 critical, 4 high (FFI unavoidable), 5 medium")))
  (session-protocol
    (on-enter ("read 0-AI-MANIFEST.a2ml"
               "read .machine_readable/STATE.scm"
               "run cargo test --workspace"))
    (on-exit ("update .machine_readable/STATE.scm"
              "run cargo clippy --workspace -- -D warnings"
              "commit if changes made"))))
