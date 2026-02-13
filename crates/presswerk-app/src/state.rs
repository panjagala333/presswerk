// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Global application state — reactive signals for the Dioxus UI.

use presswerk_core::types::{DiscoveredPrinter, PrintJob, ServerStatus};
use presswerk_core::AppConfig;

use crate::services::app_services::AppServices;

/// Shared state accessible to all pages via `use_context`.
#[derive(Debug, Clone)]
pub struct AppState {
    /// Printers found on the local network.
    pub printers: Vec<DiscoveredPrinter>,
    /// Currently selected printer URI.
    pub selected_printer: Option<String>,
    /// All print jobs (local + network-received).
    pub jobs: Vec<PrintJob>,
    /// Status of the embedded IPP print server.
    pub server_status: ServerStatus,
    /// Application settings.
    pub config: AppConfig,
    /// Whether a discovery scan is in progress.
    pub scanning: bool,
    /// Status message for user feedback.
    pub status_message: Option<String>,
    /// Currently loaded document bytes (for print/edit flows).
    pub current_document: Option<Vec<u8>>,
    /// Name of the currently loaded document.
    pub current_document_name: Option<String>,
}

impl AppState {
    /// Create initial state from the backend services.
    pub fn new(svc: &AppServices) -> Self {
        let config = svc.config();
        let jobs = svc.all_jobs().unwrap_or_default();
        let printers = svc.discovered_printers();
        let scanning = svc.is_discovering();

        Self {
            printers,
            selected_printer: None,
            jobs,
            server_status: ServerStatus::Stopped,
            config,
            scanning,
            status_message: None,
            current_document: None,
            current_document_name: None,
        }
    }
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            printers: Vec::new(),
            selected_printer: None,
            jobs: Vec::new(),
            server_status: ServerStatus::Stopped,
            config: AppConfig::default(),
            scanning: false,
            status_message: None,
            current_document: None,
            current_document_name: None,
        }
    }
}
