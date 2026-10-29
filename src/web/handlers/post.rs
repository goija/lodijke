use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use crate::models::{AppState, PostItem};

pub async fn handler_post_list(State(state): State<AppState>) -> impl IntoResponse {
    let posts = state.posts.read().await;
    (StatusCode::OK, Json(posts.clone()))
}

pub async fn handler_post_get(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let posts = state.posts.read().await;
    match posts.iter().find(|p| p.id == id) {
        Some(post) => (StatusCode::OK, Json(serde_json::json!(post))),
        None => (
            StatusCode::NOT_FOUND,
            Json(serde_json::json!({ "error": "Post not found" })),
        ),
    }
}

pub async fn handler_post_create(
    State(state): State<AppState>,
    Json(payload): Json<PostItem>,
) -> impl IntoResponse {
    let mut posts = state.posts.write().await;
    posts.push(payload.clone());
    (StatusCode::CREATED, Json(payload))
}

pub async fn handler_post_update(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(payload): Json<PostItem>,
) -> impl IntoResponse {
    let mut posts = state.posts.write().await;
    if let Some(post) = posts.iter_mut().find(|p| p.id == id) {
        post.title = payload.title;
        post.content = payload.content;
        return (StatusCode::OK, Json(serde_json::json!(post)));
    }
    (
        StatusCode::NOT_FOUND,
        Json(serde_json::json!({ "error": "Post not found" })),
    )
}

pub async fn handler_post_delete(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let mut posts = state.posts.write().await;
    let before = posts.len();
    posts.retain(|p| p.id != id);
    if posts.len() < before {
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}
