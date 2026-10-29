use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use crate::models::AppState;

pub async fn handler_author_list(State(state): State<AppState>) -> impl IntoResponse {
    let authors = state.authors.read().await;
    (StatusCode::OK, Json(authors.clone()))
}

pub async fn handler_author_get(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let authors = state.authors.read().await;
    match authors.iter().find(|a| a.id == id) {
        Some(author) => (StatusCode::OK, Json(serde_json::json!(author))),
        None => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({ "error": "Author not found" })),
        ),
    }
}
