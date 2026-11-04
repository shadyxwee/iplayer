use rusqlite::{params, Connection, Result};

pub struct LocalDatabase {
    conn: Connection,
}

impl LocalDatabase {
    pub fn open_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let db = Self { conn };
        db.init_tables()?;
        Ok(db)
    }

    pub fn open(path: &str) -> Result<Self> {
        let conn = Connection::open(path)?;
        let db = Self { conn };
        db.init_tables()?;
        Ok(db)
    }

    fn init_tables(&self) -> Result<()> {
        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS favorites (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                content_type TEXT NOT NULL,
                logo TEXT,
                group_name TEXT,
                added_at INTEGER NOT NULL
            )",
            [],
        )?;

        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS loved_categories (
                name TEXT PRIMARY KEY,
                category_type TEXT NOT NULL
            )",
            [],
        )?;

        Ok(())
    }

    pub fn add_favorite(&self, id: &str, name: &str, content_type: &str, logo: Option<&str>, group: Option<&str>) -> Result<()> {
        let now = chrono::Utc::now().timestamp();
        self.conn.execute(
            "INSERT OR REPLACE INTO favorites (id, name, content_type, logo, group_name, added_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![id, name, content_type, logo, group, now],
        )?;
        Ok(())
    }

    pub fn remove_favorite(&self, id: &str) -> Result<()> {
        self.conn.execute("DELETE FROM favorites WHERE id = ?1", params![id])?;
        Ok(())
    }

    pub fn is_favorite(&self, id: &str) -> Result<bool> {
        let mut stmt = self.conn.prepare("SELECT 1 FROM favorites WHERE id = ?1")?;
        let exists = stmt.exists(params![id])?;
        Ok(exists)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_favorites_db() {
        let db = LocalDatabase::open_in_memory().unwrap();
        assert!(!db.is_favorite("123").unwrap());
        db.add_favorite("123", "HBO HD", "live", None, Some("Movies")).unwrap();
        assert!(db.is_favorite("123").unwrap());
        db.remove_favorite("123").unwrap();
        assert!(!db.is_favorite("123").unwrap());
    }
}
