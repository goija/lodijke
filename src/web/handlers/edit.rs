use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use crate::models::{AppState, EditItem};

pub async fn handler_edit_list_all(State(state): State<AppState>) -> impl IntoResponse {
    let edits = state.edits.read().await;
    (StatusCode::OK, Json(edits.clone()))
}

pub async fn handler_edit_create(
    State(state): State<AppState>,
    Json(payload): Json<EditItem>,
) -> impl IntoResponse {
    let mut edits = state.edits.write().await;
    edits.push(payload.clone());
    (StatusCode::CREATED, Json(payload))
}

pub async fn handler_edit_get(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let edits = state.edits.read().await;
    match edits.iter().find(|e| e.id == id) {
        Some(edit) => (StatusCode::OK, Json(serde_json::json!(edit))),
        None => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({ "error": "Edit not found" })),
        ),
    }
}

pub async fn handler_edit_update(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(payload): Json<EditItem>,
) -> impl IntoResponse {
    let mut edits = state.edits.write().await;
    if let Some(edit) = edits.iter_mut().find(|e| e.id == id) {
        edit.proposed_content = payload.proposed_content;
        edit.status = payload.status;
        return (StatusCode::OK, Json(serde_json::json!(edit)));
    }
    (
        StatusCode::NOT_FOUND,
        Json(serde_json::json!({ "error": "Edit not found" })),
    )
}

pub async fn handler_edit_delete(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let mut edits = state.edits.write().await;
    let before = edits.len();
    edits.retain(|e| e.id != id);
    if edits.len() < before {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

pub async fn handler_edit_accept(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let mut edits = state.edits.write().await;
    if let Some(edit) = edits.iter_mut().find(|e| e.id == id) {
        edit.status = "ACCEPTED".to_string();
        return (StatusCode::OK, Json(serde_json::json!(edit)));
    }
    (
        StatusCode::NOT_FOUND,
        Json(serde_json::json!({ "error": "Edit not found" })),
    )
}

pub async fn handler_edit_reject(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let mut edits = state.edits.write().await;
    if let Some(edit) = edits.iter_mut().find(|e| e.id == id) {
        edit.status = "REJECTED".to_string();
        return (StatusCode::OK, Json(serde_json::json!(edit)));
    }
    (
        StatusCode::NOT_FOUND,
        Json(serde_json::json!({ "error": "Edit not found" })),
    )
}

pub async fn handler_edit_list_outgoing(State(state): State<AppState>) -> impl IntoResponse {
    let edits = state.edits.read().await;
    let outgoing: Vec<EditItem> = edits
        .iter()
        .filter(|e| e.direction.eq_ignore_ascii_case("OUTGOING"))
        .cloned()
        .collect();
    (StatusCode::OK, Json(outgoing))
}

pub async fn handler_edit_list_incoming(State(state): State<AppState>) -> impl IntoResponse {
    let edits = state.edits.read().await;
    let incoming: Vec<EditItem> = edits
        .iter()
        .filter(|e| e.direction.eq_ignore_ascii_case("INCOMING"))
        .cloned()
        .collect();
    (StatusCode::OK, Json(incoming))
}
