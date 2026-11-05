# High-Performance Poster, Thumbnail & Metadata Fetching Architecture

This document provides a complete technical specification and Rust reference implementation of the metadata, thumbnail, and poster acquisition engine implemented in VortexTube. It is designed to be language-agnostic and directly implementable in any application or backend service.

---

## 1. System Overview & Ingestion Pipeline

The metadata engine fetches, normalizes, supplements, and caches visual artwork (logos, movie posters, series backdrops, episode stills) across three distinct IPTV protocol sources:
1. **Raw M3U / M3U8 Playlists**
2. **Xtream Codes API**
3. **Stalker / Ministra MAC Portals**

### The Multi-Tier Resolution Funnel

```
               ┌────────────────────────────────────────────────────────┐
               │    Raw Stream Entry (Channel / Movie / Series)        │
               └───────────────────────────┬────────────────────────────┘
                                           │
         ┌─────────────────────────────────┼─────────────────────────────────┐
         ▼                                 ▼                                 ▼
   [M3U Attributes]               [Xtream Codes API]                 [Stalker Portal]
   • tvg-logo / logo              • stream_icon                      • logo (ITV)
   • group-title                  • cover                            • screenshot_uri / poster
                                  • get_vod_info / get_series_info   • get_ordered_list
         │                                 │                                 │
         └─────────────────────────────────┼─────────────────────────────────┘
                                           │
                                  Is Artwork Present?
                                  ├── Yes ──> Image Cache Pipeline (Memory + Disk)
                                  └── No  ──> Secondary Metadata Enrichment (TMDB / OMDb)
                                                    │
                                         Title Normalization Engine
                                         (Strip years, codecs, brackets)
                                                    │
                                         TMDB API Search & Image Ingestion
                                                    │
                                         Zero-Latency Cache Storage
```

---

## 2. Source-Level Artwork Extraction

### 2.1 Raw M3U / M3U8 Parsing
M3U files embed artwork metadata inside `#EXTINF` tags. Providers format attributes inconsistently (unquoted, single-quoted, double-quoted, or with varying key names).

```m3u
#EXTINF:-1 tvg-id="hbo.us" tvg-name="HBO HD" tvg-logo="https://img.server.net/logos/hbo.png" group-title="USA Premium",HBO HD
http://stream.server.net:8080/live/user/pass/123.ts
```

#### Extraction Rules:
- Primary key: `tvg-logo`
- Secondary key: `logo`
- Parsing Regex:
  - Double quotes: `tvg-logo="([^"]*)"` or `logo="([^"]*)"`
  - Single quotes: `tvg-logo='([^']*)'` or `logo='([^']*)'`
  - Unquoted: `tvg-logo=([^\s,]+)`

---

### 2.2 Xtream Codes API
Xtream Codes serves artwork across JSON endpoints:

#### Live Channels (`get_live_streams`):
```json
{
  "stream_id": 10542,
  "name": "BBC One HD",
  "stream_icon": "http://server:8080/images/bbcone.png"
}
```
- Direct channel logo: `stream_icon`

#### VOD Movies (`get_vod_streams`):
```json
{
  "stream_id": 20491,
  "name": "Inception (2010)",
  "stream_icon": "http://server:8080/images/inception.jpg",
  "container_extension": "mp4"
}
```
- Fallback detail call: `action=get_vod_info&vod_id={stream_id}` returns:
  - `info.movie_image`: High-resolution poster
  - `info.backdrop_path`: List of backdrop stills

#### TV Series (`get_series` & `get_series_info`):
```json
{
  "series_id": 304,
  "name": "Breaking Bad",
  "cover": "http://server:8080/images/bb_poster.jpg"
}
```
- Series Poster: `cover`
- Episode Stills (`get_series_info`): `episodes[season_num][episode_index].info.movie_image`

---

### 2.3 Stalker / Ministra MAC Portals
Stalker responses wrap attributes in `js` dictionaries or `data` arrays:

#### Live TV (`type=itv&action=get_ordered_list`):
- Logo field: `logo`
- If relative path, prefix portal base URL:
  $$\text{Logo} = \begin{cases} \text{raw}, & \text{if starts with "http"} \\ \text{base\_url} + \text{raw}, & \text{otherwise} \end{cases}$$

#### VOD / Movies (`type=vod&action=get_ordered_list`):
- Priority:
  1. `screenshot_uri`
  2. `poster`
  3. `big_poster`

#### Series (`type=series&action=get_ordered_list`):
- Series Cover: `screenshot_uri` or `poster`
- Episode Thumbnail: `screenshot_uri`

