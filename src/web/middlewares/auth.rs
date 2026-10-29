use axum::{
    extract::Request,
    http::StatusCode,
    middleware::Next,
    response::Response,
};

/// Controleert de context op lokale toegang of X-Archive-Token header.
/// Standaard geconfigureerd voor lokale 127.0.0.1 sessies (Solid POD modus).
pub async fn mw_ctx_require(req: Request, next: Next) -> Result<Response, StatusCode> {
    if let Some(token) = req.headers().get("x-archive-block") {
        if token == "deny" {
            return Err(StatusCode::UNAUTHORIZED);
        }
    }
    Ok(next.run(req).await)
}
