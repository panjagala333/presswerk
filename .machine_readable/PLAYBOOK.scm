;; SPDX-License-Identifier: PMPL-1.0-or-later
(playbook (metadata (version "0.1.0") (last-updated "2026-02-14"))
  (recipes
    (recipe "dev"
      (description "Run desktop development server")
      (command "just dev")
      (prerequisites ("cargo installed" "dioxus-cli installed")))
    (recipe "test"
      (description "Run all unit tests")
      (command "just test")
      (expected "61 tests pass, 0 failures"))
    (recipe "lint"
      (description "Clippy lint with deny warnings")
      (command "just lint")
      (expected "0 warnings"))
    (recipe "assail"
      (description "Security scan with panic-attack")
      (command "just assail")
      (expected "0 critical findings"))
    (recipe "verify-abi"
      (description "Type-check all Idris2 ABI proofs")
      (command "just verify-abi")
      (prerequisites ("idris2 installed")))
    (recipe "ios-build"
      (description "Build for iOS simulator")
      (command "just ios")
      (prerequisites ("macOS" "Xcode 15+" "dioxus-cli")))
    (recipe "android-build"
      (description "Build for Android emulator")
      (command "just android")
      (prerequisites ("Android NDK r26+" "dioxus-cli"))))
  (release-checklist
    ("cargo test --workspace passes"
     "cargo clippy --workspace -- -D warnings clean"
     "panic-attack assail . — 0 critical"
     "just verify-abi — all Idris2 proofs type-check"
     ".machine_readable/STATE.scm updated"
     "README.adoc version bumped"
     "git tag -s vX.Y.Z"
     "push to github, gitlab")))
