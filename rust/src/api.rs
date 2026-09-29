use crate::db::{ChannelRecord, DbEngine, EpgProgramRecord, PlaylistRecord};
use crate::epg::EpgParser;
use crate::m3u::M3uParser;
use crate::stalker::{StalkerConfig, StalkerEngine, StreamDetails};
use anyhow::Result;
use lazy_static::lazy_static;
use parking_lot::RwLock;
use std::sync::Arc;

lazy_static! {
    static ref GLOBAL_DB: RwLock<Option<Arc<DbEngine>>> = RwLock::new(None);
}

pub fn init_db(db_path: String) -> Result<bool> {
    let engine = DbEngine::open(db_path)?;
    *GLOBAL_DB.write() = Some(Arc::new(engine));
    Ok(true)
}

pub fn init_in_memory_db() -> Result<bool> {
    let engine = DbEngine::open_in_memory()?;
    *GLOBAL_DB.write() = Some(Arc::new(engine));
    Ok(true)
}

pub fn add_playlist(name: String, url_or_path: String, playlist_type: String) -> Result<i64> {
    let pl = PlaylistRecord {
        id: None,
        name,
        url_or_path,
        playlist_type,
        mac_address: None,
        username: None,
        password: None,
        created_at: chrono::Utc::now().timestamp(),
    };
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.add_playlist(&pl)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn get_playlists() -> Result<Vec<PlaylistRecord>> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.get_playlists()
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn delete_playlist(id: i64) -> Result<bool> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.delete_playlist(id)?;
        Ok(true)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn toggle_favorite(channel_id: i64) -> Result<bool> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.toggle_favorite(channel_id)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn get_favorites() -> Result<Vec<ChannelRecord>> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.get_favorites()
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn update_play_progress(channel_id: i64, watched_ms: i64, total_ms: i64) -> Result<bool> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.update_play_progress(channel_id, watched_ms, total_ms)?;
        Ok(true)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn get_channels_by_type(content_type: String) -> Result<Vec<ChannelRecord>> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.get_channels_by_type(&content_type)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn parse_m3u_string(content: String, playlist_id: i64) -> Vec<ChannelRecord> {
    M3uParser::parse_m3u_content(&content, playlist_id)
}

pub fn import_m3u_to_db(content: String, playlist_id: i64) -> Result<usize> {
    let channels = M3uParser::parse_m3u_content(&content, playlist_id);
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.insert_channels_batch(&channels)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn search_channels(query: String, limit: usize) -> Result<Vec<ChannelRecord>> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.search_channels_fts(&query, limit)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn get_playlist_channels(playlist_id: i64) -> Result<Vec<ChannelRecord>> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.get_channels_by_playlist(playlist_id)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn parse_and_import_epg_xml(xml_content: String) -> Result<usize> {
    let programs = EpgParser::parse_xmltv(&xml_content)?;
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.insert_epg_programs_batch(&programs)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn parse_and_import_epg_gz(gz_bytes: Vec<u8>) -> Result<usize> {
    let programs = EpgParser::parse_xmltv_gz(&gz_bytes)?;
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.insert_epg_programs_batch(&programs)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub fn get_current_epg_program(channel_tvg_id: String, timestamp: i64) -> Result<Option<EpgProgramRecord>> {
    let db_guard = GLOBAL_DB.read();
    if let Some(db) = db_guard.as_ref() {
        db.get_current_program(&channel_tvg_id, timestamp)
    } else {
        anyhow::bail!("Database not initialized");
    }
}

pub async fn stalker_handshake(portal_url: String, mac_address: String) -> Result<String> {
    let config = StalkerConfig {
        portal_url,
        mac_address,
        ..Default::default()
    };
    let engine = StalkerEngine::new(config);
    engine.handshake().await
}

pub async fn stalker_get_stream_details(
    portal_url: String,
    mac_address: String,
    cmd: String,
) -> Result<StreamDetails> {
    let config = StalkerConfig {
        portal_url,
        mac_address,
        ..Default::default()
    };
    let engine = StalkerEngine::new(config);
    engine.get_create_link(&cmd).await
}
