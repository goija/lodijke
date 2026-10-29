mod avored;
mod git_sync;
mod graphql;
mod pdok_wfs;
mod planimeter;

use async_graphql::{http::GraphiQLSource, EmptySubscription, Schema};
use async_graphql_axum::{GraphQLRequest, GraphQLResponse};
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::{Html, IntoResponse},
    routing::{delete, get, post},
    Json, Router,
};
use avored::{AvoRedCollection, CmsRecord, GeoParcelFeature, GitSyncEntry};
use git_sync::{get_git_branch_and_status, perform_git_sync};
use graphql::{LodijkeSchema, MutationRoot, QueryRoot};
use pdok_wfs::fetch_pdok_kadaster_bbox;
use planimeter::integrate_rd_polygon;
use serde::Deserialize;
use serde_json::json;
use std::{net::SocketAddr, path::PathBuf, sync::Arc};
use tokio::sync::RwLock;
use tower_http::{
    cors::CorsLayer,
    services::{ServeDir, ServeFile},
};

#[derive(Clone)]
pub struct AppState {
    pub base_dir: PathBuf,
    pub cms_file: PathBuf,
    pub col_file: PathBuf,
    pub geo_file: PathBuf,
    pub git_log_file: PathBuf,
    pub records: Arc<RwLock<Vec<CmsRecord>>>,
    pub collections: Arc<RwLock<Vec<AvoRedCollection>>>,
    pub geo_parcels: Arc<RwLock<Vec<GeoParcelFeature>>>,
}

#[derive(Deserialize)]
struct GitSyncRequest {
    message: Option<String>,
    push: Option<bool>,
}

#[derive(Deserialize)]
struct CustomPlanimeterRequest {
    label: Option<String>,
    rd_polygon: Vec<Vec<f64>>,
    map_scale: Option<u32>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let base_dir = PathBuf::from("/home/ontwerp/lodijke");
    let cms_file = base_dir.join("data/cms_records.json");
    let col_file = base_dir.join("data/avored_collections.json");
    let geo_file = base_dir.join("data/geojson_parcels.json");
    let git_log_file = base_dir.join("data/git_sync_log.json");
    let dist_dir = base_dir.join("frontend/dist");

    let initial_records: Vec<CmsRecord> = std::fs::read_to_string(&cms_file)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default();

    let initial_collections: Vec<AvoRedCollection> = std::fs::read_to_string(&col_file)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default();

    let initial_geo: Vec<GeoParcelFeature> = std::fs::read_to_string(&geo_file)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default();

    let state = AppState {
        base_dir,
        cms_file,
        col_file,
        geo_file,
        git_log_file,
        records: Arc::new(RwLock::new(initial_records)),
        collections: Arc::new(RwLock::new(initial_collections)),
        geo_parcels: Arc::new(RwLock::new(initial_geo)),
    };

    let schema: LodijkeSchema = Schema::build(QueryRoot, MutationRoot, EmptySubscription)
        .data(state.clone())
        .finish();

    let app = Router::new()
        .route("/health", get(health_handler))
        .route("/api/cms", get(get_cms_records).post(post_cms_record))
        .route("/api/cms/:id", delete(delete_cms_record))
        .route(
            "/api/avored/collections",
            get(get_avored_collections).post(post_avored_collection),
        )
        .route("/api/avored/status", get(avored_status_handler))
        .route("/api/geojson", get(get_rfc7946_geojson))
        .route("/api/geojson/parcels", get(get_geo_parcels))
        .route("/api/planimeter/audit", get(get_planimeter_audit))
        .route("/api/planimeter/integrate", post(post_planimeter_integrate))
        .route("/api/pdok/percelen", get(get_pdok_wfs_percelen))
        .route(
            "/api/graphql",
            get(graphiql_playground).post(graphql_execution_handler),
        )
        .route("/api/git/status", get(git_status_handler))
        .route("/api/git/sync", post(git_sync_handler))
        .route("/author", get(list_authors_handler))
        .route("/author/:id", get(get_author_handler))
        .route("/post", get(list_posts_handler))
        .route("/post/:id", get(get_post_handler))
        .route("/edit", get(edit_root_handler))
        .route("/edit/incoming", get(edit_incoming_handler))
        .route("/edit/outgoing", get(edit_outgoing_handler))
        .route_service("/", ServeFile::new(dist_dir.join("index.html")))
        .nest_service("/assets", ServeDir::new(dist_dir.join("assets")))
        .layer(CorsLayer::permissive())
        .with_state(schema);

