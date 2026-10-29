use serde::{Deserialize, Serialize};
use std::{path::PathBuf, sync::Arc};
use tokio::sync::RwLock;

#[derive(Clone)]
pub struct AppState {
    pub cms_file_path: PathBuf,
    pub cms_records: Arc<RwLock<Vec<CmsRecord>>>,
    pub authors: Arc<RwLock<Vec<Author>>>,
    pub posts: Arc<RwLock<Vec<PostItem>>>,
    pub edits: Arc<RwLock<Vec<EditItem>>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsRecord {
    pub id: String,
    pub title: String,
    pub category: String,
    pub date: String,
    pub body: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Author {
    pub id: String,
    pub name: String,
    pub role: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PostItem {
    pub id: String,
    pub author_id: String,
    pub title: String,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EditItem {
    pub id: String,
    pub post_id: String,
    pub proposed_content: String,
    pub status: String, // "PENDING", "ACCEPTED", "REJECTED"
    pub direction: String, // "INCOMING", "OUTGOING"
}
