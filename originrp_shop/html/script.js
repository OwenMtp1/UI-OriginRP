'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
const $ = (id) => document.getElementById(id);

const stroke = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;

const ICONS = {
    home: stroke('<path d="m3 10 9-7 9 7v10a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>'),
    history: stroke('<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>'),
    car: stroke('<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>'),
    weapon: stroke('<path d="M3 8h15l2-2h1v5h-6l-1 2h-3l-1 3H6l1-4H3z"/><path d="M12 11v2"/>'),
    box: stroke('<path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="m3 8 9 5 9-5M12 13v8"/>'),
    crown: stroke('<path d="M3 8l4.5 4L12 5l4.5 7L21 8l-2 11H5z"/>'),
    bag: stroke('<path d="M6 7h12l-1 13H7z"/><path d="M9 7V5a3 3 0 0 1 6 0v2"/>'),
};

const state = {
    open: false,
    catalog: { title: '', subtitle: '', currency: { name: 'Orins', short: 'OR' }, categories: [], items: [] },
    player: { balance: 0, vip: null, history: [], purchases: 0 },
    tab: 'home',
    search: '',
    sort: 'default',
    pending: null, // article en cours de confirmation
};

/* ---------- Utilitaires ---------- */

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text == null ? '' : String(text);
    return div.innerHTML;
}

const fmt = (n) => Number(n || 0).toLocaleString('fr-FR');
const unit = () => state.catalog.currency?.short || 'OR';
const categoryOf = (id) => state.catalog.categories.find((c) => c.id === id);

