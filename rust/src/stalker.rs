use anyhow::{bail, Context, Result};
use md5::Digest;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, CONNECTION, COOKIE, REFERER, USER_AGENT};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;

const DEFAULT_USER_AGENT: &str =
    "Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3";
const DEFAULT_TIMEZONE: &str = "Europe/London";
const DEFAULT_LANG: &str = "en";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StalkerConfig {
    pub portal_url: String,
    pub mac_address: String,
    pub device_id: String,
    pub device_id2: String,
    pub signature: String,
    pub serial_number: String,
}

impl Default for StalkerConfig {
    fn default() -> Self {
        Self {
            portal_url: String::new(),
            mac_address: "00:1A:79:00:00:00".to_string(),
            device_id: "MAG254_DEVICE_ID_DEFAULT".to_string(),
            device_id2: "MAG254_DEVICE_ID2_DEFAULT".to_string(),
            signature: "MAG254_SIGNATURE_DEFAULT".to_string(),
            serial_number: "MAG254_SERIAL_DEFAULT".to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamDetails {
    pub stream_url: String,
    pub headers: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MacCheckResult {
    pub is_working: bool,
    pub token: Option<String>,
    pub endpoint: Option<String>,
    pub expiry_date: Option<String>,
    pub status: Option<String>,
    pub error_message: Option<String>,
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
    pub cmd: String,
    pub category_id: Option<String>,
    pub logo: Option<String>,
    pub description: Option<String>,
    pub genre_id: Option<String>,
}

#[derive(Debug, Deserialize)]
struct StalkerEnvelope<T> {
    js: Option<T>,
}

#[derive(Debug, Deserialize)]
struct HandshakeData {
    token: Option<String>,
}

pub struct StalkerEngine {
    client: Client,
    pub config: StalkerConfig,
    active_endpoint: Arc<RwLock<Option<String>>>,
    token: Arc<RwLock<Option<String>>>,
}

impl StalkerEngine {
    pub fn new(config: StalkerConfig) -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(12))
            .cookie_store(true)
            .build()
            .unwrap_or_default();

        Self {
            client,
            config,
            active_endpoint: Arc::new(RwLock::new(None)),
            token: Arc::new(RwLock::new(None)),
        }
    }

    /// Step 3.1: Normalize the user-provided Portal URL:
    /// - Remove trailing /c, /c/, /index.html, etc.
    /// - Keep only scheme + host + port + optional base path up to (but not including) /c
    pub fn normalize_url(raw_url: &str) -> String {
        let trimmed = raw_url.trim();
        let mut url = trimmed.to_string();

        // Strip known trailing suffixes
        loop {
            let prev = url.clone();
            let stripped = url.trim_end_matches('/');
            if stripped.ends_with("/index.html") {
                url = stripped.trim_end_matches("/index.html").to_string();
            } else if stripped.ends_with("/index.php") {
                url = stripped.trim_end_matches("/index.php").to_string();
            } else if stripped.ends_with("/c") {
                url = stripped.trim_end_matches("/c").to_string();
            } else if stripped.ends_with("/stalker_portal/c") {
                url = stripped.trim_end_matches("/stalker_portal/c").to_string();
            } else if stripped.ends_with("/stalker_portal") {
                url = stripped.trim_end_matches("/stalker_portal").to_string();
            } else {
                url = stripped.to_string();
            }

            if url == prev {
                break;
            }
        }

        url.trim_end_matches('/').to_string()
    }

    /// Step 3.2: Generate candidate endpoints in priority order:
    /// 1. {base}/portal.php
    /// 2. {base}/c/portal.php
    /// 3. {base}/stalker_portal/server/load.php
    /// 4. {base}/server/load.php
    /// 5. {base}/stalker_portal/c/portal.php
    pub fn candidate_endpoints(base_url: &str) -> Vec<String> {
        let norm = Self::normalize_url(base_url);
        vec![
            format!("{}/portal.php", norm),
            format!("{}/c/portal.php", norm),
            format!("{}/stalker_portal/server/load.php", norm),
            format!("{}/server/load.php", norm),
            format!("{}/stalker_portal/c/portal.php", norm),
        ]
    }

    /// Get current active endpoint, or detect one if not yet determined.
    pub async fn get_active_endpoint(&self) -> Result<String> {
        {
            let guard = self.active_endpoint.read().await;
            if let Some(ep) = &*guard {
                return Ok(ep.clone());
            }
        }

        self.detect_endpoint().await
    }

    /// Detect working endpoint across candidate list
    pub async fn detect_endpoint(&self) -> Result<String> {
        let candidates = Self::candidate_endpoints(&self.config.portal_url);
        let mut last_err = None;

        for candidate in &candidates {
            match self.try_handshake_endpoint(candidate).await {
                Ok(token) => {
                    *self.active_endpoint.write().await = Some(candidate.clone());
                    *self.token.write().await = Some(token);
                    return Ok(candidate.clone());
                }
                Err(e) => {
                    last_err = Some(e);
                }
            }
        }

        bail!(
            "Failed to detect Stalker portal API endpoint across candidates: {:?}",
            last_err.map(|e| e.to_string()).unwrap_or_default()
        )
    }

    /// Build standard headers required on every request
    fn build_headers(&self, token_opt: Option<&str>) -> Result<HeaderMap> {
        let base_url = Self::normalize_url(&self.config.portal_url);
        let mut headers = HeaderMap::new();

        headers.insert(USER_AGENT, HeaderValue::from_static(DEFAULT_USER_AGENT));
        headers.insert(CONNECTION, HeaderValue::from_static("Keep-Alive"));
        headers.insert(
            REFERER,
            HeaderValue::from_str(&format!("{}/c/", base_url))
                .unwrap_or_else(|_| HeaderValue::from_static("http://localhost/c/")),
        );

        // Compute Advanced Cryptographic hashes (adid, sncut, devenc, signature)
        let bytes = self.config.mac_address.as_bytes();
        let mut adid_hasher = sha1::Sha1::new();
        adid_hasher.update(bytes);
        let adid = format!("{:x}", adid_hasher.finalize());

        let mut md5_hasher = md5::Md5::new();
        md5_hasher.update(bytes);
        let sn_hex = format!("{:X}", md5_hasher.finalize());
        let sncut = if sn_hex.len() >= 13 { &sn_hex[..13] } else { &sn_hex };

        let mut dev_hasher = sha2::Sha256::new();
        dev_hasher.update(bytes);
        let devenc = format!("{:X}", dev_hasher.finalize());

        let cookie_str = match token_opt {
            Some(tok) => format!(
                "mac={}; stb_lang={}; timezone={}; token={}; adid={}; debug=1; device_id2={}; device_id={}; hw_version=1.7-BD-00; sn={}",
                self.config.mac_address, DEFAULT_LANG, DEFAULT_TIMEZONE, tok, adid, devenc, devenc, sncut
            ),
            None => format!(
                "mac={}; stb_lang={}; timezone={}; adid={}; debug=1; device_id2={}; device_id={}; hw_version=1.7-BD-00; sn={}",
                self.config.mac_address, DEFAULT_LANG, DEFAULT_TIMEZONE, adid, devenc, devenc, sncut
            ),
        };

        headers.insert(COOKIE, HeaderValue::from_str(&cookie_str)?);

        if let Some(tok) = token_opt {
            headers.insert(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("Bearer {}", tok))?,
            );
        }

        Ok(headers)
    }

    async fn try_handshake_endpoint(&self, endpoint: &str) -> Result<String> {
        let url = format!("{}?type=stb&action=handshake&JsHttpRequest=1-xml", endpoint);
        let headers = self.build_headers(None)?;

        let resp = self
            .client
            .get(&url)
            .headers(headers)
            .send()
            .await
            .context("Handshake connection failed")?;

        let text = resp.text().await.context("Failed to read response body")?;

        let envelope: StalkerEnvelope<HandshakeData> =
            serde_json::from_str(&text).context("Invalid JSON envelope during handshake")?;

        if let Some(js) = envelope.js {
            if let Some(token) = js.token {
                if !token.is_empty() {
                    return Ok(token);
                }
            }
        }

        bail!("Handshake succeeded but no valid token returned");
    }

    pub async fn handshake(&self) -> Result<String> {
        let endpoint = self.get_active_endpoint().await?;
        let token = self.try_handshake_endpoint(&endpoint).await?;
        *self.token.write().await = Some(token.clone());
        Ok(token)
    }

    /// Generic request with token injection and automatic 401 retry
    pub async fn request(&self, params: &[(&str, &str)]) -> Result<serde_json::Value> {
        let mut token_val = {
            let t = self.token.read().await;
            t.clone()
        };

        if token_val.is_none() {
            token_val = Some(self.handshake().await?);
        }

        let endpoint = self.get_active_endpoint().await?;

        // Try request, re-handshaking if 401 / 403 or token error occurs
        for attempt in 0..2 {
            let mut req = self
                .client
                .get(&endpoint)
                .headers(self.build_headers(token_val.as_deref())?);

            for &(k, v) in params {
                req = req.query(&[(k, v)]);
            }
            req = req.query(&[("JsHttpRequest", "1-xml")]);

            let resp = req.send().await.context("Stalker API request failed")?;
            let status = resp.status();

            if (status.as_u16() == 401 || status.as_u16() == 403) && attempt == 0 {
                token_val = Some(self.handshake().await?);
                continue;
            }

            let text = resp.text().await.context("Failed to read Stalker API response")?;

            if let Ok(val) = serde_json::from_str::<serde_json::Value>(&text) {
                // If the body itself indicates token expiration or auth failure
                if let Some(js_str) = val.get("js").and_then(|j| j.as_str()) {
                    if (js_str.contains("authorization") || js_str.contains("token")) && attempt == 0 {
                        token_val = Some(self.handshake().await?);
                        continue;
                    }
                }
                return Ok(val);
            } else {
                bail!("Invalid JSON response from Stalker portal: {}", text);
            }
        }

        bail!("Stalker request failed after token re-handshake retry");
    }

    /// Step 7: MAC Checker
    pub async fn check_mac(&self) -> MacCheckResult {
        let token = match self.handshake().await {
            Ok(t) => t,
            Err(e) => {
                return MacCheckResult {
                    is_working: false,
                    token: None,
                    endpoint: None,
                    expiry_date: None,
                    status: None,
                    error_message: Some(format!("Handshake failed: {}", e)),
                };
            }
        };

        let endpoint = self.active_endpoint.read().await.clone();

        // Call get_profile
        let profile_res = self
            .request(&[("type", "stb"), ("action", "get_profile")])
            .await;

        let mut expiry_date = None;
        let mut status = None;

        match profile_res {
            Ok(val) => {
                if let Some(js) = val.get("js") {
                    if js.is_null() || js == false {
                        return MacCheckResult {
                            is_working: false,
                            token: Some(token),
                            endpoint,
                            expiry_date: None,
                            status: Some("Blocked/Invalid MAC".to_string()),
                            error_message: Some("Portal rejected MAC address in profile query".to_string()),
                        };
                    }

                    if let Some(exp) = js.get("phone").or_else(|| js.get("expire_billing")).and_then(|v| v.as_str()) {
                        expiry_date = Some(exp.to_string());
                    }
                    if let Some(st) = js.get("status").and_then(|v| v.as_str()) {
                        status = Some(st.to_string());
                    } else if let Some(st) = js.get("status").and_then(|v| v.as_i64()) {
                        status = Some(st.to_string());
                    }
                }
            }
            Err(e) => {
                return MacCheckResult {
                    is_working: false,
                    token: Some(token),
                    endpoint,
                    expiry_date: None,
                    status: None,
                    error_message: Some(format!("Profile check error: {}", e)),
                };
            }
        }

        MacCheckResult {
            is_working: true,
            token: Some(token),
            endpoint,
            expiry_date,
            status: status.or_else(|| Some("Active".to_string())),
            error_message: None,
        }
    }

    /// Load categories: itv (live), vod (movies), or series
    pub async fn get_categories(&self, media_type: &str) -> Result<Vec<StalkerCategory>> {
        let action = if media_type == "itv" {
            "get_genres"
        } else {
            "get_categories"
        };

        let val = self.request(&[("type", media_type), ("action", action)]).await?;

        let mut categories = Vec::new();
        if let Some(js) = val.get("js").and_then(|j| j.as_array()) {
            for item in js {
                let id = item.get("id").and_then(|v| v.as_str().map(|s| s.to_string()).or_else(|| v.as_i64().map(|n| n.to_string()))).unwrap_or_default();
                let title = item.get("title").and_then(|v| v.as_str()).unwrap_or("Unknown").to_string();
                let alias = item.get("alias").and_then(|v| v.as_str()).map(|s| s.to_string());

                if !id.is_empty() {
                    categories.push(StalkerCategory { id, title, alias });
                }
            }
        }

        Ok(categories)
    }

    /// Load items: ordered list of channels or VOD items with pagination
    pub async fn get_ordered_list(
        &self,
        media_type: &str,
        category_id: Option<&str>,
        page: u32,
    ) -> Result<Vec<StalkerItem>> {
        let p_str = page.to_string();
        let mut query = vec![
            ("type", media_type),
            ("action", "get_ordered_list"),
            ("p", &p_str),
        ];

        let genre_key = if media_type == "itv" { "genre" } else { "category" };
        if let Some(cat) = category_id {
            if cat != "0" && cat != "*" && !cat.is_empty() {
                query.push((genre_key, cat));
            }
        }

        let val = self.request(&query).await?;
        let mut items = Vec::new();

        if let Some(data_array) = val.pointer("/js/data").and_then(|v| v.as_array()) {
            for item in data_array {
                let id = item.get("id").and_then(|v| v.as_str().map(|s| s.to_string()).or_else(|| v.as_i64().map(|n| n.to_string()))).unwrap_or_default();
                let name = item.get("name").and_then(|v| v.as_str()).unwrap_or("Unknown").to_string();
                let number = item.get("number").and_then(|v| v.as_str().map(|s| s.to_string()).or_else(|| v.as_i64().map(|n| n.to_string())));
                let cmd = item.get("cmd").and_then(|v| v.as_str()).unwrap_or_default().to_string();
                let logo = item.get("logo").or_else(|| item.get("screenshot_uri")).and_then(|v| v.as_str()).map(|s| s.to_string());
                let description = item.get("descr").or_else(|| item.get("description")).and_then(|v| v.as_str()).map(|s| s.to_string());
                let genre_id = item.get("tv_genre_id").or_else(|| item.get("category_id")).and_then(|v| v.as_str().map(|s| s.to_string()).or_else(|| v.as_i64().map(|n| n.to_string())));

                if !id.is_empty() {
                    items.push(StalkerItem {
                        id,
                        name,
                        number,
                        cmd,
                        category_id: genre_id.clone(),
                        logo,
                        description,
                        genre_id,
                    });
                }
            }
        }

        Ok(items)
    }

    /// Clean command string (removes `ffmpeg `, auto-trim)
    pub fn clean_cmd(cmd: &str) -> String {
        let mut s = cmd.trim();
        if s.starts_with("ffmpeg ") {
            s = &s[7..];
        } else if s.starts_with("auto ") {
            s = &s[5..];
        }
        s.trim().to_string()
    }

    /// Step 8.4: Create stream link with command cleaning
    pub async fn get_create_link(&self, cmd: &str, media_type: Option<&str>) -> Result<StreamDetails> {
        let mtype = media_type.unwrap_or("itv");
        let val = self
            .request(&[
                ("type", mtype),
                ("action", "create_link"),
                ("cmd", cmd),
            ])
            .await?;

        let mut final_url = Self::clean_cmd(cmd);

        if let Some(cmd_val) = val.pointer("/js/cmd").and_then(|v| v.as_str()) {
            final_url = Self::clean_cmd(cmd_val);
        }

        let base_url = Self::normalize_url(&self.config.portal_url);
        let mut headers = HashMap::new();
        headers.insert("User-Agent".to_string(), DEFAULT_USER_AGENT.to_string());

        let token_guard = self.token.read().await;
        let cookie_val = match &*token_guard {
            Some(tok) => format!(
                "mac={}; stb_lang={}; timezone={}; token={}",
                self.config.mac_address, DEFAULT_LANG, DEFAULT_TIMEZONE, tok
            ),
            None => format!(
                "mac={}; stb_lang={}; timezone={}",
                self.config.mac_address, DEFAULT_LANG, DEFAULT_TIMEZONE
            ),
        };

        headers.insert("Cookie".to_string(), cookie_val);
        headers.insert("Referer".to_string(), format!("{}/c/", base_url));
        if let Some(tok) = &*token_guard {
            headers.insert("Authorization".to_string(), format!("Bearer {}", tok));
        }

        Ok(StreamDetails {
            stream_url: final_url,
            headers,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_url() {
        assert_eq!(
            StalkerEngine::normalize_url("http://example.com/c/"),
            "http://example.com"
        );
        assert_eq!(
            StalkerEngine::normalize_url("http://example.com/c"),
            "http://example.com"
        );
        assert_eq!(
            StalkerEngine::normalize_url("http://example.com/stalker_portal/c/"),
            "http://example.com"
        );
        assert_eq!(
            StalkerEngine::normalize_url("http://example.com/index.html"),
            "http://example.com"
        );
        assert_eq!(
            StalkerEngine::normalize_url("http://example.com:8080/portal/c/"),
            "http://example.com:8080/portal"
        );
    }

    #[test]
    fn test_candidate_endpoints_order() {
        let candidates = StalkerEngine::candidate_endpoints("http://portal.example.com/c/");
        assert_eq!(candidates.len(), 5);
        assert_eq!(candidates[0], "http://portal.example.com/portal.php");
        assert_eq!(candidates[1], "http://portal.example.com/c/portal.php");
        assert_eq!(candidates[2], "http://portal.example.com/stalker_portal/server/load.php");
        assert_eq!(candidates[3], "http://portal.example.com/server/load.php");
        assert_eq!(candidates[4], "http://portal.example.com/stalker_portal/c/portal.php");
    }

    #[test]
    fn test_clean_cmd() {
        assert_eq!(
            StalkerEngine::clean_cmd("ffmpeg http://server.com/live/1.ts"),
            "http://server.com/live/1.ts"
        );
        assert_eq!(
            StalkerEngine::clean_cmd("auto http://server.com/live/2.m3u8"),
            "http://server.com/live/2.m3u8"
        );
        assert_eq!(
            StalkerEngine::clean_cmd("http://server.com/live/3.ts"),
            "http://server.com/live/3.ts"
        );
    }
}
