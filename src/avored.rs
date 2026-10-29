use crate::models::CmsRecord;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;

#[derive(Default, Clone)]
pub struct AvoredService {
    records: Arc<RwLock<Vec<CmsRecord>>>,
    data_path: String,
}

impl AvoredService {
    pub fn new(data_path: String) -> Self {
        let mut svc = AvoredService { records: Arc::new(RwLock::new(vec![])), data_path };
        svc.load();
        svc
    }

    fn load(&mut self) {
        let path = format!("{}/cms_records.json", self.data_path);
        if let Ok(content) = std::fs::read_to_string(&path) {
            if !content.trim().is_empty() {
                self.records = Arc::new(RwLock::new(serde_json::from_str(&content).unwrap_or_default()));
            }
        }
    }

    fn save(&self) {
        let path = format!("{}/cms_records.json", self.data_path);
        let guard = self.records.blocking_read();
        let _ = std::fs::write(&path, serde_json::to_string_pretty(&*guard).unwrap_or("[]".into()));
    }

    pub async fn list(&self) -> Vec<CmsRecord> { self.records.read().await.clone() }
    pub async fn get(&self, id: &str) -> Option<CmsRecord> {
        self.records.read().await.iter().find(|r| r.id == id).cloned()
    }
    pub async fn create(&mut self, rec: CmsRecord) -> Result<CmsRecord, String> {
        let mut guard = self.records.write().await;
        if guard.iter().any(|r| r.id == rec.id) { return Err("Exists".into()); }
        guard.push(rec.clone());
        drop(guard);
        self.save();
        Ok(rec)
    }
    pub async fn update(&mut self, id: &str, upd: CmsRecord) -> Result<CmsRecord, String> {
        let mut guard = self.records.write().await;
        if let Some(idx) = guard.iter().position(|r| r.id == id) {
            guard[idx] = upd.clone();
            drop(guard);
            self.save();
            Ok(upd)
        } else { Err("Not found".into()) }
    }
    pub async fn delete(&mut self, id: &str) -> Result<bool, String> {
        let mut guard = self.records.write().await;
        if let Some(pos) = guard.iter().position(|r| r.id == id) {
            guard.remove(pos);
            drop(guard);
            self.save();
            Ok(true)
        } else { Err("Not found".into()) }
    }
}
