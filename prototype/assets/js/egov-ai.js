// eGov AI — Document Extractor (OCR).
// The access code is exchanged for a short-lived (48h) access token via
// POST /api/v1/egov/integration/token; we cache it and refresh on expiry.
// NOTE (hackathon): credentials are client-side because this prototype has no backend.
const EGOV_AI_BASE = 'https://egov-ai-core-ws.oueg.info';
const EGOV_AI_ACCESS_CODE = 'f2c81ce889a5850fd59487ce988ec1324183682c62d300bdbd33d5064862942b';

export function isOcrConfigured() {
    return Boolean(EGOV_AI_ACCESS_CODE);
}

async function fetchToken() {
    const res = await fetch(`${EGOV_AI_BASE}/api/v1/egov/integration/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ access_code: EGOV_AI_ACCESS_CODE }),
    });
    if (!res.ok) throw new Error(`eGov AI token request failed (${res.status})`);
    const json = await res.json();
    if (!json.access_token) throw new Error('No access token in eGov AI response.');
    localStorage.setItem('egov_ai_token', json.access_token);
    // Refresh 5 minutes before actual expiry.
    localStorage.setItem('egov_ai_token_exp', String(Date.now() + (json.expires_in_seconds - 300) * 1000));
    return json.access_token;
}

async function getToken() {
    const cached = localStorage.getItem('egov_ai_token');
    const exp = Number(localStorage.getItem('egov_ai_token_exp') || 0);
    if (cached && Date.now() < exp) return cached;
    return fetchToken();
}

// blob: captured image (JPEG). Returns the extractor's HTML string of fields.
export async function extractDocument(blob, filename = 'document.jpg') {
    const form = new FormData();
    form.append('file', blob, filename);

    let token = await getToken();
    let res = await fetch(`${EGOV_AI_BASE}/api/v1/egov/integration/document_extractor/generate`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` },
        body: form,
    });

    if (res.status === 401) {
        // Token revoked/expired early — refresh once and retry.
        token = await fetchToken();
        res = await fetch(`${EGOV_AI_BASE}/api/v1/egov/integration/document_extractor/generate`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` },
            body: form,
        });
    }

    if (!res.ok) {
        const body = await res.text().catch(() => '');
        throw new Error(`Document extraction failed (${res.status}): ${body.slice(0, 200)}`);
    }
    const json = await res.json();
    if (!json.data) throw new Error('No extraction data in response.');
    return json.data;
}
