pub fn clean_playback_url(raw_url: &str) -> String {
    let mut trimmed = raw_url.trim();
    if let Some(stripped) = trimmed.strip_prefix("ffmpeg ") {
        trimmed = stripped.trim();
    } else if let Some(stripped) = trimmed.strip_prefix("auto ") {
        trimmed = stripped.trim();
    }
    trimmed.to_string()
}
