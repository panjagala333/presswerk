// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// presswerk-security — Encrypted storage, audit trail, TLS certificates, and
// document integrity for the Presswerk print router.

pub mod audit;
pub mod certificates;
pub mod integrity;
pub mod storage;

pub use audit::AuditLog;
pub use certificates::SelfSignedCert;
pub use integrity::{hash_bytes, verify_hash};
pub use storage::EncryptedStorage;
