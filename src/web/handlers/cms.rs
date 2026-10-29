use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use crate::models::{AppState, CmsRecord};

pub async fn handler_cms_list(State(state): State<AppState>) -> impl IntoResponse {
    let records = state.cms_records.read().await;
    (StatusCode::OK, Json(records.clone()))
}

pub async fn handler_cms_create(
    State(state): State<AppState>,
    Json(payload): Json<CmsRecord>,
) -> impl IntoResponse {
    let mut records = state.cms_records.write().await;
    records.insert(0, payload.clone());

    if let Err(err) = save_cms_to_disk(&state.cms_file_path, &records).await {
        tracing::error!("Fout bij atomair opslaan van CMS JSON: {}", err);
        return (StatusCode::INTERNAL_SERVER_ERROR, Json(payload));
    }

    (StatusCode::CREATED, Json(payload))
}

pub async fn handler_cms_delete(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let mut records = state.cms_records.write().await;
    let initial_len = records.len();
    records.retain(|r| r.id != id);

    if records.len() == initial_len {
        return StatusCode::NOT_FOUND;
    }

    let _ = save_cms_to_disk(&state.cms_file_path, &records).await;
    StatusCode::NO_CONTENT
}

async fn save_cms_to_disk(
    path: &std::path::Path,
    records: &[CmsRecord],
) -> std::io::Result<()> {
    let tmp_path = path.with_extension("json.tmp");
    let serialized = serde_json::to_string_pretty(records)?;
    tokio::fs::write(&tmp_path, serialized).await?;
    tokio::fs::rename(&tmp_path, path).await?;
    Ok(())
}
