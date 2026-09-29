use crate::db::EpgProgramRecord;
use anyhow::{Context, Result};
use flate2::read::GzDecoder;
use quick_xml::events::Event;
use quick_xml::reader::Reader;
use std::io::Read;

pub struct EpgParser;

impl EpgParser {
    pub fn parse_xmltv_gz(gz_bytes: &[u8]) -> Result<Vec<EpgProgramRecord>> {
        let mut gz = GzDecoder::new(gz_bytes);
        let mut xml_string = String::new();
        gz.read_to_string(&mut xml_string)
            .context("Failed to decompress XMLTV gz data")?;
        Self::parse_xmltv(&xml_string)
    }

    pub fn parse_xmltv(xml_content: &str) -> Result<Vec<EpgProgramRecord>> {
        let mut reader = Reader::from_str(xml_content);
        reader.config_mut().trim_text(true);

        let mut programs = Vec::new();
        let mut buf = Vec::new();

        let mut current_channel_id = String::new();
        let mut current_start = 0i64;
        let mut current_end = 0i64;
        let mut current_title = String::new();
        let mut current_desc = String::new();
        let mut current_category = String::new();
        let mut current_icon = String::new();

        let mut in_title = false;
        let mut in_desc = false;
        let mut in_category = false;

        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(e)) => match e.name().as_ref() {
                    b"programme" => {
                        current_channel_id.clear();
                        current_title.clear();
                        current_desc.clear();
                        current_category.clear();
                        current_icon.clear();

                        for attr in e.attributes().flatten() {
                            match attr.key.as_ref() {
                                b"channel" => {
                                    current_channel_id =
                                        String::from_utf8_lossy(&attr.value).to_string();
                                }
                                b"start" => {
                                    let start_str = String::from_utf8_lossy(&attr.value);
                                    current_start = Self::parse_xmltv_date(&start_str);
                                }
                                b"stop" => {
                                    let stop_str = String::from_utf8_lossy(&attr.value);
                                    current_end = Self::parse_xmltv_date(&stop_str);
                                }
                                _ => {}
                            }
                        }
                    }
                    b"title" => in_title = true,
                    b"desc" => in_desc = true,
                    b"category" => in_category = true,
                    b"icon" => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"src" {
                                current_icon = String::from_utf8_lossy(&attr.value).to_string();
                            }
                        }
                    }
                    _ => {}
                },
                Ok(Event::Text(e)) => {
                    let text = e.unescape().unwrap_or_default().to_string();
                    if in_title {
                        current_title.push_str(&text);
                    } else if in_desc {
                        current_desc.push_str(&text);
                    } else if in_category {
                        current_category.push_str(&text);
                    }
                }
                Ok(Event::End(e)) => match e.name().as_ref() {
                    b"programme" => {
                        if !current_channel_id.is_empty() && !current_title.is_empty() {
                            programs.push(EpgProgramRecord {
                                id: None,
                                channel_tvg_id: current_channel_id.clone(),
                                title: current_title.clone(),
                                description: if current_desc.is_empty() {
                                    None
                                } else {
                                    Some(current_desc.clone())
                                },
                                start_time: current_start,
                                end_time: current_end,
                                category: if current_category.is_empty() {
                                    None
                                } else {
                                    Some(current_category.clone())
                                },
                                icon_url: if current_icon.is_empty() {
                                    None
                                } else {
                                    Some(current_icon.clone())
                                },
                            });
                        }
                    }
                    b"title" => in_title = false,
                    b"desc" => in_desc = false,
                    b"category" => in_category = false,
                    _ => {}
                },
                Ok(Event::Eof) => break,
                Err(_) => break,
                _ => {}
            }
            buf.clear();
        }

        Ok(programs)
    }

    fn parse_xmltv_date(date_str: &str) -> i64 {
        let clean_str: String = date_str.chars().filter(|c| c.is_ascii_digit()).collect();
        if clean_str.len() >= 14 {
            let year: i32 = clean_str[0..4].parse().unwrap_or(1970);
            let month: u32 = clean_str[4..6].parse().unwrap_or(1);
            let day: u32 = clean_str[6..8].parse().unwrap_or(1);
            let hour: u32 = clean_str[8..10].parse().unwrap_or(0);
            let min: u32 = clean_str[10..12].parse().unwrap_or(0);
            let sec: u32 = clean_str[12..14].parse().unwrap_or(0);

            let days_since_epoch = (year - 1970) as i64 * 365 + (month as i64 * 30) + day as i64;
            let seconds = days_since_epoch * 86400 + (hour as i64 * 3600) + (min as i64 * 60) + sec as i64;
            seconds
        } else {
            0
        }
    }
}
