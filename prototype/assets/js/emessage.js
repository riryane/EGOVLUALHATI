// eGov eMessage API — SMS delivery (used for login OTPs).
// NOTE (hackathon): token is client-side because this prototype has no backend.
const EMESSAGE_BASE_URL = 'https://ws-message.e.gov.ph';
const EMESSAGE_API_TOKEN = '40419e47290ae8488a0a796b7c4c66aa';

// SMS goes to each account's actual registered number (editable in the
// Personal Information page). Set a value here to force-route every SMS
// to one phone for demos, e.g. '+639664529917'.
const SMS_ROUTE_OVERRIDE = null;

export function isEmessageConfigured() {
    return EMESSAGE_API_TOKEN !== 'YOUR_EMESSAGE_API_TOKEN';
}

export async function sendSms(number, message) {
    const to = SMS_ROUTE_OVERRIDE || number;
    const res = await fetch(`${EMESSAGE_BASE_URL}/messaging/v1/sms/push`, {
        method: 'POST',
        headers: {
            'X-EMESSAGE-Auth': EMESSAGE_API_TOKEN,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ number: to, message }),
    });
    if (!res.ok) {
        const body = await res.text().catch(() => '');
        throw new Error(`SMS send failed (${res.status}): ${body}`);
    }
    return res.json();
}
