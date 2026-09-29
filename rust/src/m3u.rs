use crate::db::ChannelRecord;
use std::io::BufRead;

pub struct M3uParser;

impl M3uParser {
    pub fn parse_m3u_content(content: &str, playlist_id: i64) -> Vec<ChannelRecord> {
        let mut channels = Vec::new();
        let mut current_extinf: Option<String> = None;
        let mut user_agent: Option<String> = None;
        let mut referer: Option<String> = None;

        for line in content.lines() {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }

            if line.starts_with("#EXTINF:") {
                current_extinf = Some(line.to_string());
            } else if line.starts_with("#EXTVLCOPT:http-user-agent=") {
                user_agent = Some(line.trim_start_matches("#EXTVLCOPT:http-user-agent=").to_string());
            } else if line.starts_with("#EXTVLCOPT:http-referrer=") {
                referer = Some(line.trim_start_matches("#EXTVLCOPT:http-referrer=").to_string());
            } else if !line.starts_with('#') {
                if let Some(extinf) = current_extinf.take() {
                    let channel = Self::parse_extinf_line(&extinf, line, playlist_id, user_agent.take(), referer.take());
                    channels.push(channel);
                }
            }
        }

        channels
    }

    pub fn parse_m3u_reader<R: BufRead>(reader: R, playlist_id: i64) -> Vec<ChannelRecord> {
        let mut channels = Vec::new();
        let mut current_extinf: Option<String> = None;
        let mut user_agent: Option<String> = None;
        let mut referer: Option<String> = None;

        for line_res in reader.lines() {
            let line = match line_res {
                Ok(l) => l,
                Err(_) => continue,
            };
            let line = line.trim();
            if line.is_empty() {
                continue;
            }

            if line.starts_with("#EXTINF:") {
                current_extinf = Some(line.to_string());
            } else if line.starts_with("#EXTVLCOPT:http-user-agent=") {
                user_agent = Some(line.trim_start_matches("#EXTVLCOPT:http-user-agent=").to_string());
            } else if line.starts_with("#EXTVLCOPT:http-referrer=") {
                referer = Some(line.trim_start_matches("#EXTVLCOPT:http-referrer=").to_string());
            } else if !line.starts_with('#') {
                if let Some(extinf) = current_extinf.take() {
                    let channel = Self::parse_extinf_line(&extinf, line, playlist_id, user_agent.take(), referer.take());
                    channels.push(channel);
                }
            }
        }

        channels
    }

    fn parse_extinf_line(
        extinf: &str,
        stream_url: &str,
        playlist_id: i64,
        user_agent: Option<String>,
        referer: Option<String>,
    ) -> ChannelRecord {
        let mut logo_url = None;
        let mut group_title = None;
        let mut tvg_id = None;
        let mut tvg_name = None;

        let name = match extinf.rfind(',') {
            Some(idx) => extinf[idx + 1..].trim().to_string(),
            None => "Channel".to_string(),
        };

        let attributes_part = if let Some(comma_idx) = extinf.rfind(',') {
            &extinf[..comma_idx]
        } else {
            extinf
        };

        for attr in ["tvg-logo", "group-title", "tvg-id", "tvg-name"] {
            if let Some(val) = Self::extract_attribute_value(attributes_part, attr) {
                match attr {
                    "tvg-logo" => logo_url = Some(val),
                    "group-title" => group_title = Some(val),
                    "tvg-id" => tvg_id = Some(val),
                    "tvg-name" => tvg_name = Some(val),
                    _ => {}
                }
            }
        }

        let content_type = if stream_url.contains("/movie/") || stream_url.contains(".mkv") || stream_url.contains(".mp4") {
            "movie".to_string()
        } else if stream_url.contains("/series/") {
            "series".to_string()
        } else {
            "live".to_string()
        };

        ChannelRecord {
            id: None,
            playlist_id,
            name,
            stream_url: stream_url.to_string(),
            logo_url,
            group_title,
            tvg_id,
            tvg_name,
            content_type,
            is_favorite: false,
            user_agent,
            referer,
        }
    }

    fn extract_attribute_value(input: &str, key: &str) -> Option<String> {
        let pattern = format!("{}=\"", key);
        if let Some(start) = input.find(&pattern) {
            let value_start = start + pattern.len();
            if let Some(end) = input[value_start..].find('"') {
                return Some(input[value_start..value_start + end].to_string());
            }
        }

        let pattern_sq = format!("{}='", key);
        if let Some(start) = input.find(&pattern_sq) {
            let value_start = start + pattern_sq.len();
            if let Some(end) = input[value_start..].find('\'') {
                return Some(input[value_start..value_start + end].to_string());
            }
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_m3u_parsing() {
        let content = r#"#EXTM3U
#EXTINF:-1 tvg-id="cnn.us" tvg-logo="http://logo.png" group-title="News",CNN HD
http://stream.m3u8/cnn
"#;
        let channels = M3uParser::parse_m3u_content(content, 1);
        assert_eq!(channels.len(), 1);
        assert_eq!(channels[0].name, "CNN HD");
        assert_eq!(channels[0].group_title.as_deref(), Some("News"));
        assert_eq!(channels[0].tvg_id.as_deref(), Some("cnn.us"));
    }
}
