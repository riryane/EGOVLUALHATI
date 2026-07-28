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
            case 'income_below': {
                // expected_salary comes from SSO as a bracket like "130,001-180,000";
                // the bracket floor is used as the monthly income proxy.
                const bracket = profile.expected_salary;
                const floor = bracket ? parseInt(String(bracket).replace(/,/g, '').match(/\d+/)?.[0] || '', 10) : NaN;
                const hasData = !Number.isNaN(floor);
                return {
                    text: hasData
                        ? `Income below ₱${rule.max.toLocaleString()} (declared: ₱${floor.toLocaleString()}+)`
                        : `Income below ₱${rule.max.toLocaleString()} (no income record on eGov profile)`,
                    met: hasData && floor < rule.max,
                };
            }
            case 'occupation_required': {
                return {
                    text: profile.occupation
                        ? `Worker occupation on record (${profile.occupation.slice(0, 40)}${profile.occupation.length > 40 ? '…' : ''})`
                        : 'Worker occupation on eGov record',
                    met: Boolean(profile.occupation),
                };
            }
            case 'education_recent': {
                // Active/recent studies: any educational_attainment entry ending
                // within the last N years (or still ongoing).
                const cutoff = new Date().getFullYear() - (rule.within_years || 5);
                const entries = Array.isArray(profile.education) ? profile.education : [];
                const recent = entries.some(e => {
                    const to = parseInt(e.to, 10);
                    return Number.isNaN(to) || to >= cutoff;
                });
                return {
                    text: `Enrolled or recent studies (within ${rule.within_years || 5} years)`,
                    met: entries.length > 0 && recent,
                };
            }
            case 'manual':
                // Criteria that cannot be verified from the eGov profile
                // (household composition, program conditions, membership
                // records) — confirmed by the agency during review.
                return { text: rule.text, met: null };
            default:
                return { text: rule.text || 'Additional requirement', met: Boolean(rule.met) };
        }
    });

    const metCount = results.filter(r => r.met === true).length;
    const failed = results.filter(r => r.met === false).length;
    const pendingReview = results.some(r => r.met === null);

    // Rules the citizen cannot act on (e.g. age) make the program NOT
    // eligible, not "possibly" — honesty beats false hope.
    const IMMUTABLE_TYPES = ['age_range'];
    const failedImmutable = rules.some((rule, i) => IMMUTABLE_TYPES.includes(rule.type) && results[i].met === false);

    // 'manual' (review-verified) items don't block applying — the review IS
    // the application. Verdict: hard fail > fixable fail > eligible.
    const verdict = failedImmutable ? 'not_eligible'
                  : failed > 0 ? 'possible'
                  : 'eligible';
    return {
        verdict,
        results,
        pendingReview,
        title: verdict === 'eligible' ? 'Eligible'
             : verdict === 'not_eligible' ? 'Not Eligible'
             : 'Possibly Eligible',
        desc: verdict === 'not_eligible'
            ? 'You do not meet a fixed requirement for this program (such as the age range).'
            : verdict === 'possible'
            ? `You meet ${metCount} out of ${results.length} verifiable requirements. Complete the rest to apply.`
            : pendingReview
            ? 'You meet all verifiable requirements. Items marked for review are confirmed by the agency after you apply.'
            : 'You meet all the requirements for this program.',
    };
}
