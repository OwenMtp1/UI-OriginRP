'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;

const config = {
    unit: 'kmh',
    maxSpeed: 300,
    scale: 1,
    bottom: 3,
    lowFuel: 15,
    lowEngine: 30,
    seatbelt: true,
};

const $ = (id) => document.getElementById(id);
const speedo = $('speedo');
const dial = document.querySelector('.dial');

// Géométrie du cadran : arc de 270° ouvert vers le bas
const C = 160;
const START = 135;
const SWEEP = 270;
const R_SPEED = 126;
const R_RPM = 146;
const REDLINE = 0.85;

const polar = (r, deg) => {
    const a = (deg * Math.PI) / 180;
    return [C + r * Math.cos(a), C + r * Math.sin(a)];
};

function arcPath(r, from = 0, to = 1) {
    const a1 = START + SWEEP * from;
    const a2 = START + SWEEP * to;
    const [x1, y1] = polar(r, a1);
    const [x2, y2] = polar(r, a2);
    const large = a2 - a1 > 180 ? 1 : 0;
    return `M ${x1.toFixed(2)} ${y1.toFixed(2)} A ${r} ${r} 0 ${large} 1 ${x2.toFixed(2)} ${y2.toFixed(2)}`;
}

let ticks = [];

function buildDial() {
    const max = Number(config.maxSpeed) || 300;
    const major = max <= 160 ? 20 : 50;
    const minor = major / 5;
    let marks = '';
    ticks = [];
    for (let v = 0; v <= max + 0.001; v += minor) {
        const isMajor = Math.abs(v % major) < 0.001;
        const deg = START + SWEEP * (v / max);
        const [x1, y1] = polar(113, deg);
        const [x2, y2] = polar(isMajor ? 101 : 107, deg);
        marks += `<line class="tick${isMajor ? ' major' : ''}" data-v="${v}" x1="${x1.toFixed(2)}" y1="${y1.toFixed(2)}" x2="${x2.toFixed(2)}" y2="${y2.toFixed(2)}"/>`;
        if (isMajor) {
            const [lx, ly] = polar(87, deg);
            marks += `<text class="tick-label" x="${lx.toFixed(2)}" y="${ly.toFixed(2)}">${v}</text>`;
        }
    }
    $('dial-svg').innerHTML = `
        <defs>
            <linearGradient id="speed-grad" x1="0" y1="1" x2="1" y2="0">
                <stop offset="0" stop-color="#7c4dee"/>
                <stop offset="0.6" stop-color="#a874ff"/>
                <stop offset="1" stop-color="#e09bff"/>
            </linearGradient>
        </defs>
        <path class="rpm-track" d="${arcPath(R_RPM)}"/>
        <path class="rpm-red" d="${arcPath(R_RPM, REDLINE, 1)}"/>
        <path class="rpm-fill" id="rpm-fill" d="${arcPath(R_RPM)}" pathLength="100" stroke-dasharray="0 100"/>
        <path class="arc-track" d="${arcPath(R_SPEED)}"/>
        <path class="arc-fill" id="speed-fill" d="${arcPath(R_SPEED)}" pathLength="100" stroke-dasharray="0 100"/>
        ${marks}`;
    ticks = [...document.querySelectorAll('.tick')].map((el) => ({ el, v: Number(el.dataset.v) }));
}

function applyConfig(data) {
    Object.assign(config, data || {});
    const root = document.documentElement.style;
    root.setProperty('--scale', Number(config.scale) || 1);
    root.setProperty('--bottom', `${Number(config.bottom) || 3}vh`);
    $('unit').textContent = config.unit === 'mph' ? 'mph' : 'km/h';
    $('ind-belt').classList.toggle('off-feature', !config.seatbelt);
    buildDial();
}

/* ---------- Vitesse (chiffre animé) ---------- */
let target = 0;
let shown = 0;

