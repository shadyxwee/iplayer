use anyhow::Result;
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::Mutex;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaylistRecord {
    pub id: Option<i64>,
    pub name: String,
    pub url_or_path: String,
    pub playlist_type: String, // "m3u", "xtream", "stalker"
    pub mac_address: Option<String>,
    pub username: Option<String>,
    pub password: Option<String>,
    pub created_at: i64,
}

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
    pub play_count: i64,
    pub last_played: Option<i64>,
    pub rating: f64,
    pub description: Option<String>,
    pub watched_ms: i64,
    pub total_ms: i64,
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
                playlist_type TEXT NOT NULL,
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
                play_count INTEGER NOT NULL DEFAULT 0,
                last_played INTEGER,
                rating REAL NOT NULL DEFAULT 0.0,
                description TEXT,
                watched_ms INTEGER NOT NULL DEFAULT 0,
                total_ms INTEGER NOT NULL DEFAULT 0,
                user_agent TEXT,
                referer TEXT,
                FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_channels_playlist ON channels(playlist_id);
            CREATE INDEX IF NOT EXISTS idx_channels_content_type ON channels(content_type);
            CREATE INDEX IF NOT EXISTS idx_channels_favorite ON channels(is_favorite);
            CREATE INDEX IF NOT EXISTS idx_channels_last_played ON channels(last_played);

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

    pub fn add_playlist(&self, pl: &PlaylistRecord) -> Result<i64> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "INSERT INTO playlists (name, url_or_path, playlist_type, mac_address, username, password, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        )?;
        let id = stmt.insert(params![
            pl.name,
            pl.url_or_path,
            pl.playlist_type,
            pl.mac_address,
            pl.username,
            pl.password,
            pl.created_at,
        ])?;
        Ok(id)
    }

    pub fn get_playlists(&self) -> Result<Vec<PlaylistRecord>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, name, url_or_path, playlist_type, mac_address, username, password, created_at FROM playlists",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(PlaylistRecord {
                id: Some(row.get(0)?),
                name: row.get(1)?,
                url_or_path: row.get(2)?,
                playlist_type: row.get(3)?,
                mac_address: row.get(4)?,
                username: row.get(5)?,
                password: row.get(6)?,
                created_at: row.get(7)?,
            })
        })?;

        let mut list = Vec::new();
        for r in rows {
            list.push(r?);
        }
        Ok(list)
    }

    pub fn delete_playlist(&self, id: i64) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("DELETE FROM playlists WHERE id = ?1", params![id])?;
        conn.execute("DELETE FROM channels WHERE playlist_id = ?1", params![id])?;
        Ok(())
    }

    pub fn insert_channels_batch(&self, channels: &[ChannelRecord]) -> Result<usize> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        let mut inserted_count = 0;
        {
            let mut stmt = tx.prepare(
                "INSERT INTO channels (playlist_id, name, stream_url, logo_url, group_title, tvg_id, tvg_name, content_type, is_favorite, play_count, last_played, rating, description, watched_ms, total_ms, user_agent, referer)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17)",
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
                    c.play_count,
                    c.last_played,
                    c.rating,
                    c.description,
                    c.watched_ms,
                    c.total_ms,
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

    pub fn toggle_favorite(&self, channel_id: i64) -> Result<bool> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT is_favorite FROM channels WHERE id = ?1")?;
        let current: i32 = stmt.query_row(params![channel_id], |row| row.get(0))?;
        let new_fav = if current == 1 { 0 } else { 1 };

        conn.execute(
            "UPDATE channels SET is_favorite = ?1 WHERE id = ?2",
            params![new_fav, channel_id],
        )?;

        Ok(new_fav == 1)
    }

    pub fn update_play_progress(&self, channel_id: i64, watched_ms: i64, total_ms: i64) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        let now = chrono::Utc::now().timestamp();
        conn.execute(
            "UPDATE channels SET watched_ms = ?1, total_ms = ?2, play_count = play_count + 1, last_played = ?3 WHERE id = ?4",
            params![watched_ms, total_ms, now, channel_id],
        )?;
        Ok(())
    }

    pub fn search_channels_fts(&self, query: &str, limit: usize) -> Result<Vec<ChannelRecord>> {
        let conn = self.conn.lock().unwrap();
        let fts_query = format!("{}*", query.replace('"', ""));

        let mut stmt = conn.prepare(
            "SELECT c.id, c.playlist_id, c.name, c.stream_url, c.logo_url, c.group_title, c.tvg_id, c.tvg_name, c.content_type, c.is_favorite, c.play_count, c.last_played, c.rating, c.description, c.watched_ms, c.total_ms, c.user_agent, c.referer
             FROM channels_fts fts
             JOIN channels c ON fts.content_rowid = c.id
             WHERE channels_fts MATCH ?1
             LIMIT ?2",
        )?;

        let channel_rows = stmt.query_map(params![fts_query, limit as i64], |row| {
            Self::map_channel_row(row)
        })?;

        let mut results = Vec::new();
        for ch in channel_rows {
            results.push(ch?);
        }

        Ok(results)
    }

    pub fn get_channels_by_type(&self, content_type: &str) -> Result<Vec<ChannelRecord>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, playlist_id, name, stream_url, logo_url, group_title, tvg_id, tvg_name, content_type, is_favorite, play_count, last_played, rating, description, watched_ms, total_ms, user_agent, referer
             FROM channels
             WHERE content_type = ?1",
        )?;

        let channel_rows = stmt.query_map(params![content_type], |row| Self::map_channel_row(row))?;
        let mut results = Vec::new();
        for ch in channel_rows {
            results.push(ch?);
        }
        Ok(results)
    }

    pub fn get_favorites(&self) -> Result<Vec<ChannelRecord>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, playlist_id, name, stream_url, logo_url, group_title, tvg_id, tvg_name, content_type, is_favorite, play_count, last_played, rating, description, watched_ms, total_ms, user_agent, referer
             FROM channels
             WHERE is_favorite = 1",
        )?;

        let channel_rows = stmt.query_map([], |row| Self::map_channel_row(row))?;
        let mut results = Vec::new();
        for ch in channel_rows {
            results.push(ch?);
        }
        Ok(results)
    }

    pub fn get_channels_by_playlist(&self, playlist_id: i64) -> Result<Vec<ChannelRecord>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, playlist_id, name, stream_url, logo_url, group_title, tvg_id, tvg_name, content_type, is_favorite, play_count, last_played, rating, description, watched_ms, total_ms, user_agent, referer
             FROM channels
             WHERE playlist_id = ?1",
        )?;

        let channel_rows = stmt.query_map(params![playlist_id], |row| Self::map_channel_row(row))?;
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

    fn map_channel_row(row: &rusqlite::Row) -> rusqlite::Result<ChannelRecord> {
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
            play_count: row.get(10)?,
            last_played: row.get(11)?,
            rating: row.get(12)?,
            description: row.get(13)?,
            watched_ms: row.get(14)?,
            total_ms: row.get(15)?,
            user_agent: row.get(16)?,
            referer: row.get(17)?,
        })
    }
}
