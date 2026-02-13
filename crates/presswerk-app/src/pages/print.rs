// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Print page — pick a file, select printer, configure settings, print.

use dioxus::prelude::*;

use presswerk_core::types::DocumentType;

use crate::services::app_services::AppServices;
use crate::state::AppState;

#[component]
pub fn Print() -> Element {
    let mut state = use_context::<Signal<AppState>>();
    let svc = use_context::<AppServices>();
    let mut file_name = use_signal(|| Option::<String>::None);
    let mut file_bytes = use_signal(|| Option::<Vec<u8>>::None);
    let mut file_type = use_signal(|| DocumentType::Pdf);
    let mut printing = use_signal(|| false);
    let mut print_result = use_signal(|| Option::<String>::None);

    rsx! {
        div {
            h1 { "Print" }

            // File selection
            section { style: "margin: 16px 0;",
                h3 { "1. Select Document" }
                if let Some(ref name) = *file_name.read() {
                    div { style: "display: flex; align-items: center; gap: 8px;",
                        p { "Selected: {name}" }
                        button {
                            style: "padding: 4px 12px; border-radius: 4px; border: 1px solid #ccc; background: white; font-size: 12px;",
                            onclick: move |_| {
                                file_name.set(None);
                                file_bytes.set(None);
                                print_result.set(None);
                            },
                            "Clear"
                        }
                    }
                } else {
                    button {
                        style: "padding: 12px 24px; border-radius: 8px; border: 1px solid #007aff; color: #007aff; background: white; font-size: 16px;",
                        onclick: move |_| {
                            // Desktop: use rfd file dialog
                            #[cfg(not(any(target_os = "ios", target_os = "android")))]
                            {
                                if let Some(path) = rfd::FileDialog::new()
                                    .add_filter("Documents", &["pdf", "jpg", "jpeg", "png", "tiff", "tif", "txt"])
                                    .pick_file()
                                {
                                    let name = path.file_name()
                                        .map(|n| n.to_string_lossy().to_string())
                                        .unwrap_or_else(|| "unknown".into());
                                    let ext = path.extension()
                                        .map(|e| e.to_string_lossy().to_string())
                                        .unwrap_or_default();

                                    if let Some(dt) = DocumentType::from_extension(&ext) {
                                        file_type.set(dt);
                                    }

                                    match std::fs::read(&path) {
                                        Ok(bytes) => {
                                            tracing::info!(file = %name, bytes = bytes.len(), "file loaded");
                                            file_bytes.set(Some(bytes));
                                            file_name.set(Some(name));
                                        }
                                        Err(e) => {
                                            tracing::error!(error = %e, "failed to read file");
                                            print_result.set(Some(format!("Error reading file: {e}")));
                                        }
                                    }
                                }
                            }
                            // Mobile: will use native bridge (TODO)
                            #[cfg(any(target_os = "ios", target_os = "android"))]
                            {
                                tracing::info!("file picker: use native bridge on mobile");
                                print_result.set(Some("File picker not yet wired on mobile".into()));
                            }
                        },
                        "Choose File"
                    }
                }
            }

            // Printer selection
            section { style: "margin: 16px 0;",
                h3 { "2. Select Printer" }
                if state.read().printers.is_empty() {
                    p { style: "color: #888;",
                        "No printers found. "
                        Link { to: crate::Route::Home {}, "Go to Home to scan." }
                    }
                } else {
                    select {
                        style: "width: 100%; padding: 8px; font-size: 16px; border-radius: 8px; border: 1px solid #ccc;",
                        onchange: move |evt| {
                            let val = evt.value().to_string();
                            if !val.is_empty() {
                                state.write().selected_printer = Some(val);
                            }
                        },
                        option { value: "", "Select a printer..." }
                        for printer in state.read().printers.iter() {
                            option { value: "{printer.uri}", "{printer.name}" }
                        }
                    }
                }
            }

            // Print settings
            section { style: "margin: 16px 0;",
                h3 { "3. Settings" }
                div { style: "display: grid; grid-template-columns: 1fr 1fr; gap: 8px;",
                    label { "Copies:" }
                    input { r#type: "number", value: "1", min: "1", max: "99",
                        style: "padding: 4px; border: 1px solid #ccc; border-radius: 4px;" }
                    label { "Color:" }
                    input { r#type: "checkbox", checked: true }
                    label { "Duplex:" }
                    select { style: "padding: 4px; border: 1px solid #ccc; border-radius: 4px;",
                        option { value: "simplex", "One-sided" }
                        option { value: "long-edge", "Two-sided (long edge)" }
                        option { value: "short-edge", "Two-sided (short edge)" }
                    }
                }
            }

            // Print button
            button {
                style: "width: 100%; padding: 16px; border-radius: 12px; border: none; background: #007aff; color: white; font-size: 18px; font-weight: bold; margin-top: 16px;",
                disabled: file_bytes.read().is_none() || state.read().selected_printer.is_none() || *printing.read(),
                onclick: {
                    let svc = svc.clone();
                    move |_| {
                        let doc_bytes = file_bytes.read().clone();
                        let doc_name = file_name.read().clone();
                        let printer_uri = state.read().selected_printer.clone();
                        let doc_type = *file_type.read();

                        if let (Some(bytes), Some(name), Some(uri)) = (doc_bytes, doc_name, printer_uri) {
                            printing.set(true);
                            print_result.set(Some("Sending to printer...".into()));
                            let svc = svc.clone();

                            spawn(async move {
                                match svc.print_document(bytes, name, doc_type, uri).await {
                                    Ok(job_id) => {
                                        tracing::info!(job_id = %job_id, "print job submitted");
                                        print_result.set(Some(format!("Job submitted: {job_id}")));
                                        // Refresh jobs list
                                        if let Ok(jobs) = svc.all_jobs() {
                                            state.write().jobs = jobs;
                                        }
                                    }
                                    Err(e) => {
                                        tracing::error!(error = %e, "print failed");
                                        print_result.set(Some(format!("Print failed: {e}")));
                                    }
                                }
                                printing.set(false);
                            });
                        }
                    }
                },
                if *printing.read() { "Printing..." } else { "Print" }
            }

            // Result message
            if let Some(ref msg) = *print_result.read() {
                p { style: "margin-top: 12px; color: #666; font-size: 14px; text-align: center;",
                    "{msg}"
                }
            }
        }
    }
}
