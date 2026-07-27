// Eligibility rules engine — computes each citizen's real eligibility from
// their eGov profile and application history, instead of showing seeded text.
//
// A program's `rules` (jsonb) is a list of criteria:
//   { type: 'age_range',  min, max }
//   { type: 'residency',  keyword }                — address must contain keyword
//   { type: 'profile_complete', fields: [...] }    — profile fields must be filled
//   { type: 'no_active_same_category' }            — no other active application
//                                                    in the same program category
//
// Verdict: every rule met → 'eligible'; at least half → 'possible';
// otherwise 'possible' as well (a citizen can always work toward eligibility).

const ACTIVE_STATUSES = ['pending', 'info_requested', 'appealed', 'approved', 'for_pickup'];

function ageFrom(dateOfBirth) {
    if (!dateOfBirth) return null;
    const dob = new Date(dateOfBirth);
    return Math.floor((Date.now() - dob.getTime()) / (365.25 * 24 * 3600 * 1000));
}

const FIELD_LABELS = {
    date_of_birth: 'birth date', address: 'address', phone: 'mobile number',
    email: 'email', full_name: 'name',
};

// program: the assistance row; profile: session profile;
// apps: the user's applications joined with assistance(category).
export function evaluate(program, profile, apps) {
    const rules = program.rules || [];
    if (!rules.length || !profile) return null; // caller falls back to seeded data

    const results = rules.map((rule) => {
        switch (rule.type) {
            case 'age_range': {
                const age = ageFrom(profile.date_of_birth);
                return {
                    text: `Aged ${rule.min}–${rule.max} years`,
                    met: age !== null && age >= rule.min && age <= rule.max,
                };
            }
            case 'residency': {
                const addr = (profile.address || '').toLowerCase();
                return {
                    text: `Resident of ${rule.keyword}`,
                    met: addr.includes(rule.keyword.toLowerCase()),
                };
            }
            case 'profile_complete': {
                const missing = (rule.fields || []).filter(f => !profile[f]);
                return {
                    text: missing.length
                        ? `Complete eGov profile (missing: ${missing.map(f => FIELD_LABELS[f] || f).join(', ')})`
                        : 'Complete eGov profile information',
                    met: !missing.length,
                };
            }
            case 'no_active_same_category': {
                const conflict = (apps || []).find(a =>
                    ACTIVE_STATUSES.includes(a.status) &&
                    a.assistance?.category === program.category &&
                    a.assistance_id !== program.id);
                return {
                    text: conflict
                        ? `No other active ${program.category} benefit (active: ${conflict.assistance?.program_name || 'another program'})`
                        : `No other active ${program.category} benefit`,
                    met: !conflict,
                };
            }
            default:
                return { text: rule.text || 'Additional requirement', met: Boolean(rule.met) };
        }
    });

    const metCount = results.filter(r => r.met).length;
    const verdict = metCount === results.length ? 'eligible' : 'possible';
    return {
        verdict,
        results,
        title: verdict === 'eligible' ? 'Eligible' : 'Possibly Eligible',
        desc: verdict === 'eligible'
            ? 'You meet all the requirements for this program.'
            : `You meet ${metCount} out of ${results.length} requirements. Complete the rest to apply.`,
    };
}
