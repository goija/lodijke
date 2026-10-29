use axum::{
    extract::State,
    http::StatusCode,
    response::{Html, IntoResponse},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::fs;
use std::sync::{Arc, Mutex};
use tower_http::cors::{Any, CorsLayer};

#[derive(Clone, Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct CmsRecord {
    pub id: String,
    pub title: String,
    pub content: String,
    pub created_at: String,
}

#[derive(Clone)]
pub struct AppState {
    pub records: Arc<Mutex<Vec<CmsRecord>>>,
}

impl AppState {
    pub fn load_or_init() -> Self {
        let records = match fs::read_to_string("data/cms_records.json") {
            Ok(content) => serde_json::from_str(&content).unwrap_or_else(|_| Self::default_records()),
            Err(_) => Self::default_records(),
        };
        AppState {
            records: Arc::new(Mutex::new(records)),
        }
    }

    fn default_records() -> Vec<CmsRecord> {
        vec![
            CmsRecord {
                id: "doc-369".into(),
                title: "Oesterperceel No. 369 Concessie".into(),
                content: "Concessie op de Bol van Lodijke (12,5 ha) gepacht door B.W. Schot.".into(),
                created_at: "1892-11-22".into(),
            },
            CmsRecord {
                id: "doc-gortzak".into(),
                title: "Hofstede De Gortzak Schakerloo".into(),
                content: "Tholen Sectie I nr. 360 (53,75 ha / 122 gemeten).".into(),
                created_at: "1873-12-23".into(),
            },
        ]
    }

    pub fn save_to_disk(&self) {
        if let Ok(guard) = self.records.lock() {
            if let Ok(json_str) = serde_json::to_string_pretty(&*guard) {
                let _ = fs::create_dir_all("data");
                let _ = fs::write("data/cms_records.json", json_str);
            }
        }
    }
}

