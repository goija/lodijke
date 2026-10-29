#!/usr/bin/env bash
set -euo pipefail

cd ~/lodijke

echo "=== [1/4] Toevoegen van flate2 (voor gzipped .gramps bestanden) & roxmltree aan Cargo.toml ==="
cat << 'TOML' > Cargo.toml
[package]
name = "lodijke-cms-server"
version = "7.2.0"
edition = "2021"

[dependencies]
axum = { version = "0.8", features = ["macros", "multipart"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
tower-http = { version = "0.6", features = ["cors", "fs"] }
uuid = { version = "1", features = ["v4", "serde"] }
bytes = "1"
flate2 = "1.0"
roxmltree = "0.20"
TOML

echo "=== [2/4] Updaten van src/main.rs met GRAMPS XML 1.7.1 Import & Export ==="
cat << 'RUST' > src/main.rs
use axum::{
    body::Bytes,
    extract::{Multipart, Path as AxumPath, Query, State},
    http::{header, StatusCode},
    response::{Html, IntoResponse, Json},
    routing::{delete, get, post, put},
    Router,
};
use chrono::{DateTime, Datelike, Utc};
use flate2::read::GzDecoder;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::{
    fs,
    io::Read,
    net::SocketAddr,
    path::{Path as FsPath, PathBuf},
    sync::{Arc, RwLock},
};
use tower_http::{
    cors::{Any, CorsLayer},
    services::ServeDir,
};
use uuid::Uuid;

// ============================================================================
// 1. GRAMPS DEVELOPER PORTAL DATA MODEL
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsName {
    pub first_name: String,
    pub surname: String,
    pub call_name: String,
    pub title: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsPerson {
    pub handle: String,
    pub gramps_id: String,
    pub gender: String,
    pub primary_name: GrampsName,
    pub event_ref_list: Vec<String>,
    pub family_list: Vec<String>,
    pub parent_family_list: Vec<String>,
    pub citation_list: Vec<String>,
    pub media_list: Vec<String>,
    pub note_list: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsFamily {
    pub handle: String,
    pub gramps_id: String,
    pub father_handle: Option<String>,
    pub mother_handle: Option<String>,
    pub child_ref_list: Vec<String>,
    pub event_ref_list: Vec<String>,
    pub citation_list: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsEvent {
    pub handle: String,
    pub gramps_id: String,
    pub event_type: String,
    pub date: String,
    pub place_handle: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsPlace {
    pub handle: String,
    pub gramps_id: String,
    pub title: String,
    pub name: String,
    pub place_type: String,
    pub lat: f64,
    pub lon: f64,
    pub rd_x: f64,
    pub rd_y: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsSource {
    pub handle: String,
    pub gramps_id: String,
    pub title: String,
    pub author: String,
    pub pubinfo: String,
    pub abbrev: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsCitation {
    pub handle: String,
    pub gramps_id: String,
    pub source_handle: String,
    pub page: String,
    pub date: String,
    pub confidence: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GrampsDatabase {
    pub people: Vec<GrampsPerson>,
    pub families: Vec<GrampsFamily>,
    pub events: Vec<GrampsEvent>,
    pub places: Vec<GrampsPlace>,
    pub sources: Vec<GrampsSource>,
    pub citations: Vec<GrampsCitation>,
}

// ============================================================================
// 2. GRAMPS XML 1.7.1 SERIALIZER & PARSER
// ============================================================================

fn xml_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

impl GrampsDatabase {
    pub fn to_gramps_xml(&self) -> String {
        let mut out = String::with_capacity(8192);
        out.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        out.push_str("<!DOCTYPE database PUBLIC \"-//Gramps//DTD Gramps XML 1.7.1//EN\" \"http://gramps-project.org/xml/1.7.1/grampsxml.dtd\">\n");
        out.push_str("<database xmlns=\"http://gramps-project.org/xml/1.7.1/\">\n");
        out.push_str("  <header>\n");
        out.push_str(&format!(
            "    <created date=\"{}\" version=\"Visser-Dossier-Axum-7.2.0\"/>\n",
            Utc::now().format("%Y-%m-%d")
        ));
        out.push_str("    <researcher><resname>Visser Dossier</resname></researcher>\n");
        out.push_str("  </header>\n");

        // Events
        out.push_str("  <events>\n");
        for ev in &self.events {
            out.push_str(&format!(
                "    <event handle=\"{}\" id=\"{}\">\n      <type>{}</type>\n      <dateval val=\"{}\"/>\n      <place hlink=\"{}\"/>\n      <description>{}</description>\n    </event>\n",
                xml_escape(&ev.handle),
                xml_escape(&ev.gramps_id),
                xml_escape(&ev.event_type),
                xml_escape(&ev.date),
                xml_escape(&ev.place_handle),
                xml_escape(&ev.description)
            ));
        }
        out.push_str("  </events>\n");

        // People
        out.push_str("  <people>\n");
        for p in &self.people {
            out.push_str(&format!(
                "    <person handle=\"{}\" id=\"{}\">\n      <gender>{}</gender>\n      <name type=\"Birth Name\">\n        <first>{}</first>\n        <call>{}</call>\n        <surname>{}</surname>\n        <title>{}</title>\n      </name>\n",
                xml_escape(&p.handle),
                xml_escape(&p.gramps_id),
                xml_escape(&p.gender),
                xml_escape(&p.primary_name.first_name),
                xml_escape(&p.primary_name.call_name),
                xml_escape(&p.primary_name.surname),
                xml_escape(&p.primary_name.title),
            ));
            for eref in &p.event_ref_list {
                out.push_str(&format!("      <eventref hlink=\"{}\" role=\"Primary\"/>\n", xml_escape(eref)));
            }
            for fref in &p.family_list {
                out.push_str(&format!("      <parentin hlink=\"{}\"/>\n", xml_escape(fref)));
            }
            for pfref in &p.parent_family_list {
                out.push_str(&format!("      <childof hlink=\"{}\"/>\n", xml_escape(pfref)));
            }
            for cref in &p.citation_list {
                out.push_str(&format!("      <citationref hlink=\"{}\"/>\n", xml_escape(cref)));
            }
            for note in &p.note_list {
                out.push_str(&format!("      <noteref text=\"{}\"/>\n", xml_escape(note)));
            }
            out.push_str("    </person>\n");
        }
        out.push_str("  </people>\n");

        // Families
        out.push_str("  <families>\n");
        for f in &self.families {
            out.push_str(&format!(
                "    <family handle=\"{}\" id=\"{}\">\n",
                xml_escape(&f.handle),
                xml_escape(&f.gramps_id)
            ));
            if let Some(ref fh) = f.father_handle {
                out.push_str(&format!("      <father hlink=\"{}\"/>\n", xml_escape(fh)));
            }
            if let Some(ref mh) = f.mother_handle {
                out.push_str(&format!("      <mother hlink=\"{}\"/>\n", xml_escape(mh)));
            }
            for ch in &f.child_ref_list {
                out.push_str(&format!("      <childref hlink=\"{}\"/>\n", xml_escape(ch)));
            }
            out.push_str("    </family>\n");
        }
        out.push_str("  </families>\n");

        // Places
        out.push_str("  <places>\n");
        for pl in &self.places {
            out.push_str(&format!(
                "    <placeobj handle=\"{}\" id=\"{}\" type=\"{}\">\n      <ptitle>{}</ptitle>\n      <pname value=\"{}\"/>\n      <coord lat=\"{}\" long=\"{}\" rd_x=\"{}\" rd_y=\"{}\"/>\n    </placeobj>\n",
                xml_escape(&pl.handle),
                xml_escape(&pl.gramps_id),
                xml_escape(&pl.place_type),
                xml_escape(&pl.title),
                xml_escape(&pl.name),
                pl.lat,
                pl.lon,
                pl.rd_x,
                pl.rd_y
            ));
        }
        out.push_str("  </places>\n");

        // Sources & Citations
        out.push_str("  <sources>\n");
        for s in &self.sources {
            out.push_str(&format!(
                "    <source handle=\"{}\" id=\"{}\">\n      <stitle>{}</stitle>\n      <sauthor>{}</sauthor>\n      <spubinfo>{}</spubinfo>\n      <sabbrev>{}</sabbrev>\n    </source>\n",
                xml_escape(&s.handle),
                xml_escape(&s.gramps_id),
                xml_escape(&s.title),
                xml_escape(&s.author),
                xml_escape(&s.pubinfo),
                xml_escape(&s.abbrev)
            ));
        }
        out.push_str("  </sources>\n");

        out.push_str("  <citations>\n");
        for c in &self.citations {
            out.push_str(&format!(
                "    <citation handle=\"{}\" id=\"{}\">\n      <dateval val=\"{}\"/>\n      <page>{}</page>\n      <confidence>{}</confidence>\n      <sourceref hlink=\"{}\"/>\n    </citation>\n",
                xml_escape(&c.handle),
                xml_escape(&c.gramps_id),
                xml_escape(&c.date),
                xml_escape(&c.page),
                c.confidence,
                xml_escape(&c.source_handle)
            ));
        }
        out.push_str("  </citations>\n");
        out.push_str("</database>\n");
        out
    }

    pub fn merge_from_gramps_xml(&mut self, xml_text: &str) -> Result<(usize, usize, usize, usize), String> {
        let doc = roxmltree::Document::parse(xml_text).map_err(|e| e.to_string())?;
        let mut added_people = 0usize;
        let mut added_events = 0usize;
        let mut added_places = 0usize;
        let mut added_families = 0usize;

        for node in doc.descendants().filter(|n| n.is_element()) {
            match node.tag_name().name() {
                "person" => {
                    let handle = node
                        .attribute("handle")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("p_{}", Uuid::new_v4().simple()));
                    let gramps_id = node
                        .attribute("id")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("I{:04}", self.people.len() + 1));

                    let mut gender = "U".to_string();
                    let mut first_name = String::new();
                    let mut surname = String::new();
                    let mut call_name = String::new();
                    let mut title = String::new();
                    let mut event_ref_list = Vec::new();
                    let mut family_list = Vec::new();
                    let mut parent_family_list = Vec::new();
                    let mut citation_list = Vec::new();
                    let mut note_list = Vec::new();

                    for child in node.children().filter(|c| c.is_element()) {
                        match child.tag_name().name() {
                            "gender" => gender = child.text().unwrap_or("U").trim().to_string(),
                            "name" => {
                                for nc in child.children().filter(|c| c.is_element()) {
                                    match nc.tag_name().name() {
                                        "first" => first_name = nc.text().unwrap_or("").trim().to_string(),
                                        "surname" => surname = nc.text().unwrap_or("").trim().to_string(),
                                        "call" => call_name = nc.text().unwrap_or("").trim().to_string(),
                                        "title" => title = nc.text().unwrap_or("").trim().to_string(),
                                        _ => {}
                                    }
                                }
                            }
                            "eventref" => {
                                if let Some(h) = child.attribute("hlink") {
                                    event_ref_list.push(h.to_string());
                                }
                            }
                            "parentin" => {
                                if let Some(h) = child.attribute("hlink") {
                                    family_list.push(h.to_string());
                                }
                            }
                            "childof" => {
                                if let Some(h) = child.attribute("hlink") {
                                    parent_family_list.push(h.to_string());
                                }
                            }
                            "citationref" => {
                                if let Some(h) = child.attribute("hlink") {
                                    citation_list.push(h.to_string());
                                }
                            }
                            "noteref" => {
                                if let Some(t) = child.attribute("text").or_else(|| child.attribute("hlink")) {
                                    note_list.push(t.to_string());
                                }
                            }
                            _ => {}
                        }
                    }

                    let person = GrampsPerson {
                        handle: handle.clone(),
                        gramps_id,
                        gender,
                        primary_name: GrampsName {
                            first_name,
                            surname,
                            call_name,
                            title,
                        },
                        event_ref_list,
                        family_list,
                        parent_family_list,
                        citation_list,
                        media_list: Vec::new(),
                        note_list,
                    };

                    if let Some(existing) = self.people.iter_mut().find(|p| p.handle == handle) {
                        *existing = person;
                    } else {
                        self.people.push(person);
                    }
                    added_people += 1;
                }
                "event" => {
                    let handle = node
                        .attribute("handle")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("e_{}", Uuid::new_v4().simple()));
                    let gramps_id = node
                        .attribute("id")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("E{:04}", self.events.len() + 1));
                    let mut event_type = "Event".to_string();
                    let mut date = String::new();
                    let mut place_handle = String::new();
                    let mut description = String::new();

                    for child in node.children().filter(|c| c.is_element()) {
                        match child.tag_name().name() {
                            "type" => event_type = child.text().unwrap_or("Event").trim().to_string(),
                            "dateval" => date = child.attribute("val").unwrap_or("").to_string(),
                            "place" => place_handle = child.attribute("hlink").unwrap_or("").to_string(),
                            "description" => description = child.text().unwrap_or("").trim().to_string(),
                            _ => {}
                        }
                    }

                    let ev = GrampsEvent {
                        handle: handle.clone(),
                        gramps_id,
                        event_type,
                        date,
                        place_handle,
                        description,
                    };
                    if let Some(existing) = self.events.iter_mut().find(|e| e.handle == handle) {
                        *existing = ev;
                    } else {
                        self.events.push(ev);
                    }
                    added_events += 1;
                }
                "placeobj" => {
                    let handle = node
                        .attribute("handle")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("pl_{}", Uuid::new_v4().simple()));
                    let gramps_id = node
                        .attribute("id")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("P{:04}", self.places.len() + 1));
                    let place_type = node.attribute("type").unwrap_or("Location").to_string();
                    let mut title = String::new();
                    let mut name = String::new();
                    let mut lat = 51.4580;
                    let mut lon = 4.1820;
                    let mut rd_x = 71460.0;
                    let mut rd_y = 385700.0;

                    for child in node.children().filter(|c| c.is_element()) {
                        match child.tag_name().name() {
                            "ptitle" => title = child.text().unwrap_or("").trim().to_string(),
                            "pname" => name = child.attribute("value").unwrap_or("").to_string(),
                            "coord" => {
                                if let Some(v) = child.attribute("lat").and_then(|s| s.parse().ok()) { lat = v; }
                                if let Some(v) = child.attribute("long").and_then(|s| s.parse().ok()) { lon = v; }
                                if let Some(v) = child.attribute("rd_x").and_then(|s| s.parse().ok()) { rd_x = v; }
                                if let Some(v) = child.attribute("rd_y").and_then(|s| s.parse().ok()) { rd_y = v; }
                            }
                            _ => {}
                        }
                    }
                    if title.is_empty() {
                        title = name.clone();
                    }

                    let pl = GrampsPlace {
                        handle: handle.clone(),
                        gramps_id,
                        title,
                        name,
                        place_type,
                        lat,
                        lon,
                        rd_x,
                        rd_y,
                    };
                    if let Some(existing) = self.places.iter_mut().find(|p| p.handle == handle) {
                        *existing = pl;
                    } else {
                        self.places.push(pl);
                    }
                    added_places += 1;
                }
                "family" => {
                    let handle = node
                        .attribute("handle")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("f_{}", Uuid::new_v4().simple()));
                    let gramps_id = node
                        .attribute("id")
                        .map(|s| s.to_string())
                        .unwrap_or_else(|| format!("F{:04}", self.families.len() + 1));
                    let mut father_handle = None;
                    let mut mother_handle = None;
                    let mut child_ref_list = Vec::new();

                    for child in node.children().filter(|c| c.is_element()) {
                        match child.tag_name().name() {
                            "father" => father_handle = child.attribute("hlink").map(|s| s.to_string()),
                            "mother" => mother_handle = child.attribute("hlink").map(|s| s.to_string()),
                            "childref" => {
                                if let Some(h) = child.attribute("hlink") {
                                    child_ref_list.push(h.to_string());
                                }
                            }
                            _ => {}
                        }
                    }

                    let fam = GrampsFamily {
                        handle: handle.clone(),
                        gramps_id,
                        father_handle,
                        mother_handle,
                        child_ref_list,
                        event_ref_list: Vec::new(),
                        citation_list: Vec::new(),
                    };
                    if let Some(existing) = self.families.iter_mut().find(|f| f.handle == handle) {
                        *existing = fam;
                    } else {
                        self.families.push(fam);
                    }
                    added_families += 1;
                }
                _ => {}
            }
        }

        Ok((added_people, added_families, added_events, added_places))
    }
}

// ============================================================================
// 3. FOTOALBUM & CMS DATA MODEL (VISSER DOSSIER)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhotoItem {
    pub id: String,
    pub filename: String,
    pub title: String,
    pub description: String,
    pub album: String,
    pub gramps_handle: Option<String>,
    pub date_taken: Option<DateTime<Utc>>,
    pub rd_x: Option<f64>,
    pub rd_y: Option<f64>,
    pub tags: Vec<String>,
    pub uploaded_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsSection {
    pub id: String,
    pub title: String,
    pub category: String,
    pub content: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsState {
    pub hero_title: String,
    pub sections: Vec<CmsSection>,
}

#[derive(Clone)]
pub struct AppState {
    pub data_dir: PathBuf,
    pub upload_dir: PathBuf,
    pub solid_pod_dir: PathBuf,
    pub photos: Arc<RwLock<Vec<PhotoItem>>>,
    pub cms: Arc<RwLock<CmsState>>,
    pub gramps: Arc<RwLock<GrampsDatabase>>,
}

#[derive(Debug, Deserialize)]
pub struct PhotoFilter {
    pub q: Option<String>,
    pub album: Option<String>,
    pub year: Option<i32>,
    pub gramps_handle: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct PhotoUpdatePayload {
    pub title: Option<String>,
    pub description: Option<String>,
    pub album: Option<String>,
    pub gramps_handle: Option<String>,
    pub rd_x: Option<f64>,
    pub rd_y: Option<f64>,
    pub tags: Option<Vec<String>>,
}

impl AppState {
    pub fn load(base: &FsPath) -> Self {
        let data_dir = base.join("data");
        let upload_dir = data_dir.join("uploads");
        let solid_pod_dir = base.join("01_Solid_POD_Vault");
        let _ = fs::create_dir_all(&upload_dir);
        let _ = fs::create_dir_all(&solid_pod_dir);

        let photos_path = data_dir.join("photos.json");
        let photos: Vec<PhotoItem> = fs::read_to_string(&photos_path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();

        let cms_path = data_dir.join("cms_state.json");
        let cms: CmsState = fs::read_to_string(&cms_path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or(CmsState {
                hero_title: "Visser Dossier".to_string(),
                sections: vec![],
            });

        let gramps_path = data_dir.join("gramps_db.json");
        let gramps: GrampsDatabase = fs::read_to_string(&gramps_path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();

        Self {
            data_dir,
            upload_dir,
            solid_pod_dir,
            photos: Arc::new(RwLock::new(photos)),
            cms: Arc::new(RwLock::new(cms)),
            gramps: Arc::new(RwLock::new(gramps)),
        }
    }

    pub fn save_photos(&self) {
        if let Ok(guard) = self.photos.read() {
            if let Ok(json_str) = serde_json::to_string_pretty(&*guard) {
                let _ = fs::write(self.data_dir.join("photos.json"), json_str);
            }
        }
    }

    pub fn save_cms(&self) {
        if let Ok(guard) = self.cms.read() {
            if let Ok(json_str) = serde_json::to_string_pretty(&*guard) {
                let _ = fs::write(self.data_dir.join("cms_state.json"), json_str);
            }
        }
    }

    pub fn save_gramps(&self) {
        if let Ok(guard) = self.gramps.read() {
            if let Ok(json_str) = serde_json::to_string_pretty(&*guard) {
                let _ = fs::write(self.data_dir.join("gramps_db.json"), json_str);
            }
        }
    }

    pub fn purge_solid_pod_photos(&self) -> usize {
        let mut removed = 0usize;
        fn walk_and_remove(dir: &FsPath, count: &mut usize) {
            if let Ok(entries) = fs::read_dir(dir) {
                for entry in entries.flatten() {
                    let p = entry.path();
                    if p.is_dir() {
                        let name = p.file_name().and_then(|n| n.to_str()).unwrap_or("");
                        if matches!(name, "photos" | "images" | "media") {
                            let _ = fs::remove_dir_all(&p);
                            *count += 1;
                        } else {
                            walk_and_remove(&p, count);
                        }
                    } else if let Some(ext) = p.extension().and_then(|e| e.to_str()) {
                        if matches!(
                            ext.to_lowercase().as_str(),
                            "jpg" | "jpeg" | "png" | "webp" | "gif" | "tiff" | "bmp"
                        ) {
                            if fs::remove_file(&p).is_ok() {
                                *count += 1;
                            }
                        }
                    }
                }
            }
        }
        walk_and_remove(&self.solid_pod_dir, &mut removed);
        removed
    }
}

// ============================================================================
// 4. AXUM HANDLERS
// ============================================================================

async fn serve_index() -> impl IntoResponse {
    match fs::read_to_string("index.html") {
        Ok(html) => Html(html).into_response(),
        Err(_) => (StatusCode::NOT_FOUND, "index.html niet gevonden").into_response(),
    }
}

async fn get_cms(State(state): State<AppState>) -> impl IntoResponse {
    let cms = state.cms.read().unwrap().clone();
    Json(cms)
}

async fn update_cms(
    State(state): State<AppState>,
    Json(mut payload): Json<CmsState>,
) -> impl IntoResponse {
    if payload.hero_title.trim().is_empty() {
        payload.hero_title = "Visser Dossier".to_string();
    }
    {
        let mut guard = state.cms.write().unwrap();
        *guard = payload.clone();
    }
    state.save_cms();
    Json(json!({ "status": "ok", "cms": payload }))
}

async fn add_cms_section(
    State(state): State<AppState>,
    Json(mut sec): Json<CmsSection>,
) -> impl IntoResponse {
    if sec.id.trim().is_empty() {
        sec.id = format!("sec-{}", Uuid::new_v4());
    }
    sec.updated_at = Utc::now().to_rfc3339();
    {
        let mut guard = state.cms.write().unwrap();
        guard.sections.push(sec.clone());
    }
    state.save_cms();
    Json(json!({ "status": "ok", "section": sec }))
}

async fn delete_cms_section(
    State(state): State<AppState>,
    AxumPath(id): AxumPath<String>,
) -> impl IntoResponse {
    {
        let mut guard = state.cms.write().unwrap();
        guard.sections.retain(|s| s.id != id);
    }
    state.save_cms();
    Json(json!({ "status": "deleted", "id": id }))
}

async fn list_photos(
    State(state): State<AppState>,
    Query(filter): Query<PhotoFilter>,
) -> impl IntoResponse {
    let mut result = state.photos.read().unwrap().clone();

    if let Some(year) = filter.year {
        result.retain(|p| p.date_taken.map_or(false, |dt| dt.year() == year));
    }
    if let Some(ref album) = filter.album {
        if !album.trim().is_empty() {
            result.retain(|p| p.album.eq_ignore_ascii_case(album.trim()));
        }
    }
    if let Some(ref gh) = filter.gramps_handle {
        if !gh.trim().is_empty() {
            result.retain(|p| p.gramps_handle.as_deref() == Some(gh.trim()));
        }
    }
    if let Some(ref q) = filter.q {
        let needle = q.trim().to_lowercase();
        if !needle.is_empty() {
            result.retain(|p| {
                p.title.to_lowercase().contains(&needle)
                    || p.description.to_lowercase().contains(&needle)
                    || p.tags.iter().any(|t| t.to_lowercase().contains(&needle))
            });
        }
    }

    Json(json!({
        "query": filter.q,
        "count": result.len(),
        "results": result
    }))
}

async fn upload_photo(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    let mut title = String::from("Visser Dossier Archiefstuk");
    let mut description = String::new();
    let mut album = String::from("Visser Dossier");
    let mut gramps_handle: Option<String> = None;
    let mut rd_x: Option<f64> = None;
    let mut rd_y: Option<f64> = None;
    let mut tags: Vec<String> = vec!["Visser Dossier".to_string()];
    let mut saved_filename: Option<String> = None;

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();
        if name == "file" {
            let orig = field.file_name().unwrap_or("image.jpg").to_string();
            let ext = FsPath::new(&orig)
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("jpg");
            let fname = format!("{}.{}", Uuid::new_v4(), ext);
            if let Ok(bytes) = field.bytes().await {
                let dest = state.upload_dir.join(&fname);
                if fs::write(&dest, &bytes).is_ok() {
                    saved_filename = Some(fname);
                }
            }
        } else if let Ok(txt) = field.text().await {
            match name.as_str() {
                "title" if !txt.trim().is_empty() => title = txt,
                "description" => description = txt,
                "album" if !txt.trim().is_empty() => album = txt,
                "gramps_handle" if !txt.trim().is_empty() => gramps_handle = Some(txt),
                "rd_x" => rd_x = txt.parse::<f64>().ok(),
                "rd_y" => rd_y = txt.parse::<f64>().ok(),
                "tags" => {
                    tags = txt
                        .split(',')
                        .map(|s| s.trim().to_string())
                        .filter(|s| !s.is_empty())
                        .collect();
                }
                _ => {}
            }
        }
    }

    let filename = saved_filename.unwrap_or_else(|| "placeholder.jpg".to_string());
    let item = PhotoItem {
        id: Uuid::new_v4().to_string(),
        filename,
        title,
        description,
        album,
        gramps_handle,
        date_taken: Some(Utc::now()),
        rd_x,
        rd_y,
        tags,
        uploaded_at: Utc::now(),
    };

    {
        let mut guard = state.photos.write().unwrap();
        guard.insert(0, item.clone());
    }
    state.save_photos();

    (StatusCode::CREATED, Json(json!({ "status": "uploaded", "photo": item })))
}

async fn update_photo(
    State(state): State<AppState>,
    AxumPath(id): AxumPath<String>,
    Json(payload): Json<PhotoUpdatePayload>,
) -> impl IntoResponse {
    let mut updated: Option<PhotoItem> = None;
    {
        let mut guard = state.photos.write().unwrap();
        if let Some(p) = guard.iter_mut().find(|p| p.id == id) {
            if let Some(t) = payload.title { p.title = t; }
            if let Some(d) = payload.description { p.description = d; }
            if let Some(a) = payload.album { p.album = a; }
            if payload.gramps_handle.is_some() { p.gramps_handle = payload.gramps_handle; }
            if payload.rd_x.is_some() { p.rd_x = payload.rd_x; }
            if payload.rd_y.is_some() { p.rd_y = payload.rd_y; }
            if let Some(tags) = payload.tags { p.tags = tags; }
            updated = Some(p.clone());
        }
    }
    state.save_photos();
    match updated {
        Some(p) => (StatusCode::OK, Json(json!({ "status": "updated", "photo": p }))),
        None => (StatusCode::NOT_FOUND, Json(json!({ "error": "Photo not found" }))),
    }
}

async fn delete_photo(
    State(state): State<AppState>,
    AxumPath(id): AxumPath<String>,
) -> impl IntoResponse {
    let mut removed_file: Option<String> = None;
    {
        let mut guard = state.photos.write().unwrap();
        if let Some(pos) = guard.iter().position(|p| p.id == id) {
            let item = guard.remove(pos);
            removed_file = Some(item.filename);
        }
    }
    if let Some(fname) = removed_file {
        let _ = fs::remove_file(state.upload_dir.join(fname));
    }
    state.save_photos();
    Json(json!({ "status": "deleted", "id": id }))
}

async fn get_gramps_db(State(state): State<AppState>) -> impl IntoResponse {
    let db = state.gramps.read().unwrap().clone();
    Json(db)
}

async fn upsert_gramps_person(
    State(state): State<AppState>,
    Json(mut person): Json<GrampsPerson>,
) -> impl IntoResponse {
    if person.handle.trim().is_empty() {
        person.handle = format!("p_{}", Uuid::new_v4().simple());
    }
    {
        let mut db = state.gramps.write().unwrap();
        if let Some(existing) = db.people.iter_mut().find(|p| p.handle == person.handle) {
            *existing = person.clone();
        } else {
            if person.gramps_id.trim().is_empty() {
                person.gramps_id = format!("I{:04}", db.people.len() + 1);
            }
            db.people.push(person.clone());
        }
    }
    state.save_gramps();
    Json(json!({ "status": "ok", "person": person }))
}

async fn delete_gramps_person(
    State(state): State<AppState>,
    AxumPath(handle): AxumPath<String>,
) -> impl IntoResponse {
    {
        let mut db = state.gramps.write().unwrap();
        db.people.retain(|p| p.handle != handle);
    }
    state.save_gramps();
    Json(json!({ "status": "deleted", "handle": handle }))
}

async fn upsert_gramps_event(
    State(state): State<AppState>,
    Json(mut ev): Json<GrampsEvent>,
) -> impl IntoResponse {
    if ev.handle.trim().is_empty() {
        ev.handle = format!("e_{}", Uuid::new_v4().simple());
    }
    {
        let mut db = state.gramps.write().unwrap();
        if let Some(existing) = db.events.iter_mut().find(|e| e.handle == ev.handle) {
            *existing = ev.clone();
        } else {
            if ev.gramps_id.trim().is_empty() {
                ev.gramps_id = format!("E{:04}", db.events.len() + 1);
            }
            db.events.push(ev.clone());
        }
    }
    state.save_gramps();
    Json(json!({ "status": "ok", "event": ev }))
}

async fn upsert_gramps_family(
    State(state): State<AppState>,
    Json(mut fam): Json<GrampsFamily>,
) -> impl IntoResponse {
    if fam.handle.trim().is_empty() {
        fam.handle = format!("f_{}", Uuid::new_v4().simple());
    }
    {
        let mut db = state.gramps.write().unwrap();
        if let Some(existing) = db.families.iter_mut().find(|f| f.handle == fam.handle) {
            *existing = fam.clone();
        } else {
            if fam.gramps_id.trim().is_empty() {
                fam.gramps_id = format!("F{:04}", db.families.len() + 1);
            }
            db.families.push(fam.clone());
        }
    }
    state.save_gramps();
    Json(json!({ "status": "ok", "family": fam }))
}

async fn import_gramps_db(
    State(state): State<AppState>,
    Json(new_db): Json<GrampsDatabase>,
) -> impl IntoResponse {
    {
        let mut db = state.gramps.write().unwrap();
        *db = new_db;
    }
    state.save_gramps();
    Json(json!({ "status": "imported" }))
}

// --- NIEUW: GRAMPS XML (.gramps) Export & Import (Plain XML + Gzipped .gramps) ---
async fn export_gramps_xml(State(state): State<AppState>) -> impl IntoResponse {
    let xml = state.gramps.read().unwrap().to_gramps_xml();
    (
        StatusCode::OK,
        [
            (header::CONTENT_TYPE, "application/xml; charset=utf-8"),
            (
                header::CONTENT_DISPOSITION,
                "attachment; filename=\"visser_dossier.gramps\"",
            ),
        ],
        xml,
    )
}

async fn import_gramps_xml(
    State(state): State<AppState>,
    body: Bytes,
) -> impl IntoResponse {
    // Check op GZIP magic bytes (0x1f, 0x8b) voor gecomprimeerde .gramps bestanden
    let xml_string = if body.len() >= 2 && body[0] == 0x1f && body[1] == 0x8b {
        let mut decoder = GzDecoder::new(&body[..]);
        let mut s = String::new();
        if let Err(e) = decoder.read_to_string(&mut s) {
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": format!("Gzip decompressie mislukt: {}", e) })),
            );
        }
        s
    } else {
        String::from_utf8_lossy(&body).to_string()
    };

    let res = {
        let mut db = state.gramps.write().unwrap();
        db.merge_from_gramps_xml(&xml_string)
    };

    match res {
        Ok((p, f, e, pl)) => {
            state.save_gramps();
            (
                StatusCode::OK,
                Json(json!({
                    "status": "gramps_xml_imported",
                    "imported": {
                        "people": p,
                        "families": f,
                        "events": e,
                        "places": pl
                    }
                })),
            )
        }
        Err(err) => (
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": format!("XML parse fout: {}", err) })),
        ),
    }
}

async fn purge_solid_photos_handler(State(state): State<AppState>) -> impl IntoResponse {
    let removed_files = state.purge_solid_pod_photos();
    Json(json!({
        "status": "purged",
        "solid_pod_vault": "01_Solid_POD_Vault",
        "removed_photo_files": removed_files,
        "policy": "NO_PHOTOS_IN_SOLID_POD"
    }))
}

async fn export_geojson(State(state): State<AppState>) -> impl IntoResponse {
    let db = state.gramps.read().unwrap().clone();
    let photos = state.photos.read().unwrap().clone();

    let mut features: Vec<Value> = db
        .places
        .iter()
        .map(|pl| {
            json!({
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [pl.lon, pl.lat]
                },
                "properties": {
                    "layer": "GRAMPS_Place",
                    "handle": pl.handle,
                    "gramps_id": pl.gramps_id,
                    "title": pl.title,
                    "rd_x": pl.rd_x,
                    "rd_y": pl.rd_y
                }
            })
        })
        .collect();

    for p in photos.iter() {
        if let (Some(rx), Some(ry)) = (p.rd_x, p.rd_y) {
            features.push(json!({
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [rx, ry]
                },
                "properties": {
                    "layer": "Photo_RD",
                    "id": p.id,
                    "title": p.title,
                    "album": p.album
                }
            }));
        }
    }

    Json(json!({
        "type": "FeatureCollection",
        "name": "Visser Dossier Geodata",
        "features": features
    }))
}

#[tokio::main]
async fn main() {
    let base_dir = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let state = AppState::load(&base_dir);

    let purged = state.purge_solid_pod_photos();
    println!(
        "[Solid POD] Foto-opschoning voltooid ({} bestanden verwijderd).",
        purged
    );

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/", get(serve_index))
        // CMS Endpoints (Visser Dossier)
        .route("/api/cms", get(get_cms).put(update_cms))
        .route("/api/cms/sections", post(add_cms_section))
        .route("/api/cms/sections/{id}", delete(delete_cms_section))
        // Fotoalbum Endpoints
        .route("/api/photos", get(list_photos).post(upload_photo))
        .route("/api/photos/{id}", put(update_photo).delete(delete_photo))
        // GRAMPS Developer API + Native GRAMPS XML (.gramps)
        .route("/api/gramps/tree", get(get_gramps_db).put(import_gramps_db))
        .route("/api/gramps/xml", get(export_gramps_xml).post(import_gramps_xml))
        .route("/api/gramps/people", post(upsert_gramps_person))
        .route("/api/gramps/people/{handle}", delete(delete_gramps_person))
        .route("/api/gramps/events", post(upsert_gramps_event))
        .route("/api/gramps/families", post(upsert_gramps_family))
        // Solid POD & GeoJSON
        .route("/api/solid/purge-photos", delete(purge_solid_photos_handler))
        .route("/api/geojson", get(export_geojson))
        .nest_service("/uploads", ServeDir::new(state.upload_dir.clone()))
        .layer(cors)
        .with_state(state);

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8090);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("=========================================================");
    println!(" Visser Dossier — Rust Axum CMS + GRAMPS XML 1.7.1 API");
    println!(" Luistert op: http://127.0.0.1:{}", port);
    println!("=========================================================");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
RUST

echo "=== [3/4] Vue.js Interface uitbreiden met .gramps XML Import & Export knoppen ==="
python3 - << 'PYEOF'
with open("index.html", "r") as f:
    html = f.read()

xml_ui_block = """      <div class="card p-6 space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-4 border-b border-slate-800 pb-4">
          <div>
            <h2 class="text-xl font-bold text-white">GRAMPS Developer API & Native XML (.gramps)</h2>
            <p class="text-xs text-slate-400">Importeer en exporteer direct volgens de GRAMPS XML 1.7.1 DTD standaard (ondersteunt zowel plain XML als gzipped .gramps)</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <a href="/api/gramps/xml" download="visser_dossier.gramps" class="btn-primary text-sm inline-block">Download .gramps XML</a>
            <label class="px-3 py-2 rounded bg-emerald-800 hover:bg-emerald-700 text-white text-sm font-semibold cursor-pointer">
              Importeer .gramps Bestand
              <input type="file" accept=".gramps,.xml,.gz" @change="uploadGrampsXml" class="hidden" />
            </label>
          </div>
        </div>"""

html = html.replace(
    """      <div class="card p-6 space-y-4">
        <h2 class="text-xl font-bold text-white">GRAMPS Developer API — Personen, Families, Events & Plaatsen</h2>""",
    xml_ui_block
)

xml_method_block = """    async uploadGrampsXml(ev) {
      const file = ev.target.files[0];
      if (!file) return;
      const buf = await file.arrayBuffer();
      try {
        const res = await fetch('/api/gramps/xml', {
          method: 'POST',
          headers: { 'Content-Type': 'application/octet-stream' },
          body: buf
        });
        if (res.ok) {
          await this.loadAll();
          alert('.gramps XML succesvol geïmporteerd in Visser Dossier!');
        }
      } catch (e) {
        alert('Offline: kan .gramps XML pas parsen zodra de lokale Rust-server draait.');
      }
    },
    async addGrampsPerson() {"""

html = html.replace("    async addGrampsPerson() {", xml_method_block)

with open("index.html", "w") as f:
    f.write(html)

cp_target = "frontend/index.html"
try:
    with open(cp_target, "w") as f2:
        f2.write(html)
except Exception:
    pass
PYEOF

echo "=== [4/4] Compileren en herstarten ==="
cargo build --release
systemctl --user restart lodijke-cms-server.service 2>/dev/null || true

echo "================================================================="
echo " KLAAR! GRAMPS XML (.gramps) Import & Export is actief."
echo " - Download XML via terminal: curl -s http://127.0.0.1:8090/api/gramps/xml"
echo " - Upload .gramps via terminal: curl -X POST --data-binary @bestand.gramps http://127.0.0.1:8090/api/gramps/xml"
echo "================================================================="
