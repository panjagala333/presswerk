// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>
//
// Presswerk — High-Assurance Local Print Router/Server
//
// Entry point. Initialises logging, backend services, app state, and launches
// the Dioxus UI.

mod pages;
mod services;
mod state;

use dioxus::prelude::*;

use pages::audit::Audit;
use pages::edit::Edit;
use pages::home::Home;
use pages::jobs::Jobs;
use pages::print::Print;
use pages::scan::Scan;
use pages::server::Server;
use pages::settings::Settings;
use pages::text_editor::TextEditor;

use services::app_services::AppServices;

fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    tracing::info!("Presswerk starting");

    dioxus::launch(app);
}

/// Top-level route enum.
#[derive(Debug, Clone, Routable, PartialEq)]
enum Route {
    #[layout(TabLayout)]
    #[route("/")]
    Home {},
    #[route("/print")]
    Print {},
    #[route("/scan")]
    Scan {},
    #[route("/edit")]
    Edit {},
    #[route("/text")]
    TextEditor {},
    #[route("/server")]
    Server {},
    #[route("/jobs")]
    Jobs {},
    #[route("/audit")]
    Audit {},
    #[route("/settings")]
    Settings {},
}

/// Root component.
fn app() -> Element {
    // Initialise backend services (databases, mDNS, config)
    let svc = use_hook(|| match AppServices::init() {
        Ok(s) => {
            tracing::info!("backend services initialised");
            s
        }
        Err(e) => {
            tracing::error!(error = %e, "persistent storage failed — using in-memory fallback");
            AppServices::fallback().expect("even fallback init failed")
        }
    });

    // Provide services and state as context for all pages
    use_context_provider(|| svc.clone());
    use_context_provider(|| Signal::new(state::AppState::new(&svc)));

    // Auto-start discovery if we have it
    let svc_clone = svc.clone();
    use_hook(move || {
        if let Err(e) = svc_clone.start_discovery() {
            tracing::warn!(error = %e, "auto-start discovery failed");
        }
    });

    rsx! {
        Router::<Route> {}
    }
}

/// Persistent bottom tab layout wrapping all pages.
#[component]
fn TabLayout() -> Element {
    rsx! {
        div { class: "app-container",
            style: "display: flex; flex-direction: column; height: 100vh; font-family: system-ui, -apple-system, sans-serif;",

            // Page content
            div { class: "page-content",
                style: "flex: 1; overflow-y: auto; padding: 16px;",
                Outlet::<Route> {}
            }

            // Bottom tab bar
            nav { class: "tab-bar",
                style: "display: flex; justify-content: space-around; padding: 8px 0; border-top: 1px solid #e0e0e0; background: #fafafa;",
                TabButton { to: Route::Home {}, label: "Home", icon: "H" }
                TabButton { to: Route::Print {}, label: "Print", icon: "P" }
                TabButton { to: Route::Scan {}, label: "Scan", icon: "S" }
                TabButton { to: Route::Edit {}, label: "Edit", icon: "E" }
                TabButton { to: Route::Server {}, label: "Server", icon: "N" }
            }
        }
    }
}

#[component]
fn TabButton(to: Route, label: &'static str, icon: &'static str) -> Element {
    rsx! {
        Link { to: to,
            style: "display: flex; flex-direction: column; align-items: center; text-decoration: none; color: #333; font-size: 12px;",
            span { style: "font-size: 20px;", "{icon}" }
            span { "{label}" }
        }
    }
}
