use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EpgProgram {
    pub channel_id: String,
    pub title: String,
    pub description: Option<String>,
    pub start_time: i64,
    pub end_time: i64,
}

pub fn filter_current_programs(programs: &[EpgProgram], current_epoch: i64) -> Vec<EpgProgram> {
    programs
        .iter()
        .filter(|p| p.start_time <= current_epoch && current_epoch < p.end_time)
        .cloned()
        .collect()
}