    let addr = SocketAddr::from(([127, 0, 0, 1], 8082));
    tracing::info!(
        "Lodijke Vue 3 + AvoRed Rust CMS + PDOK WFS v5.0 + GraphQL luistert op http://{}",
        addr
    );
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn graphiql_playground() -> impl IntoResponse {
    Html(GraphiQLSource::build().endpoint("/api/graphql").finish())
}

async fn graphql_execution_handler(
    State(schema): State<LodijkeSchema>,
    req: GraphQLRequest,
) -> GraphQLResponse {
    schema.execute(req.into_inner()).await.into()
}

async fn get_pdok_wfs_percelen() -> impl IntoResponse {
    let bbox = "67000,387000,75000,396000,EPSG:28992";
    match fetch_pdok_kadaster_bbox(bbox).await {
        Ok(list) => Json(json!({ "status": "OK", "bbox": bbox, "count": list.len(), "parcels": list })),
        Err(e) => Json(json!({ "status": "FALLBACK", "error": e, "parcels": [] })),
    }
}

async fn get_planimeter_audit(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    // We kunnen de state benaderen via schema data
    if let Some(state) = schema.data::<AppState>() {
        let parcels = state.geo_parcels.read().await;
        let audit: Vec<_> = parcels
            .iter()
            .map(|p| {
                integrate_rd_polygon(
                    &p.id,
                    &p.cadastral_code,
                    &p.rd_polygon,
                    Some(p.area_hectares),
                    2500,
                )
            })
            .collect();
        return Json(serde_json::to_value(audit).unwrap_or_default());
    }
    Json(json!([]))
}

async fn post_planimeter_integrate(
    Json(payload): Json<CustomPlanimeterRequest>,
) -> impl IntoResponse {
    let label = payload
        .label
        .unwrap_or_else(|| "Handmatige RD-Polygoon".to_string());
    let scale = payload.map_scale.unwrap_or(2500);
    let res = integrate_rd_polygon("custom-rd", &label, &payload.rd_polygon, None, scale);
    Json(res)
}

async fn get_rfc7946_geojson(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let parcels = state.geo_parcels.read().await;
        let features: Vec<serde_json::Value> =
            parcels.iter().map(|p| p.to_rfc7946_feature()).collect();
        return Json(json!({
            "type": "FeatureCollection",
            "name": "lodijke_tholen_scherpenisse_percelen",
            "crs_wgs84": "EPSG:4326",
            "crs_rd_new": "EPSG:28992",
            "features": features
        }));
    }
    Json(json!({}))
}

async fn get_geo_parcels(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let parcels = state.geo_parcels.read().await;
        return Json(serde_json::to_value(&*parcels).unwrap_or_default());
    }
    Json(json!([]))
}

async fn health_handler() -> impl IntoResponse {
    Json(json!({
        "status": "OK",
        "engine": "AvoRed Rust CMS + PDOK WFS v5.0 Kadaster + Shoelace Planimeter + GraphQL",
        "avg_shield": "ACTIVE",
        "graphql_endpoint": "/api/graphql",
        "pdok_wfs_endpoint": "/api/pdok/percelen",
        "port": 8082
    }))
}

async fn avored_status_handler(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let cols = state.collections.read().await;
        let recs = state.records.read().await;
        let parcels = state.geo_parcels.read().await;
        let (branch, last_commit, remote) = get_git_branch_and_status(&state.base_dir).await;
        return Json(json!({
            "cms": "avored-rust-cms-pdok-wfs-graphql-git",
            "collections_count": cols.len(),
            "records_count": recs.len(),
            "geojson_parcels_count": parcels.len(),
            "git_branch": branch,
            "git_last_commit": last_commit,
            "git_remote": remote
        }));
    }
    Json(json!({}))
}

async fn git_status_handler(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let (branch, last_commit, remote) = get_git_branch_and_status(&state.base_dir).await;
        let logs: Vec<GitSyncEntry> = std::fs::read_to_string(&state.git_log_file)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();
        return Json(json!({
            "branch": branch,
            "last_commit": last_commit,
            "remote": remote,
            "logs": logs
        }));
    }
    Json(json!({}))
}

async fn git_sync_handler(
    State(schema): State<LodijkeSchema>,
    Json(payload): Json<GitSyncRequest>,
) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let msg = payload
            .message
            .unwrap_or_else(|| "[AvoRed CMS] Synchronisatie collecties, PDOK WFS & Planimeter".to_string());
        let push = payload.push.unwrap_or(false);
        let entry = perform_git_sync(
            &state.base_dir,
            &state.git_log_file,
            "REST_GIT_SYNC",
            &msg,
            push,
        )
        .await;
        let (branch, last_commit, remote) = get_git_branch_and_status(&state.base_dir).await;
        let logs: Vec<GitSyncEntry> = std::fs::read_to_string(&state.git_log_file)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();
        return Json(json!({
            "latest": entry,
            "branch": branch,
            "last_commit": last_commit,
            "remote": remote,
            "logs": logs
        }));
    }
    Json(json!({}))
}

async fn get_cms_records(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let recs = state.records.read().await;
        return Json(serde_json::to_value(&*recs).unwrap_or_default());
    }
    Json(json!([]))
}