function tick() {
    shown += (target - shown) * 0.25;
    if (Math.abs(target - shown) < 0.5) shown = target;
    $('speed').textContent = Math.round(shown);
    requestAnimationFrame(tick);
}
requestAnimationFrame(tick);

const CIRC = 2 * Math.PI * 34;
document.querySelectorAll('.side .fill').forEach((c) => { c.style.strokeDasharray = CIRC; c.style.strokeDashoffset = CIRC; });

function setSide(id, value, low) {
    const node = $(id);
    const v = Math.max(0, Math.min(100, Number(value) || 0));
    node.querySelector('.fill').style.strokeDashoffset = String(CIRC * (1 - v / 100));
    node.querySelector('.side-value span').textContent = Math.round(v);
    node.classList.toggle('low', v <= low);
}

function update(d) {
    const max = Number(config.maxSpeed) || 300;
    target = Math.max(0, Number(d.speed) || 0);
    const p = Math.min(1, target / max);
    const fill = $('speed-fill');
    fill.setAttribute('stroke-dasharray', `${(p * 100).toFixed(2)} 100`);
    fill.style.opacity = p > 0.003 ? 1 : 0;
    ticks.forEach((t) => t.el.classList.toggle('lit', t.v <= target && target > 0));

    const rpm = Math.max(0, Math.min(1, Number(d.rpm) || 0));
    $('rpm-fill').setAttribute('stroke-dasharray', `${(rpm * 100).toFixed(2)} 100`);
    dial.classList.toggle('redline', rpm >= REDLINE);

    const gear = $('gear');
    gear.textContent = d.gear ?? 'N';
    gear.classList.toggle('reverse', d.gear === 'R');

    const lights = $('ind-lights');
    lights.classList.toggle('on', d.lights === 1);
    lights.classList.toggle('high', d.lights === 2);
    // Ceinture : voyant rouge clignotant tant qu'elle n'est pas bouclée
    const belt = $('ind-belt');
    belt.classList.toggle('on', !!d.seatbelt);
    belt.classList.toggle('warn', !d.seatbelt);

    setSide('fuel', d.fuel, config.lowFuel);
    setSide('engine', d.engine, config.lowEngine);
}

window.addEventListener('message', (e) => {
    const msg = e.data || {};
    if (msg.action === 'update') update(msg);
    else if (msg.action === 'visible') speedo.classList.toggle('hidden', !msg.visible);
});

if (RESOURCE) {
    buildDial();
    fetch(`https://${RESOURCE}/ready`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: '{}',
    }).then((r) => r.json()).then(applyConfig).catch(() => {});
} else {
    // Aperçu hors jeu : accélérations, passages de rapports, freinage
    applyConfig();
    requestAnimationFrame(() => speedo.classList.remove('hidden'));
    const GEARS = [0, 45, 85, 125, 160, 195, 999];
    let speed = 0, dir = 1, fuel = 64, engine = 100, t = 0;
    setInterval(() => {
        t += 1;
        speed = Math.max(0, Math.min(228, speed + (dir > 0 ? 2.4 - speed / 150 : -4)));
        if (speed >= 226) dir = -1;
        if (speed <= 0 && dir < 0) { dir = 1; fuel = fuel <= 12 ? 64 : fuel - 9; engine = engine <= 25 ? 100 : engine - 25; }
        const g = GEARS.findIndex((top) => speed < top);
        const lo = GEARS[g - 1] ?? 0, hi = GEARS[g];
        const rpm = speed < 1 ? 0.2 : dir > 0 ? 0.25 + 0.72 * ((speed - lo) / Math.min(60, hi - lo)) : 0.3;
        update({
            speed: Math.round(speed),
            rpm: Math.min(1, rpm),
            gear: speed < 1 ? 'N' : String(g),
            fuel, engine,
            lights: t % 300 < 150 ? 1 : 2,
            seatbelt: t % 200 > 40,
        });
    }, 80);
}
