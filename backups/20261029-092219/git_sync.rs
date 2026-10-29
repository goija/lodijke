use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitEntry {
    pub timestamp: String,
    pub commit: String,
    pub message: String,
    pub status: String,
}

#[derive(Default)]
pub struct GitSync { repo_path: String, branch: String }

impl GitSync {
    pub fn new(path: String, br: String) -> Self { GitSync { repo_path: path, branch: br } }

    pub async fn sync(&self, msg: &str) -> Result<GitEntry, String> {
        let mut entry = GitEntry { timestamp: Utc::now().to_rfc3339(), commit: String::new(), message: msg.into(), status: "pending".into() };

        let out = Command::new("git").current_dir(&self.repo_path).args(["add", "."]).output()?;
        if !out.status.success() { entry.status = "failed".into(); return Err("Add failed".into()); }

        let diff = Command::new("git").current_dir(&self.repo_path).args(["diff", "--cached", "--quiet"]).output()?;
        if diff.status.success() { entry.status = "success".into(); entry.commit = "no-changes".into(); return Ok(entry); }

        let commit_out = Command::new("git").current_dir(&self.repo_path).args(["commit", "-m", msg]).output()?;
        if !commit_out.status.success() { entry.status = "failed".into(); return Err("Commit failed".into()); }

        let hash = String::from_utf8_lossy(&Command::new("git").current_dir(&self.repo_path).args(["rev-parse", "HEAD"]).output()?.stdout).trim().to_string();
        
        Command::new("git").current_dir(&self.repo_path).args(["push", "origin", &self.branch]).output()?;
        entry.status = "success".into();
        entry.commit = hash;
        Ok(entry)
    }
}
