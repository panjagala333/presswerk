;; SPDX-License-Identifier: PMPL-1.0-or-later
(ecosystem (metadata (version "0.2.0") (last-updated "2026-02-14"))
  (project (name "presswerk") (purpose "High-assurance local print router/server for mobile") (role "end-user-app"))
  (forges
    (forge "github" (url "https://github.com/hyperpolymath/presswerk"))
    (forge "gitlab" (url "https://gitlab.com/hyperpolymath/presswerk")))
  (related-projects
    (project "dotmatrix-fileprinter" (relationship "sibling") (description "Desktop printer app (ReScript + Tauri) — different scope, same domain"))
    (project "proven" (relationship "dependency") (description "Idris2 formally verified library — ABI proofs foundation"))
    (project "hypatia" (relationship "consumer") (description "Neurosymbolic CI/CD — scans presswerk for security"))
    (project "gitbot-fleet" (relationship "consumer") (description "Bot orchestration — 7 bots with presswerk-specific directives"))
    (project "panic-attacker" (relationship "tool") (description "Security scanning tool — 10 weak points found, 0 critical"))
    (project "verisimdb-data" (relationship "consumer") (description "Security findings database — ingests panic-attack scan results"))
    (project "echidna" (relationship "tool") (description "Formal proofing tool — validates Idris2 ABI proofs"))
    (project "rsr-template-repo" (relationship "template") (description "RSR template — scaffolded presswerk structure"))))
