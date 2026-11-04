use regex::Regex;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelItem {
    pub name: String,
    pub url: String,
    pub logo: Option<String>,
    pub group: Option<String>,
    pub content_type: String, // "live", "movie", "series"
    pub tvg_id: Option<String>,
    pub rating: Option<f64>,
}

pub fn parse_m3u(content: &str) -> Vec<ChannelItem> {
    let mut channels = Vec::new();
    let mut current_name: Option<String> = None;
    let mut current_logo: Option<String> = None;
    let mut current_group: Option<String> = None;
    let mut current_tvg_id: Option<String> = None;

    let re_tvg_name = Regex::new(r#"tvg-name=["']?([^"'\r\n,]+)["']?"#).unwrap();
    let re_tvg_logo = Regex::new(r#"tvg-logo=["']?([^"'\r\n\s]+)["']?"#).unwrap();
    let re_group = Regex::new(r#"group-title=["']?([^"'\r\n,]+)["']?"#).unwrap();
    let re_tvg_id = Regex::new(r#"tvg-id=["']?([^"'\r\n,]+)["']?"#).unwrap();

    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        if trimmed.starts_with("#EXTINF:") {
            current_logo = re_tvg_logo.captures(trimmed).map(|c| c[1].to_string());
            current_group = re_group.captures(trimmed).map(|c| c[1].to_string());
            current_tvg_id = re_tvg_id.captures(trimmed).map(|c| c[1].to_string());

            if let Some(pos) = trimmed.rfind(',') {
                let name = trimmed[pos + 1..].trim().to_string();
                if !name.is_empty() {
                    current_name = Some(name);
                }
            }

            if current_name.is_none() {
                if let Some(caps) = re_tvg_name.captures(trimmed) {
                    current_name = Some(caps[1].to_string());
                }
            }
        } else if !trimmed.starts_with('#') {
            if let Some(name) = current_name.take() {
                let url = trimmed.to_string();
                let lower_url = url.to_lowercase();
                let lower_group = current_group.as_deref().unwrap_or("").to_lowercase();

                let content_type = if lower_group.contains("series")
                    || lower_url.contains("/series/")
                    || lower_url.contains(".s01")
                {
                    "series"
                } else if lower_group.contains("movie")
                    || lower_group.contains("vod")
                    || lower_url.contains("/movie/")
                    || lower_url.ends_with(".mp4")
                    || lower_url.ends_with(".mkv")
                {
                    "movie"
                } else {
                    "live"
                };

                channels.push(ChannelItem {
                    name,
                    url,
                    logo: current_logo.take(),
                    group: current_group.take(),
                    content_type: content_type.to_string(),
                    tvg_id: current_tvg_id.take(),
                    rating: None,
                });
            }
        }
    }

    channels
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_m3u_channels() {
        let raw = r#"
#EXTM3U
#EXTINF:-1 tvg-id="cnn" tvg-name="CNN HD" tvg-logo="http://logo.png" group-title="News",CNN HD
http://stream.m3u8
#EXTINF:-1 tvg-id="batman" group-title="Movies",Batman Movie
http://stream.mp4
"#;
        let items = parse_m3u(raw);
        assert_eq!(items.len(), 2);
        assert_eq!(items[0].name, "CNN HD");
        assert_eq!(items[0].content_type, "live");
        assert_eq!(items[1].name, "Batman Movie");
        assert_eq!(items[1].content_type, "movie");
    }
}
