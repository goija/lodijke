use axum::response::IntoResponse;

pub async fn handler_hello() -> impl IntoResponse {
    "Archief & Rust CMS — Familie Schot, Bout & Bol van Lodijke"
}

pub async fn handler_hello_2() -> impl IntoResponse {
    "Status: OK (127.0.0.1:8082)"
}