function post(name, data = {}) {
    if (!RESOURCE) return Promise.resolve(preview(name, data));
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

let toastTimer = null;
function toast(message, kind = '') {
    const node = $('toast');
    node.textContent = message;
    node.className = `toast show ${kind}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => node.classList.remove('show'), 2800);
}

/* ---------- Rendu ---------- */

function renderSidebar() {
    const counts = {};
    state.catalog.items.forEach((i) => { counts[i.category] = (counts[i.category] || 0) + 1; });
    const tabs = [
        { id: 'home', label: 'Accueil', icon: ICONS.home },
        ...state.catalog.categories.map((c) => ({ id: `cat:${c.id}`, label: c.label, icon: ICONS[c.icon] || ICONS.box, count: counts[c.id] || 0 })),
        { id: 'history', label: 'Historique', icon: ICONS.history },
    ];
    $('sidebar').innerHTML = tabs.map((t) => `
        <button class="tab${state.tab === t.id ? ' active' : ''}" data-tab="${t.id}" type="button">
            ${t.icon}<span>${escapeHtml(t.label)}</span>${t.count != null ? `<em class="tab-count">${t.count}</em>` : ''}
        </button>`).join('') + `
        <div class="sidebar-foot"><span class="live-dot"></span><span>Boutique en ligne</span></div>`;
}

function renderHeader() {
    const { catalog, player } = state;
    $('shop-title').textContent = catalog.title || '';
    $('shop-subtitle').textContent = catalog.subtitle || '';
    ['coin-top', 'coin-stat'].forEach((id) => { $(id).textContent = unit().slice(0, 2); });
    $('balance-top').textContent = fmt(player.balance);
    $('unit-top').textContent = unit();
    $('stat-balance').textContent = `${fmt(player.balance)} ${unit()}`;
    $('stat-vip').textContent = player.vip ? `${player.vip.label}${player.vip.expires ? ` · ${player.vip.expires}` : ''}` : 'Aucun VIP actif';
    $('stat-purchases').textContent = fmt(player.purchases ?? player.history?.length);
}

function cardHtml(item, showCategory) {
    const poor = state.player.balance < item.price;
    const cat = categoryOf(item.category);
    const media = item.image
        ? `<img src="${escapeHtml(item.image)}" alt="" onerror="this.remove()">`
        : '';
    return `
        <article class="card${poor ? ' poor' : ''}">
            <div class="card-media">
                ${ICONS[cat?.icon] || ICONS.box}${media}
                ${item.tag ? `<span class="card-tag">${escapeHtml(item.tag)}</span>` : ''}
                ${showCategory && cat ? `<span class="card-cat">${escapeHtml(cat.label)}</span>` : ''}
            </div>
            <div class="card-body">
                <p class="card-title">${escapeHtml(item.label)}</p>
                <p class="card-desc">${escapeHtml(item.description || '')}</p>
                <div class="card-foot">
                    <span class="price"><span class="coin sm">${escapeHtml(unit().slice(0, 2))}</span>${fmt(item.price)} <small>${escapeHtml(unit())}</small></span>
                    <button class="btn ${poor ? 'btn-ghost' : 'btn-primary'}" data-buy="${escapeHtml(item.id)}" type="button">${poor ? 'Solde insuffisant' : 'Acheter'}</button>
                </div>
            </div>
        </article>`;
}

function renderFeatured() {
    const items = state.catalog.items.filter((i) => i.featured);
    $('featured').className = items.length ? 'grid' : '';
    $('featured').innerHTML = items.length
        ? items.map((i) => cardHtml(i, true)).join('')
        : '<div class="empty-box">Aucun article à la une.</div>';
}

function renderCategory() {
    const id = state.tab.slice(4);
    const cat = categoryOf(id);
    if (!cat) return;
    const search = state.search.trim().toLowerCase();
    let items = state.catalog.items.filter((i) => i.category === id);
    $('cat-title').textContent = cat.label;
    $('cat-subtitle').textContent = `${items.length} article${items.length > 1 ? 's' : ''} disponible${items.length > 1 ? 's' : ''}`;
    items = items.filter((i) => !search || `${i.label} ${i.description || ''}`.toLowerCase().includes(search));
    if (state.sort === 'asc') items.sort((a, b) => a.price - b.price);
    if (state.sort === 'desc') items.sort((a, b) => b.price - a.price);
    $('cat-grid').className = items.length ? 'grid' : '';
    $('cat-grid').innerHTML = items.length
        ? items.map((i) => cardHtml(i, false)).join('')
        : '<div class="empty-box">Aucun article trouvé.</div>';
}

function renderHistory() {
    const list = state.player.history || [];
    $('history').innerHTML = list.length ? list.map((h) => `
        <div class="history-row">
            <div class="history-icon">${ICONS.bag}</div>
            <div class="history-main"><p>${escapeHtml(h.label)}</p><p>${escapeHtml(h.date || '')}</p></div>
            <span class="history-price">−${fmt(h.price)} ${escapeHtml(unit())}</span>
        </div>`).join('') : '<div class="empty-box">Aucun achat pour le moment.</div>';
}

function renderAll() {
    renderSidebar();
    renderHeader();
    renderFeatured();
    renderCategory();
    renderHistory();
}

function setTab(tab) {
    state.tab = tab;
    state.search = '';
    $('search').value = '';
    const panel = tab.startsWith('cat:') ? 'category' : tab;
    document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('active', p.id === `panel-${panel}`));
    renderSidebar();
    if (panel === 'category') renderCategory();
}

/* ---------- Confirmation d'achat ---------- */

function askBuy(id) {
    const item = state.catalog.items.find((i) => i.id === id);
    if (!item) return;
    if (state.player.balance < item.price) {
        toast(`Il te manque ${fmt(item.price - state.player.balance)} ${unit()}.`, 'error');
        return;
    }
    state.pending = item;
    const cat = categoryOf(item.category);
    const after = state.player.balance - item.price;
    $('confirm-item').innerHTML = `
        <div class="history-icon">${ICONS[cat?.icon] || ICONS.box}</div>
        <div class="history-main"><p>${escapeHtml(item.label)}</p><p>${escapeHtml(cat?.label || '')}</p></div>`;
    $('confirm-lines').innerHTML = `
        <div><span>Solde actuel</span><strong>${fmt(state.player.balance)} ${unit()}</strong></div>
        <div><span>Prix</span><strong>−${fmt(item.price)} ${unit()}</strong></div>
        <div class="total${after < 0 ? ' bad' : ''}"><span>Solde après achat</span><strong>${fmt(after)} ${unit()}</strong></div>`;
    $('modal').classList.add('show');
}

function closeModal() {
    state.pending = null;
    $('modal').classList.remove('show');
}

/* ---------- Ouverture / fermeture ---------- */

function openShop(msg) {
    if (msg.catalog) state.catalog = { ...state.catalog, ...msg.catalog };
    if (msg.state) state.player = { ...state.player, ...msg.state };
    state.open = true;
    closeModal();
    setTab('home');
    renderAll();
    $('tablet').classList.remove('hidden');
}

function hideShop() {
    state.open = false;
    closeModal();
    $('tablet').classList.add('hidden');
}

function closeShop() {
    if (!state.open) return;
    hideShop();
    post('close');
}

function openUrl(url) {
    if (!url) return;
    if (typeof window.invokeNative === 'function') window.invokeNative('openUrl', url);
    else window.open(url, '_blank');
}

/* ---------- Événements ---------- */

$('sidebar').addEventListener('click', (event) => {
    const tab = event.target.closest('[data-tab]');
    if (tab) setTab(tab.dataset.tab);
});

document.querySelector('.content').addEventListener('click', (event) => {
    const buy = event.target.closest('[data-buy]');
    if (buy) return askBuy(buy.dataset.buy);
});

// Recharger : ne mène nulle part pour l'instant (voir Config.RechargeUrl / l'événement
// client originrp_shop:recharge pour le brancher plus tard)
$('btn-recharge').addEventListener('click', () => {
    if (state.catalog.rechargeUrl) return openUrl(state.catalog.rechargeUrl);
    post('recharge');
    toast('La recharge d\'Orins sera bientôt disponible.');
});
$('btn-close').addEventListener('click', closeShop);
$('search').addEventListener('input', (e) => { state.search = e.target.value; renderCategory(); });
$('sort').addEventListener('change', (e) => { state.sort = e.target.value; renderCategory(); });
$('confirm-cancel').addEventListener('click', closeModal);
$('modal').addEventListener('click', (e) => { if (e.target === $('modal')) closeModal(); });
$('confirm-ok').addEventListener('click', () => {
    if (!state.pending) return;
    post('buy', { id: state.pending.id });
    closeModal();
});

document.addEventListener('keydown', (event) => {
    if (!state.open || event.key !== 'Escape') return;
    if ($('modal').classList.contains('show')) closeModal();
    else closeShop();
});

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    switch (msg.action) {
        case 'open':
            openShop(msg);
            break;
        case 'update':
            state.player = { ...state.player, ...(msg.state || {}) };
            renderAll();
            break;
        case 'close':
            hideShop();
            break;
        case 'toast':
            toast(msg.message, msg.kind);
            break;
    }
});

/* ---------- Aperçu hors jeu ---------- */

const DEMO = {
    catalog: {
        title: 'Boutique OriginRP',
        subtitle: 'Dépense tes Orins en véhicules, armes, packs et VIP',
        currency: { name: 'Orins', short: 'OR' },
        categories: [
            { id: 'vehicles', label: 'Véhicules', icon: 'car' },
            { id: 'weapons', label: 'Armes', icon: 'weapon' },
            { id: 'packs', label: 'Packs', icon: 'box' },
            { id: 'vip', label: 'VIP', icon: 'crown' },
        ],
        items: [
            { id: 'sultanrs', category: 'vehicles', label: 'Karin Sultan RS', description: 'Sportive 4 portes, idéale en ville.', price: 1500, tag: 'Nouveau', featured: true },
            { id: 'comet', category: 'vehicles', label: 'Pfister Comet', description: 'Coupé sport classique.', price: 2200 },
            { id: 'pistol', category: 'weapons', label: 'Pistolet', description: 'Arme de poing + 50 munitions.', price: 600 },
            { id: 'starter', category: 'packs', label: 'Pack Démarrage', description: '25 000 $ + téléphone + kit de soin.', price: 800, featured: true },
            { id: 'vip_gold', category: 'vip', label: 'VIP Gold · 30 jours', description: 'Salaire +20 %, garage étendu, tenue exclusive.', price: 1200, tag: 'Populaire', featured: true },
        ],
    },
    state: {
        balance: 1850,
        vip: null,
        history: [{ label: 'Pack Démarrage', price: 800, date: '25/09/2026 21:14' }],
        purchases: 1,
    },
};

function preview(name, data) {
    if (name !== 'buy') return;
    const item = DEMO.catalog.items.find((i) => i.id === data.id);
    if (!item || DEMO.state.balance < item.price) return toast('Solde insuffisant.', 'error');
    DEMO.state.balance -= item.price;
    DEMO.state.history.unshift({ label: item.label, price: item.price, date: new Date().toLocaleString('fr-FR').slice(0, 16) });
    DEMO.state.purchases += 1;
    if (item.category === 'vip') DEMO.state.vip = { label: 'VIP Gold', expires: '27/10/2026' };
    state.player = JSON.parse(JSON.stringify(DEMO.state));
    renderAll();
    toast(`${item.label} acheté !`, 'success');
}

if (!RESOURCE && !location.hash.startsWith('#admin')) {
    openShop(JSON.parse(JSON.stringify(DEMO)));
    const hash = location.hash.slice(1);
    if (hash) setTab(hash === 'history' ? 'history' : `cat:${hash}`);
}
