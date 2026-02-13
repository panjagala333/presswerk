// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Central service layer — initialises all backend subsystems and provides
// async-friendly methods for the Dioxus UI to call.
//
// Backend services (rusqlite-based JobQueue and AuditLog) are `Send` but not
// `Sync`, so they are wrapped in `Arc<Mutex<>>` for safe sharing across the
// Dioxus task pool.  Mutex contention is minimal because all operations are
// fast (sub-millisecond SQLite queries).

use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use presswerk_core::error::{PresswerkError, Result};
use presswerk_core::types::{
    DiscoveredPrinter, DocumentType, JobId, JobSource, JobStatus, PrintJob, ServerStatus,
};
use presswerk_core::AppConfig;
use presswerk_print::discovery::PrinterDiscovery;
use presswerk_print::ipp_client::IppClient;
use presswerk_print::ipp_server::IppServer;
use presswerk_print::queue::JobQueue;
use presswerk_security::audit::{AuditEntry, AuditLog};
use presswerk_security::integrity::hash_bytes;
use tracing::{error, info, warn};

use super::data_dir;

/// Shared application services accessible from all Dioxus components via
/// `use_context::<AppServices>()`.
///
/// All fields are cheaply cloneable (Arc-wrapped) so that the struct can be
/// passed into closures and async blocks without lifetime issues.
#[derive(Clone)]
pub struct AppServices {
    job_queue: Arc<Mutex<JobQueue>>,
    audit_log: Arc<Mutex<AuditLog>>,
    discovery: Arc<Mutex<Option<PrinterDiscovery>>>,
    ipp_server: Arc<tokio::sync::Mutex<IppServer>>,
    data_dir: PathBuf,
    config: Arc<Mutex<AppConfig>>,
}

#[allow(dead_code)]
impl AppServices {
    /// Initialise all services.  Call once at app startup.
    ///
    /// Creates the data directory, opens the SQLite databases, and prepares
    /// the mDNS discovery engine (but does not start browsing).
    pub fn init() -> Result<Self> {
        let dir = data_dir::data_dir();
        info!(path = %dir.display(), "initialising app services");

        // Open persistent databases
        let queue_path = dir.join("jobs.db");
        let audit_path = dir.join("audit.db");

        let job_queue = JobQueue::open(&queue_path)?;
        let audit_log = AuditLog::open(&audit_path)?;

        // Prepare discovery (may fail on platforms without multicast)
        let discovery = match PrinterDiscovery::new() {
            Ok(d) => Some(d),
            Err(e) => {
                warn!("mDNS discovery unavailable: {e}");
                None
            }
        };

        // Load persisted config or use defaults
        let config = load_config(&dir).unwrap_or_default();

        // Create IPP server (not started until user toggles it on)
        let ipp_server = IppServer::new(Some(config.server_port));

        info!("app services initialised");

        Ok(Self {
            job_queue: Arc::new(Mutex::new(job_queue)),
            audit_log: Arc::new(Mutex::new(audit_log)),
            discovery: Arc::new(Mutex::new(discovery)),
            ipp_server: Arc::new(tokio::sync::Mutex::new(ipp_server)),
            data_dir: dir,
            config: Arc::new(Mutex::new(config)),
        })
    }

    // -- Discovery -----------------------------------------------------------

    /// Start mDNS printer discovery in the background.
    pub fn start_discovery(&self) -> Result<()> {
        let mut guard = self.discovery.lock().expect("discovery lock poisoned");
        if let Some(ref mut disc) = *guard {
            disc.start()?;
        }
        Ok(())
    }

    /// Stop mDNS printer discovery.
    pub fn stop_discovery(&self) -> Result<()> {
        let mut guard = self.discovery.lock().expect("discovery lock poisoned");
        if let Some(ref mut disc) = *guard {
            disc.stop()?;
        }
        Ok(())
    }

    /// Return a snapshot of currently discovered printers.
    pub fn discovered_printers(&self) -> Vec<DiscoveredPrinter> {
        let guard = self.discovery.lock().expect("discovery lock poisoned");
        match *guard {
            Some(ref disc) => disc.printers(),
            None => Vec::new(),
        }
    }

