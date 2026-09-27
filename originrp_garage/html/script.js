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
    boat: stroke('<path d="M2 20c2 1.3 4 1.3 6 0s4-1.3 6 0 4 1.3 6 0"/><path d="M4 17 3 12h18l-2.5 5"/><path d="M12 12V3l6 6h-6"/>'),
    air: stroke('<path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/>'),
    emergency: stroke('<path d="M7 18v-6a5 5 0 0 1 10 0v6"/><path d="M5 21a1 1 0 0 1-1-1v-1a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v1a1 1 0 0 1-1 1z"/><path d="M21 12h1M18.5 4.5 18 5M2 12h1M12 2v1M4.9 4.9l.7.7"/>'),
    all: stroke('<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>'),
    out: stroke('<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><path d="m10 17 5-5-5-5M15 12H3"/>', 2.4),
};

// Catégories connues (ordre d'affichage des filtres)
const CATEGORIES = [
    { id: 'car', label: 'Voitures' },
    { id: 'bike', label: 'Motos' },
    { id: 'truck', label: 'Utilitaires' },
    { id: 'boat', label: 'Bateaux' },
    { id: 'air', label: 'Aériens' },
    { id: 'emergency', label: 'Urgence' },
];

const state = { open: false, data: null, tab: 0, active: 0, filter: 'all' };

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
const tabVehicles = () => tabs()[state.tab]?.vehicles || [];
const categoryOf = (v) => v.category || 'car';
// Véhicules affichés (avec leur index d'origine, renvoyé au script)
const vehicles = () => tabVehicles()
    .map((v, index) => ({ ...v, index }))
    .filter((v) => state.filter === 'all' || categoryOf(v) === state.filter);
const available = (v) => (v.state || 'garage') === 'garage';

/* ---------- Rendu ---------- */

function stat(icon, value, title) {
    if (value == null) return '';
    const pct = Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
    return `<span class="stat${pct <= 25 ? ' low' : ''}" title="${title}">${ICONS[icon]}<span class="bar"><i style="width:${pct}%"></i></span>${pct}%</span>`;
}

function renderTabs() {
    const list = tabs();
    $('g-tabs').innerHTML = list.map((t, i) => `
        <button class="g-tab${i === state.tab ? ' active' : ''}" data-tab="${i}" type="button">
            ${ICONS[t.icon] || ICONS.car}<span>${esc(t.label || 'Mes véhicules')}</span><em>${(t.vehicles || []).length}</em>
        </button>`).join('');
    $('hint-tabs').hidden = list.length < 2;
}

function renderFilters() {
    const counts = {};
    tabVehicles().forEach((v) => { counts[categoryOf(v)] = (counts[categoryOf(v)] || 0) + 1; });
    const known = CATEGORIES.filter((c) => counts[c.id]);
    const other = Object.keys(counts).filter((id) => !CATEGORIES.some((c) => c.id === id)).map((id) => ({ id, label: id }));
    const cats = [...known, ...other];
    if (!cats.some((c) => c.id === state.filter)) state.filter = 'all';
    // Un filtre n'a d'intérêt qu'à partir de deux catégories
    $('g-filters').hidden = cats.length < 2;
    $('g-filters').innerHTML = [{ id: 'all', label: 'Tous' }, ...cats].map((c) => `
        <button class="chip${state.filter === c.id ? ' active' : ''}" data-filter="${esc(c.id)}" type="button">
            ${ICONS[c.id] || ICONS.car}${esc(c.label)}<em>${c.id === 'all' ? tabVehicles().length : counts[c.id]}</em>
        </button>`).join('');
}

function renderList(animate) {
    renderFilters();
    const list = vehicles();
    const tabIcon = ICONS[tabs()[state.tab]?.icon] || ICONS.car;
    if (!list.length) {
        const filtered = tabVehicles().length > 0;
        $('g-list').innerHTML = `
            <li class="g-empty">
                <span class="circle">${filtered ? ICONS[state.filter] || tabIcon : tabIcon}</span>
                <p>${filtered ? 'Aucun véhicule dans cette catégorie' : 'Aucun véhicule rangé ici'}</p>
                <p>${filtered ? 'Choisis une autre catégorie ou « Tous ».' : 'Range un véhicule dans ce garage pour le retrouver dans cette liste.'}</p>
            </li>`;
    } else {
        $('g-list').innerHTML = list.map((v, i) => {
            const status = v.state === 'impound' ? '<span class="veh-status impound">Fourrière</span>'
                : v.state === 'out' ? '<span class="veh-status">Déjà sorti</span>'
                : `<span class="veh-action">${ICONS.out}Sortir</span>`;
            return `
            <li class="veh${available(v) ? '' : ' unavailable'}" data-index="${i}" role="option">
                <div class="veh-icon">${ICONS[categoryOf(v)] || ICONS.car}</div>
                <div class="veh-main">
                    <div class="veh-title">
                        <span class="veh-name">${esc(v.label)}</span>
                        ${v.plate ? `<span class="plate">${esc(v.plate)}</span>` : ''}
                    </div>
                    <div class="veh-stats">${stat('fuel', v.fuel, 'Carburant')}${stat('engine', v.condition, 'État (moteur + carrosserie)')}</div>
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
    state.filter = 'all';
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

function takeOut(position) {
    const v = vehicles()[position];
    if (!v || !available(v)) return;
    post('takeOut', { tab: state.tab, index: v.index });
    hide();
}

function setFilter(id) {
    if (id === state.filter) return;
    state.filter = id;
    state.active = 0;
    renderList(true);
    $('g-filters').querySelector('.chip.active')?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
}

function open(data) {
    state.data = data || {};
    state.tab = 0;
    state.active = 0;
    state.filter = 'all';
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

$('g-filters').addEventListener('click', (e) => {
    const chip = e.target.closest('[data-filter]');
    if (chip) setFilter(chip.dataset.filter);
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
                { label: 'Karin Sultan RS', plate: 'ORG 123', fuel: 82, condition: 85, category: 'car', state: 'garage' },
                { label: 'Pfister Comet', plate: '4DK 872', fuel: 18, condition: 90, category: 'car', state: 'garage' },
                { label: 'Pegassi Bati 801', plate: 'MTO 09', fuel: 45, condition: 100, category: 'bike', state: 'garage' },
                { label: 'Vapid Speedo', plate: 'LS 5521', fuel: 60, condition: 55, category: 'truck', state: 'out' },
                { label: 'Shitzu Squalo', plate: 'SEA 77', fuel: 90, condition: 22, category: 'boat', state: 'impound' },
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
