;; SPDX-License-Identifier: PMPL-1.0-or-later
(ecosystem (metadata (version "0.1.0") (last-updated "2026-02-13"))
  (project (name "presswerk") (purpose "High-assurance local print router/server for mobile") (role "end-user-app"))
  (related-projects
    (project "dotmatrix-fileprinter" (relationship "sibling") (description "Desktop printer app (ReScript + Tauri)"))
    (project "proven" (relationship "dependency") (description "Idris2 formally verified library — ABI proofs"))
    (project "hypatia" (relationship "consumer") (description "Neurosymbolic CI/CD — scans presswerk"))
    (project "gitbot-fleet" (relationship "consumer") (description "Bot orchestration for automated fixes"))
    (project "panic-attacker" (relationship "tool") (description "Security scanning tool"))))
