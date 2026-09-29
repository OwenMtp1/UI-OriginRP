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

/* ---------- Armurerie ---------- */

const ICONS = {
    logo: stroke('<path d="M3 9h14l2-2h2v4h-5l-1 2h-3l-1 3H7l1-4H3z"/><path d="M12 11v2"/>', 2.2),
    knife: stroke('<path d="M14.5 3.5 20 9l-9.5 9.5a2.1 2.1 0 0 1-3-3z"/><path d="m7.5 15.5-4 4"/><path d="M14.5 3.5 11 7"/>'),
    gun: stroke('<path d="M3 8h15l2-2h1v5h-6l-1 2h-3l-1 3H6l1-4H3z"/><path d="M12 11v2"/>'),
    ammo: stroke('<path d="M6 21V10a2 2 0 0 1 2-4h0a2 2 0 0 1 2 4v11z"/><path d="M14 21V10a2 2 0 0 1 2-4h0a2 2 0 0 1 2 4v11z"/><path d="M6 14h4M14 14h4"/>'),
    shield: stroke('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/>'),
    box: stroke('<path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="m3 8 9 5 9-5M12 13v8"/>'),
    minus: stroke('<path d="M5 12h14"/>', 2.4),
    plus: stroke('<path d="M12 5v14M5 12h14"/>', 2.4),
};

const state = { open: false, data: null, tab: 0, qty: {} };

const cats = () => state.data?.categories || [];
const cat = () => cats()[state.tab];
const items = () => (state.data?.items || []).filter((i) => i.category === cat()?.id);
const license = () => state.data?.license;
const locked = (c) => c?.license && license()?.required !== false && !license()?.owned;
const qtyOf = (item) => (item.stackable ? state.qty[item.id] || 1 : 1);

function licenseBanner() {
    const l = license();
    if (!l || l.required === false) return '';
    if (l.owned) {
        return `<div class="banner ok"><span class="banner-icon">${ICONS.shield}</span>
            <div class="banner-text"><strong>${esc(l.label || "Permis de port d'arme")} valide</strong><small>Tu peux acheter des armes à feu et des munitions.</small></div></div>`;
    }
    return `<div class="banner"><span class="banner-icon">${ICONS.shield}</span>
        <div class="banner-text"><strong>${esc(l.label || "Permis de port d'arme")} requis</strong>
            <small>Obligatoire pour les armes à feu et les munitions · <b>${fmtMoney(l.price)}</b></small></div>
        <div class="banner-pay">${payButtons('license', l.price, state.data.money)}</div></div>`;
}

function render(animate) {
    const d = state.data;
    const counts = {};
    (d.items || []).forEach((i) => { counts[i.category] = (counts[i.category] || 0) + 1; });

    const tabs = cats().map((c, i) => `
        <button class="s-tab${i === state.tab ? ' active' : ''}" data-tab="${i}" type="button">
            ${ICONS[c.icon] || ICONS.box}${esc(c.label)}${locked(c) ? `<span class="tab-lock">${COMMON_ICONS.lock}</span>` : `<em>${counts[c.id] || 0}</em>`}
        </button>`).join('');

    const list = items();
    const isLocked = locked(cat());
    const rows = list.length ? list.map((item) => {
        const qty = qtyOf(item);
        const total = item.price * qty;
        const right = isLocked
            ? `<span class="status">${COMMON_ICONS.lock}Permis requis</span>`
            : `${item.stackable ? `<div class="stepper">
                    <button data-qty="${esc(item.id)}" data-step="-1" type="button" ${qty <= 1 ? 'disabled' : ''}>${ICONS.minus}</button>
                    <span>×${qty}</span>
                    <button data-qty="${esc(item.id)}" data-step="1" type="button" ${qty >= (item.max || 10) ? 'disabled' : ''}>${ICONS.plus}</button>
                </div>` : ''}
                <span class="price">${fmtMoney(total)}</span>
                <div class="row-pay">${payButtons(`item:${item.id}`, total, d.money)}</div>`;
        return `
            <div class="item${isLocked ? ' locked' : ''}">
                <div class="item-icon">${ICONS[cat().icon] || ICONS.box}</div>
                <div class="item-main"><p>${esc(item.label)}</p><p>${esc(item.description || '')}</p></div>
                ${right}
            </div>`;
    }).join('') : `<div class="empty"><span class="circle">${ICONS[cat()?.icon] || ICONS.box}</span><p>Aucun article dans cette catégorie</p><p>Reviens plus tard, le stock est renouvelé régulièrement.</p></div>`;

    $('store').innerHTML = `
        ${headerHtml(ICONS.logo, d.title || 'Armurerie', d.subtitle, d.money, false)}
        ${licenseBanner()}
        <nav class="s-tabs">${tabs}</nav>
        <div class="s-body${animate ? ' slide' : ''}">${rows}</div>
        <div id="toast" class="toast"></div>`;
}

