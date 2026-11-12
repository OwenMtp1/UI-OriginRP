'use strict';

// Config (config.js) + paramètres de l'adresse (?nom=...&discord=...&heure=...&min=...)
const P = new URLSearchParams(location.search);
const K = Object.assign({}, window.KIT || {});
if (P.has('nom')) K.streamer = P.get('nom');
['discord', 'heure', 'connexion', 'slogan'].forEach((k) => { if (P.has(k)) K[k] = P.get(k); });

const fmt = (s) => String(s).replace(/\{(\w+)\}/g, (_, k) => K[k] ?? '');

const LOGO = (document.currentScript?.src || '').replace(/kit\.js.*$/, 'logo.png');

// Emblème (logo + anneaux) : <div class="emblem" style="--e: 400px"></div>
function emblems() {
    document.querySelectorAll('.emblem:not(.done)').forEach((el) => {
        el.classList.add('done');
        el.innerHTML = `
            <svg viewBox="0 0 200 200">
                <circle class="ring faint" cx="100" cy="100" r="99"/>
                <circle class="ring" cx="100" cy="100" r="92"/>
                <circle class="arc" cx="100" cy="100" r="96" stroke-dasharray="150 453"/>
                <circle class="arc b" cx="100" cy="100" r="88" stroke-dasharray="70 483" stroke-dashoffset="-260"/>
                <circle class="arc c" cx="100" cy="100" r="99" stroke-dasharray="40 582" stroke-dashoffset="-330"/>
            </svg>
            <img src="${LOGO}" alt="Origin Roleplay">`;
    });
}

// Traits / bandes : <div class="streaks" data-n="..."></div> rempli selon un motif fixe
const STREAKS = [
    { top: '8%', p: '72%', t: '8s', d: '0s' }, { top: '16%', p: '30%', t: '10s', d: '-3s', o: 0.7 },
    { top: '27%', p: '80%', t: '9s', d: '-6s', o: 0.5 }, { top: '70%', p: '28%', t: '9s', d: '-2s' },
    { top: '82%', p: '62%', t: '11s', d: '-5s', o: 0.8 }, { top: '92%', p: '22%', t: '8s', d: '-7s', o: 0.6 },
];
const BANDS = ['-6%', '22%', '64%', '96%'];
function fx() {
    document.querySelectorAll('.streaks:empty').forEach((el) => {
        el.innerHTML = STREAKS.map((s) => `<i style="top:${s.top};--p:${s.p};--t:${s.t};--d:${s.d};--o:${s.o ?? 1}"></i>`).join('');
    });
    document.querySelectorAll('.bands:empty').forEach((el) => {
        el.innerHTML = BANDS.map((t) => `<i style="top:${t}"></i>`).join('');
    });
}

// Textes : <span data-k="discord"></span>, <span data-f="Bonjour {streamer}"></span>
function fill() {
    document.querySelectorAll('[data-k]').forEach((el) => { el.textContent = K[el.dataset.k] ?? ''; });
    document.querySelectorAll('[data-f]').forEach((el) => { el.textContent = fmt(el.dataset.f); });
    document.querySelectorAll('[data-if]').forEach((el) => { el.style.display = K[el.dataset.if] ? '' : 'none'; });
}

// Messages qui défilent
function ticker(el, list = K.infos || [], ms = 5000) {
    if (!el || !list.length) return;
    let i = 0;
    el.classList.add('ticker');
    el.textContent = fmt(list[0]);
    setInterval(() => {
        el.classList.add('out');
        setTimeout(() => { i = (i + 1) % list.length; el.textContent = fmt(list[i]); el.classList.remove('out'); }, 450);
    }, ms);
}

// Compte à rebours (?min=5)
function countdown(el, minutes, onEnd) {
    if (!el) return;
    let left = Math.max(0, Math.round(minutes * 60));
    const draw = () => { el.textContent = `${String(Math.floor(left / 60)).padStart(2, '0')}:${String(left % 60).padStart(2, '0')}`; };
    draw();
    const id = setInterval(() => {
        left -= 1;
        if (left <= 0) { left = 0; draw(); clearInterval(id); onEnd && onEnd(); return; }
        draw();
    }, 1000);
}

const ICON = {
    discord: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M19.6 5.3A16 16 0 0 0 15.6 4l-.5 1a15 15 0 0 0-6.2 0l-.5-1a16 16 0 0 0-4 1.3C1.9 9.1 1.2 12.8 1.5 16.4A16 16 0 0 0 6.4 19l1-1.6a10 10 0 0 1-1.6-.8l.4-.3a11.4 11.4 0 0 0 11.6 0l.4.3-1.6.8 1 1.6a16 16 0 0 0 4.9-2.6c.4-4.2-.6-7.8-2.9-11.1zM8.7 14.2c-1 0-1.8-.9-1.8-2s.8-2 1.8-2 1.8.9 1.8 2-.8 2-1.8 2zm6.6 0c-1 0-1.8-.9-1.8-2s.8-2 1.8-2 1.8.9 1.8 2-.8 2-1.8 2z"/></svg>',
    game: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="11" rx="5"/><path d="M7 11v3M5.5 12.5h3"/><circle cx="15.5" cy="11.5" r=".6" fill="currentColor"/><circle cx="18" cy="13.5" r=".6" fill="currentColor"/></svg>',
    clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>',
    heart: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 21s-7.5-4.6-9.6-9.3C.9 8.2 2.9 4 6.9 4c2.2 0 3.7 1.2 5.1 3 1.4-1.8 2.9-3 5.1-3 4 0 6 4.2 4.5 7.7C19.5 16.4 12 21 12 21z"/></svg>',
};
function icons() {
    document.querySelectorAll('[data-icon]').forEach((el) => { el.innerHTML = ICON[el.dataset.icon] || ''; });
}

// Particules lumineuses qui montent : <div class="particles" data-n="24"></div>
// Positions tirées d'une suite fixe : le rendu est le même à chaque chargement.
function particles() {
    document.querySelectorAll('.particles:empty').forEach((el) => {
        let seed = 7;
        const r = () => (seed = (seed * 9301 + 49297) % 233280) / 233280;
        const n = Number(el.dataset.n) || 24;
        el.innerHTML = Array.from({ length: n }, () =>
            `<i style="left:${(r() * 100).toFixed(1)}%;--s:${(2 + r() * 3).toFixed(1)}px;--t:${(7 + r() * 8).toFixed(1)}s;` +
            `--d:-${(r() * 14).toFixed(1)}s;--x:${Math.round((r() - 0.5) * 70)}px;--o:${(0.35 + r() * 0.6).toFixed(2)}"></i>`).join('');
    });
}

// ?intro=0 : pas d'animation d'entrée (le visuel apparaît directement)
function intro() { if (P.get('intro') === '0') document.body.classList.add('no-intro'); }

function kit() { intro(); fx(); particles(); emblems(); fill(); icons(); }
document.addEventListener('DOMContentLoaded', kit);
