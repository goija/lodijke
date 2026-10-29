use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsPerson {
    pub gramps_id: String,
    pub handle: String,
    pub name_given: Option<String>,
    pub name_surname: Option<String>,
    pub birth_date: Option<String>,
    pub death_date: Option<String>,
}

pub struct GrampsProxy {
    client: Client,
    base_url: String,
    tree_id: String,
}

impl GrampsProxy {
    pub fn new() -> Self {
        GrampsProxy {
            client: Client::builder().timeout(std::time::Duration::from_secs(60)).build().unwrap(),
            base_url: env::var("GRAMPS_URL").unwrap_or("http://localhost:8081".into()),
            tree_id: env::var("GRAMPS_TREE").unwrap_or("Main".into()),
        }
    }

    pub fn base_url(&self) -> String { self.base_url.clone() }
    pub fn tree_id(&self) -> String { self.tree_id.clone() }

    pub async fn ping(&self) -> Result<(), String> {
        let url = format!("{}/api/{}/stats/?format=json", self.base_url, self.tree_id);
        self.client.get(&url).send().await.map_err(|e| e.to_string())?.error_for_status().map(|_| ()).map_err(|e| e.to_string())
    }

    pub async fn get_people(&self) -> Result<Vec<GrampsPerson>, String> {
        let url = format!("{}/api/{}/people/?format=json", self.base_url, self.tree_id);
        self.client.get(&url).send().await.map_err(|e| e.to_string())?.json().await.map_err(|e| e.to_string())
    }

    pub async fn get_person(&self, handle: &str) -> Result<Option<GrampsPerson>, String> {
        let url = format!("{}/api/{}/people/{}?format=json", self.base_url, self.tree_id, handle);
        match self.client.get(&url).send().await {
            Ok(r) if r.status().is_not_found() => Ok(None),
            Ok(r) => r.json().await.map(Some).map_err(|e| e.to_string()),
            Err(e) => Err(e.to_string()),
        }
    }
}
