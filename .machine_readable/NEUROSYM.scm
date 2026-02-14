;; SPDX-License-Identifier: PMPL-1.0-or-later
(neurosym (metadata (version "0.1.0") (last-updated "2026-02-14"))
  (integration
    (hypatia-scan
      (enabled #t)
      (workflow ".github/workflows/hypatia-scan.yml")
      (triggers ("push to main" "pull request")))
    (panic-attack
      (enabled #t)
      (command "panic-attack assail .")
      (baseline-findings 10)
      (critical-threshold 0)
      (high-threshold 4)))
  (formal-verification
    (idris2-abi
      (files ("src/abi/Types.idr"
              "src/abi/Protocol.idr"
              "src/abi/Encryption.idr"
              "src/abi/Layout.idr"
              "src/abi/Bridge.idr"))
      (properties ("job-status-injectivity"
                   "ipp-op-code-injectivity"
                   "valid-state-transitions"
                   "terminal-state-no-exit"
                   "encrypt-decrypt-roundtrip"
                   "ciphertext-size-bounds"
                   "struct-alignment"
                   "toll-free-bridging-symmetry"
                   "toll-free-bridging-transitivity"
                   "keychain-store-load"
                   "keychain-delete-load"
                   "keychain-last-write-wins"
                   "thread-requirement-safety"
                   "jni-invariants"
                   "opaque-handle-safety"))
      (banned ("Admitted" "believe_me" "assert_total" "unsafePerformIO"))))
  (zig-ffi
    (files ("ffi/zig/src/main.zig"))
    (tests 5)
    (exports ("presswerk_init" "presswerk_free" "presswerk_validate_transition"
              "presswerk_hash" "presswerk_last_error" "presswerk_version"
              "presswerk_build_info" "presswerk_is_initialized"))))