async fn post_cms_record(
    State(schema): State<LodijkeSchema>,
    Json(payload): Json<CmsRecord>,
) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let title_copy = payload.title.clone();
        let id_copy = payload.id.clone();
        {
            let mut recs = state.records.write().await;
            recs.insert(0, payload);
            if let Ok(json_str) = serde_json::to_string_pretty(&*recs) {
                let _ = std::fs::write(&state.cms_file, json_str);
            }
        }
        let bg_state = state.clone();
        tokio::spawn(async move {
            let msg = format!("[Auto-Git] Nieuw archiefstuk: {} ({})", title_copy, id_copy);
            let _ = perform_git_sync(
                &bg_state.base_dir,
                &bg_state.git_log_file,
                "AUTO_POST_CMS",
                &msg,
                false,
            )
            .await;
        });
        let recs = state.records.read().await;
        return Json(serde_json::to_value(&*recs).unwrap_or_default());
    }
    Json(json!([]))
}

async fn delete_cms_record(
    Path(id): Path<String>,
    State(schema): State<LodijkeSchema>,
) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        {
            let mut recs = state.records.write().await;
            recs.retain(|r| r.id != id);
            if let Ok(json_str) = serde_json::to_string_pretty(&*recs) {
                let _ = std::fs::write(&state.cms_file, json_str);
            }
        }
        let bg_state = state.clone();
        let id_copy = id.clone();
        tokio::spawn(async move {
            let msg = format!("[Auto-Git] Verwijderd archiefstuk: {}", id_copy);
            let _ = perform_git_sync(
                &bg_state.base_dir,
                &bg_state.git_log_file,
                "AUTO_DELETE_CMS",
                &msg,
                false,
            )
            .await;
        });
        let recs = state.records.read().await;
        return Json(serde_json::to_value(&*recs).unwrap_or_default());
    }
    Json(json!([]))
}

async fn get_avored_collections(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let cols = state.collections.read().await;
        return Json(serde_json::to_value(&*cols).unwrap_or_default());
    }
    Json(json!([]))
}

async fn post_avored_collection(
    State(schema): State<LodijkeSchema>,
    Json(payload): Json<AvoRedCollection>,
) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let col_id = payload.identifier.clone();
        {
            let mut cols = state.collections.write().await;
            cols.push(payload);
            if let Ok(json_str) = serde_json::to_string_pretty(&*cols) {
                let _ = std::fs::write(&state.col_file, json_str);
            }
        }
        let bg_state = state.clone();
        tokio::spawn(async move {
            let msg = format!("[Auto-Git] Nieuwe AvoRed collectie: {}", col_id);
            let _ = perform_git_sync(
                &bg_state.base_dir,
                &bg_state.git_log_file,
                "AUTO_POST_COLLECTION",
                &msg,
                false,
            )
            .await;
        });
        let cols = state.collections.read().await;
        return Json(serde_json::to_value(&*cols).unwrap_or_default());
    }
    Json(json!([]))
}

async fn list_authors_handler() -> impl IntoResponse {
    Json(json!([
        {
            "id": "I0103",
            "name": "Benjamin Willem Schot (1840-1935)",
            "location": "Kruittoren 23, Tholen",
            "fleet": ["TH 2", "TH 12", "TH 90"]
        }
    ]))
}

async fn get_author_handler(Path(id): Path<String>) -> impl IntoResponse {
    if id == "I0103" {
        (
            StatusCode::OK,
            Json(json!({
                "id": "I0103",
                "name": "Benjamin Willem Schot (1840-1935)",
                "perceel": "Perceel No. 369 Bol van Lodijke (12,5 ha)",
                "avg_shield": "Generatie I & II afgeschermd"
            })),
        )
    } else {
        (
            StatusCode::NOT_FOUND,
            Json(json!({ "error": "Auteur niet gevonden" })),
        )
    }
}

async fn list_posts_handler(State(schema): State<LodijkeSchema>) -> impl IntoResponse {
    get_cms_records(State(schema)).await
}

async fn get_post_handler(
    Path(id): Path<String>,
    State(schema): State<LodijkeSchema>,
) -> impl IntoResponse {
    if let Some(state) = schema.data::<AppState>() {
        let recs = state.records.read().await;
        if let Some(found) = recs.iter().find(|r| r.id == id) {
            return (StatusCode::OK, Json(json!(found)));
        }
    }
    (
        StatusCode::NOT_FOUND,
        Json(json!({ "error": "Archiefstuk niet gevonden" })),
    )
}

async fn edit_root_handler() -> impl IntoResponse {
    Json(json!({
        "workflow": "AvoRed Editorial Queue + PDOK WFS v5.0 Kadaster + Shoelace Planimeter + GraphQL",
        "endpoints": ["/edit/incoming", "/edit/outgoing", "/api/graphql", "/api/pdok/percelen", "/api/geojson"]
    }))
}

async fn edit_incoming_handler() -> impl IntoResponse {
    Json(json!({ "queue": "incoming", "status": "ready", "avg_check": "enforced" }))
}

async fn edit_outgoing_handler() -> impl IntoResponse {
    Json(json!({ "queue": "outgoing", "status": "published", "solid_pod_sync": true, "git_auto_commit": true }))
}
