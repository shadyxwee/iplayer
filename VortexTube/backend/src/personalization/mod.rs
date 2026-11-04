use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScoredItem {
    pub id: String,
    pub name: String,
    pub score: f64,
    pub is_favorite: bool,
    pub in_loved_category: bool,
    pub play_count: i64,
}

pub fn calculate_personalization_score(
    is_favorite: bool,
    in_loved_category: bool,
    play_count: i64,
    has_watch_progress: bool,
    rating: f64,
) -> f64 {
    let mut score = 0.0;
    if is_favorite {
        score += 500.0;
    }
    if in_loved_category {
        score += 300.0;
    }
    if has_watch_progress {
        score += 150.0;
    }
    score += (play_count as f64) * 20.0;
    score += rating * 10.0;
    score
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_personalization_score() {
        let score_fav = calculate_personalization_score(true, true, 2, false, 8.5);
        let score_normal = calculate_personalization_score(false, false, 0, false, 5.0);
        assert!(score_fav > score_normal);
        assert_eq!(score_fav, 500.0 + 300.0 + 40.0 + 85.0);
    }
}
