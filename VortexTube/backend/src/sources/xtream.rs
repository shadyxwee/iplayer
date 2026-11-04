use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XtreamCategory {
    pub category_id: String,
    pub category_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XtreamStream {
    pub num: Option<i64>,
    pub name: String,
    pub stream_type: Option<String>,
    pub stream_id: Option<i64>,
    pub stream_icon: Option<String>,
    pub category_id: Option<String>,
    pub rating: Option<f64>,
}

pub fn build_stream_url(base: &str, user: &str, pass: &str, stream_id: i64, ext: &str) -> String {
    let clean_base = base.trim_end_matches('/');
    format!("{}/live/{}/{}/{}.{}", clean_base, user, pass, stream_id, ext)
}