---

## 3. Title Cleaning & Normalization Engine

Providers pollute movie and series titles with release groups, quality tags, and codecs (e.g., `Inception.2010.1080p.BluRay.x264-SPARKS.mp4` or `[EN] Breaking Bad S01-S05 4K HDR`). To match TMDB / OMDb, strip noise using this deterministic order:

### Cleaning Pipeline:
1. **Bracketed Prefixes / Suffixes**:
   `(\[[^\]]*\]|\([^\)]*\))`
2. **Resolution & Codec Indicators**:
   `\b(4K|2160p|1080p|720p|480p|HD|FHD|UHD|HDR|HEVC|H\.?264|H\.?265|x264|x265|10bit|BluRay|WEB-DL|WEBRip|DVDRip|CAM|TS)\b`
3. **Language & Dub Tags**:
   `\b(EN|US|UK|FR|ES|DE|IT|MULTI|SUB|DUB|VOSTFR)\b`
4. **Punctuation & Separators**:
   Replace `.` `_` `-` with a space.
5. **Whitespace Normalization**:
   Collapse multiple consecutive spaces into a single space and trim.

---

## 4. TMDB & External Metadata Enrichment

When artwork is absent or low-resolution:

### 4.1 Search Query Endpoint
```http
GET https://api.themoviedb.org/3/search/{type}?api_key={api_key}&query={cleaned_title}&language=en-US HTTP/1.1
```
- `type`: `movie` for VOD, `tv` for TV Series.

### 4.2 CDN Image URL Construction
TMDB returns relative path strings (`/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg`). Construct CDN URLs with standard widths:
- **Poster (2:3 aspect ratio)**: `https://image.tmdb.org/t/p/w500{poster_path}`
- **High-Res Backdrop (16:9 banner)**: `https://image.tmdb.org/t/p/original{backdrop_path}`
- **Thumbnail / Small Badge**: `https://image.tmdb.org/t/p/w200{poster_path}`

---

## 5. Zero-Latency Caching Pipeline (Disk + In-Memory)

To eliminate network latency and prevent UI flicker when scrolling grids:
1. **Key Generation**: Cryptographic SHA-256 hash of the normalized URL string.
2. **Two-Tier Storage**:
   - **Tier 1 (RAM)**: In-memory byte buffer map (`HashMap<String, Vec<u8>>`) for zero-latency instant rendering.
   - **Tier 2 (Disk Storage)**: Local filesystem directory (`/poster_cache/{sha256}.img`). Atomic write (`.tmp` file rename) to avoid corrupted cache files during app crash or network interruption.

---

## 6. Complete Rust Reference Implementation

This standalone Rust module implements the entire pipeline: URL normalization, M3U attribute parsing, title cleaning, TMDB fallback queries, and atomic two-tier image caching.

