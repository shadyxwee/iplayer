use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaylistConfig {
    pub id: Option<i64>,
    pub name: String,
    pub source_type: String, // "m3u", "xtream", "stalker"
    pub url: String,
    pub username: Option<String>,
    pub password: Option<String>,
    pub mac_address: Option<String>,
    pub is_active: bool,
}
