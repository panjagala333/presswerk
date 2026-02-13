// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// presswerk-document — Document processing for the Presswerk print router.
//
// Provides PDF operations (read, create, merge, split, rotate), image processing
// (resize, rotate, crop, grayscale, brightness adjustment), and a scanning pipeline
// (binarization, enhancement, scan-to-PDF conversion).

pub mod image;
pub mod pdf;
pub mod scan;

// Re-export the primary structs so callers can use `presswerk_document::PdfReader` etc.
pub use image::processor::ImageProcessor;
pub use pdf::reader::PdfReader;
pub use pdf::writer::PdfWriter;
pub use scan::enhance::ScanEnhancer;

#[cfg(feature = "ocr")]
pub use scan::ocr::OcrEngine;