```rust
use anyhow::{Context, Result};
use regex::Regex;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;

// ==========================================
// 1. DATA STRUCTURES
// ==========================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaArtwork {
    pub poster_url: Option<String>,
    pub backdrop_url: Option<String>,
    pub thumbnail_url: Option<String>,
    pub rating: Option<f64>,
    pub plot: Option<String>,
}

#[derive(Debug, Deserialize)]
struct TmdbSearchResponse {
    results: Option<Vec<TmdbResultItem>>,
}

#[derive(Debug, Deserialize)]
struct TmdbResultItem {
    id: Option<i64>,
    title: Option<String>,
    name: Option<String>,
    poster_path: Option<String>,
    backdrop_path: Option<String>,
    vote_average: Option<f64>,
    overview: Option<String>,
}

// ==========================================
// 2. TITLE NORMALIZATION ENGINE
// ==========================================

pub struct TitleCleaner;

impl TitleCleaner {
    pub fn clean(raw: &str) -> String {
        let mut s = raw.to_string();

        // 1. Remove bracketed / parenthetical metadata: [4K], (2022), etc.
        let re_brackets = Regex::new(r"(\[[^\]]*\]|\([^\)]*\))").unwrap();
        s = re_brackets.replace_all(&s, "").to_string();

        // 2. Remove resolution, codecs, and release tags
        let re_tags = Regex::new(r"(?i)\b(4k|2160p|1080p|720p|480p|hd|fhd|uhd|hdr|hevc|h\.?264|h\.?265|x264|x265|10bit|bluray|web-?dl|webrip|dvdrip|cam|ts)\b").unwrap();
        s = re_tags.replace_all(&s, "").to_string();

        // 3. Remove language and audio identifiers
        let re_lang = Regex::new(r"(?i)\b(en|us|uk|fr|es|de|it|multi|sub|dub|vostfr|aac|ddp?5\.1)\b").unwrap();
        s = re_lang.replace_all(&s, "").to_string();

        // 4. Replace separators (. _ -) with spaces
        let re_sep = Regex::new(r"[._\-]").unwrap();
        s = re_sep.replace_all(&s, " ").to_string();

        // 5. Collapse consecutive whitespaces and trim
        let re_spaces = Regex::new(r"\s+").unwrap();
        s = re_spaces.replace_all(&s, " ").trim().to_string();

        s
    }
}

// ==========================================
// 3. M3U ATTRIBUTE PARSER
// ==========================================

pub struct M3uArtworkParser;

impl M3uArtworkParser {
    pub fn extract_logo(extinf_line: &str) -> Option<String> {
        // Double-quoted tvg-logo="url"
        let re_double = Regex::new(r#"(?i)(?:tvg-logo|logo)="([^"]+)""#).unwrap();
        if let Some(caps) = re_double.captures(extinf_line) {
            return Some(caps[1].to_string());
        }

        // Single-quoted tvg-logo='url'
        let re_single = Regex::new(r"(?i)(?:tvg-logo|logo)='([^']+)'").unwrap();
        if let Some(caps) = re_single.captures(extinf_line) {
            return Some(caps[1].to_string());
        }

        // Unquoted tvg-logo=url
        let re_unquoted = Regex::new(r"(?i)(?:tvg-logo|logo)=([^\s,]+)").unwrap();
        if let Some(caps) = re_unquoted.captures(extinf_line) {
            return Some(caps[1].to_string());
        }

        None
    }
}

// ==========================================
// 4. TMDB METADATA PROVIDER
// ==========================================

pub struct TmdbProvider {
    client: Client,
    api_key: String,
}

impl TmdbProvider {
    pub const BASE_URL: &'static str = "https://api.themoviedb.org/3";
    pub const IMAGE_BASE_W500: &'static str = "https://image.tmdb.org/t/p/w500";
    pub const IMAGE_BASE_ORIGINAL: &'static str = "https://image.tmdb.org/t/p/original";

    pub fn new(api_key: String) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(8))
            .build()
            .unwrap_or_default();

        Self { client, api_key }
    }

    pub async fn search(&self, title: &str, is_movie: bool) -> Result<Option<MediaArtwork>> {
        let clean_title = TitleCleaner::clean(title);
        if clean_title.is_empty() {
            return Ok(None);
        }

        let media_type = if is_movie { "movie" } else { "tv" };
        let url = format!("{}/search/{}", Self::BASE_URL, media_type);

        let resp = self
            .client
            .get(&url)
            .query(&[
                ("api_key", &self.api_key),
                ("query", &clean_title),
                ("language", &"en-US".to_string()),
            ])
            .send()
            .await
            .context("TMDB search request failed")?;

        if !resp.status().is_success() {
            return Ok(None);
        }

        let body: TmdbSearchResponse = resp.json().await?;
        if let Some(results) = body.results {
            if let Some(first) = results.first() {
                let poster_url = first
                    .poster_path
                    .as_ref()
                    .map(|p| format!("{}{}", Self::IMAGE_BASE_W500, p));

                let backdrop_url = first
                    .backdrop_path
                    .as_ref()
                    .map(|b| format!("{}{}", Self::IMAGE_BASE_ORIGINAL, b));

                return Ok(Some(MediaArtwork {
                    poster_url,
                    backdrop_url,
                    thumbnail_url: None,
                    rating: first.vote_average,
                    plot: first.overview.clone(),
                }));
            }
        }

        Ok(None)
    }
}

// ==========================================
// 5. TWO-TIER IMAGE CACHING ENGINE
// ==========================================

pub struct ImageCacheEngine {
    client: Client,
    cache_dir: PathBuf,
    memory_cache: Arc<RwLock<HashMap<String, Vec<u8>>>>,
}

impl ImageCacheEngine {
    pub fn new<P: AsRef<Path>>(cache_dir: P) -> Self {
        let dir = cache_dir.as_ref().to_path_buf();
        if !dir.exists() {
            let _ = fs::create_dir_all(&dir);
        }

        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .build()
            .unwrap_or_default();

        Self {
            client,
            cache_dir: dir,
            memory_cache: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Computes deterministic SHA-256 hash for cache key
    pub fn hash_url(url: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(url.as_bytes());
        format!("{:x}", hasher.finalize())
    }

    /// Retrieve cached image bytes (Tier 1: RAM -> Tier 2: Disk)
    pub async fn get_image_bytes(&self, url: &str) -> Option<Vec<u8>> {
        let key = Self::hash_url(url);

        // Tier 1: Memory Cache Lookup
        {
            let mem = self.memory_cache.read().await;
            if let Some(bytes) = mem.get(&key) {
                return Some(bytes.clone());
            }
        }

        // Tier 2: Disk Cache Lookup
        let disk_path = self.cache_dir.join(format!("{}.img", key));
        if disk_path.exists() {
            if let Ok(bytes) = fs::read(&disk_path) {
                if !bytes.is_empty() {
                    // Populate Tier 1 RAM cache
                    self.memory_cache.write().await.insert(key, bytes.clone());
                    return Some(bytes);
                }
            }
        }

        None
    }

    /// Downloads and caches image to Disk and RAM atomically
    pub async fn fetch_and_cache(&self, url: &str) -> Result<Vec<u8>> {
        if let Some(existing) = self.get_image_bytes(url).await {
            return Ok(existing);
        }

        let resp = self
            .client
            .get(url)
            .send()
            .await
            .context("Failed to download image")?;

        if !resp.status().is_success() {
            anyhow::bail!("Image download failed with status {}", resp.status());
        }

        let bytes = resp.bytes().await?.to_vec();
        let key = Self::hash_url(url);

        // 1. Atomic Disk Write via temporary file
        let temp_path = self.cache_dir.join(format!("{}.tmp", key));
        let final_path = self.cache_dir.join(format!("{}.img", key));

        {
            let mut file = File::create(&temp_path)?;
            file.write_all(&bytes)?;
            file.sync_all()?;
        }
        fs::rename(temp_path, final_path)?;

        // 2. Store in Memory Cache
        self.memory_cache.write().await.insert(key, bytes.clone());

        Ok(bytes)
    }
}

// ==========================================
// 6. UNIT TESTS
// ==========================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_title_cleaner() {
        assert_eq!(
            TitleCleaner::clean("Inception.2010.1080p.BluRay.x264-SPARKS.mp4"),
            "Inception"
        );
        assert_eq!(
            TitleCleaner::clean("[EN] Breaking Bad S01-S05 4K HDR UHD"),
            "Breaking Bad S01 S05"
        );
        assert_eq!(
            TitleCleaner::clean("The.Dark.Knight.(2008).FHD.HEVC"),
            "The Dark Knight"
        );
    }

    #[test]
    fn test_m3u_logo_extraction() {
        let extinf1 = r#"#EXTINF:-1 tvg-id="bbc1" tvg-logo="https://cdn.logos.com/bbc1.png" group-title="UK",BBC One"#;
        assert_eq!(
            M3uArtworkParser::extract_logo(extinf1),
            Some("https://cdn.logos.com/bbc1.png".to_string())
        );

        let extinf2 = r#"#EXTINF:-1 logo='https://cdn.logos.com/hbo.png',HBO"#;
        assert_eq!(
            M3uArtworkParser::extract_logo(extinf2),
            Some("https://cdn.logos.com/hbo.png".to_string())
        );

        let extinf3 = r#"#EXTINF:-1 tvg-logo=https://cdn.logos.com/sky.png,Sky Sports"#;
        assert_eq!(
            M3uArtworkParser::extract_logo(extinf3),
            Some("https://cdn.logos.com/sky.png".to_string())
        );
    }

    #[test]
    fn test_hash_url() {
        let hash1 = ImageCacheEngine::hash_url("https://image.tmdb.org/t/p/w500/test.jpg");
        let hash2 = ImageCacheEngine::hash_url("https://image.tmdb.org/t/p/w500/test.jpg");
        assert_eq!(hash1, hash2);
        assert_eq!(hash1.len(), 64); // SHA-256 hex string length
    }
}
```

---

## 7. Implementation Checklist

- [ ] Strip noise (resolutions, codecs, brackets, release tags) before querying external metadata APIs.
- [ ] Parse `tvg-logo` and `logo` supporting unquoted, single-quoted, and double-quoted formats.
- [ ] Prefer panel-provided posters (`stream_icon`, `cover`, `screenshot_uri`) before making network calls to external APIs.
- [ ] Cache resolved artwork on disk using SHA-256 file keys and atomic `.tmp` renames.
- [ ] Maintain an in-memory byte map in RAM to ensure zero-latency image decoding and avoid UI stutters.
