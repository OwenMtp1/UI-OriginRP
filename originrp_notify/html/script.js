'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
const $ = (id) => document.getElementById(id);

// Petites icônes blanches dans la pastille colorée à côté du titre
const ICONS = {
    info: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round"><path d="M12 11v7M12 6h.01"/></svg>',
    success: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"><path d="m5.5 12.5 4 4L18.5 7.5"/></svg>',
    error: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.6" stroke-linecap="round"><path d="m7 7 10 10M17 7 7 17"/></svg>',
    warning: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round"><path d="M12 5v8.5M12 18.5h.01"/></svg>',
};

const notif = $('notif');
const bar = $('notif-bar');
const count = $('notif-count');

// Une seule notification visible : une nouvelle remplace l'actuelle.
let current = null; // { key, count }
let hideTimer = null;
let swapTimer = null;

function applyConfig(data) {
    if (!data) return;
    if (data.logo) {
        const img = document.createElement('img');
        img.src = data.logo;
        img.alt = '';
        $('notif-logo').replaceChildren(img);
    }
    if (data.position) notif.dataset.position = data.position;
    const root = document.documentElement.style;
    if (data.offset) {
        root.setProperty('--offset-x', `${Number(data.offset.x) || 0}px`);
        root.setProperty('--offset-y', `${Number(data.offset.y) || 0}px`);
    }
}

function restartBar(duration) {
    bar.classList.remove('run');
    void bar.offsetWidth; // relance l'animation
    bar.style.animationDuration = `${duration}ms`;
    bar.classList.add('run');
}

function scheduleHide(duration) {
    clearTimeout(hideTimer);
    hideTimer = setTimeout(leave, duration);
}

function leave() {
    clearTimeout(hideTimer);
    notif.classList.remove('show');
    notif.classList.add('leave');
    current = null;
}

function enter(data) {
    const type = ICONS[data.type] ? data.type : 'info';
    notif.dataset.type = type;
    $('notif-icon').innerHTML = ICONS[type];
    $('notif-title').textContent = data.title || '';
    $('notif-message').textContent = data.message || '';
    count.textContent = '';

    notif.classList.remove('leave');
    void notif.offsetWidth;
    notif.classList.add('show');
    restartBar(data.duration);
    scheduleHide(data.duration);
}

function show(data) {
    const duration = Math.max(1000, Number(data.duration) || 5000);
    const payload = { ...data, duration };
    const key = `${data.type}|${data.title}|${data.message}`;
    clearTimeout(swapTimer);

    // Même notification répétée : compteur ×2, ×3… et temps relancé
    if (current && current.key === key) {
        current.count += 1;
        count.textContent = `×${current.count}`;
        count.classList.remove('pop');
        void count.offsetWidth;
        count.classList.add('pop');
        restartBar(duration);
        scheduleHide(duration);
        return;
    }

    if (current) {
        // Une autre est affichée : elle sort, puis la nouvelle entre
        leave();
        current = { key, count: 1 };
        swapTimer = setTimeout(() => enter(payload), 220);
    } else {
        current = { key, count: 1 };
        enter(payload);
    }
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'notify') show(msg);
});

if (RESOURCE) {
    fetch(`https://${RESOURCE}/ready`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: '{}',
    })
        .then((res) => res.json())
        .then(applyConfig)
        .catch(() => {});
} else {
    // Aperçu hors jeu : enchaîne quelques notifications de démo
    document.body.style.background = 'transparent';
    const demo = [
        { type: 'success', title: 'Staff', message: 'Tu as été soigné.' },
        { type: 'info', title: 'Banque', message: 'Virement de 2 500 $ reçu de Malou Malou.' },
        { type: 'warning', title: 'Véhicule', message: 'Réservoir presque vide.' },
        { type: 'error', title: 'Inventaire', message: "Tu n'as pas assez de place." },
    ];
    let i = 0;
    const next = () => { show({ ...demo[i % demo.length], duration: 3500 }); i += 1; };
    next();
    setInterval(next, 4300);
}
