use axum::{
    http::StatusCode,
    middleware,
    response::IntoResponse,
    routing::{delete, get, patch, post},
    Router,
};
use tower_http::services::ServeFile;

use crate::models::AppState;
use crate::web::handlers::{
    author::{handler_author_get, handler_author_list},
    cms::{handler_cms_create, handler_cms_delete, handler_cms_list},
    edit::{
        handler_edit_accept, handler_edit_create, handler_edit_delete, handler_edit_get,
        handler_edit_list_all, handler_edit_list_incoming, handler_edit_list_outgoing,
        handler_edit_reject, handler_edit_update,
    },
    hello::{handler_hello, handler_hello_2},
    post::{
        handler_post_create, handler_post_delete, handler_post_get, handler_post_list,
        handler_post_update,
    },
};
use super::middlewares::auth::mw_ctx_require;

pub fn routes_main(app_state: AppState) -> Router {
    Router::new()
        .route_service("/", ServeFile::new("index.html"))
        .route_service("/index.html", ServeFile::new("index.html"))
        .route("/health", get(handler_hello_2))
        .route("/hello", get(handler_hello))
        .merge(routes_cms(app_state.clone()))
        .merge(routes_post(app_state.clone()))
        .merge(routes_author(app_state.clone()))
        .merge(routes_edit(app_state))
        .fallback(handler_404)
}

/// 1. Archief & Solid POD CMS Routes (/api/cms)
fn routes_cms(app_state: AppState) -> Router {
    Router::new()
        .route("/api/cms", get(handler_cms_list).post(handler_cms_create))
        .route("/api/cms/:id", delete(handler_cms_delete))
        .with_state(app_state)
}

/// 2. Author Routes (/author)
fn routes_author(app_state: AppState) -> Router {
    Router::new()
        .route("/author", get(handler_author_list))
        .route("/author/:id", get(handler_author_get))
        .with_state(app_state)
}

/// 3. Post Routes (/post) - Gesplitst in publiek & beveiligd
fn routes_post(app_state: AppState) -> Router {
    let public_routes = Router::new()
        .route("/post", get(handler_post_list))
        .route("/post/:id", get(handler_post_get));

    let protected_routes = Router::new()
        .route("/post", post(handler_post_create))
        .route("/post/:id", patch(handler_post_update).delete(handler_post_delete))
        .route_layer(middleware::from_fn(mw_ctx_require));

    public_routes
        .merge(protected_routes)
        .with_state(app_state)
}

/// 4. Edit Routes (/edit)
fn routes_edit(app_state: AppState) -> Router {
    Router::new()
        .route("/edit", post(handler_edit_create).get(handler_edit_list_all))
        .route(
            "/edit/:id",
            get(handler_edit_get)
                .patch(handler_edit_update)
                .delete(handler_edit_delete),
        )
        .route("/edit/accept/:id", post(handler_edit_accept))
        .route("/edit/reject/:id", post(handler_edit_reject))
        .route("/edit/outgoing", get(handler_edit_list_outgoing))
        .route("/edit/incoming", get(handler_edit_list_incoming))
        .route_layer(middleware::from_fn(mw_ctx_require))
        .with_state(app_state)
}

/// 404 Route
pub async fn handler_404() -> impl IntoResponse {
    (StatusCode::NOT_FOUND, "Route not found")
}
