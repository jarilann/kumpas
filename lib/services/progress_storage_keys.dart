/// Shared SharedPreferences key format for a user's lesson-progress
/// map. Used by both ProgressService (normal read/write) and
/// AuthService (to migrate a guest/bisita session's progress into a
/// real account when that guest signs up or logs in). Centralized
/// here so the two services can't silently drift out of sync on the
/// key format.
String progressPrefsKey(String uid) => 'kk_progress_$uid';
