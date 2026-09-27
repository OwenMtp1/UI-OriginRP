'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
const $ = (id) => document.getElementById(id);
const stroke = (d, w = 2) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;

const ICONS = {
    car: stroke('<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>'),
    users: stroke('<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20v-.5A5.5 5.5 0 0 1 8 14h2a5.5 5.5 0 0 1 5.5 5.5v.5"/><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8"/><path d="M18.5 14.2a5.5 5.5 0 0 1 3 4.8v1"/>'),
    truck: stroke('<path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.62l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/>'),
    bike: stroke('<circle cx="5" cy="16.5" r="3"/><circle cx="19" cy="16.5" r="3"/><path d="M5 16.5 8.5 12"/><path d="M19 16.5 15.8 8.5H13.5"/><path d="M4 11.5h5l1.5-2.5h4.2l1.6 2.6"/><path d="M8.5 12h7.7"/><path d="M10 12.5l1.2 4h3.3l1.7-4.4"/><path d="M8 16.5h3.2"/>'),
    fuel: stroke('<path d="M3 22V5a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v17M2 22h13M3 10h11"/><path d="M14 8h2a2 2 0 0 1 2 2v6a1.5 1.5 0 0 0 3 0V9l-3-3"/>', 2.2),
    engine: stroke('<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.8-3.8a6 6 0 0 1-7.9 7.9l-6.9 6.9a2.1 2.1 0 0 1-3-3l6.9-6.9a6 6 0 0 1 7.9-7.9z"/>', 2.2),
    body: stroke('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>', 2.2),
    out: stroke('<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><path d="m10 17 5-5-5-5M15 12H3"/>', 2.4),
};

const state = { open: false, data: null, tab: 0, active: 0 };

/* ---------- Utilitaires ---------- */

function esc(text) {
    const div = document.createElement('div');
    div.textContent = text == null ? '' : String(text);
    return div.innerHTML;
}

