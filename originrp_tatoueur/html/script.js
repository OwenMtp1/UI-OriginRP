'use strict';

/* ---------- Commun aux boutiques OriginRP ---------- */

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
const $ = (id) => document.getElementById(id);
const stroke = (d, w = 2) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;

const COMMON_ICONS = {
    cash: stroke('<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/><path d="M6 12h.01M18 12h.01"/>'),
    card: stroke('<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20M6 15h4"/>'),
    search: stroke('<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>', 2.2),
    lock: stroke('<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>', 2.2),
    check: stroke('<path d="m5 12.5 4.5 4.5L19 7.5"/>', 2.6),
    rotl: stroke('<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>', 2.2),
    rotr: stroke('<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>', 2.2),
};

function esc(text) {
    const div = document.createElement('div');
    div.textContent = text == null ? '' : String(text);
    return div.innerHTML;
}

const fmtMoney = (n) => `${Number(n || 0).toLocaleString('fr-FR')} $`;

function post(name, data = {}) {
    if (!RESOURCE) return typeof preview === 'function' ? preview(name, data) : undefined;
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

let toastTimer = null;
function toast(message, kind = '') {
    const node = $('toast');
    if (!node) return;
    node.textContent = message;
    node.className = `toast show ${kind}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => node.classList.remove('show'), 2600);
}

// En-tête commun : logo, titre, espèces / carte, fermer
function headerHtml(icon, title, subtitle, money, side) {
    const wallet = money ? `
        <div class="wallet">
            <div class="pill"><span class="pill-icon">${COMMON_ICONS.cash}</span><span><small>Espèces</small><strong>${fmtMoney(money.cash)}</strong></span></div>
            <div class="pill"><span class="pill-icon">${COMMON_ICONS.card}</span><span><small>Carte</small><strong>${fmtMoney(money.bank)}</strong></span></div>
        </div>` : '';
    return `
        <header class="s-header">
            <div class="s-logo">${icon}</div>
            <div class="s-heading"><h1>${esc(title)}</h1><p>${esc(subtitle || '')}</p></div>
            ${side ? '' : wallet}
            <button class="s-close" data-close type="button" aria-label="Fermer"><span>ESC</span></button>
        </header>
        ${side ? wallet : ''}`;
}

const canPay = (money, method, price) => !money || Number(money[method === 'bank' ? 'bank' : 'cash']) >= Number(price || 0);

// Paiement en deux temps : 1er clic = « Confirmer », 2e clic = achat
const confirmState = { key: null, timer: null };
function askConfirm(key, onReset) {
    if (confirmState.key === key) {
        confirmState.key = null;
        clearTimeout(confirmState.timer);
        return true;
    }
    confirmState.key = key;
    clearTimeout(confirmState.timer);
    confirmState.timer = setTimeout(() => { confirmState.key = null; onReset(); }, 3500);
    return false;
}

function payButtons(keyBase, price, money, extraClass = '') {
    return ['cash', 'bank'].map((method) => {
        const key = `${keyBase}|${method}`;
        const ok = canPay(money, method, price);
        const confirming = confirmState.key === key;
        const label = method === 'cash' ? 'Espèces' : 'Carte';
        return `<button class="pay ${extraClass}${confirming ? ' confirm' : ''}" data-pay="${esc(key)}" type="button" ${ok ? '' : 'disabled'}
            title="${ok ? '' : `Il manque ${fmtMoney(price - (method === 'bank' ? money.bank : money.cash))}`}">
            ${confirming ? `Confirmer · ${fmtMoney(price)}` : `${COMMON_ICONS[method === 'cash' ? 'cash' : 'card']}${label}`}
        </button>`;
    }).join('');
}

/* ---------- Salon de tatouage ---------- */

const ICONS = {
    logo: stroke('<path d="M18.4 2.6a2 2 0 0 1 2.8 2.8L10 16.6 6.5 17.5l.9-3.5z"/><path d="m15 6 3 3"/><path d="M4 21c1-2 2.5-2.5 4-2"/>', 2.1),
    head: stroke('<circle cx="12" cy="8" r="5"/><path d="M8 21v-3a4 4 0 0 1 8 0v3"/>'),
    torso: stroke('<path d="M7 3h10l2 5-2 1v12H7V9L5 8z"/><path d="M12 9v8"/>'),
    arm: stroke('<path d="M8 3c-1 4 0 8 3 11l5 7"/><path d="M12 3c-1 4 0 7 2 9l5 6"/>'),
    leg: stroke('<path d="M9 2v10l-1 9h3l1-9 1 9h3l-1-9V2"/>'),
    none: stroke('<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>'),
    ink: stroke('<path d="M12 2.5s-6 6.5-6 11a6 6 0 0 0 12 0c0-4.5-6-11-6-11z"/>'),
};

const state = { open: false, data: null, zone: 0, search: '', selected: null }; // selected = id | 'none'

const zones = () => state.data?.zones || [];
const zone = () => zones()[state.zone];
const tattoos = () => state.data?.tattoos?.[zone()?.id] || [];
const owned = (id) => (state.data?.owned?.[zone()?.id] || []).includes(id);

function render(animate) {
    const d = state.data;
    const z = zone();
    const q = state.search.trim().toLowerCase();
    const list = tattoos().filter((t) => !q || t.label.toLowerCase().includes(q));
    const sel = state.selected;
    const selItem = sel && sel !== 'none' ? tattoos().find((t) => t.id === sel) : null;

    const tabs = zones().map((t, i) => `
        <button class="s-tab${i === state.zone ? ' active' : ''}" data-zone="${i}" type="button">${ICONS[t.icon] || ICONS.ink}${esc(t.label)}</button>`).join('');

    const cards = [
        !q ? `<button class="tcard${sel === 'none' ? ' active' : ''}" data-tattoo="none" type="button">
            <span class="tcard-icon">${ICONS.none}</span><span class="tcard-name">Aucun</span></button>` : '',
        ...list.map((t) => `
            <button class="tcard${sel === t.id ? ' active' : ''}" data-tattoo="${esc(t.id)}" type="button">
                <span class="tcard-icon">${ICONS.ink}</span>
                <span class="tcard-name">${esc(t.label)}</span>
                ${owned(t.id) ? '<span class="owned">Possédé</span>' : ''}
            </button>`),
    ].join('');

    const price = selItem ? (selItem.price ?? z.price) : 0;
    let foot;
    if (selItem && owned(selItem.id)) {
        foot = `<div class="s-foot"><div class="s-foot-top"><div class="s-foot-title"><small>${esc(z.label)}</small><strong>${esc(selItem.label)}</strong></div>
            <span class="badge-ok">${COMMON_ICONS.check}Déjà tatoué</span></div></div>`;
    } else if (selItem) {
        foot = `<div class="s-foot"><div class="s-foot-top"><div class="s-foot-title"><small>${esc(z.label)}</small><strong>${esc(selItem.label)}</strong></div>
            <span class="price">${fmtMoney(price)}</span></div>
            <div class="s-foot-pay">${payButtons(`${z.id}:${selItem.id}`, price, d.money, 'primary')}</div></div>`;
    } else {
        foot = `<div class="s-foot idle"><p class="note">${sel === 'none' ? 'Aperçu de la zone sans nouveau tatouage.' : 'Choisis un motif pour le voir sur ton personnage.'}</p></div>`;
    }

    const empty = !list.length && q ? `<div class="empty"><span class="circle">${COMMON_ICONS.search}</span><p>Aucun motif trouvé</p><p>Essaie un autre mot-clé.</p></div>` : '';

    $('store').innerHTML = `
        ${headerHtml(ICONS.logo, d.title || 'Tatoueur', d.subtitle, d.money, true)}
        <nav class="s-tabs grid three">${tabs}</nav>
        <div class="section-label"><span>${esc(z?.label || '')}</span><strong>${fmtMoney(z?.price)} le motif</strong></div>
        <label class="search">${COMMON_ICONS.search}<input id="t-search" type="text" placeholder="Rechercher un motif…" value="${esc(state.search)}" autocomplete="off"></label>
        <div class="s-body${animate ? ' slide' : ''}"><div class="tcards">${cards}</div>${empty}</div>
        ${foot}
        <footer class="hints">
            <span class="hint"><button data-rotate="-1" type="button">A</button><button data-rotate="1" type="button">E</button>Pivoter</span>
            <span class="hint end"><kbd>ESC</kbd>Fermer</span>
        </footer>
        <div id="toast" class="toast"></div>`;
}

function keepScroll(fn) {
    const scroll = document.querySelector('.s-body')?.scrollTop || 0;
    fn();
    const body = document.querySelector('.s-body');
    if (body) body.scrollTop = scroll;
}

function setZone(i) {
    state.zone = i;
    state.search = '';
    state.selected = null;
    confirmState.key = null;
    post('preview', { zone: zone().id, tattoo: null });
    render(true);
}

document.addEventListener('click', (e) => {
    if (!state.open) return;
    const t = e.target;
    if (t.closest('[data-close]')) return close();
    const z = t.closest('[data-zone]');
    if (z) return setZone(Number(z.dataset.zone));
    const card = t.closest('[data-tattoo]');
    if (card) {
        state.selected = card.dataset.tattoo;
        confirmState.key = null;
        post('preview', { zone: zone().id, tattoo: state.selected === 'none' ? null : state.selected });
        return keepScroll(() => render(false));
    }
    const r = t.closest('[data-rotate]');
    if (r) return post('rotate', { direction: Number(r.dataset.rotate) });
    const pay = t.closest('[data-pay]');
    if (pay && !pay.disabled) {
        const key = pay.dataset.pay;
        if (askConfirm(key, () => state.open && keepScroll(() => render(false)))) {
            post('buy', { zone: zone().id, tattoo: state.selected, method: key.split('|')[1] });
        }
        keepScroll(() => render(false));
    }
});

document.addEventListener('input', (e) => {
    if (e.target.id !== 't-search') return;
    state.search = e.target.value;
    const pos = e.target.selectionStart;
    render(false);
    const input = $('t-search');
    input.focus();
    input.setSelectionRange(pos, pos);
});

document.addEventListener('keydown', (e) => {
    if (!state.open) return;
    const typing = e.target.id === 't-search';
    const k = e.key.toLowerCase();
    if (k === 'escape') close();
    else if (!typing && k === 'backspace') close();
    else if (!typing && (k === 'a' || k === 'q')) post('rotate', { direction: -1 });
    else if (!typing && k === 'e') post('rotate', { direction: 1 });
    else return;
    e.preventDefault();
});

function open(data) {
    state.data = data || {};
    state.zone = 0;
    state.search = '';
    state.selected = null;
    state.open = true;
    confirmState.key = null;
    render(false);
    $('store').classList.remove('hidden');
}

function hide() {
    state.open = false;
    $('store').classList.add('hidden');
}

function close() {
    if (!state.open) return;
    hide();
    post('close');
}

window.addEventListener('message', (e) => {
    const msg = e.data || {};
    if (msg.action === 'open') open(msg.data);
    else if (msg.action === 'update' && state.open) { Object.assign(state.data, msg.data || {}); keepScroll(() => render(false)); }
    else if (msg.action === 'close') hide();
    else if (msg.action === 'toast' && state.open) toast(msg.message, msg.kind);
});

/* ---------- Aperçu hors jeu ---------- */

const names = ['Tribal Star', 'Rose Tribute', 'Ride or Die', 'Bad Luck', 'Engulfed Skull', 'Scorched Soul', 'Ride Free',
    'Bone Cruiser', 'Laughing Skull', 'Spider Outline', 'Spider Color', 'Patriot Skull', 'Stylized Tiger', 'Death Skull',
    'Rose Revolver', 'Love Fist', 'Tropical Serpent', 'Pineapple Skull', 'Glow Princess', 'Skull Waters', 'Soundwaves'];
const list = (prefix) => names.map((label, i) => ({ id: `${prefix}_${i}`, label }));

const DEMO = {
    title: 'Tatoueur', subtitle: 'Blazing Tattoo · Vinewood',
    money: { cash: 305, bank: 4200 },
    zones: [
        { id: 'head', label: 'Tête', icon: 'head', price: 300 },
        { id: 'torso', label: 'Torse', icon: 'torso', price: 400 },
        { id: 'left_arm', label: 'Bras G.', icon: 'arm', price: 250 },
        { id: 'right_arm', label: 'Bras D.', icon: 'arm', price: 250 },
        { id: 'left_leg', label: 'Jambe G.', icon: 'leg', price: 250 },
        { id: 'right_leg', label: 'Jambe D.', icon: 'leg', price: 250 },
    ],
    tattoos: { head: list('h'), torso: list('t'), left_arm: list('la'), right_arm: list('ra'), left_leg: list('ll'), right_leg: list('rl') },
    owned: { head: ['h_2'] },
};

function preview(name, data) {
    if (name === 'buy') {
        const z = DEMO.zones.find((x) => x.id === data.zone);
        DEMO.money[data.method === 'bank' ? 'bank' : 'cash'] -= z.price;
        (DEMO.owned[z.id] = DEMO.owned[z.id] || []).push(data.tattoo);
        Object.assign(state.data, JSON.parse(JSON.stringify({ money: DEMO.money, owned: DEMO.owned })));
        keepScroll(() => render(false));
        toast('Tatouage réalisé !', 'success');
    } else if (name === 'close') {
        setTimeout(() => open(JSON.parse(JSON.stringify(DEMO))), 800);
    }
}

if (!RESOURCE) open(JSON.parse(JSON.stringify(DEMO)));
