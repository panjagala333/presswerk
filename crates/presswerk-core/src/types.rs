// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Core domain types for the Presswerk print router.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::net::IpAddr;
use uuid::Uuid;

/// Unique identifier for a print job.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct JobId(pub Uuid);

impl JobId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for JobId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for JobId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Where a print job originated from.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum JobSource {
    /// User selected a file on this device.
    Local,
    /// Received over the network via the IPP print server.
    Network { remote_addr: IpAddr },
    /// Created from the built-in scanner.
    Scan,
    /// Created from the built-in text editor.
    TextEditor,
}

/// Lifecycle states of a print job.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum JobStatus {
    /// Queued, waiting to be sent.
    Pending,
    /// Currently being transmitted to the printer.
    Processing,
    /// Successfully printed.
    Completed,
    /// Printing failed — see job error field.
    Failed,
    /// User cancelled the job.
    Cancelled,
    /// Held for user review (e.g. network-received jobs in preview mode).
    Held,
}

/// Supported input document types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DocumentType {
    Pdf,
    Jpeg,
    Png,
    Tiff,
    PlainText,
    /// Format delegated to native OS print dialog (DOCX, XLS, etc.)
    NativeDelegate,
}

impl DocumentType {
    /// MIME type string for IPP Content-Type.
    pub fn mime_type(&self) -> &'static str {
        match self {
            Self::Pdf => "application/pdf",
            Self::Jpeg => "image/jpeg",
            Self::Png => "image/png",
            Self::Tiff => "image/tiff",
            Self::PlainText => "text/plain",
            Self::NativeDelegate => "application/octet-stream",
        }
    }

    /// Infer document type from file extension.
    pub fn from_extension(ext: &str) -> Option<Self> {
        match ext.to_ascii_lowercase().as_str() {
            "pdf" => Some(Self::Pdf),
            "jpg" | "jpeg" => Some(Self::Jpeg),
            "png" => Some(Self::Png),
            "tif" | "tiff" => Some(Self::Tiff),
            "txt" => Some(Self::PlainText),
            "docx" | "doc" | "xlsx" | "xls" | "pptx" | "ppt" | "odt" | "ods" => {
                Some(Self::NativeDelegate)
            }
            _ => None,
        }
    }
}

/// Standard paper sizes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PaperSize {
    A4,
    A3,
    A5,
    Letter,
    Legal,
    Tabloid,
    Custom { width_mm: u32, height_mm: u32 },
}

impl PaperSize {
    /// Dimensions in millimetres (width, height).
    pub fn dimensions_mm(&self) -> (u32, u32) {
        match self {
            Self::A4 => (210, 297),
            Self::A3 => (297, 420),
            Self::A5 => (148, 210),
            Self::Letter => (216, 279),
            Self::Legal => (216, 356),
            Self::Tabloid => (279, 432),
            Self::Custom {
                width_mm,
                height_mm,
            } => (*width_mm, *height_mm),
        }
    }
}

/// Duplex printing mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DuplexMode {
    Simplex,
    LongEdge,
    ShortEdge,
}

/// Page orientation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Orientation {
    Portrait,
    Landscape,
    ReversePortrait,
    ReverseLandscape,
}

/// Print settings for a job.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrintSettings {
    pub copies: u32,
    pub paper_size: PaperSize,
    pub duplex: DuplexMode,
    pub orientation: Orientation,
    pub color: bool,
    pub page_range: Option<PageRange>,
    pub scale_to_fit: bool,
}

impl Default for PrintSettings {
    fn default() -> Self {
        Self {
            copies: 1,
            paper_size: PaperSize::A4,
            duplex: DuplexMode::Simplex,
            orientation: Orientation::Portrait,
            color: true,
            page_range: None,
            scale_to_fit: true,
        }
    }
}

/// Page range specification.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageRange {
    pub start: u32,
    pub end: u32,
}

/// A complete print job.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrintJob {
    pub id: JobId,
    pub source: JobSource,
    pub status: JobStatus,
    pub document_type: DocumentType,
    pub document_name: String,
    /// SHA-256 hash of the original document bytes.
    pub document_hash: String,
    pub settings: PrintSettings,
    pub printer_uri: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub error_message: Option<String>,
}

impl PrintJob {
    pub fn new(
        source: JobSource,
        document_type: DocumentType,
        document_name: String,
        document_hash: String,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: JobId::new(),
            source,
            status: JobStatus::Pending,
            document_type,
            document_name,
            document_hash,
            settings: PrintSettings::default(),
            printer_uri: None,
            created_at: now,
            updated_at: now,
            error_message: None,
        }
    }
}

/// A printer discovered on the local network via mDNS.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscoveredPrinter {
    pub name: String,
    pub uri: String,
    pub ip: IpAddr,
    pub port: u16,
    pub supports_color: bool,
    pub supports_duplex: bool,
    pub supports_tls: bool,
    pub paper_sizes: Vec<PaperSize>,
    pub make_and_model: Option<String>,
    pub location: Option<String>,
}

/// Status of the embedded IPP print server.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ServerStatus {
    Stopped,
    Starting,
    Running,
    Error,
}
