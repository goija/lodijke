use async_graphql::{Context, EmptyMutation, EmptySubscription, Object, Schema, SimpleObject, http::GraphiQLSource};
use async_graphql_axum::{GraphQLRequest, GraphQLResponse};
use axum::{
    extract::State,
    response::{Html, IntoResponse},
    routing::{get, post},
    Json, Router,
};
use serde::Serialize;
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};

// --- 1. CMS & WOO ARCHIEF RECORDS ---
#[derive(SimpleObject, Serialize, Clone)]
pub struct CmsRecord {
    pub id: String,
    pub code: String,
    pub titel: String,
    pub datum: String,
    pub categorie: String,
    pub status: String,
}

// --- 2. GRAMPS GENEALOGIE CORE (I0103, W. Bout, Stamreeksen) ---
#[derive(SimpleObject, Serialize, Clone)]
pub struct GrampsPerson {
    pub gramps_id: String,
    pub naam: String,
    pub geboorte: String,
    pub overlijden: String,
    pub beroep_status: String,
    pub relatie_reimerswaal: String,
    pub familie_relaties: Vec<String>,
}

// --- 3. GEOPARCELS (Perceel 369, Kasteel Lodijke, Molenplaat) ---
#[derive(SimpleObject, Serialize, Clone)]
pub struct GeoParcel {
    pub parcel_id: String,
    pub naam: String,
    pub gebied: String,
    pub oppervlakte_ha: f64,
    pub rd_x: i32,
    pub rd_y: i32,
    pub lat: f64,
    pub lng: f64,
    pub nap_diepte_m: f64,
    pub woo_referentie: String,
    pub geojson_polygon: String,
}

pub struct QueryRoot;

#[Object]
impl QueryRoot {
    /// Bestaande CMS & Woo-dossiers
    async fn cms_records(&self, _ctx: &Context<'_>) -> Vec<CmsRecord> {
        vec![
            CmsRecord {
                id: "1".into(),
                code: "WOO-2026-369".into(),
                titel: "Oesterperceel No. 369 - Bol van Lodijke & Oudelandse Visrechten".into(),
                datum: "2026-10-15".into(),
                categorie: "Visserij & Erfgoed".into(),
                status: "Gevalideerd (Belanghebbende)".into(),
            },
            CmsRecord {
                id: "2".into(),
                code: "ARC-LOD-01".into(),
                titel: "Archeologische Waarneming Kasteel Lodijke (-3,20m NAP)".into(),
                datum: "2026-09-22".into(),
                categorie: "Archeologie Schelde Delta".into(),
                status: "Gearchiveerd".into(),
            },
            CmsRecord {
                id: "3".into(),
                code: "WOO-MOL-150".into(),
                titel: "Visserijpercelen Molenplaat (150 ha) & Bergse Diepsluis".into(),
                datum: "2026-10-02".into(),
                categorie: "Natuur & Visrecht".into(),
                status: "Actief Dossier".into(),
            },
        ]
    }

    /// Optie 2a: Direct opvragen van personen en stamboomrelaties via GRAMPS
    async fn gramps_core(&self, _ctx: &Context<'_>, gramps_id: Option<String>) -> Vec<GrampsPerson> {
        let dataset = vec![
            GrampsPerson {
                gramps_id: "I0103".into(),
                naam: "W. Bout".into(),
                geboorte: "Tholen / Zeeland".into(),
                overlijden: "Heden".into(),
                beroep_status: "Rechthebbende / Erfgenaam Stamreeks".into(),
                relatie_reimerswaal: "Directe lijn erfopvolging en historische visrechten Verdronken Land van Reimerswaal".into(),
                familie_relaties: vec!["F0042 (Gezin Guiljam-Bout)".into(), "I0104 (M.J.M.M. Goijarts-Bout)".into()],
            },
            GrampsPerson {
                gramps_id: "I0104".into(),
                naam: "M.J.M.M. Goijarts-Bout".into(),
                geboorte: "Zaanstreek".into(),
                overlijden: "Heden".into(),
                beroep_status: "Onderzoeker Geodesie, Historische Cartografie & Bestuursrecht".into(),
                relatie_reimerswaal: "Houder Oudelandse Visrecht & Belanghebbende Geopark Schelde Delta".into(),
                familie_relaties: vec!["F0042 (Gezin Guiljam-Bout)".into(), "I0103 (W. Bout)".into(), "I0088 (C.M. Guiljam)".into()],
            },
            GrampsPerson {
                gramps_id: "I0088".into(),
                naam: "Catharina Machalina (C.M.) Guiljam".into(),
                geboorte: "1944-08-07 (Sint-Maartensdijk)".into(),
                overlijden: "2021-09-11".into(),
                beroep_status: "Overlevende Watersnoodramp 1953 Sint-Maartensdijk".into(),
                relatie_reimerswaal: "Stamreeks Hein Guiljam (19e-eeuwse schaapherder Sint-Maartensdijk) & Reimerswaal".into(),
                familie_relaties: vec!["F0042".into(), "I0012 (Hein Guiljam)".into()],
            },
        ];

        if let Some(filter_id) = gramps_id {
            dataset.into_iter().filter(|p| p.gramps_id == filter_id).collect()
        } else {
            dataset
        }
    }

