// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Presswerk Print — IPP client/server, mDNS printer discovery, and persistent
// job queue.  This crate bridges between the core domain types defined in
// `presswerk-core` and the actual network printing infrastructure.

pub mod discovery;
pub mod ipp_client;
pub mod ipp_server;
pub mod queue;

pub use discovery::PrinterDiscovery;
pub use ipp_client::IppClient;
pub use ipp_server::IppServer;
pub use queue::JobQueue;