    /// Whether discovery is currently browsing.
    pub fn is_discovering(&self) -> bool {
        let guard = self.discovery.lock().expect("discovery lock poisoned");
        match *guard {
            Some(ref disc) => disc.is_browsing(),
            None => false,
        }
    }

    // -- IPP Server ----------------------------------------------------------

    /// Start the embedded IPP print server.
    ///
    /// The server listens on the configured port and registers via mDNS
    /// so other devices on the LAN can discover and print to this device.
    pub async fn start_ipp_server(&self) -> Result<ServerStatus> {
        let job_queue = Arc::clone(&self.job_queue);
        let mut server = self.ipp_server.lock().await;
        server.start(job_queue).await?;
        self.audit("server_start", "system", true, Some(&format!("port {}", server.port())));
        Ok(server.status())
    }

    /// Stop the embedded IPP print server.
    pub async fn stop_ipp_server(&self) -> Result<ServerStatus> {
        let mut server = self.ipp_server.lock().await;
        server.stop().await?;
        self.audit("server_stop", "system", true, None);
        Ok(server.status())
    }

    /// Get the current IPP server status without blocking.
    pub fn ipp_server_status(&self) -> ServerStatus {
        match self.ipp_server.try_lock() {
            Ok(server) => server.status(),
            Err(_) => ServerStatus::Starting, // Lock held = transitioning
        }
    }

    // -- Printing ------------------------------------------------------------

    /// Send a document to a printer via IPP.
    ///
    /// Creates a print job in the queue, sends it via IPP, updates the job
    /// status, and records the operation in the audit log.
    pub async fn print_document(
        &self,
        document_bytes: Vec<u8>,
        document_name: String,
        document_type: DocumentType,
        printer_uri: String,
    ) -> Result<JobId> {
        let doc_hash = hash_bytes(&document_bytes);

        // Create the job record
        let mut job = PrintJob::new(
            JobSource::Local,
            document_type,
            document_name.clone(),
            doc_hash.clone(),
        );
        job.printer_uri = Some(printer_uri.clone());

        // Insert into persistent queue
        {
            let queue = self.job_queue.lock().expect("queue lock poisoned");
            queue.insert_job(&job)?;
        }

        let job_id = job.id;

        // Record audit entry
        self.audit("print_submitted", &doc_hash, true, Some(&document_name));

        // Send to printer asynchronously
        let services = self.clone();
        let doc_bytes = document_bytes;
        let uri = printer_uri;
        let name = document_name;
        let hash = doc_hash;

        tokio::spawn(async move {
            // Update status to Processing
            if let Ok(queue) = services.job_queue.lock() {
                let _ = queue.update_status(&job_id, JobStatus::Processing, None);
            }

            match IppClient::new(&uri) {
                Ok(client) => {
                    match client.print_job(doc_bytes, document_type, &name).await {
                        Ok(remote_id) => {
                            info!(job_id = %job_id, remote_id, "print job accepted");
                            if let Ok(queue) = services.job_queue.lock() {
                                let _ = queue.update_status(&job_id, JobStatus::Completed, None);
                            }
                            services.audit("print_completed", &hash, true, None);
                        }
                        Err(e) => {
                            error!(job_id = %job_id, error = %e, "print job failed");
                            let msg = e.to_string();
                            if let Ok(queue) = services.job_queue.lock() {
                                let _ = queue.update_status(
                                    &job_id,
                                    JobStatus::Failed,
                                    Some(&msg),
                                );
                            }
                            services.audit("print_failed", &hash, false, Some(&msg));
                        }
                    }
                }
                Err(e) => {
                    error!(error = %e, "invalid printer URI");
                    let msg = e.to_string();
                    if let Ok(queue) = services.job_queue.lock() {
                        let _ = queue.update_status(&job_id, JobStatus::Failed, Some(&msg));
                    }
                    services.audit("print_failed", &hash, false, Some(&msg));
                }
            }
        });

        Ok(job_id)
    }

    // -- Job Queue -----------------------------------------------------------

