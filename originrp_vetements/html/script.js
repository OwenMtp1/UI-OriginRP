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

/* ---------- Magasin de vêtements ---------- */

const ICONS = {
    logo: stroke('<path d="M20.4 3.5 16 2a4 4 0 0 1-8 0L3.6 3.5a2 2 0 0 0-1.3 2.2l.6 3.5a1 1 0 0 0 1 .8H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.2a1 1 0 0 0 1-.8l.6-3.5a2 2 0 0 0-1.4-2.2z"/>', 2.1),
    top: stroke('<path d="M20.4 3.5 16 2a4 4 0 0 1-8 0L3.6 3.5a2 2 0 0 0-1.3 2.2l.6 3.5a1 1 0 0 0 1 .8H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.2a1 1 0 0 0 1-.8l.6-3.5a2 2 0 0 0-1.4-2.2z"/>'),
    undershirt: stroke('<path d="M8 3v3a4 4 0 0 0 8 0V3M8 3 5 4v17h14V4l-3-1"/>'),
    pants: stroke('<path d="M6 3h12l1 18h-5l-2-11-2 11H5z"/><path d="M6 7h12"/>'),
    shoes: stroke('<path d="M3 17V9h5l3 3 6 1a4 4 0 0 1 4 4v1H3z"/><path d="M3 20h18"/>'),
    hat: stroke('<path d="M4 16a8 8 0 0 1 16 0"/><path d="M2 16h20v2H2z"/><path d="M12 8V5"/>'),
    gloves: stroke('<path d="M7 21v-6L4 11a1.5 1.5 0 0 1 2-2l2 2V4a1.5 1.5 0 0 1 3 0v5V3a1.5 1.5 0 0 1 3 0v6V4.5a1.5 1.5 0 0 1 3 0V15l-2 6z"/>'),
    bag: stroke('<path d="M5 8h14l-1 13H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>'),
    glasses: stroke('<circle cx="6" cy="15" r="4"/><circle cx="18" cy="15" r="4"/><path d="M10 15h4M2 15l2-7h3M22 15l-2-7h-3"/>'),
    prev: stroke('<path d="m15 5-7 7 7 7"/>', 2.4),
    next: stroke('<path d="m9 5 7 7-7 7"/>', 2.4),
};

const state = { open: false, data: null, tab: 0, selected: null }; // selected = { drawable, variant }

const cats = () => state.data?.categories || [];
const cat = () => cats()[state.tab];
const pad = (n) => String(n).padStart(2, '0');

// Articles d'une catégorie : liste explicite, ou générée depuis count / price
function items(c = cat()) {
    if (!c) return [];
    if (Array.isArray(c.items)) return c.items;
    return Array.from({ length: c.count || 0 }, (_, i) => ({ id: i, price: c.price, variants: c.variants }));
}

const itemLabel = (item) => item.label || `N° ${pad(item.id)}`;
const variantsOf = (item) => Math.max(1, Number(item.variants) || 1);

function render(animate) {
    const d = state.data;
    const c = cat();
    const list = items();
    const sel = state.selected;
    const selItem = sel && list.find((i) => i.id === sel.drawable);

    const tabs = cats().map((t, i) => `
        <button class="s-tab${i === state.tab ? ' active' : ''}" data-tab="${i}" type="button">${ICONS[t.icon] || ICONS.top}${esc(t.label)}</button>`).join('');

    const tiles = list.length ? list.map((item) => `
        <button class="tile${sel && sel.drawable === item.id ? ' active' : ''}" data-item="${esc(item.id)}" type="button">
            <span class="tile-media">${item.image ? `<img src="${esc(item.image)}" alt="" onerror="this.remove()">` : ''}${ICONS[c.icon] || ICONS.top}</span>
            <span class="tile-name">${esc(itemLabel(item))}</span>
            <span class="tile-price">${fmtMoney(item.price ?? c.price)}</span>
        </button>`).join('') : `<div class="empty"><span class="circle">${ICONS[c?.icon] || ICONS.top}</span><p>Rien en rayon pour le moment</p><p>Choisis une autre catégorie.</p></div>`;

    const price = selItem ? (selItem.price ?? c.price) : 0;
    const foot = selItem ? `
        <div class="s-foot">
            <div class="s-foot-top">
                <div class="s-foot-title"><small>${esc(c.label)}</small><strong>${esc(itemLabel(selItem))}</strong></div>
                ${variantsOf(selItem) > 1 ? `<div class="variants">
                    <button data-variant="-1" type="button">${ICONS.prev}</button>
                    <span>Couleur ${sel.variant + 1} / ${variantsOf(selItem)}</span>
                    <button data-variant="1" type="button">${ICONS.next}</button>
                </div>` : ''}
                <span class="price">${fmtMoney(price)}</span>
            </div>
            <div class="s-foot-pay">${payButtons(`${c.id}:${selItem.id}:${sel.variant}`, price, d.money, 'primary')}</div>
        </div>` : `
        <div class="s-foot idle"><p class="note">Clique sur un article pour l'essayer.</p></div>`;

    $('store').innerHTML = `
        ${headerHtml(ICONS.logo, d.title || 'Vêtements', d.subtitle, d.money, true)}
        <nav class="s-tabs grid">${tabs}</nav>
        <div class="section-label"><span>${esc(c?.label || '')}</span><strong>${list.length} modèle${list.length > 1 ? 's' : ''}</strong></div>
        <div class="s-body${animate ? ' slide' : ''}"><div class="tiles">${tiles}</div></div>
        ${foot}
        <footer class="hints">
            <span class="hint"><button data-rotate="-1" type="button">A</button><button data-rotate="1" type="button">E</button>Pivoter</span>
            <span class="hint end"><kbd>ESC</kbd>Fermer</span>
        </footer>
        <div id="toast" class="toast"></div>`;
}

