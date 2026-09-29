use anyhow::{Context, Result};
use reqwest::header::{HeaderMap, HeaderValue, COOKIE, REFERER, USER_AGENT};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;

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

#[derive(Debug, Deserialize)]
struct HandshakeResult {
    token: Option<String>,
}

#[derive(Debug, Deserialize)]
struct HandshakeResponse {
    js: Option<HandshakeResult>,
}

pub struct StalkerEngine {
    client: Client,
    config: StalkerConfig,
    token: Arc<Mutex<Option<String>>>,
    cookies: Arc<Mutex<String>>,
}

impl StalkerEngine {
    pub fn new(config: StalkerConfig) -> Self {
        let client = Client::builder()
            .cookie_store(true)
            .build()
            .unwrap_or_default();

        Self {
            client,
            config,
            token: Arc::new(Mutex::new(None)),
            cookies: Arc::new(Mutex::new(String::new())),
        }
    }

    pub async fn handshake(&self) -> Result<String> {
        let base_url = self.config.portal_url.trim_end_matches('/');
        let url = format!("{}/server/load.php?type=stb&action=handshake", base_url);

        let mut headers = HeaderMap::new();
        headers.insert(
            USER_AGENT,
            HeaderValue::from_static("Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3"),
        );
        headers.insert(REFERER, HeaderValue::from_str(&format!("{}/c/", base_url))?);
        headers.insert(
            COOKIE,
            HeaderValue::from_str(&format!("mac={}; stb_lang=en; timezone=Europe/London", self.config.mac_address))?,
        );

        let resp = self
            .client
            .get(&url)
            .headers(headers)
            .send()
            .await
            .context("Failed to send Stalker handshake request")?;

        let res_text = resp.text().await.context("Failed to read Stalker handshake response")?;

        let token = if let Ok(parsed) = serde_json::from_str::<HandshakeResponse>(&res_text) {
            parsed.js.and_then(|j| j.token)
        } else {
            None
        };

        let token_str = match token {
            Some(t) => t,
            None => "SESSION_TOKEN_STALKER".to_string(),
        };

        *self.token.lock().await = Some(token_str.clone());
        *self.cookies.lock().await = format!("mac={}; stb_lang=en; timezone=Europe/London", self.config.mac_address);

        Ok(token_str)
    }

    pub async fn get_create_link(&self, cmd: &str) -> Result<StreamDetails> {
        let mut current_token = self.token.lock().await.clone();
        if current_token.is_none() {
            let new_token = self.handshake().await?;
            current_token = Some(new_token);
        }

        let token_val = current_token.unwrap();
        let base_url = self.config.portal_url.trim_end_matches('/');
        let url = format!(
            "{}/server/load.php?type=itv&action=create_link&cmd={}&JsHttpRequest=1-xml",
            base_url, cmd
        );

        let mut headers = HeaderMap::new();
        headers.insert(
            USER_AGENT,
            HeaderValue::from_static("Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3"),
        );
        headers.insert(
            COOKIE,
            HeaderValue::from_str(&format!("mac={}; stb_lang=en; timezone=Europe/London", self.config.mac_address))?,
        );
        headers.insert(
            "Authorization",
            HeaderValue::from_str(&format!("Bearer {}", token_val))?,
        );

        let resp = self
            .client
            .get(&url)
            .headers(headers)
            .send()
            .await
            .context("Failed to request Stalker create_link")?;

        let status = resp.status();
        if status.as_u16() == 401 {
            self.handshake().await?;
            return Box::pin(self.get_create_link(cmd)).await;
        }

        let body = resp.text().await?;

        let mut stream_url = cmd.to_string();
        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&body) {
            if let Some(cmd_val) = val.pointer("/js/cmd").and_then(|v| v.as_str()) {
                stream_url = cmd_val.replace("ffmpeg ", "").trim().to_string();
            }
        }

        let mut req_headers = HashMap::new();
        req_headers.insert("User-Agent".to_string(), "Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3".to_string());
        req_headers.insert("Cookie".to_string(), format!("mac={}; stb_lang=en; timezone=Europe/London", self.config.mac_address));
        req_headers.insert("Referer".to_string(), format!("{}/c/", base_url));

        Ok(StreamDetails {
            stream_url,
            headers: req_headers,
        })
    }
}
