use crate::{
    avored::{
        AuthorProfile, AvoRedCollection, CmsRecord, CreateCmsRecordInput, CreateCollectionInput,
        CreateGeoParcelInput, GeoParcelFeature, GitSyncEntry,
    },
    git_sync::perform_git_sync,
    pdok_wfs::{fetch_pdok_kadaster_bbox, PdokPerceelFeature},
    planimeter::{integrate_rd_polygon, PlanimeterIntegrationResult},
    AppState,
};
use async_graphql::{Context, EmptySubscription, Object, Result, Schema};
use chrono::Utc;
use serde_json::json;

pub type LodijkeSchema = Schema<QueryRoot, MutationRoot, EmptySubscription>;

pub struct QueryRoot;

#[Object]
impl QueryRoot {
    async fn cms_records(
        &self,
        ctx: &Context<'_>,
        category: Option<String>,
        collection: Option<String>,
    ) -> Result<Vec<CmsRecord>> {
        let state = ctx.data::<AppState>()?;
        let recs = state.records.read().await;
        let filtered: Vec<CmsRecord> = recs
            .iter()
            .filter(|r| {
                let match_cat = category
                    .as_ref()
                    .map(|c| r.category.eq_ignore_ascii_case(c))
                    .unwrap_or(true);
                let match_col = collection
                    .as_ref()
                    .map(|col| r.collection.eq_ignore_ascii_case(col))
                    .unwrap_or(true);
                match_cat && match_col
            })
            .cloned()
            .collect();
        Ok(filtered)
    }

    async fn cms_record_by_id(&self, ctx: &Context<'_>, id: String) -> Result<Option<CmsRecord>> {
        let state = ctx.data::<AppState>()?;
        let recs = state.records.read().await;
        Ok(recs.iter().find(|r| r.id == id).cloned())
    }

    async fn avored_collections(&self, ctx: &Context<'_>) -> Result<Vec<AvoRedCollection>> {
        let state = ctx.data::<AppState>()?;
        let cols = state.collections.read().await;
        Ok(cols.clone())
    }

    async fn geojson_parcels(
        &self,
        ctx: &Context<'_>,
        section_filter: Option<String>,
    ) -> Result<Vec<GeoParcelFeature>> {
        let state = ctx.data::<AppState>()?;
        let parcels = state.geo_parcels.read().await;
        let filtered: Vec<GeoParcelFeature> = parcels
            .iter()
            .filter(|p| {
                section_filter
                    .as_ref()
                    .map(|s| {
                        p.section.to_lowercase().contains(&s.to_lowercase())
                            || p.cadastral_code.to_lowercase().contains(&s.to_lowercase())
                    })
                    .unwrap_or(true)
            })
            .cloned()
            .collect();
        Ok(filtered)
    }

    async fn geojson_parcel_by_id(
        &self,
        ctx: &Context<'_>,
        id: String,
    ) -> Result<Option<GeoParcelFeature>> {
        let state = ctx.data::<AppState>()?;
        let parcels = state.geo_parcels.read().await;
        Ok(parcels.iter().find(|p| p.id == id).cloned())
    }

    /// Vraag actuele perceelgrenzen en oppervlakten op via PDOK Kadaster WFS v5.0 op basis van een RD BBOX
    async fn pdok_cadastral_parcels(
        &self,
        bbox: Option<String>,
    ) -> Result<Vec<PdokPerceelFeature>> {
        // Standaard BBOX rond Tholen, Scherpenisse en Bol van Lodijke (RD X: 67000-75000, Y: 387000-396000)
        let b = bbox.unwrap_or_else(|| "67000,387000,75000,396000,EPSG:28992".to_string());
        match fetch_pdok_kadaster_bbox(&b).await {
            Ok(list) => Ok(list),
            Err(e) => {
                // Fallback naar lokale simulatie indien netwerk offline of WFS traag
                Ok(vec![PdokPerceelFeature {
                    id: "pdok-fallback-369".to_string(),
                    kadastrale_aanduiding: "Reimerswaal / Tholen Perceel 369 (PDOK Fallback)".to_string(),
                    gemeente: "Tholen".to_string(),
                    sectie: "Bol".to_string(),
                    perceelnummer: "369".to_string(),
                    oppervlakte_kadaster_m2: 125000.0,
                    calculated_shoelace_m2: 125000.0,
                    delta_m2: 0.0,
                    wfs_crs: format!("EPSG:28992 (Fout: {})", e),
                }])
            }
        }
    }

