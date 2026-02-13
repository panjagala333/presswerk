// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Platform-agnostic trait definitions for native capabilities.

use presswerk_core::error::Result;

/// Unified bridge that groups all native capabilities.
pub trait PlatformBridge: NativePrint + NativeCamera + NativeFilePicker + NativeKeychain + NativeShare {
    /// Human-readable platform name (e.g. "iOS 17", "Android 14").
    fn platform_name(&self) -> &str;
}

/// Send documents to the OS-level print dialog.
pub trait NativePrint {
    /// Open the native print dialog for the given document bytes.
    /// Returns Ok(()) if the dialog was presented (user may still cancel).
    fn show_print_dialog(&self, document: &[u8], mime_type: &str) -> Result<()>;
}

/// Capture images from the device camera.
pub trait NativeCamera {
    /// Launch the system camera and return the captured JPEG bytes.
    /// Returns Ok(None) if the user cancelled.
    fn capture_image(&self) -> Result<Option<Vec<u8>>>;
}

/// Pick files from the device storage.
pub trait NativeFilePicker {
    /// Show a file picker filtered to the given MIME types.
    /// Returns the file path chosen, or None if cancelled.
    fn pick_file(&self, mime_types: &[&str]) -> Result<Option<String>>;

    /// Read the bytes of a previously picked file.
    fn read_picked_file(&self, path: &str) -> Result<Vec<u8>>;
}

/// Secure key storage in the platform keychain / keystore.
pub trait NativeKeychain {
    /// Store a secret under the given key.
    fn store_secret(&self, key: &str, value: &[u8]) -> Result<()>;

    /// Retrieve a secret by key. Returns None if not found.
    fn load_secret(&self, key: &str) -> Result<Option<Vec<u8>>>;

    /// Delete a secret by key.
    fn delete_secret(&self, key: &str) -> Result<()>;
}

/// Share content via the OS share sheet.
pub trait NativeShare {
    /// Share a file with other apps via the native share sheet.
    fn share_file(&self, path: &str, mime_type: &str) -> Result<()>;
}