function post(name, data = {}) {
    if (!RESOURCE) return preview(name, data);
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

const tabs = () => state.data?.tabs || [];
const vehicles = () => tabs()[state.tab]?.vehicles || [];
const available = (v) => (v.state || 'garage') === 'garage';

/* ---------- Rendu ---------- */

function stat(icon, value) {
    if (value == null) return '';
    const pct = Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
    return `<span class="stat${pct <= 25 ? ' low' : ''}">${ICONS[icon]}<span class="bar"><i style="width:${pct}%"></i></span>${pct}%</span>`;
}

function renderTabs() {
    const list = tabs();
    $('g-tabs').innerHTML = list.map((t, i) => `
        <button class="g-tab${i === state.tab ? ' active' : ''}" data-tab="${i}" type="button">
            ${ICONS[t.icon] || ICONS.car}<span>${esc(t.label || 'Mes véhicules')}</span><em>${(t.vehicles || []).length}</em>
        </button>`).join('');
    $('hint-tabs').hidden = list.length < 2;
}

function renderList(animate) {
    const list = vehicles();
    const tabIcon = ICONS[tabs()[state.tab]?.icon] || ICONS.car;
    if (!list.length) {
        $('g-list').innerHTML = `
            <li class="g-empty">
                <span class="circle">${tabIcon}</span>
                <p>Aucun véhicule rangé ici</p>
                <p>Range un véhicule dans ce garage pour le retrouver dans cette liste.</p>
            </li>`;
    } else {
        $('g-list').innerHTML = list.map((v, i) => {
            const status = v.state === 'impound' ? '<span class="veh-status impound">Fourrière</span>'
                : v.state === 'out' ? '<span class="veh-status">Déjà sorti</span>'
                : `<span class="veh-action">${ICONS.out}Sortir</span>`;
            return `
            <li class="veh${available(v) ? '' : ' unavailable'}" data-index="${i}" role="option">
                <div class="veh-icon">${ICONS[tabs()[state.tab]?.icon] || ICONS.car}</div>
                <div class="veh-main">
                    <div class="veh-title">
                        <span class="veh-name">${esc(v.label)}</span>
                        ${v.plate ? `<span class="plate">${esc(v.plate)}</span>` : ''}
                    </div>
                    <div class="veh-stats">${stat('fuel', v.fuel)}${stat('engine', v.engine)}${stat('body', v.body)}</div>
                </div>
                ${status}
            </li>`;
        }).join('');
    }
    if (animate) {
        $('g-list').classList.remove('slide');
        void $('g-list').offsetWidth;
        $('g-list').classList.add('slide');
    }
    setActive(Math.min(state.active, Math.max(0, list.length - 1)), false);
}

function setActive(index, scroll = true) {
    state.active = index;
    document.querySelectorAll('.veh').forEach((node, i) => {
        node.classList.toggle('active', i === index);
        if (i === index && scroll) node.scrollIntoView({ block: 'nearest' });
    });
}

function setTab(index) {
    if (index < 0 || index >= tabs().length || index === state.tab) return;
    state.tab = index;
    state.active = 0;
    renderTabs();
    renderList(true);
}

function render() {
    const d = state.data;
    $('g-title').textContent = d.title || 'Garage';
    $('g-subtitle').textContent = d.subtitle || '';
    $('garage').dataset.position = d.position || 'center';
    renderTabs();
    renderList(false);
}

/* ---------- Actions ---------- */

function takeOut(index) {
    const v = vehicles()[index];
    if (!v || !available(v)) return;
    post('takeOut', { tab: state.tab, index });
    hide();
}

function open(data) {
    state.data = data || {};
    state.tab = 0;
    state.active = 0;
    state.open = true;
    render();
    $('garage').classList.remove('hidden');
}

function hide() {
    state.open = false;
    $('garage').classList.add('hidden');
}

function close() {
    if (!state.open) return;
    hide();
    post('close');
}

/* ---------- Événements ---------- */

$('g-tabs').addEventListener('click', (e) => {
    const tab = e.target.closest('[data-tab]');
    if (tab) setTab(Number(tab.dataset.tab));
});

$('g-list').addEventListener('mousemove', (e) => {
    const row = e.target.closest('.veh');
    if (row && Number(row.dataset.index) !== state.active) setActive(Number(row.dataset.index), false);
});

$('g-list').addEventListener('click', (e) => {
    const row = e.target.closest('.veh');
    if (row) takeOut(Number(row.dataset.index));
});

$('g-close').addEventListener('click', close);

document.addEventListener('keydown', (e) => {
    if (!state.open) return;
    const count = vehicles().length;
    switch (e.key) {
        case 'ArrowDown': if (count) setActive((state.active + 1) % count); break;
        case 'ArrowUp': if (count) setActive((state.active - 1 + count) % count); break;
        case 'ArrowRight': case 'Tab': setTab((state.tab + 1) % tabs().length); break;
        case 'ArrowLeft': setTab((state.tab - 1 + tabs().length) % tabs().length); break;
        case 'Enter': takeOut(state.active); break;
        case 'Escape': case 'Backspace': close(); break;
        default: return;
    }
    e.preventDefault();
});

window.addEventListener('message', (e) => {
    const msg = e.data || {};
    if (msg.action === 'open') open(msg.data);
    else if (msg.action === 'close') hide();
});

/* ---------- Aperçu hors jeu ---------- */

const DEMO = {
    title: 'Garage',
    subtitle: 'Parking de Pillbox Hill · Récupérez vos véhicules',
    tabs: [
        {
            id: 'perso', label: 'Mes véhicules', icon: 'car',
            vehicles: [
                { label: 'Karin Sultan RS', plate: 'ORG 123', fuel: 82, engine: 96, body: 74, state: 'garage' },
                { label: 'Pfister Comet', plate: '4DK 872', fuel: 18, engine: 88, body: 91, state: 'garage' },
                { label: 'Bravado Buffalo', plate: 'LS 5521', fuel: 60, engine: 70, body: 40, state: 'out' },
                { label: 'Pegassi Bati 801', plate: 'MTO 09', fuel: 45, engine: 100, body: 100, state: 'impound' },
            ],
        },
        { id: 'entreprise', label: 'Entreprise', icon: 'users', vehicles: [] },
    ],
};

function preview(name, data) {
    if (name === 'takeOut') {
        const v = DEMO.tabs[data.tab].vehicles[data.index];
        console.log('[aperçu] sortie', v);
        setTimeout(() => { DEMO.tabs[data.tab].vehicles[data.index].state = 'out'; open(DEMO); }, 900);
    } else if (name === 'close') {
        setTimeout(() => open(DEMO), 900);
    }
}

if (!RESOURCE) open(DEMO);
