use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StalkerProfile {
    pub id: Option<String>,
    pub login: Option<String>,
    pub status: Option<String>,
    pub expire_date: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StalkerCategory {
    pub id: String,
    pub title: String,
    pub alias: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StalkerItem {
    pub id: String,
    pub name: String,
    pub number: Option<String>,
    pub cmd: Option<String>,
    pub logo: Option<String>,
    pub genre_id: Option<String>,
}

pub fn normalize_portal_url(url: &str) -> String {
    let mut normalized = url.trim().to_string();
    if !normalized.starts_with("http://") && !normalized.starts_with("https://") {
        normalized = format!("http://{}", normalized);
    }
    while normalized.ends_with('/') {
        normalized.pop();
    }
    for suffix in &["/c", "/c/portal.php", "/portal.php", "/index.html", "/server/load.php"] {
        if normalized.ends_with(suffix) {
            normalized.truncate(normalized.len() - suffix.len());
            while normalized.ends_with('/') {
                normalized.pop();
            }
        }
    }
    normalized
}

pub fn get_candidate_endpoints(base_url: &str) -> Vec<String> {
    let base = normalize_portal_url(base_url);
    vec![
        format!("{}/portal.php", base),
        format!("{}/c/portal.php", base),
        format!("{}/stalker_portal/server/load.php", base),
        format!("{}/server/load.php", base),
        format!("{}/stalker_portal/c/portal.php", base),
    ]
}

pub fn clean_cmd(cmd: &str) -> String {
    let mut cleaned = cmd.trim();
    if let Some(stripped) = cleaned.strip_prefix("ffmpeg ") {
        cleaned = stripped.trim();
    } else if let Some(stripped) = cleaned.strip_prefix("auto ") {
        cleaned = stripped.trim();
    }
    cleaned.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_and_clean_cmd() {
        assert_eq!(normalize_portal_url("http://example.com/c/"), "http://example.com");
        assert_eq!(clean_cmd("ffmpeg http://stream.m3u8"), "http://stream.m3u8");
    }
}
