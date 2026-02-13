// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Scanning pipeline — binarization, contrast enhancement, scan-to-PDF conversion,
// and optical character recognition (OCR).

pub mod enhance;

#[cfg(feature = "ocr")]
pub mod ocr;

pub use enhance::ScanEnhancer;

#[cfg(feature = "ocr")]
pub use ocr::OcrEngine;