    async fn planimeter_audit(
        &self,
        ctx: &Context<'_>,
        map_scale: Option<u32>,
    ) -> Result<Vec<PlanimeterIntegrationResult>> {
        let state = ctx.data::<AppState>()?;
        let parcels = state.geo_parcels.read().await;
        let scale = map_scale.unwrap_or(2500);
        let results = parcels
            .iter()
            .map(|p| {
                integrate_rd_polygon(
                    &p.id,
                    &p.cadastral_code,
                    &p.rd_polygon,
                    Some(p.area_hectares),
                    scale,
                )
            })
            .collect();
        Ok(results)
    }

    async fn geojson_feature_collection(&self, ctx: &Context<'_>) -> Result<String> {
        let state = ctx.data::<AppState>()?;
        let parcels = state.geo_parcels.read().await;
        let features: Vec<serde_json::Value> =
            parcels.iter().map(|p| p.to_rfc7946_feature()).collect();
        let fc = json!({
            "type": "FeatureCollection",
            "name": "lodijke_tholen_scherpenisse_percelen",
            "crs_wgs84": "EPSG:4326",
            "crs_rd_new": "EPSG:28992",
            "features": features
        });
        Ok(serde_json::to_string_pretty(&fc).unwrap_or_default())
    }

    async fn author(&self, id: String) -> Result<Option<AuthorProfile>> {
        if id == "I0103" {
            Ok(Some(AuthorProfile {
                id: "I0103".to_string(),
                name: "Benjamin Willem Schot".to_string(),
                lifespan: "26 sep 1840 Tholen – 17 nov 1935 Tholen (95 jr)".to_string(),
                residence: "Kruittoren 23 (Wijk A 107), Tholen".to_string(),
                parcel: "Perceel No. 369 Bol van Lodijke (12,5 ha)".to_string(),
                fleet: vec![
                    "TH 2 Eben Haëzer (1902/1918)".to_string(),
                    "TH 12 Niets zonder Gods zegen (Watersnood 1906)".to_string(),
                    "TH 90 Vijf Gebroeders".to_string(),
                ],
                avg_shield: "Generatie I & II strikt afgeschermd conform AVG".to_string(),
            }))
        } else {
            Ok(None)
        }
    }

    async fn git_sync_log(&self, ctx: &Context<'_>) -> Result<Vec<GitSyncEntry>> {
        let state = ctx.data::<AppState>()?;
        let logs: Vec<GitSyncEntry> = std::fs::read_to_string(&state.git_log_file)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();
        Ok(logs)
    }
}

pub struct MutationRoot;

#[Object]
impl MutationRoot {
    async fn create_cms_record(
        &self,
        ctx: &Context<'_>,
        input: CreateCmsRecordInput,
    ) -> Result<CmsRecord> {
        let state = ctx.data::<AppState>()?;
        let new_id = input
            .id
            .unwrap_or_else(|| format!("cms-{}", Utc::now().timestamp_millis()));
        let rec = CmsRecord {
            id: new_id,
            title: input.title,
            category: input.category,
            collection: input
                .collection
                .unwrap_or_else(|| "dossiers_schot_bout".to_string()),
            date: input.date,
            author_id: "I0103".to_string(),
            avg_shield: true,
            body: input.body,
        };

        {
            let mut recs = state.records.write().await;
            recs.insert(0, rec.clone());
            if let Ok(json_str) = serde_json::to_string_pretty(&*recs) {
                let _ = std::fs::write(&state.cms_file, json_str);
            }
        }

        let msg = format!("[AvoRed GraphQL] Nieuw archiefstuk: {} ({})", rec.title, rec.id);
        let _ = perform_git_sync(
            &state.base_dir,
            &state.git_log_file,
            "GRAPHQL_CREATE_RECORD",
            &msg,
            false,
        )
        .await;

        Ok(rec)
    }

