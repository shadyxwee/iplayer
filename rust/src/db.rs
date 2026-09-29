use anyhow::Result;
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::Mutex;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelRecord {
    pub id: Option<i64>,
    pub playlist_id: i64,
    pub name: String,
    pub stream_url: String,
    pub logo_url: Option<String>,
    pub group_title: Option<String>,
    pub tvg_id: Option<String>,
    pub tvg_name: Option<String>,
    pub content_type: String, // "live", "movie", "series"
    pub is_favorite: bool,
    pub user_agent: Option<String>,
    pub referer: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EpgProgramRecord {
    pub id: Option<i64>,
    pub channel_tvg_id: String,
    pub title: String,
    pub description: Option<String>,
    pub start_time: i64, // Unix timestamp in seconds
    pub end_time: i64,   // Unix timestamp in seconds
    pub category: Option<String>,
    pub icon_url: Option<String>,
}

pub struct DbEngine {
    conn: Mutex<Connection>,
}

impl DbEngine {
    pub fn open<P: AsRef<Path>>(db_path: P) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        let engine = Self {
            conn: Mutex::new(conn),
        };
        engine.init_tables()?;
        Ok(engine)
    }

    pub fn open_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let engine = Self {
            conn: Mutex::new(conn),
        };
        engine.init_tables()?;
        Ok(engine)
    }

    fn init_tables(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();

        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS playlists (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                url_or_path TEXT NOT NULL,
                playlist_type TEXT NOT NULL, -- 'm3u', 'xtream', 'stalker'
                mac_address TEXT,
                username TEXT,
                password TEXT,
                created_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS channels (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                playlist_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                stream_url TEXT NOT NULL,
                logo_url TEXT,
                group_title TEXT,
                tvg_id TEXT,
                tvg_name TEXT,
                content_type TEXT NOT NULL DEFAULT 'live',
                is_favorite INTEGER NOT NULL DEFAULT 0,
                user_agent TEXT,
                referer TEXT,
                FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_channels_playlist ON channels(playlist_id);
            CREATE INDEX IF NOT EXISTS idx_channels_content_type ON channels(content_type);
            CREATE INDEX IF NOT EXISTS idx_channels_tvg_id ON channels(tvg_id);

            CREATE TABLE IF NOT EXISTS epg_programs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                channel_tvg_id TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                start_time INTEGER NOT NULL,
                end_time INTEGER NOT NULL,
                category TEXT,
                icon_url TEXT
            );

            CREATE INDEX IF NOT EXISTS idx_epg_channel_time ON epg_programs(channel_tvg_id, start_time, end_time);

            -- FTS5 Virtual Table for Channel Search
            CREATE VIRTUAL TABLE IF NOT EXISTS channels_fts USING fts5(
                name,
                group_title,
                tvg_id,
                content_rowid UNINDEXED
            );
            ",
        )?;

        Ok(())
    }

    pub fn insert_channels_batch(&self, channels: &[ChannelRecord]) -> Result<usize> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        let mut inserted_count = 0;
        {
            let mut stmt = tx.prepare(
                "INSERT INTO channels (playlist_id, name, stream_url, logo_url, group_title, tvg_id, tvg_name, content_type, is_favorite, user_agent, referer)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
            )?;

            let mut fts_stmt = tx.prepare(
                "INSERT INTO channels_fts (rowid, name, group_title, tvg_id, content_rowid)
                 VALUES (?1, ?2, ?3, ?4, ?1)",
            )?;

            for c in channels {
                let row_id = stmt.insert(params![
                    c.playlist_id,
                    c.name,
                    c.stream_url,
                    c.logo_url,
                    c.group_title,
                    c.tvg_id,
                    c.tvg_name,
                    c.content_type,
                    if c.is_favorite { 1 } else { 0 },
                    c.user_agent,
                    c.referer,
                ])?;

                fts_stmt.execute(params![
                    row_id,
                    c.name,
                    c.group_title.as_deref().unwrap_or(""),
                    c.tvg_id.as_deref().unwrap_or(""),
                ])?;

                inserted_count += 1;
            }
        }

        tx.commit()?;
        Ok(inserted_count)
    }

    pub fn search_channels_fts(&self, query: &str, limit: usize) -> Result<Vec<ChannelRecord>> {
        let conn = self.conn.lock().unwrap();
        let fts_query = format!("{}*", query.replace('"', ""));

        let mut stmt = conn.prepare(
            "SELECT c.id, c.playlist_id, c.name, c.stream_url, c.logo_url, c.group_title, c.tvg_id, c.tvg_name, c.content_type, c.is_favorite, c.user_agent, c.referer
             FROM channels_fts fts
             JOIN channels c ON fts.content_rowid = c.id
             WHERE channels_fts MATCH ?1
             LIMIT ?2",
        )?;

        let channel_rows = stmt.query_map(params![fts_query, limit as i64], |row| {
            Ok(ChannelRecord {
                id: Some(row.get(0)?),
                playlist_id: row.get(1)?,
                name: row.get(2)?,
                stream_url: row.get(3)?,
                logo_url: row.get(4)?,
                group_title: row.get(5)?,
                tvg_id: row.get(6)?,
                tvg_name: row.get(7)?,
                content_type: row.get(8)?,
                is_favorite: row.get::<_, i32>(9)? == 1,
                user_agent: row.get(10)?,
                referer: row.get(11)?,
            })
        })?;

        let mut results = Vec::new();
        for ch in channel_rows {
            results.push(ch?);
        }

        Ok(results)
    }

    pub fn get_channels_by_playlist(&self, playlist_id: i64) -> Result<Vec<ChannelRecord>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, playlist_id, name, stream_url, logo_url, group_title, tvg_id, tvg_name, content_type, is_favorite, user_agent, referer
             FROM channels
             WHERE playlist_id = ?1",
        )?;

        let channel_rows = stmt.query_map(params![playlist_id], |row| {
            Ok(ChannelRecord {
                id: Some(row.get(0)?),
                playlist_id: row.get(1)?,
                name: row.get(2)?,
                stream_url: row.get(3)?,
                logo_url: row.get(4)?,
                group_title: row.get(5)?,
                tvg_id: row.get(6)?,
                tvg_name: row.get(7)?,
                content_type: row.get(8)?,
                is_favorite: row.get::<_, i32>(9)? == 1,
                user_agent: row.get(10)?,
                referer: row.get(11)?,
            })
        })?;

        let mut results = Vec::new();
        for ch in channel_rows {
            results.push(ch?);
        }

        Ok(results)
    }

    pub fn insert_epg_programs_batch(&self, programs: &[EpgProgramRecord]) -> Result<usize> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        let mut count = 0;
        {
            let mut stmt = tx.prepare(
                "INSERT INTO epg_programs (channel_tvg_id, title, description, start_time, end_time, category, icon_url)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            )?;

            for p in programs {
                stmt.execute(params![
                    p.channel_tvg_id,
                    p.title,
                    p.description,
                    p.start_time,
                    p.end_time,
                    p.category,
                    p.icon_url,
                ])?;
                count += 1;
            }
        }

        tx.commit()?;
        Ok(count)
    }

    pub fn get_current_program(&self, channel_tvg_id: &str, timestamp: i64) -> Result<Option<EpgProgramRecord>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, channel_tvg_id, title, description, start_time, end_time, category, icon_url
             FROM epg_programs
             WHERE channel_tvg_id = ?1 AND start_time <= ?2 AND end_time >= ?2
             LIMIT 1",
        )?;

        let mut rows = stmt.query(params![channel_tvg_id, timestamp])?;
        if let Some(row) = rows.next()? {
            Ok(Some(EpgProgramRecord {
                id: Some(row.get(0)?),
                channel_tvg_id: row.get(1)?,
                title: row.get(2)?,
                description: row.get(3)?,
                start_time: row.get(4)?,
                end_time: row.get(5)?,
                category: row.get(6)?,
                icon_url: row.get(7)?,
            }))
        } else {
            Ok(None)
        }
    }
}
