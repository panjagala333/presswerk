// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Stub bridge for desktop/CI builds where native mobile APIs are unavailable.

use presswerk_core::error::{PresswerkError, Result};

use crate::traits::*;

/// No-op bridge returned on non-mobile platforms.
pub struct StubBridge;

impl PlatformBridge for StubBridge {
    fn platform_name(&self) -> &str {
        "Desktop (stub)"
    }
}

impl NativePrint for StubBridge {
    fn show_print_dialog(&self, _document: &[u8], _mime_type: &str) -> Result<()> {
        tracing::warn!("NativePrint::show_print_dialog called on stub bridge");
        Err(PresswerkError::PlatformUnavailable)
    }
}

impl NativeCamera for StubBridge {
    fn capture_image(&self) -> Result<Option<Vec<u8>>> {
        tracing::warn!("NativeCamera::capture_image called on stub bridge");
        Err(PresswerkError::PlatformUnavailable)
    }
}

impl NativeFilePicker for StubBridge {
    fn pick_file(&self, _mime_types: &[&str]) -> Result<Option<String>> {
        tracing::warn!("NativeFilePicker::pick_file called on stub bridge");
        Err(PresswerkError::PlatformUnavailable)
    }

    fn read_picked_file(&self, _path: &str) -> Result<Vec<u8>> {
        Err(PresswerkError::PlatformUnavailable)
    }
}

impl NativeKeychain for StubBridge {
    fn store_secret(&self, _key: &str, _value: &[u8]) -> Result<()> {
        tracing::warn!("NativeKeychain::store_secret called on stub bridge");
        Err(PresswerkError::PlatformUnavailable)
    }

    fn load_secret(&self, _key: &str) -> Result<Option<Vec<u8>>> {
        tracing::warn!("NativeKeychain::load_secret called on stub bridge");
        Err(PresswerkError::PlatformUnavailable)
    }

    fn delete_secret(&self, _key: &str) -> Result<()> {
        Err(PresswerkError::PlatformUnavailable)
    }
}

impl NativeShare for StubBridge {
    fn share_file(&self, _path: &str, _mime_type: &str) -> Result<()> {
        tracing::warn!("NativeShare::share_file called on stub bridge");
        Err(PresswerkError::PlatformUnavailable)
    }
}