// Standalone, 100% lokale GraphQL Studio zonder externe CDN's
async fn graphql_ide() -> Html<&'static str> {
    Html(r#"<!DOCTYPE html>
<html lang="nl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Lodijke GraphQL Studio (Poort 8082)</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #1e1e2e; color: #cdd6f4; height: 100vh; display: flex; flex-direction: column; }
    header { background: #181825; padding: 1rem 1.5rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #313244; }
    h1 { margin: 0; font-size: 1.25rem; color: #f38ba8; display: flex; align-items: center; gap: 0.5rem; }
    .badge { background: #a6e3a1; color: #11111b; padding: 0.25rem 0.75rem; border-radius: 12px; font-weight: bold; font-size: 0.8rem; }
    .toolbar { background: #181825; padding: 0.75rem 1.5rem; display: flex; gap: 0.75rem; border-bottom: 1px solid #313244; align-items: center; flex-wrap: wrap; }
    .btn { background: #89b4fa; color: #11111b; border: none; padding: 0.5rem 1rem; border-radius: 6px; font-weight: bold; cursor: pointer; font-size: 0.9rem; transition: background 0.2s; }
    .btn:hover { background: #b4befe; }
    .btn-exec { background: #a6e3a1; color: #11111b; font-size: 1rem; padding: 0.5rem 1.25rem; }
    .btn-exec:hover { background: #94e2d5; }
    .container { flex: 1; display: grid; grid-template-columns: 1fr 1fr; gap: 1px; background: #313244; overflow: hidden; }
    .pane { background: #1e1e2e; display: flex; flex-direction: column; height: 100%; }
    .pane-header { background: #181825; padding: 0.5rem 1rem; font-size: 0.85rem; font-weight: bold; color: #a6adc8; border-bottom: 1px solid #313244; text-transform: uppercase; letter-spacing: 0.5px; }
    textarea { flex: 1; background: #1e1e2e; color: #a6e3a1; border: none; padding: 1rem; font-family: "Fira Code", "Courier New", monospace; font-size: 0.95rem; resize: none; outline: none; line-height: 1.5; }
    .variables-pane { height: 140px; border-top: 1px solid #313244; display: flex; flex-direction: column; }
    .variables-pane textarea { color: #f9e2af; font-size: 0.85rem; }
    pre { flex: 1; margin: 0; padding: 1rem; background: #181825; color: #89b4fa; font-family: "Fira Code", "Courier New", monospace; font-size: 0.9rem; overflow: auto; line-height: 1.5; white-space: pre-wrap; word-break: break-all; }
  </style>
</head>
<body>
  <header>
    <h1>🏛️ Lodijke Axum GraphQL Studio</h1>
    <span class="badge">Online op :8082</span>
  </header>
  <div class="toolbar">
    <button class="btn btn-exec" onclick="runQuery()">▶ Uitvoeren</button>
    <button class="btn" onclick="loadQueryPreset()">🔍 Preset: Query (Documenten Opvragen)</button>
    <button class="btn" onclick="loadMutationPreset()">⚡ Preset: Mutation (Document Toevoegen)</button>
  </div>
  <div class="container">
    <div class="pane">
      <div class="pane-header">GraphQL Query / Mutation</div>
      <textarea id="queryInput" spellcheck="false"></textarea>
      <div class="variables-pane">
        <div class="pane-header">Query Variables (JSON)</div>
        <textarea id="variablesInput" spellcheck="false"></textarea>
      </div>
    </div>
    <div class="pane">
      <div class="pane-header">JSON Respons (Axum Backend)</div>
      <pre id="jsonOutput">// Klik op "▶ Uitvoeren" om data op te halen...</pre>
    </div>
  </div>
  <script>
    const queryPreset = `query {\n  cmsRecords {\n    id\n    title\n    content\n    createdAt\n  }\n}`;

    const mutationPreset = `mutation AddRecord($title: String!, $content: String!) {\n  addCmsRecord(title: $title, content: $content) {\n    id\n    title\n    content\n    createdAt\n  }\n}`;

    const variablesPreset = `{\n  "title": "Woo-besluit Zaak 1456324 (Molenplaat)",\n  "content": "Pachtovereenkomst en visserijrechten 1892-1935."\n}`;

    function loadQueryPreset() {
      document.getElementById('queryInput').value = queryPreset;
      document.getElementById('variablesInput').value = '{}';
    }

    function loadMutationPreset() {
      document.getElementById('queryInput').value = mutationPreset;
      document.getElementById('variablesInput').value = variablesPreset;
    }

    async function runQuery() {
      const query = document.getElementById('queryInput').value;
      const varStr = document.getElementById('variablesInput').value;
      const out = document.getElementById('jsonOutput');
      out.textContent = "Bezig met verwerken...";

      let variables = {};
      try {
        if (varStr.trim()) variables = JSON.parse(varStr);
      } catch (e) {
        out.textContent = "❌ Fout in JSON Variables: " + e.message;
        return;
      }

      try {
        const res = await fetch('/api/graphql', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query, variables })
        });
        const data = await res.json();
        out.textContent = JSON.stringify(data, null, 2);
      } catch (err) {
        out.textContent = "❌ Verbindingsfout: " + err.message;
      }
    }

    loadQueryPreset();
  </script>
</body>
</html>"#)
}

#[derive(Deserialize, Debug)]
pub struct GraphQLPayload {
    pub query: String,
    pub variables: Option<Value>,
}

async fn graphql_handler(
    State(state): State<AppState>,
    Json(payload): Json<GraphQLPayload>,
) -> impl IntoResponse {
    let query_str = payload.query.trim();

    if query_str.contains("mutation") || query_str.contains("addCmsRecord") {
        let title = payload
            .variables
            .as_ref()
            .and_then(|v| v.get("title"))
            .and_then(|v| v.as_str())
            .unwrap_or("Nieuw Document");

        let content = payload
            .variables
            .as_ref()
            .and_then(|v| v.get("content"))
            .and_then(|v| v.as_str())
            .unwrap_or("Geen inhoud");

        let new_record = CmsRecord {
            id: format!("doc-{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_millis()),
            title: title.to_string(),
            content: content.to_string(),
            created_at: chrono::Utc::now().format("%Y-%m-%d").to_string(),
        };

        {
            let mut guard = state.records.lock().unwrap();
            guard.push(new_record.clone());
        }
        state.save_to_disk();

        let response = json!({
            "data": {
                "addCmsRecord": new_record
            }
        });
        (StatusCode::OK, Json(response))
    } else {
        let guard = state.records.lock().unwrap();
        let records = guard.clone();

        let response = json!({
            "data": {
                "cmsRecords": records
            }
        });
        (StatusCode::OK, Json(response))
    }
}

#[tokio::main]
async fn main() {
    let state = AppState::load_or_init();
    state.save_to_disk();

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/", get(graphql_ide))
        .route("/graphql", get(graphql_ide))
        .route("/api/graphql", get(graphql_ide).post(graphql_handler))
        .layer(cors)
        .with_state(state);

    println!("🚀 GraphQL Studio & API actief op http://127.0.0.1:8082");

    let listener = tokio::net::TcpListener::bind("127.0.0.1:8082").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