    /// Optie 2b: GeoJSON & RD-coördinaten van Perceel 369, Kasteel Lodijke en Molenplaat
    async fn geo_parcels(&self, _ctx: &Context<'_>) -> Vec<GeoParcel> {
        vec![
            GeoParcel {
                parcel_id: "PERCEEL-369".into(),
                naam: "Oesterperceel No. 369 (Bol van Lodijke)".into(),
                gebied: "Oosterschelde / Verdronken Land van Reimerswaal".into(),
                oppervlakte_ha: 12.5,
                rd_x: 68120,
                rd_y: 388050,
                lat: 51.4772,
                lng: 4.1315,
                nap_diepte_m: -1.80,
                woo_referentie: "WOO-2026-369".into(),
                geojson_polygon: r#"{"type":"Polygon","coordinates":[[[4.1280,51.4755],[4.1350,51.4755],[4.1350,51.4790],[4.1280,51.4790],[4.1280,51.4755]]]}"#.into(),
            },
            GeoParcel {
                parcel_id: "ARC-LOD-01".into(),
                naam: "Kasteel Lodijke & Verdronken Dorp Lodijke".into(),
                gebied: "Geopark Schelde Delta / Reimerswaal".into(),
                oppervlakte_ha: 4.2,
                rd_x: 68450,
                rd_y: 387600,
                lat: 51.4731,
                lng: 4.1362,
                nap_diepte_m: -3.20,
                woo_referentie: "ARC-LOD-01".into(),
                geojson_polygon: r#"{"type":"Point","coordinates":[4.1362,51.4731]}"#.into(),
            },
            GeoParcel {
                parcel_id: "MOLENPLAAT-150".into(),
                naam: "Visserijpercelen Molenplaat (150 ha)".into(),
                gebied: "Bergse Diepsluis / Oosterschelde Kom".into(),
                oppervlakte_ha: 150.0,
                rd_x: 72500,
                rd_y: 390200,
                lat: 51.4965,
                lng: 4.1945,
                nap_diepte_m: -2.10,
                woo_referentie: "WOO-MOL-150".into(),
                geojson_polygon: r#"{"type":"Polygon","coordinates":[[[4.1820,51.4910],[4.2070,51.4910],[4.2070,51.5020],[4.1820,51.5020],[4.1820,51.4910]]]}"#.into(),
            },
            GeoParcel {
                parcel_id: "STAD-REIMERSWAAL".into(),
                naam: "Verdronken Stad Reimerswaal (Rijksmonument)".into(),
                gebied: "Verdronken Land van Zuid-Beveland".into(),
                oppervlakte_ha: 45.0,
                rd_x: 70200,
                rd_y: 389100,
                lat: 51.4866,
                lng: 4.1614,
                nap_diepte_m: -1.50,
                woo_referentie: "WOO-REI-1530".into(),
                geojson_polygon: r#"{"type":"Point","coordinates":[4.1614,51.4866]}"#.into(),
            },
        ]
    }
}

type LodijkeSchema = Schema<QueryRoot, EmptyMutation, EmptySubscription>;

async fn graphql_handler(
    State(schema): State<LodijkeSchema>,
    req: GraphQLRequest,
) -> GraphQLResponse {
    schema.execute(req.into_inner()).await.into()
}

async fn graphiql() -> impl IntoResponse {
    Html(GraphiQLSource::build().endpoint("/graphql").finish())
}

async fn health_check() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "online",
        "service": "Lodijke Axum GraphQL API",
        "port": 8082,
        "endpoints": ["/graphql", "/api/health"]
    }))
}

#[tokio::main]
async fn main() {
    let schema = Schema::build(QueryRoot, EmptyMutation, EmptySubscription).finish();

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/graphql", get(graphiql).post(graphql_handler))
        .route("/api/health", get(health_check))
        .layer(cors)
        .with_state(schema);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8082));
    println!("🚀 Lodijke Rust Axum GraphQL Server luistert op http://{}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