function handlePay(key) {
    const [what, method] = key.split('|');
    if (!askConfirm(key, () => state.open && render(false))) return render(false);
    if (what === 'license') {
        post('buyLicense', { method });
    } else {
        const item = items().find((i) => `item:${i.id}` === what);
        if (!item) return;
        post('buy', { id: item.id, quantity: qtyOf(item), method });
    }
    render(false);
}

document.addEventListener('click', (e) => {
    if (!state.open) return;
    const t = e.target;
    if (t.closest('[data-close]')) return close();
    const tab = t.closest('[data-tab]');
    if (tab) { state.tab = Number(tab.dataset.tab); confirmState.key = null; return render(true); }
    const q = t.closest('[data-qty]');
    if (q && !q.disabled) {
        const item = items().find((i) => i.id === q.dataset.qty);
        state.qty[item.id] = Math.max(1, Math.min(item.max || 10, qtyOf(item) + Number(q.dataset.step)));
        confirmState.key = null;
        return render(false);
    }
    const pay = t.closest('[data-pay]');
    if (pay && !pay.disabled) handlePay(pay.dataset.pay);
});

document.addEventListener('keydown', (e) => {
    if (!state.open) return;
    if (e.key === 'Escape' || e.key === 'Backspace') close();
    else if (e.key === 'ArrowRight' || e.key === 'Tab') { state.tab = (state.tab + 1) % cats().length; render(true); }
    else if (e.key === 'ArrowLeft') { state.tab = (state.tab - 1 + cats().length) % cats().length; render(true); }
    else return;
    e.preventDefault();
});

function open(data) {
    state.data = data || {};
    state.tab = 0;
    state.qty = {};
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
    title: 'Armurerie', subtitle: 'Ammu-Nation · Pillbox Hill',
    money: { cash: 305, bank: 4200 },
    license: { required: true, owned: false, price: 5000, label: "Permis de port d'arme" },
    categories: [
        { id: 'melee', label: 'Mêlée', icon: 'knife' },
        { id: 'firearms', label: 'Armes à feu', icon: 'gun', license: true },
        { id: 'ammo', label: 'Munitions', icon: 'ammo', license: true },
    ],
    items: [
        { id: 'knife', category: 'melee', label: 'Couteau', description: 'Lame de combat en acier', price: 150 },
        { id: 'bat', category: 'melee', label: 'Batte de baseball', description: 'Aluminium, poignée grip', price: 90 },
        { id: 'flashlight', category: 'melee', label: 'Lampe torche', description: 'Pratique la nuit', price: 45 },
        { id: 'knuckle', category: 'melee', label: 'Poing américain', description: 'Discret et efficace', price: 380 },
        { id: 'pistol', category: 'firearms', label: 'Pistolet', description: 'Semi-automatique, 9 mm', price: 2500 },
        { id: 'ammo_9mm', category: 'ammo', label: 'Munitions 9 mm', description: 'Boîte de 12 cartouches', price: 40, stackable: true, max: 10 },
    ],
};

function preview(name, data) {
    if (name === 'buyLicense') {
        const key = data.method === 'bank' ? 'bank' : 'cash';
        DEMO.money[key] -= DEMO.license.price;
        DEMO.license.owned = true;
        open(JSON.parse(JSON.stringify({ ...DEMO })));
        state.tab = 0; render(false);
        toast("Permis de port d'arme obtenu.", 'success');
    } else if (name === 'buy') {
        const item = DEMO.items.find((i) => i.id === data.id);
        const key = data.method === 'bank' ? 'bank' : 'cash';
        DEMO.money[key] -= item.price * data.quantity;
        state.data.money = { ...DEMO.money };
        render(false);
        toast(`${item.label}${data.quantity > 1 ? ` ×${data.quantity}` : ''} acheté.`, 'success');
    } else if (name === 'close') {
        setTimeout(() => open(JSON.parse(JSON.stringify(DEMO))), 800);
    }
}

if (!RESOURCE) {
    DEMO.money.cash = 3050;
    DEMO.money.bank = 8200;
    open(JSON.parse(JSON.stringify(DEMO)));
}
