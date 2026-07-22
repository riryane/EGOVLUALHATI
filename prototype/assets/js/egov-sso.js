// eGov SSO integration (OAuth2 authorization-code style).
// Flow: eGovPH redirects to our page with ?exchange_code=... →
//   1. POST /api/token          (exchange_code → access_token)
//   2. POST /api/partner/sso_authentication (access_token → citizen profile)
//   3. Upsert the profile into Supabase `users` (match by egov_uniqid),
//      seed default assistance + id_card for first-time users,
//      store users.id as the session and enter the app.
//
// NOTE (hackathon): the partner_secret is exposed client-side because this
// prototype has no backend. In production the token exchange must be moved
// to a server/edge function.
import { supabase } from './supabase-client.js';
import { setSession } from './session.js';

// The seeded demo row (supabase/seed.sql) acts as the benefits-catalog
// template copied to first-time SSO users. It is not a login fallback.
const ASSISTANCE_TEMPLATE_USER_ID = '11111111-1111-1111-1111-111111111111';

const SSO_BASE_URL = 'https://hackathon-sso.e.gov.ph';
const PARTNER_CODE = 'HACKATHON_SSO';
const PARTNER_SECRET = '0d77fba530ee49f5b00e36fe947bd384';

async function getAccessToken(exchangeCode) {
    const res = await fetch(`${SSO_BASE_URL}/api/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            exchange_code: exchangeCode,
            scope: 'SSO_AUTHENTICATION',
            partner_code: PARTNER_CODE,
            partner_secret: PARTNER_SECRET,
        }),
    });
    if (!res.ok) throw new Error(`Token exchange failed (${res.status}). The exchange code may be expired or already used.`);
    const json = await res.json();
    if (!json.access_token) throw new Error('No access token in response.');
    return json.access_token;
}

async function getProfile(accessToken) {
    const res = await fetch(`${SSO_BASE_URL}/api/partner/sso_authentication`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${accessToken}` },
    });
    if (!res.ok) throw new Error(`SSO authentication failed (${res.status}).`);
    const json = await res.json();
    if (!json.data) throw new Error('No profile data in response.');
    return json.data;
}

function titleCase(s) {
    return String(s ?? '').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

function mapProfileToUser(p) {
    const extra = p.additional_information || {};
    const health = extra.health_data || {};
    const birth = extra.birth_place || {};
    const other = extra.other_personal_information || {};
    return {
        egov_uniqid: p.uniqid,
        full_name: titleCase(`${p.first_name} ${p.last_name}`),
        email: p.email,
        phone: p.mobile,
        date_of_birth: p.birth_date,
        citizenship: p.nationality,
        address: p.address,
        avatar_url: p.photo,
        location: titleCase(p.municipality || p.province || ''),
        weight_kg: health.weight ? Number(health.weight) : null,
        height_cm: health.height ? Number(health.height) : null,
        eyes_color: health.eyes_color ? titleCase(health.eyes_color) : null,
        complexion: health.complexion ? titleCase(health.complexion) : null,
        birth_country: birth.birth_country,
        birth_province: birth.birth_province ? titleCase(birth.birth_province) : null,
        birth_municipality: birth.birth_municipality ? titleCase(birth.birth_municipality) : null,
        marital_status: other.marital_status,
    };
}

async function seedDefaultsForNewUser(userId, p) {
    // Copy the demo catalog of matched benefits to the new user.
    const { data: templates } = await supabase
        .from('assistance').select('*').eq('user_id', ASSISTANCE_TEMPLATE_USER_ID);
    if (templates?.length) {
        const copies = templates.map(({ id, user_id, ...rest }) => ({ ...rest, user_id: userId }));
        const { data: inserted } = await supabase.from('assistance').insert(copies).select('id, program_name');

        // Sample application history so the new account isn't empty.
        if (inserted?.length) {
            const byName = (frag) => inserted.find(a => a.program_name.includes(frag))?.id;
            const samples = [
                { frag: 'AICS',  status: 'done',       applied_at: '2026-06-10' },
                { frag: 'TUPAD', status: 'for_pickup', applied_at: '2026-07-15' },
                { frag: 'CHED',  status: 'approved',   applied_at: '2026-07-18' },
            ].map(s => ({ user_id: userId, assistance_id: byName(s.frag), status: s.status, applied_at: s.applied_at }))
             .filter(s => s.assistance_id);
            if (samples.length) await supabase.from('applications').insert(samples);
        }
    }

    // Digital ID from the SSO national_id block.
    const nid = p.national_id || {};
    const fullName = [p.first_name, p.middle_name, p.last_name].filter(Boolean).join(' ').toUpperCase();
    await supabase.from('id_cards').insert({
        user_id: userId,
        id_type: 'PhilSys National ID',
        id_number: nid.pcn || null,
        full_name: fullName,
        date_of_birth: p.birth_date,
        sex: titleCase(p.gender),
        address: p.address,
        photo_url: nid.face_url || p.photo,
    });
}

// Full login flow. Returns the local users row.
export async function loginWithExchangeCode(exchangeCode, onStatus = () => {}) {
    onStatus('Connecting to eGovPH…');
    const token = await getAccessToken(exchangeCode);

    onStatus('Fetching your eGov profile…');
    const profile = await getProfile(token);

    onStatus('Signing you in…');
    const mapped = mapProfileToUser(profile);

    // Existing user? Match by uniqid (per eGov integration guide).
    const { data: existing } = await supabase
        .from('users').select('id').eq('egov_uniqid', profile.uniqid).maybeSingle();

    let userId;
    if (existing) {
        userId = existing.id;
        await supabase.from('users').update(mapped).eq('id', userId);
    } else {
        const { data: created, error } = await supabase
            .from('users').insert(mapped).select('id').single();
        if (error) throw new Error(`Could not create your account: ${error.message}`);
        userId = created.id;
        await seedDefaultsForNewUser(userId, profile);
    }

    // The SSO payload is the source of truth for profile data — carry it in
    // the session so pages never need to read the users table.
    setSession(userId, mapped);
    return userId;
}