function select(drawable, variant = 0) {
    state.selected = { drawable, variant };
    confirmState.key = null;
    post('preview', { category: cat().id, drawable, variant });
    const scroll = document.querySelector('.s-body')?.scrollTop || 0;
    render(false);
    document.querySelector('.s-body').scrollTop = scroll;
}

function setTab(i) {
    state.tab = i;
    state.selected = null;
    confirmState.key = null;
    post('preview', { category: null }); // remet la tenue d'origine
    render(true);
}

document.addEventListener('click', (e) => {
    if (!state.open) return;
    const t = e.target;
    if (t.closest('[data-close]')) return close();
    const tab = t.closest('[data-tab]');
    if (tab) return setTab(Number(tab.dataset.tab));
    const tile = t.closest('[data-item]');
    if (tile) {
        const item = items().find((i) => String(i.id) === tile.dataset.item);
        return select(item.id, 0);
    }
    const v = t.closest('[data-variant]');
    if (v && state.selected) {
        const item = items().find((i) => i.id === state.selected.drawable);
        const n = variantsOf(item);
        return select(item.id, (state.selected.variant + Number(v.dataset.variant) + n) % n);
    }
    const r = t.closest('[data-rotate]');
    if (r) return post('rotate', { direction: Number(r.dataset.rotate) });
    const pay = t.closest('[data-pay]');
    if (pay && !pay.disabled) {
        const key = pay.dataset.pay;
        const scroll = document.querySelector('.s-body')?.scrollTop || 0;
        if (askConfirm(key, () => state.open && render(false))) {
            const [, method] = key.split('|');
            post('buy', { category: cat().id, drawable: state.selected.drawable, variant: state.selected.variant, method });
        }
        render(false);
        document.querySelector('.s-body').scrollTop = scroll;
    }
});

document.addEventListener('keydown', (e) => {
    if (!state.open) return;
    const k = e.key.toLowerCase();
    if (k === 'escape' || k === 'backspace') close();
    else if (k === 'a' || k === 'q') post('rotate', { direction: -1 });
    else if (k === 'e') post('rotate', { direction: 1 });
    else return;
    e.preventDefault();
});

function open(data) {
    state.data = data || {};
    state.tab = 0;
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
    else if (msg.action === 'update' && state.open) { Object.assign(state.data, msg.data || {}); render(false); }
    else if (msg.action === 'close') hide();
    else if (msg.action === 'toast' && state.open) toast(msg.message, msg.kind);
});

/* ---------- Aperçu hors jeu ---------- */

const DEMO = {
    title: 'Vêtements', subtitle: 'Binco · Textile City',
    money: { cash: 305, bank: 4200 },
    categories: [
        { id: 'tops', label: 'Haut', icon: 'top', count: 40, price: 120, variants: 5 },
        { id: 'undershirt', label: 'Sous-vêt.', icon: 'undershirt', count: 20, price: 60, variants: 3 },
        { id: 'pants', label: 'Pantalon', icon: 'pants', count: 30, price: 90, variants: 4 },
        { id: 'shoes', label: 'Chaussures', icon: 'shoes', count: 25, price: 80, variants: 3 },
        { id: 'hats', label: 'Couvre-chef', icon: 'hat', count: 15, price: 45, variants: 2 },
        { id: 'gloves', label: 'Gants', icon: 'gloves', count: 10, price: 35 },
        { id: 'bags', label: 'Sac', icon: 'bag', count: 8, price: 150, variants: 2 },
        { id: 'glasses', label: 'Lunettes', icon: 'glasses', count: 12, price: 55, variants: 4 },
    ],
};

function preview(name, data) {
    if (name === 'buy') {
        const c = DEMO.categories.find((x) => x.id === data.category);
        DEMO.money[data.method === 'bank' ? 'bank' : 'cash'] -= c.price;
        state.data.money = { ...DEMO.money };
        render(false);
        toast(`${c.label} N° ${pad(data.drawable)} acheté.`, 'success');
    } else if (name === 'close') {
        setTimeout(() => open(JSON.parse(JSON.stringify(DEMO))), 800);
    }
}

if (!RESOURCE) open(JSON.parse(JSON.stringify(DEMO)));
