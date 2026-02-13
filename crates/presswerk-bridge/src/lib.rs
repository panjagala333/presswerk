// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Presswerk — Native platform bridge abstractions.
//
// Provides trait-based interfaces over platform-specific APIs (iOS via objc2,
// Android via JNI). On unsupported platforms a stub implementation is used
// so the crate compiles everywhere (desktop dev, CI).

pub mod traits;

#[cfg(target_os = "ios")]
pub mod ios;

#[cfg(target_os = "android")]
pub mod android;

#[cfg(not(any(target_os = "ios", target_os = "android")))]
pub mod stub;

/// Return the platform bridge for the current target.
pub fn platform_bridge() -> Box<dyn traits::PlatformBridge> {
    #[cfg(target_os = "ios")]
    {
        Box::new(ios::IosBridge::new())
    }
    #[cfg(target_os = "android")]
    {
        Box::new(android::AndroidBridge::new())
    }
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
    {
        Box::new(stub::StubBridge)
    }
}
