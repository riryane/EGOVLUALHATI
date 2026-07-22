// Simple session management. A session is the users.id stored at login
// (via eGov SSO or OTP). No hardcoded accounts — no session means login.
export function currentSession() {
    return localStorage.getItem('session_user_id');
}

export function setSession(userId, profile = null) {
    localStorage.setItem('session_user_id', userId);
    // Profile data lives in the session (sourced from eGov SSO at login) —
    // pages read it from here instead of querying the users table.
    if (profile) localStorage.setItem('session_profile', JSON.stringify(profile));
}

export function currentProfile() {
    try {
        return JSON.parse(localStorage.getItem('session_profile'));
    } catch {
        return null;
    }
}

export function requireSession() {
    // A valid session carries both the user id and the profile snapshot;
    // sessions from before the snapshot era are cleared and sent to login.
    if (!currentSession() || !currentProfile()) {
        localStorage.removeItem('session_user_id');
        localStorage.removeItem('session_profile');
        window.location.replace('login.html');
    }
}

export function clearCapturedDocs() {
    Object.keys(localStorage)
        .filter(k => k.startsWith('captured_'))
        .forEach(k => localStorage.removeItem(k));
}

export function logout() {
    localStorage.removeItem('session_user_id');
    localStorage.removeItem('session_profile');
    clearCapturedDocs();
    window.location.replace('login.html');
}
