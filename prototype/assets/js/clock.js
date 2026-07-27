// Live status-bar clock + dashboard date (replaces the hardcoded 10:15).
function tick() {
    const now = new Date();
    const time = now.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: false });

    const bar = document.querySelector('.status-bar > div:first-child');
    if (bar && bar.firstChild && bar.firstChild.nodeType === Node.TEXT_NODE) {
        bar.firstChild.nodeValue = `\n                ${time}\n                `;
    }

    const dateEl = document.getElementById('date-today');
    if (dateEl) {
        const wd = now.toLocaleDateString('en-US', { weekday: 'short' });
        const md = now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
        dateEl.textContent = `${wd} - ${md}`;
    }
}
tick();
setInterval(tick, 30_000);
