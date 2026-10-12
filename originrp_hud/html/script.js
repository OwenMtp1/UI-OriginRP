'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;

const ICONS = {
    health: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 21s-7.5-4.6-9.6-9.3C.9 8.2 2.9 4 6.9 4c2.2 0 3.7 1.2 5.1 3 1.4-1.8 2.9-3 5.1-3 4 0 6 4.2 4.5 7.7C19.5 16.4 12 21 12 21z"/></svg>',
    armor: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2 4 5v6.2c0 5 3.4 9.3 8 10.8 4.6-1.5 8-5.8 8-10.8V5z"/></svg>',
    thirst: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.5s-7 7.6-7 12.3a7 7 0 0 0 14 0C19 10.1 12 2.5 12 2.5z"/></svg>',
    hunger: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M4 10.5C4 6.4 7.6 4 12 4s8 2.4 8 6.5c0 .6-.4 1-1 1H5c-.6 0-1-.4-1-1z"/><rect x="3" y="13" width="18" height="2.6" rx="1.3"/><path d="M4.5 17.5h15c0 1.4-1.1 2.5-2.5 2.5H7c-1.4 0-2.5-1.1-2.5-2.5z"/></svg>',
};

const RADIUS = 20.4;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

const hud = document.getElementById('hud');
const gauges = {};
const bars = {};

const config = {
    gauges: ['thirst', 'hunger'],
    bars: ['health', 'armor'],
    scale: 1,
    gap: 14,
    barWidth: 210,
    showValues: true,
    lowThreshold: 20,
    hideArmorWhenEmpty: false,
};

function build() {
    hud.textContent = '';
    for (const key of Object.keys(gauges)) delete gauges[key];
    for (const key of Object.keys(bars)) delete bars[key];

    // Faim / soif : jauges rondes (inchangées), au-dessus
    const needs = document.createElement('div');
    needs.className = 'needs';
    config.gauges.forEach((type) => {
        if (!ICONS[type]) return;
        const node = document.createElement('div');
        node.className = 'gauge';
        node.dataset.type = type;
        node.innerHTML = `
            <svg class="ring" viewBox="0 0 46 46">
                <defs>
                    <linearGradient id="grad-${type}" x1="0" y1="0" x2="1" y2="1">
                        <stop offset="0" stop-color="var(--c1)"/>
                        <stop offset="1" stop-color="var(--c2)"/>
                    </linearGradient>
                </defs>
                <circle class="track" cx="23" cy="23" r="${RADIUS}"/>
                <circle class="bar" cx="23" cy="23" r="${RADIUS}" stroke="url(#grad-${type})"
                    stroke-dasharray="${CIRCUMFERENCE}" stroke-dashoffset="${CIRCUMFERENCE}"/>
            </svg>
            <div class="icon">${ICONS[type]}</div>`;
        needs.appendChild(node);
        gauges[type] = { node, bar: node.querySelector('.bar') };
    });
    if (needs.children.length) hud.appendChild(needs);

    // Vie / armure : barres sur la longueur, en dessous
    const list = document.createElement('div');
    list.className = `bars${config.showValues ? '' : ' no-values'}`;
    config.bars.forEach((type) => {
        if (!ICONS[type]) return;
        const node = document.createElement('div');
        node.className = 'bar-row';
        node.dataset.type = type;
        node.innerHTML = `<span class="b-icon">${ICONS[type]}</span><div class="b-track"><i class="b-fill"></i></div><span class="b-val">0</span>`;
        list.appendChild(node);
        bars[type] = { node, fill: node.querySelector('.b-fill'), val: node.querySelector('.b-val') };
    });
    if (list.children.length) hud.appendChild(list);
}

function applyConfig(data) {
    Object.assign(config, data || {});
    const scale = Number(config.scale) || 1;
    const root = document.documentElement.style;
    root.setProperty('--size', `${44 * scale}px`);
    root.setProperty('--bar-width', `${(Number(config.barWidth) || 210) * scale}px`);
    root.setProperty('--bar-height', `${8 * scale}px`);
    root.setProperty('--gap', `${Number(config.gap) || 0}px`);
    build();
}

function setValue(type, value) {
    const percent = Math.max(0, Math.min(100, Number(value) || 0));
    const low = percent > 0 && percent <= config.lowThreshold && type !== 'armor';
    const gauge = gauges[type];
    if (gauge) {
        gauge.bar.style.strokeDashoffset = String(CIRCUMFERENCE * (1 - percent / 100));
        gauge.node.classList.toggle('empty', percent <= 0);
        gauge.node.classList.toggle('low', low);
    }
    const bar = bars[type];
    if (bar) {
        bar.fill.style.width = `${percent}%`;
        bar.val.textContent = Math.round(percent);
        bar.node.classList.toggle('empty', percent <= 0);
        bar.node.classList.toggle('low', low);
        if (type === 'armor') bar.node.classList.toggle('gone', config.hideArmorWhenEmpty && percent <= 0);
    }
}

function setAnchor(anchor) {
    const root = document.documentElement.style;
    root.setProperty('--anchor-right', `${anchor.right * 100}vw`);
    root.setProperty('--anchor-bottom', `${(1 - anchor.bottom) * 100}vh`);
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    switch (msg.action) {
        case 'status':
            Object.entries(msg.values || {}).forEach(([type, value]) => setValue(type, value));
            break;
        case 'visible':
            hud.classList.toggle('hidden', !msg.visible);
            break;
        case 'anchor':
            setAnchor(msg.anchor);
            break;
    }
});

if (RESOURCE) {
    build();
    fetch(`https://${RESOURCE}/ready`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: '{}',
    })
        .then((res) => res.json())
        .then(applyConfig)
        .catch(() => {});
} else {
    // Aperçu hors jeu : valeurs de démo qui évoluent
    applyConfig();
    setAnchor({ right: 0.02, bottom: 0.9 });
    const demo = { health: 85, armor: 0, thirst: 60, hunger: 35 };
    Object.entries(demo).forEach(([t, v]) => setValue(t, v));
    requestAnimationFrame(() => hud.classList.remove('hidden'));
    setInterval(() => {
        demo.thirst = demo.thirst <= 10 ? 90 : demo.thirst - 7;
        demo.hunger = demo.hunger <= 10 ? 80 : demo.hunger - 4;
        demo.armor = demo.armor >= 100 ? 0 : demo.armor + 25;
        demo.health = demo.health <= 15 ? 100 : demo.health - 9;
        Object.entries(demo).forEach(([t, v]) => setValue(t, v));
    }, 1500);
}
