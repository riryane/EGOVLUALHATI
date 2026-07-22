// eGov eMessage API — SMS delivery (used for login OTPs).
// NOTE (hackathon): token is client-side because this prototype has no backend.
const EMESSAGE_BASE_URL = 'https://ws-message.e.gov.ph';
const EMESSAGE_API_TOKEN = '40419e47290ae8488a0a796b7c4c66aa';

export function isEmessageConfigured() {
    return EMESSAGE_API_TOKEN !== 'YOUR_EMESSAGE_API_TOKEN';
}

export async function sendSms(number, message) {
    const res = await fetch(`${EMESSAGE_BASE_URL}/messaging/v1/sms/push`, {
        method: 'POST',
        headers: {
            'X-EMESSAGE-Auth': EMESSAGE_API_TOKEN,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ number, message }),
    });
    if (!res.ok) {
        const body = await res.text().catch(() => '');
        throw new Error(`SMS send failed (${res.status}): ${body}`);
    }
    return res.json();
}
