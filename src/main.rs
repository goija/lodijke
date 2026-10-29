use async_graphql::{
    http::GraphiQLSource,
    EmptyMutation, EmptySubscription, Object, Request, Response, Schema, SimpleObject,
};
use axum::{
    extract::Extension,
    response::{Html, IntoResponse},
    routing::get,
    Json, Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};

#[derive(SimpleObject, Clone)]
pub struct CmsRecord {
    pub id: String,
    pub title: String,
    pub content: String,
    pub created_at: String,
}

pub struct QueryRoot;

#[Object]
impl QueryRoot {
    async fn hello(&self) -> &'static str {
        "Lodijke Master Platform API operational"
    }

    async fn cms_records(&self) -> Vec<CmsRecord> {
        vec![
            CmsRecord {
                id: "doc-369".to_string(),
                title: "Oesterperceel No. 369 Concessie".to_string(),
                content: "Concessie op de Bol van Lodijke (12,5 ha) van B.W. Schot.".to_string(),
                created_at: "1892-11-22".to_string(),
            },
            CmsRecord {
                id: "doc-gortzak".to_string(),
                title: "Hofstede De Gortzak Schakerloo".to_string(),
                content: "Tholen Sectie I nr. 360 (53,75 ha / 122 gemeten).".to_string(),
                created_at: "1873-12-23".to_string(),
            }
        ]
    }
}

pub type AppSchema = Schema<QueryRoot, EmptyMutation, EmptySubscription>;

async fn graphql_handler(
    Extension(schema): Extension<AppSchema>,
    Json(req): Json<Request>,
) -> Json<Response> {
    Json(schema.execute(req).await)
}

async fn graphiql_playground() -> impl IntoResponse {
    Html(GraphiQLSource::build().endpoint("/api/graphql").finish())
}

async fn health_check() -> &'static str {
    "Lodijke Backend API is running on port 8082!"
}

#[tokio::main]
async fn main() {
    let schema = Schema::build(QueryRoot, EmptyMutation, EmptySubscription).finish();

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/", get(health_check))
        .route("/api/graphql", get(graphiql_playground).post(graphql_handler))
        .layer(cors)
        .layer(Extension(schema));

    let addr: SocketAddr = "127.0.0.1:8082".parse().unwrap();
    println!("🚀 Lodijke Backend gestart op http://{}", addr);
    println!("📊 GraphQL Explorer bereikbaar op http://localhost:8082/api/graphql");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