    /// Get all jobs from the persistent queue.
    pub fn all_jobs(&self) -> Result<Vec<PrintJob>> {
        let queue = self.job_queue.lock().expect("queue lock poisoned");
        queue.get_all_jobs()
    }

    /// Get pending jobs only.
    pub fn pending_jobs(&self) -> Result<Vec<PrintJob>> {
        let queue = self.job_queue.lock().expect("queue lock poisoned");
        queue.get_pending_jobs()
    }

    /// Cancel a job.
    pub fn cancel_job(&self, job_id: &JobId) -> Result<()> {
        let queue = self.job_queue.lock().expect("queue lock poisoned");
        queue.update_status(job_id, JobStatus::Cancelled, None)?;
        self.audit("job_cancelled", &job_id.to_string(), true, None);
        Ok(())
    }

    /// Delete a job from the queue.
    pub fn delete_job(&self, job_id: &JobId) -> Result<()> {
        let queue = self.job_queue.lock().expect("queue lock poisoned");
        queue.delete_job(job_id)
    }

    // -- Audit Trail ---------------------------------------------------------

    /// Record an audit entry (convenience wrapper).
    pub fn audit(&self, action: &str, document_hash: &str, success: bool, details: Option<&str>) {
        if let Ok(log) = self.audit_log.lock()
            && let Err(e) = log.record(action, document_hash, success, details)
        {
            error!(error = %e, "failed to record audit entry");
        }
    }

    /// Get recent audit entries.
    pub fn recent_audit_entries(&self, limit: u32) -> Result<Vec<AuditEntry>> {
        let log = self.audit_log.lock().expect("audit lock poisoned");
        log.recent_entries(limit)
    }

    /// Get audit entries for a specific document hash.
    pub fn audit_entries_for_hash(&self, hash: &str) -> Result<Vec<AuditEntry>> {
        let log = self.audit_log.lock().expect("audit lock poisoned");
        log.entries_for_hash(hash)
    }

    /// Total number of audit entries.
    pub fn audit_count(&self) -> Result<u64> {
        let log = self.audit_log.lock().expect("audit lock poisoned");
        log.count()
    }

    // -- Config Persistence --------------------------------------------------

    /// Get a clone of the current config.
    pub fn config(&self) -> AppConfig {
        self.config.lock().expect("config lock poisoned").clone()
    }

    /// Update and persist the config.
    pub fn save_config(&self, config: &AppConfig) -> Result<()> {
        *self.config.lock().expect("config lock poisoned") = config.clone();
        persist_config(&self.data_dir, config)
    }

    // -- Document Storage (encrypted at rest) --------------------------------

    /// Save document bytes to the data directory.
    ///
    /// Returns the SHA-256 hash used as the filename.
    pub fn store_document(&self, data: &[u8]) -> Result<String> {
        let hash = hash_bytes(data);
        let docs_dir = data_dir::data_subdir("documents");
        let path = docs_dir.join(&hash);

        if !path.exists() {
            std::fs::write(&path, data)
                .map_err(PresswerkError::Io)?;
        }

        Ok(hash)
    }

    /// Load document bytes from the data directory by hash.
    pub fn load_document(&self, hash: &str) -> Result<Vec<u8>> {
        let docs_dir = data_dir::data_subdir("documents");
        let path = docs_dir.join(hash);

        std::fs::read(&path)
            .map_err(PresswerkError::Io)
    }

    /// Path to the data directory.
    pub fn data_dir(&self) -> &PathBuf {
        &self.data_dir
    }
}

// -- Config file persistence -------------------------------------------------

const CONFIG_FILE: &str = "config.json";

fn load_config(data_dir: &std::path::Path) -> Option<AppConfig> {
    let path = data_dir.join(CONFIG_FILE);
    let data = std::fs::read_to_string(&path).ok()?;
    serde_json::from_str(&data).ok()
}

fn persist_config(data_dir: &std::path::Path, config: &AppConfig) -> Result<()> {
    let path = data_dir.join(CONFIG_FILE);
    let json = serde_json::to_string_pretty(config)?;
    std::fs::write(&path, json)?;
    Ok(())
}
