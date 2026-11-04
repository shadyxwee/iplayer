use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use crate::sources::m3u::parse_m3u;
use crate::sources::stalker::{clean_cmd, get_candidate_endpoints, normalize_portal_url};
use crate::personalization::calculate_personalization_score;

#[no_mangle]
pub extern "C" fn vt_parse_m3u(m3u_text: *const c_char) -> *mut c_char {
    if m3u_text.is_null() {
        return CString::new("[]").unwrap().into_raw();
    }
    let c_str = unsafe { CStr::from_ptr(m3u_text) };
    let text = c_str.to_str().unwrap_or("");
    let channels = parse_m3u(text);
    let json = serde_json::to_string(&channels).unwrap_or_else(|_| "[]".to_string());
    CString::new(json).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn vt_normalize_stalker_url(url: *const c_char) -> *mut c_char {
    if url.is_null() {
        return CString::new("").unwrap().into_raw();
    }
    let c_str = unsafe { CStr::from_ptr(url) };
    let text = c_str.to_str().unwrap_or("");
    let normalized = normalize_portal_url(text);
    CString::new(normalized).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn vt_get_stalker_candidates(url: *const c_char) -> *mut c_char {
    if url.is_null() {
        return CString::new("[]").unwrap().into_raw();
    }
    let c_str = unsafe { CStr::from_ptr(url) };
    let text = c_str.to_str().unwrap_or("");
    let candidates = get_candidate_endpoints(text);
    let json = serde_json::to_string(&candidates).unwrap_or_else(|_| "[]".to_string());
    CString::new(json).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn vt_clean_cmd(cmd: *const c_char) -> *mut c_char {
    if cmd.is_null() {
        return CString::new("").unwrap().into_raw();
    }
    let c_str = unsafe { CStr::from_ptr(cmd) };
    let text = c_str.to_str().unwrap_or("");
    let cleaned = clean_cmd(text);
    CString::new(cleaned).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn vt_calculate_score(
    is_favorite: bool,
    in_loved_category: bool,
    play_count: i64,
    has_watch_progress: bool,
    rating: f64,
) -> f64 {
    calculate_personalization_score(is_favorite, in_loved_category, play_count, has_watch_progress, rating)
}

#[no_mangle]
pub extern "C" fn vt_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}
