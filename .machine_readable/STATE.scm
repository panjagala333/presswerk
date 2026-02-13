;; SPDX-License-Identifier: PMPL-1.0-or-later
(state (metadata (version "0.1.0") (last-updated "2026-02-13") (status active))
  (project-context
    (name "presswerk")
    (purpose "High-assurance local print router and server for iOS/Android")
    (completion-percentage 15))
  (components
    (component "presswerk-core" (status "complete") (description "Shared types, errors, config"))
    (component "presswerk-security" (status "implemented") (description "Encrypted storage, audit trail, TLS"))
    (component "presswerk-document" (status "implemented") (description "PDF ops, image processing, scanning"))
    (component "presswerk-print" (status "implemented") (description "IPP client/server, mDNS discovery, job queue"))
    (component "presswerk-bridge" (status "scaffolded") (description "iOS/Android native bridges — stubs"))
    (component "presswerk-app" (status "scaffolded") (description "Dioxus UI with all pages")))
  (current-position
    (phase "Phase 1 — Scaffolding + Core")
    (milestone "All crates created with real implementations, UI pages scaffolded")
    (next-actions
      ("Wire discovery into Home page"
       "Wire IPP client into Print page"
       "Implement iOS bridge methods"
       "Test on iOS simulator")))
  (blockers-and-issues
    (blocker "iOS/Android bridges are stubs — need Xcode/NDK to test")
    (blocker "ippper crate availability not confirmed for print server")
    (note "Desktop dev mode works without mobile bridges via stub bridge")))