    async fn create_geojson_parcel(
        &self,
        ctx: &Context<'_>,
        input: CreateGeoParcelInput,
    ) -> Result<GeoParcelFeature> {
        let state = ctx.data::<AppState>()?;
        let new_id = input
            .id
            .unwrap_or_else(|| format!("parcel-{}", Utc::now().timestamp_millis()));
        let gemeten = (input.area_hectares / 0.44056 * 100.0).round() / 100.0;
        let half_side = (input.area_hectares * 10_000.0).sqrt() / 2.0;

        let rd_poly = vec![
            vec![input.rd_x - half_side, input.rd_y - half_side],
            vec![input.rd_x + half_side, input.rd_y - half_side],
            vec![input.rd_x + half_side, input.rd_y + half_side],
            vec![input.rd_x - half_side, input.rd_y + half_side],
            vec![input.rd_x - half_side, input.rd_y - half_side],
        ];
        let wgs_poly = vec![
            vec![input.wgs84_lon - 0.0015, input.wgs84_lat - 0.0010],
            vec![input.wgs84_lon + 0.0015, input.wgs84_lat - 0.0010],
            vec![input.wgs84_lon + 0.0015, input.wgs84_lat + 0.0010],
            vec![input.wgs84_lon - 0.0015, input.wgs84_lat + 0.0010],
            vec![input.wgs84_lon - 0.0015, input.wgs84_lat - 0.0010],
        ];

        let feature = GeoParcelFeature {
            id: new_id,
            cadastral_code: input.cadastral_code,
            name: input.name,
            municipality: input.municipality,
            section: input.section,
            parcel_number: input.parcel_number,
            area_hectares: input.area_hectares,
            area_gemeten: gemeten,
            owner_lessee: input.owner_lessee,
            period: input.period,
            rd_epsg: 28992,
            rd_centroid: vec![input.rd_x, input.rd_y],
            rd_polygon: rd_poly,
            wgs84_epsg: 4326,
            wgs84_centroid: vec![input.wgs84_lon, input.wgs84_lat],
            wgs84_polygon: wgs_poly,
        };

        {
            let mut parcels = state.geo_parcels.write().await;
            parcels.push(feature.clone());
            if let Ok(json_str) = serde_json::to_string_pretty(&*parcels) {
                let _ = std::fs::write(&state.geo_file, json_str);
            }
        }

        let msg = format!(
            "[AvoRed GeoJSON] Nieuw perceel: {} ({})",
            feature.cadastral_code, feature.id
        );
        let _ = perform_git_sync(
            &state.base_dir,
            &state.git_log_file,
            "GRAPHQL_CREATE_GEOPARCEL",
            &msg,
            false,
        )
        .await;

        Ok(feature)
    }

    async fn create_avored_collection(
        &self,
        ctx: &Context<'_>,
        input: CreateCollectionInput,
    ) -> Result<AvoRedCollection> {
        let state = ctx.data::<AppState>()?;
        let col = AvoRedCollection {
            identifier: input.identifier,
            name: input.name,
            fields: input.fields,
        };

        {
            let mut cols = state.collections.write().await;
            cols.push(col.clone());
            if let Ok(json_str) = serde_json::to_string_pretty(&*cols) {
                let _ = std::fs::write(&state.col_file, json_str);
            }
        }

        let msg = format!("[AvoRed GraphQL] Nieuwe collectie: {}", col.identifier);
        let _ = perform_git_sync(
            &state.base_dir,
            &state.git_log_file,
            "GRAPHQL_CREATE_COLLECTION",
            &msg,
            false,
        )
        .await;

        Ok(col)
    }

    async fn trigger_git_sync(
        &self,
        ctx: &Context<'_>,
        message: Option<String>,
        push: Option<bool>,
    ) -> Result<GitSyncEntry> {
        let state = ctx.data::<AppState>()?;
        let commit_msg = message.unwrap_or_else(|| {
            "[AvoRed CMS] Handmatige synchronisatie collecties, GeoJSON & PDOK WFS".to_string()
        });
        let entry = perform_git_sync(
            &state.base_dir,
            &state.git_log_file,
            "MANUAL_GRAPHQL_SYNC",
            &commit_msg,
            push.unwrap_or(false),
        )
        .await;
        Ok(entry)
    }
}
