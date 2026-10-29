use crate::avored::GitSyncEntry;
use chrono::Utc;
use std::path::Path;
use tokio::process::Command;

pub async fn perform_git_sync(
    repo_dir: &Path,
    log_file: &Path,
    action: &str,
    commit_msg: &str,
    push_remote: bool,
) -> GitSyncEntry {
    let timestamp = Utc::now().to_rfc3339();

    // 1. Stage data/ en eventuele schema-wijzigingen
    let _ = Command::new("git")
        .arg("add")
        .arg("data/")
        .current_dir(repo_dir)
        .output()
        .await;

    // 2. Commit indien er wijzigingen zijn
    let commit_out = Command::new("git")
        .args(["commit", "-m", commit_msg])
        .current_dir(repo_dir)
        .output()
        .await;

    let mut status_str = match commit_out {
        Ok(out) if out.status.success() => "COMMITTED".to_string(),
        _ => "CLEAN_OR_NO_DIFF".to_string(),
    };

    // 3. Optionele niet-blokkerende git push naar origin main
    if push_remote {
        if let Ok(push_out) = Command::new("git")
            .args(["push", "origin", "main"])
            .current_dir(repo_dir)
            .output()
            .await
        {
            if push_out.status.success() {
                status_str = "COMMITTED_AND_PUSHED".to_string();
            } else {
                status_str = format!("{}_LOCAL_ONLY", status_str);
            }
        }
    }

    // 4. Haal huidige korte commit-hash op
    let hash_out = Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .current_dir(repo_dir)
        .output()
        .await;

    let commit_hash = hash_out
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "HEAD".to_string());

    let entry = GitSyncEntry {
        timestamp,
        action: action.to_string(),
        commit_hash,
        message: commit_msg.to_string(),
        status: status_str,
    };

    // 5. Schrijf naar data/git_sync_log.json
    let mut logs: Vec<GitSyncEntry> = std::fs::read_to_string(log_file)
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default();

    logs.insert(0, entry.clone());
    if logs.len() > 50 {
        logs.truncate(50);
    }
    if let Ok(json_str) = serde_json::to_string_pretty(&logs) {
        let _ = std::fs::write(log_file, json_str);
    }

    entry
}

pub async fn get_git_branch_and_status(repo_dir: &Path) -> (String, String, String) {
    let branch = Command::new("git")
        .args(["rev-parse", "--abbrev-ref", "HEAD"])
        .current_dir(repo_dir)
        .output()
        .await
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "main".to_string());

    let last_commit = Command::new("git")
        .args(["log", "-1", "--pretty=format:%h - %s (%ci)"])
        .current_dir(repo_dir)
        .output()
        .await
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "Nog geen commits".to_string());

    let remote = Command::new("git")
        .args(["remote", "get-url", "origin"])
        .current_dir(repo_dir)
        .output()
        .await
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "https://github.com/goija/lodijke".to_string());

    (branch, last_commit, remote)
}
