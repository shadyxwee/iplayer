use anyhow::{Context, Result};
use md5::Digest;
use regex::Regex;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, COOKIE, REFERER, USER_AGENT};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use sha1::Sha1;
use sha2::Sha256;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::Mutex;
use url::Url;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StalkerConfig {
    pub portal_url: String,
    pub mac_address: String,
    pub device_id: Option<String>,
    pub device_id2: Option<String>,
    pub signature: Option<String>,
    pub serial_number: Option<String>,
}

impl Default for StalkerConfig {
    fn default() -> Self {
        Self {
            portal_url: String::new(),
            mac_address: "00:1A:79:00:00:00".to_string(),
            device_id: None,
            device_id2: None,
            signature: None,
            serial_number: None,
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

pub struct StalkerEngine {
    client: Client,
    pub config: StalkerConfig,
    base_url: String,
    candidate_endpoints: Vec<String>,
    active_endpoint: Arc<Mutex<Option<String>>>,
    token: Arc<Mutex<Option<String>>>,
    token_timestamp: Arc<Mutex<Option<Instant>>>,
    pub mac_clean: String,
    pub mac_formatted: String,
}

impl StalkerEngine {
    pub const USER_AGENT_VAL: &'static str =
        "Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 4 rev: 1812  Safari/533.3";

    pub fn new(mut config: StalkerConfig) -> Self {
        // Sanitize MAC
        let clean: String = config
            .mac_address
            .chars()
            .filter(|c| c.is_ascii_hexdigit())
            .collect();
        let clean_upper = clean.to_uppercase();

        let mac_formatted = if clean_upper.len() == 12 {
            clean_upper
                .as_bytes()
                .chunks(2)
                .map(|chunk| std::str::from_utf8(chunk).unwrap())
                .collect::<Vec<_>>()
                .join(":")
        } else {
            config.mac_address.to_uppercase()
        };

        config.mac_address = mac_formatted.clone();

        let (base_url, candidates) = Self::normalize_url(&config.portal_url);

        // Client with strict timeout to prevent indefinite 5-minute socket hangs
        let client = Client::builder()
            .timeout(Duration::from_secs(8))
            .connect_timeout(Duration::from_secs(5))
            .cookie_store(true)
            .danger_accept_invalid_certs(true)
            .build()
            .unwrap_or_default();

        Self {
            client,
            config,
            base_url,
            candidate_endpoints: candidates,
            active_endpoint: Arc::new(Mutex::new(None)),
            token: Arc::new(Mutex::new(None)),
            token_timestamp: Arc::new(Mutex::new(None)),
            mac_clean: clean_upper,
            mac_formatted,
        }
    }

    /// Strips trailing portal suffixes down to clean base URL
    pub fn normalize_url(raw_url: &str) -> (String, Vec<String>) {
        let mut url_str = raw_url.trim().to_string();
        if !url_str.starts_with("http://") && !url_str.starts_with("https://") {
            url_str = format!("http://{}", url_str);
        }

        let parsed = Url::parse(&url_str).unwrap_or_else(|_| Url::parse("http://localhost").unwrap());
        let mut path = parsed.path().trim_end_matches('/').to_string();

        let suffixes = [
            "/c/index.html", "/c/index.php", "/index.html", "/index.php",
            "/stalker_portal/server/load.php", "/stalker_portal/c/portal.php",
            "/stalker_portal/c", "/stalker_portal",
            "/c/portal.php", "/server/load.php", "/portal.php", "/load.php", "/c",
        ];

        let mut changed = true;
        while changed {
            changed = false;
            for s in suffixes {
                if path.ends_with(s) {
                    path = path[..path.len() - s.len()].trim_end_matches('/').to_string();
                    changed = true;
                    break;
                }
            }
        }

        let port_str = parsed.port().map(|p| format!(":{}", p)).unwrap_or_default();
        let base = format!("{}://{}{}{}", parsed.scheme(), parsed.host_str().unwrap_or(""), port_str, path);

        let mut candidates = Vec::new();
        let clean_raw = raw_url.trim().trim_end_matches('/');
        if clean_raw.ends_with(".php") {
            candidates.push(clean_raw.to_string());
        }

        candidates.extend(vec![
            format!("{}/portal.php", base),
            format!("{}/c/portal.php", base),
            format!("{}/stalker_portal/server/load.php", base),
            format!("{}/server/load.php", base),
            format!("{}/stalker_portal/c/portal.php", base),
        ]);

        let mut seen = std::collections::HashSet::new();
        let mut dedup = Vec::new();
        for c in candidates {
            if seen.insert(c.clone()) {
                dedup.push(c);
            }
        }

        (base, dedup)
    }

    /// Derives cryptographic signatures when not explicitly provided
    fn compute_signatures(&self) -> (String, String, String) {
        let mac = &self.mac_formatted;

        let mut adid_hasher = Sha1::new();
        adid_hasher.update(mac.as_bytes());
        let adid = format!("{:x}", adid_hasher.finalize());

        let mut md5_hasher = md5::Md5::new();
        md5_hasher.update(mac.as_bytes());
        let sn_hex = format!("{:X}", md5_hasher.finalize());
        let sncut = if sn_hex.len() >= 13 { sn_hex[..13].to_string() } else { sn_hex };

        let mut dev_hasher = Sha256::new();
        dev_hasher.update(mac.as_bytes());
        let devenc = format!("{:X}", dev_hasher.finalize());

        let final_sn = match &self.config.serial_number {
            Some(s) if !s.trim().is_empty() && !s.contains("DEFAULT") => s.clone(),
            _ => sncut,
        };

        let final_dev = match &self.config.device_id {
            Some(d) if !d.trim().is_empty() && !d.contains("DEFAULT") => d.clone(),
            _ => devenc,
        };

        (adid, final_sn, final_dev)
    }

    fn build_cookie_string(&self, token: &str) -> String {
        let (adid, sn, dev) = self.compute_signatures();
        format!(
            "mac={}; stb_lang=en; timezone=Asia%20Shanghai; token={}; adid={}; debug=1; device_id2={}; device_id={}; hw_version=1.7-BD-00; sn={}",
            self.mac_formatted, token, adid, dev, dev, sn
        )
    }

    pub fn clean_cmd(cmd: &str) -> String {
        let mut s = cmd.trim();
        if s.starts_with("ffmpeg ") {
            s = &s[7..];
        } else if s.starts_with("auto ") {
            s = &s[5..];
        }
        s.trim().to_string()
    }

    pub fn candidate_endpoints(base_url: &str) -> Vec<String> {
        let (_, candidates) = Self::normalize_url(base_url);
        candidates
    }

    pub async fn handshake(&self) -> Result<String> {
        // Reuse valid cached token if younger than 9 minutes (540s)
        {
            let tok_guard = self.token.lock().await;
            let time_guard = self.token_timestamp.lock().await;
            if let (Some(tok), Some(inst)) = (tok_guard.as_ref(), time_guard.as_ref()) {
                if inst.elapsed() < Duration::from_secs(540) {
                    return Ok(tok.clone());
                }
            }
        }

        let mut candidates = Vec::new();
        {
            let active = self.active_endpoint.lock().await;
            if let Some(ep) = active.as_ref() {
                candidates.push(ep.clone());
            }
        }
        for c in &self.candidate_endpoints {
            if !candidates.contains(c) {
                candidates.push(c.clone());
            }
        }

        for endpoint in &candidates {
            let is_load_php = endpoint.contains("load.php");
            let handshake_get = if is_load_php {
                format!("{}?type=stb&action=handshake&prehash=false&JsHttpRequest=1-xml", endpoint)
            } else {
                format!("{}?type=stb&action=handshake&token=&JsHttpRequest=1-xml", endpoint)
            };

            let cookie_str = self.build_cookie_string("");

            // 1. Try GET Handshake
            let resp = self
                .client
                .get(&handshake_get)
                .header(USER_AGENT, Self::USER_AGENT_VAL)
                .header(REFERER, format!("{}/c/", self.base_url))
                .header(COOKIE, &cookie_str)
                .send()
                .await;

            let mut token_found = None;
            if let Ok(res) = resp {
                if res.status().is_success() {
                    let text = res.text().await.unwrap_or_default();
                    token_found = Self::extract_token(&text);
                }
            }

            // 2. Try POST fallback if GET fails or returns invalid response
            if token_found.is_none() {
                let (_, sn, dev) = self.compute_signatures();
                let mut params = HashMap::new();
                params.insert("type", "stb");
                params.insert("action", "handshake");
                params.insert("JsHttpRequest", "1-xml");
                params.insert("sn", &sn);
                params.insert("id1", &dev);

                let post_resp = self
                    .client
                    .post(endpoint)
                    .header(USER_AGENT, Self::USER_AGENT_VAL)
                    .header(REFERER, format!("{}/c/", self.base_url))
                    .header(COOKIE, &cookie_str)
                    .form(&params)
                    .send()
                    .await;

                if let Ok(pres) = post_resp {
                    if pres.status().is_success() {
                        let text = pres.text().await.unwrap_or_default();
                        token_found = Self::extract_token(&text);
                    }
                }
            }

            if let Some(tok) = token_found {
                // Session Initialization: Call get_modules to activate token
                let mod_url = format!("{}?type=stb&action=get_modules&JsHttpRequest=1-xml", endpoint);
                let _ = self
                    .client
                    .get(&mod_url)
                    .header(USER_AGENT, Self::USER_AGENT_VAL)
                    .header(REFERER, format!("{}/c/", self.base_url))
                    .header(AUTHORIZATION, format!("Bearer {}", tok))
                    .header(COOKIE, self.build_cookie_string(&tok))
                    .send()
                    .await;

                *self.token.lock().await = Some(tok.clone());
                *self.token_timestamp.lock().await = Some(Instant::now());
                *self.active_endpoint.lock().await = Some(endpoint.clone());

                return Ok(tok);
            }
        }

        anyhow::bail!("Stalker handshake failed on all candidate endpoints for {}", self.config.portal_url);
    }

    fn extract_token(body: &str) -> Option<String> {
        let re1 = Regex::new(r#""token"\s*:\s*"([^"]+)""#).ok()?;
        if let Some(caps) = re1.captures(body) {
            let t = caps[1].trim().to_string();
            if !t.is_empty() && !["UDONTHAVEACCESS", "INVALID", "ERROR", "FAILED"].contains(&t.to_uppercase().as_str()) {
                return Some(t);
            }
        }
        let re2 = Regex::new(r#"token":"([^"]+)"#).ok()?;
        if let Some(caps) = re2.captures(body) {
            let t = caps[1].trim().to_string();
            if !t.is_empty() && !["UDONTHAVEACCESS", "INVALID", "ERROR", "FAILED"].contains(&t.to_uppercase().as_str()) {
                return Some(t);
            }
        }
        None
    }

    pub async fn check_mac(&self) -> MacCheckResult {
        let tok = match self.handshake().await {
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

        let endpoint = {
            let ep = self.active_endpoint.lock().await;
            ep.clone()
        };

        MacCheckResult {
            is_working: true,
            token: Some(tok),
            endpoint,
            expiry_date: None,
            status: Some("Active".to_string()),
            error_message: None,
        }
    }

    pub async fn get_categories(&self, media_type: &str) -> Result<Vec<StalkerCategory>> {
        let tok = self.handshake().await?;
        let endpoint = {
            let ep = self.active_endpoint.lock().await;
            ep.clone().unwrap_or_else(|| self.candidate_endpoints[0].clone())
        };

        let action = if media_type == "itv" {
            "get_genres"
        } else {
            "get_categories"
        };

        let url = format!("{}?type={}&action={}&JsHttpRequest=1-xml", endpoint, media_type, action);
        let resp = self
            .client
            .get(&url)
            .header(USER_AGENT, Self::USER_AGENT_VAL)
            .header(REFERER, format!("{}/c/", self.base_url))
            .header(AUTHORIZATION, format!("Bearer {}", tok))
            .header(COOKIE, self.build_cookie_string(&tok))
            .send()
            .await?;

        let body = resp.text().await?;
        let mut categories = Vec::new();

        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&body) {
            let mut list_opt = val.get("js").and_then(|j| j.as_array());
            if list_opt.is_none() {
                list_opt = val.pointer("/js/data").and_then(|j| j.as_array());
            }

            if let Some(list) = list_opt {
                for item in list {
                    let id = item.get("id").and_then(|v| v.as_str().map(|s| s.to_string()).or_else(|| v.as_i64().map(|n| n.to_string()))).unwrap_or_default();
                    let title = item.get("title").or_else(|| item.get("category_name")).and_then(|v| v.as_str()).unwrap_or("Unknown").to_string();
                    let alias = item.get("alias").and_then(|v| v.as_str()).map(|s| s.to_string());
                    if !id.is_empty() {
                        categories.push(StalkerCategory { id, title, alias });
                    }
                }
            } else if let Some(map) = val.get("js").and_then(|j| j.as_object()) {
                for (k, v) in map {
                    if let Some(obj) = v.as_object() {
                        let id = obj.get("id").and_then(|i| i.as_str().map(|s| s.to_string()).or_else(|| i.as_i64().map(|n| n.to_string()))).unwrap_or_else(|| k.clone());
                        let title = obj.get("title").or_else(|| obj.get("category_name")).and_then(|i| i.as_str()).unwrap_or("Unknown").to_string();
                        let alias = obj.get("alias").and_then(|i| i.as_str()).map(|s| s.to_string());
                        categories.push(StalkerCategory { id, title, alias });
                    } else if let Some(str_val) = v.as_str() {
                        categories.push(StalkerCategory { id: k.clone(), title: str_val.to_string(), alias: None });
                    }
                }
            }
        }

        Ok(categories)
    }

    pub async fn get_ordered_list(
        &self,
        media_type: &str,
        category_id: Option<&str>,
        page: u32,
    ) -> Result<Vec<StalkerItem>> {
        let tok = self.handshake().await?;
        let endpoint = {
            let ep = self.active_endpoint.lock().await;
            ep.clone().unwrap_or_else(|| self.candidate_endpoints[0].clone())
        };

        let p_str = page.to_string();
        let genre_key = if media_type == "itv" { "genre" } else { "category" };
        let mut url = format!(
            "{}?type={}&action=get_ordered_list&p={}&JsHttpRequest=1-xml",
            endpoint, media_type, p_str
        );
        if let Some(cat) = category_id {
            if !cat.is_empty() && cat != "0" && cat != "*" {
                url.push_str(&format!("&{}={}", genre_key, cat));
            }
        }

        let resp = self
            .client
            .get(&url)
            .header(USER_AGENT, Self::USER_AGENT_VAL)
            .header(REFERER, format!("{}/c/", self.base_url))
            .header(AUTHORIZATION, format!("Bearer {}", tok))
            .header(COOKIE, self.build_cookie_string(&tok))
            .send()
            .await?;

        let body = resp.text().await?;
        let mut items = Vec::new();

        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&body) {
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
        }

        Ok(items)
    }

    pub async fn get_create_link(&self, cmd: &str, media_type: Option<&str>) -> Result<StreamDetails> {
        let mut clean_cmd = cmd.trim();
        if clean_cmd.starts_with("ffmpeg ") {
            clean_cmd = &clean_cmd[7..];
        }

        // Direct stream if not a /ch/..._ indirection
        if !clean_cmd.contains("/ch/") || !clean_cmd.ends_with('_') {
            let mut req_headers = HashMap::new();
            req_headers.insert("User-Agent".to_string(), Self::USER_AGENT_VAL.to_string());
            req_headers.insert("Referer".to_string(), format!("{}/c/", self.base_url));
            req_headers.insert("Cookie".to_string(), self.build_cookie_string(""));

            return Ok(StreamDetails {
                stream_url: clean_cmd.to_string(),
                headers: req_headers,
            });
        }

        let tok = self.handshake().await?;
        let endpoint = {
            let ep_guard = self.active_endpoint.lock().await;
            ep_guard.clone().unwrap_or_else(|| self.candidate_endpoints[0].clone())
        };

        let encoded_cmd: String = url::form_urlencoded::byte_serialize(clean_cmd.as_bytes()).collect();
        let url = format!(
            "{}?type=itv&action=create_link&cmd={}&JsHttpRequest=1-xml",
            endpoint, encoded_cmd
        );

        let resp = self
            .client
            .get(&url)
            .header(USER_AGENT, Self::USER_AGENT_VAL)
            .header(REFERER, format!("{}/c/", self.base_url))
            .header(AUTHORIZATION, format!("Bearer {}", tok))
            .header(COOKIE, self.build_cookie_string(&tok))
            .send()
            .await
            .context("Failed to request Stalker create_link")?;

        let body = resp.text().await?;
        let mut stream_url = clean_cmd.to_string();

        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&body) {
            if let Some(cmd_val) = val.pointer("/js/cmd").and_then(|v| v.as_str()) {
                let mut resolved = cmd_val.trim();
                if resolved.starts_with("ffmpeg ") {
                    resolved = &resolved[7..];
                }
                stream_url = resolved.to_string();
            }
        }

        let mut req_headers = HashMap::new();
        req_headers.insert("User-Agent".to_string(), Self::USER_AGENT_VAL.to_string());
        req_headers.insert("Referer".to_string(), format!("{}/c/", self.base_url));
        req_headers.insert("Cookie".to_string(), self.build_cookie_string(&tok));

        Ok(StreamDetails {
            stream_url,
            headers: req_headers,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_url() {
        let (base, _) = StalkerEngine::normalize_url("http://example.com/c/");
        assert_eq!(base, "http://example.com");

        let (base2, _) = StalkerEngine::normalize_url("http://example.com:8080/portal/c/");
        assert_eq!(base2, "http://example.com:8080/portal");
    }

    #[test]
    fn test_candidate_endpoints_order() {
        let candidates = StalkerEngine::candidate_endpoints("http://portal.example.com/c/");
        assert!(candidates.len() >= 5);
        assert_eq!(candidates[0], "http://portal.example.com/portal.php");
        assert_eq!(candidates[1], "http://portal.example.com/c/portal.php");
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
    }
}
