'use strict';

/* Gestion interne de la boutique (tablette admin) */
(() => {
    const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
    const $ = (id) => document.getElementById(id);
    const svg = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;

    const I = {
        dashboard: svg('<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>'),
        settings: svg('<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>'),
        car: svg('<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>'),
        weapon: svg('<path d="M3 8h15l2-2h1v5h-6l-1 2h-3l-1 3H6l1-4H3z"/><path d="M12 11v2"/>'),
        box: svg('<path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="m3 8 9 5 9-5M12 13v8"/>'),
        crown: svg('<path d="M3 8l4.5 4L12 5l4.5 7L21 8l-2 11H5z"/>'),
        coins: svg('<circle cx="12" cy="12" r="9"/><path d="M14.5 9.5c-.5-1-1.5-1.5-2.5-1.5-1.7 0-3 1-3 2.2 0 2.8 6 1.5 6 4.3 0 1.3-1.3 2.3-3 2.3-1.1 0-2.2-.6-2.7-1.6M12 6v2M12 16.8V18"/>'),
        users: svg('<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20v-.5A5.5 5.5 0 0 1 8 14h2a5.5 5.5 0 0 1 5.5 5.5v.5"/><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8"/><path d="M18.5 14.2a5.5 5.5 0 0 1 3 4.8v1"/>'),
        bag: svg('<path d="M6 7h12l-1 13H7z"/><path d="M9 7V5a3 3 0 0 1 6 0v2"/>'),
        refund: svg('<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>'),
        link: svg('<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>'),
        alert: svg('<path d="M10.3 3.9 2.4 17.5A2 2 0 0 0 4.1 20.5h15.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9.5v4M12 17h.01"/>'),
        plus: svg('<path d="M12 5v14M5 12h14"/>'),
        search: svg('<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>'),
        chevron: '<svg class="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 5 7 7-7 7"/></svg>',
        close: svg('<path d="M6 6l12 12M18 6 6 18"/>'),
        star: svg('<path d="M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6-4.9-4.6 6.6-.8z"/>'),
        reset: svg('<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>'),
    };

    const A = {
        open: false,
        data: { settings: {}, categories: [], items: [], packs: [], stats: {}, breakdown: {}, recentOrders: [], recentMoves: [], players: [] },
        tab: 'dashboard',
        drawer: null,     // { type: 'item', id } | { type: 'newItem', category } | { type: 'pack', index } | { type: 'newPack' } | { type: 'player' }
        confirm: null,    // fonction à exécuter si l'admin confirme
        query: '',
    };

    /* ---------- Utilitaires ---------- */

    const esc = (t) => { const d = document.createElement('div'); d.textContent = t == null ? '' : String(t); return d.innerHTML; };
    const fmt = (n) => Number(n || 0).toLocaleString('fr-FR');
    const unit = () => A.data.settings.currencyShort || 'OR';
    const cat = (id) => A.data.categories.find((c) => c.id === id);
    const initials = (n) => String(n || '?').trim().split(/\s+/).slice(0, 2).map((w) => w[0]).join('').toUpperCase();

    function action(name, payload = {}) {
        if (!RES) return demoAction(name, payload);
        fetch(`https://${RES}/adminAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ action: name, payload }),
        }).catch(() => {});
    }

    let toastTimer = null;
    function toast(message, kind = '') {
        const node = $('a-toast');
        node.textContent = message;
        node.className = `toast show ${kind}`;
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => node.classList.remove('show'), 2800);
    }

    function askConfirm(title, text, fn) {
        $('a-modal-title').textContent = title;
        $('a-modal-text').textContent = text;
        A.confirm = fn;
        $('a-modal').classList.add('show');
    }

    function closeConfirm() {
        A.confirm = null;
        $('a-modal').classList.remove('show');
    }

    /* ---------- Menu latéral ---------- */

    function tabs() {
        const counts = {};
        A.data.items.forEach((i) => { counts[i.category] = (counts[i.category] || 0) + 1; });
        return [
            { id: 'dashboard', label: 'Tableau de bord', icon: I.dashboard },
            { id: 'settings', label: 'Configuration', icon: I.settings },
            ...A.data.categories.map((c) => ({ id: `cat:${c.id}`, label: c.label, icon: I[c.icon] || I.box, count: counts[c.id] || 0 })),
            { id: 'packs', label: "Packs d'Orins", icon: I.coins, count: A.data.packs.length },
            { id: 'players', label: 'Joueurs', icon: I.users },
        ];
    }

    function renderSidebar() {
        const s = A.data.settings;
        $('a-sidebar').innerHTML = tabs().map((t) => `
            <button class="tab${A.tab === t.id ? ' active' : ''}" data-tab="${t.id}" type="button">
                ${t.icon}<span>${esc(t.label)}</span>${t.count != null ? `<em class="tab-count">${t.count}</em>` : ''}
            </button>`).join('') + `
            <div class="sidebar-foot"><span class="live-dot" style="${s.open === false ? 'background:#f07575' : ''}"></span><span>${s.open === false ? 'Boutique fermée' : 'Boutique ouverte'}</span></div>`;
    }

    /* ---------- Tableau de bord ---------- */

    function kpi(label, value, icon, cls = '') {
        return `<div class="kpi ${cls}"><div class="kpi-top"><div class="stat-icon">${icon}</div></div>
            <div><p class="kpi-value">${esc(value)}</p><p class="kpi-label" style="margin-top:6px">${esc(label)}</p></div></div>`;
    }

    function dashboard() {
        const d = A.data;
        const s = d.stats || {};
        const breakdown = d.breakdown || {};
        const total = Object.values(breakdown).reduce((a, b) => a + (Number(b) || 0), 0);
        const bars = d.categories.map((c) => {
            const n = Number(breakdown[c.id]) || 0;
            const pct = total ? Math.round((n / total) * 100) : 0;
            return `<div class="bar-row"><span class="name">${I[c.icon] || I.box}${esc(c.label)}</span>
                <div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div>
                <span class="count">${fmt(n)}<small>${pct}%</small></span></div>`;
        }).join('');

        const statusLabel = { ok: 'Crédité', pending: 'En attente', refunded: 'Remboursé' };
        const orders = (d.recentOrders || []).map((o) => `
            <div class="mini-row">
                <div class="mini-main"><p>${esc(o.player)} · ${esc(o.label)}</p><p>${esc(o.date || '')}${o.price ? ` · ${esc(o.price)}` : ''}</p></div>
                <span class="status ${esc(o.status || 'ok')}">${esc(statusLabel[o.status] || statusLabel.ok)}</span>
            </div>`).join('') || '<p class="muted-empty">Aucune commande récente.</p>';

        const moves = (d.recentMoves || []).map((m) => {
            const plus = Number(m.amount) >= 0;
            return `<div class="mini-row">
                <div class="mini-main"><p>${esc(m.player)} · ${esc(m.label)}</p><p>${esc(m.date || '')}</p></div>
                <span class="amount ${plus ? 'plus' : 'minus'}">${plus ? '+' : '−'}${fmt(Math.abs(m.amount))} ${esc(unit())}</span>
            </div>`;
        }).join('') || '<p class="muted-empty">Aucun mouvement récent.</p>';

        return `
            <div class="panel-top">
                <div class="panel-head"><h2>Tableau de bord</h2><p>Statistiques depuis le ${esc(d.since || '-')}</p></div>
                <button class="btn btn-danger" data-act="reset" type="button">${I.reset}Réinitialiser les statistiques</button>
            </div>
            <div class="kpis">
                ${kpi(`${d.settings.currencyName || 'Orins'} vendus`, fmt(s.orinsSold), I.coins, 'accent')}
                ${kpi('Commandes traitées', fmt(s.orders), I.bag)}
                ${kpi('Remboursements', fmt(s.refunds), I.refund, s.refunds ? 'warn' : '')}
                ${kpi('En attente de compte', fmt(s.pendingAccounts), I.link, s.pendingAccounts ? 'warn' : '')}
                ${kpi('Achats en jeu', fmt(s.ingamePurchases), I.box)}
                ${kpi(`${d.settings.currencyName || 'Orins'} dépensés`, fmt(s.orinsSpent), I.coins, 'accent')}
                ${kpi('VIP actifs', fmt(s.vipActive), I.crown)}
                ${kpi('Soldes négatifs', fmt(s.negativeBalances), I.alert, s.negativeBalances ? 'warn' : '')}
            </div>
            <div class="block">
                <div class="block-head"><h3>Répartition des achats</h3><span>${fmt(total)} achat${total > 1 ? 's' : ''}</span></div>
                <div class="bars">${bars}</div>
            </div>
            <div class="two-cols">
                <div class="block"><div class="block-head"><h3>Commandes récentes</h3><span>Site</span></div>${orders}</div>
                <div class="block"><div class="block-head"><h3>Mouvements récents</h3><span>${esc(unit())}</span></div>${moves}</div>
            </div>`;
    }

    /* ---------- Configuration ---------- */

    function settingsPanel() {
        const s = A.data.settings;
        return `
            <div class="panel-head"><h2>Configuration</h2><p>Réglages généraux de la boutique joueur.</p></div>
            <div class="block">
                <div class="form-grid">
                    <div class="full">
                        <label class="toggle-row">
                            <span>Boutique ouverte<small>Fermée, les joueurs ne peuvent plus l'ouvrir ni acheter.</small></span>
                            <input id="s-open" type="checkbox" ${s.open !== false ? 'checked' : ''}><i class="switch"></i>
                        </label>
                    </div>
                    <div><label class="field-label" for="s-title">Nom de la boutique</label><input id="s-title" class="input" value="${esc(s.title)}" maxlength="40"></div>
                    <div><label class="field-label" for="s-subtitle">Sous-titre</label><input id="s-subtitle" class="input" value="${esc(s.subtitle)}" maxlength="80"></div>
                    <div class="full"><label class="field-label" for="s-url">Lien d'achat des Orins</label><input id="s-url" class="input" value="${esc(s.buyUrl)}" placeholder="https://…"><p class="hint-text">Ouvert dans le navigateur du joueur depuis l'accueil de la boutique.</p></div>
                    <div><label class="field-label" for="s-cname">Nom de la monnaie</label><input id="s-cname" class="input" value="${esc(s.currencyName)}" maxlength="20"></div>
                    <div><label class="field-label" for="s-cshort">Abréviation</label><input id="s-cshort" class="input" value="${esc(s.currencyShort)}" maxlength="4"></div>
                </div>
                <div class="form-actions"><button class="btn btn-primary" data-act="save-settings" type="button">Enregistrer</button></div>
            </div>`;
    }

    /* ---------- Articles d'une catégorie ---------- */

    function categoryPanel(id) {
        const c = cat(id);
        const items = A.data.items.filter((i) => i.category === id);
        const rows = items.map((i) => `
            <div class="edit-row" data-item="${esc(i.id)}">
                <div class="history-icon">${I[c?.icon] || I.box}</div>
                <div class="history-main"><p>${esc(i.label)}</p><p>${esc(i.description || 'Sans description')}</p></div>
                <div class="row-badges">
                    ${i.featured ? `<span class="mini-chip violet">${I.star.replace('<svg', '<svg width="11" height="11"')}À la une</span>` : ''}
                    ${i.tag ? `<span class="mini-chip">${esc(i.tag)}</span>` : ''}
                    <span class="price"><span class="coin sm">${esc(unit().slice(0, 2))}</span>${fmt(i.price)}</span>
                </div>
                ${I.chevron}
            </div>`).join('') || '<div class="empty-box">Aucun article dans cette catégorie.</div>';
        return `
            <div class="panel-top">
                <div class="panel-head"><h2>${esc(c?.label || '')}</h2><p>${items.length} article${items.length > 1 ? 's' : ''} en vente</p></div>
                <button class="btn btn-primary" data-act="new-item" data-cat="${esc(id)}" type="button">${I.plus}Ajouter un article</button>
            </div>
            <div style="margin-top:16px">${rows}</div>`;
    }

    /* ---------- Packs d'Orins ---------- */

    function packsPanel() {
        const rows = A.data.packs.map((p, index) => `
            <div class="edit-row" data-pack="${index}">
                <span class="coin" style="width:40px;height:40px;font-size:12px">${esc(unit().slice(0, 2))}</span>
                <div class="history-main"><p>${fmt(p.amount)} ${esc(unit())}</p><p>${esc(p.price || '')}</p></div>
                <div class="row-badges">
                    ${p.popular ? '<span class="mini-chip violet">Populaire</span>' : ''}
                    ${p.bonus ? `<span class="mini-chip">${esc(p.bonus)}</span>` : ''}
                </div>
                ${I.chevron}
            </div>`).join('') || '<div class="empty-box">Aucun pack configuré.</div>';
        return `
            <div class="panel-top">
                <div class="panel-head"><h2>Packs d'Orins</h2><p>Affichés sur l'accueil de la boutique, achetés sur le site.</p></div>
                <button class="btn btn-primary" data-act="new-pack" type="button">${I.plus}Ajouter un pack</button>
            </div>
            <div style="margin-top:16px">${rows}</div>`;
    }

    /* ---------- Joueurs ---------- */

    function playersPanel() {
        const list = A.data.players || [];
        const rows = list.map((p) => `
            <div class="edit-row" data-player="${esc(p.id)}">
                <div class="history-icon" style="font-weight:700;color:#d4d4d8">${esc(initials(p.name))}<span class="online-dot${p.online ? ' on' : ''}"></span></div>
                <div class="history-main"><p>${esc(p.name)}</p><p>${esc(p.id)}</p></div>
                <div class="row-badges">
                    ${p.vip ? `<span class="mini-chip violet">${esc(p.vip)}</span>` : ''}
                    <span class="amount ${Number(p.balance) < 0 ? 'minus' : ''}">${fmt(p.balance)} ${esc(unit())}</span>
                </div>
                ${I.chevron}
            </div>`).join('');
        return `
            <div class="panel-head"><h2>Joueurs</h2><p>Recherche un joueur pour voir son solde et le modifier.</p></div>
            <div class="toolbar">
                <label class="search">${I.search}<input id="p-search" type="text" placeholder="Nom, ID ou licence…" value="${esc(A.query)}" autocomplete="off"></label>
                <button class="btn btn-ghost" data-act="search" type="button">Rechercher</button>
            </div>
            ${rows || `<div class="empty-box">${A.query ? 'Aucun joueur trouvé.' : 'Lance une recherche pour afficher des joueurs.'}</div>`}`;
    }

    /* ---------- Volet d'édition ---------- */

    function drawerHead(icon, title, sub) {
        return `<div class="drawer-head"><div class="history-icon" style="width:48px;height:48px">${icon}</div>
            <div><p class="drawer-title">${esc(title)}</p><p class="drawer-sub">${esc(sub)}</p></div>
            <button class="icon-btn" data-close-drawer type="button" aria-label="Fermer">${I.close}</button></div>`;
    }

    function itemDrawer(item, category) {
        const isNew = !item;
        const c = cat(item?.category || category);
        return `${drawerHead(I[c?.icon] || I.box, isNew ? 'Nouvel article' : item.label, c?.label || '')}
            <div class="drawer-body"><div class="form-grid">
                <div class="full"><label class="field-label" for="i-label">Nom</label><input id="i-label" class="input" value="${esc(item?.label || '')}" maxlength="48"></div>
                <div><label class="field-label" for="i-id">Identifiant</label><input id="i-id" class="input" value="${esc(item?.id || '')}" ${isNew ? '' : 'disabled'} placeholder="ex. sultanrs"></div>
                <div><label class="field-label" for="i-price">Prix (${esc(unit())})</label><input id="i-price" class="input" type="number" min="0" value="${esc(item?.price ?? '')}"></div>
                <div class="full"><label class="field-label" for="i-desc">Description</label><textarea id="i-desc" class="input" maxlength="140">${esc(item?.description || '')}</textarea></div>
                <div><label class="field-label" for="i-tag">Étiquette</label><input id="i-tag" class="input" value="${esc(item?.tag || '')}" maxlength="16" placeholder="Nouveau, -20 %…"></div>
                <div><label class="field-label" for="i-image">Image</label><input id="i-image" class="input" value="${esc(item?.image || '')}" placeholder="img/… ou https://…"></div>
                <div class="full"><label class="toggle-row"><span>À la une<small>Affiché sur l'accueil de la boutique.</small></span>
                    <input id="i-featured" type="checkbox" ${item?.featured ? 'checked' : ''}><i class="switch"></i></label></div>
                <div class="full"><label class="field-label" for="i-data">Données de livraison (JSON)</label>
                    <textarea id="i-data" class="input mono" placeholder='{"model": "sultanrs"}'>${esc(item?.data ? JSON.stringify(item.data) : '')}</textarea>
                    <p class="hint-text">Lu par le serveur pour livrer l'article (modèle, arme, durée VIP…).</p></div>
            </div></div>
            <div class="drawer-foot">
                <button class="btn btn-primary" data-act="save-item" type="button">${isNew ? "Créer l'article" : 'Enregistrer'}</button>
                ${isNew ? '' : '<button class="btn btn-danger" data-act="delete-item" type="button">Supprimer l\'article</button>'}
            </div>`;
    }

    function packDrawer(pack) {
        const isNew = !pack;
        return `${drawerHead(`<span class="coin">${esc(unit().slice(0, 2))}</span>`, isNew ? 'Nouveau pack' : `${fmt(pack.amount)} ${unit()}`, "Pack d'Orins")}
            <div class="drawer-body"><div class="form-grid">
                <div><label class="field-label" for="k-amount">Quantité (${esc(unit())})</label><input id="k-amount" class="input" type="number" min="1" value="${esc(pack?.amount ?? '')}"></div>
                <div><label class="field-label" for="k-price">Prix affiché</label><input id="k-price" class="input" value="${esc(pack?.price || '')}" placeholder="9,99 €"></div>
                <div class="full"><label class="field-label" for="k-bonus">Bonus</label><input id="k-bonus" class="input" value="${esc(pack?.bonus || '')}" placeholder="+10 %"></div>
                <div class="full"><label class="toggle-row"><span>Mis en avant<small>Affiche le bandeau « Populaire ».</small></span>
                    <input id="k-popular" type="checkbox" ${pack?.popular ? 'checked' : ''}><i class="switch"></i></label></div>
            </div></div>
            <div class="drawer-foot">
                <button class="btn btn-primary" data-act="save-pack" type="button">${isNew ? 'Créer le pack' : 'Enregistrer'}</button>
                ${isNew ? '' : '<button class="btn btn-danger" data-act="delete-pack" type="button">Supprimer le pack</button>'}
            </div>`;
    }

    function playerDrawer(p) {
        const history = (p.history || []).map((h) => `
            <div class="mini-row"><div class="mini-main"><p>${esc(h.label)}</p><p>${esc(h.date || '')}</p></div>
            <span class="amount ${Number(h.amount ?? -h.price) >= 0 ? 'plus' : 'minus'}">${Number(h.amount ?? -h.price) >= 0 ? '+' : '−'}${fmt(Math.abs(h.amount ?? h.price))}</span></div>`).join('')
            || '<p class="muted-empty">Aucun achat.</p>';
        return `${drawerHead(`<span style="font-weight:800;color:#d4d4d8">${esc(initials(p.name))}</span>`, p.name, p.online ? 'En ligne' : 'Hors ligne')}
            <div class="drawer-body">
                <div class="info-grid">
                    <div class="info"><p>Solde</p><p class="${Number(p.balance) < 0 ? 'amount minus' : ''}">${fmt(p.balance)} ${esc(unit())}</p></div>
                    <div class="info"><p>Achats</p><p>${fmt(p.purchases)}</p></div>
                    <div class="info wide"><p>VIP</p><p>${esc(p.vip || 'Aucun')}</p></div>
                </div>
                <div style="margin-top:18px">
                    <label class="field-label" for="p-amount">Modifier le solde</label>
                    <div class="adjust">
                        <input id="p-amount" class="input" type="number" min="1" placeholder="Montant">
                        <button class="btn btn-success" data-act="adjust" data-sign="1" type="button">+ Ajouter</button>
                        <button class="btn btn-danger" data-act="adjust" data-sign="-1" type="button">− Retirer</button>
                    </div>
                    <input id="p-reason" class="input" style="margin-top:8px" maxlength="80" placeholder="Raison (ex. geste commercial, remboursement…)">
                </div>
                <div class="block" style="margin-top:18px"><div class="block-head"><h3>Historique</h3><span>${esc(p.id)}</span></div>${history}</div>
            </div>`;
    }

    function renderDrawer() {
        const d = A.drawer;
        if (!d) return;
        let html = '';
        if (d.type === 'item') {
            const item = A.data.items.find((i) => i.id === d.id);
            if (!item) return closeDrawer();
            html = itemDrawer(item);
        } else if (d.type === 'newItem') html = itemDrawer(null, d.category);
        else if (d.type === 'pack') {
            const pack = A.data.packs[d.index];
            if (!pack) return closeDrawer();
            html = packDrawer(pack);
        } else if (d.type === 'newPack') html = packDrawer(null);
        else if (d.type === 'player') {
            if (!A.data.selectedPlayer) return;
            html = playerDrawer(A.data.selectedPlayer);
        }
        $('a-drawer').innerHTML = html;
    }

    function openDrawer(d) {
        A.drawer = d;
        renderDrawer();
        $('a-drawer').classList.add('show');
        $('a-overlay').classList.add('show');
    }

    function closeDrawer() {
        A.drawer = null;
        $('a-drawer').classList.remove('show');
        $('a-overlay').classList.remove('show');
    }

    /* ---------- Rendu général ---------- */

    function render() {
        $('a-title').textContent = A.data.settings.title || 'Boutique';
        renderSidebar();
        let html = '';
        if (A.tab === 'dashboard') html = dashboard();
        else if (A.tab === 'settings') html = settingsPanel();
        else if (A.tab === 'packs') html = packsPanel();
        else if (A.tab === 'players') html = playersPanel();
        else if (A.tab.startsWith('cat:')) html = categoryPanel(A.tab.slice(4));
        // Ne pas écraser un formulaire en cours de saisie dans Configuration
        if (!(A.tab === 'settings' && $('a-body').contains(document.activeElement) && document.activeElement.tagName === 'INPUT')) {
            $('a-body').innerHTML = html;
        }
        if (A.drawer && !$('a-drawer').contains(document.activeElement)) renderDrawer();
    }

    function setTab(tab) {
        A.tab = tab;
        closeDrawer();
        $('a-body').scrollTop = 0;
        $('a-body').innerHTML = '';
        render();
    }

    /* ---------- Actions ---------- */

    function val(id) { return $(id)?.value.trim() ?? ''; }

    function saveItem() {
        const d = A.drawer;
        const label = val('i-label');
        const id = d.type === 'newItem' ? val('i-id').toLowerCase().replace(/[^a-z0-9_-]/g, '') : d.id;
        const price = Number(val('i-price'));
        if (!label) return toast("Donne un nom à l'article.", 'error');
        if (!id) return toast('Identifiant invalide (lettres, chiffres, - et _).', 'error');
        if (d.type === 'newItem' && A.data.items.some((i) => i.id === id)) return toast('Cet identifiant existe déjà.', 'error');
        if (!Number.isFinite(price) || price < 0) return toast('Prix invalide.', 'error');
        let data;
        if (val('i-data')) {
            try { data = JSON.parse(val('i-data')); } catch { return toast('Données de livraison : JSON invalide.', 'error'); }
        } else {
            data = d.type === 'item' ? A.data.items.find((i) => i.id === id)?.data : undefined;
        }
        const category = d.type === 'newItem' ? d.category : A.data.items.find((i) => i.id === id)?.category;
        action('saveItem', {
            new: d.type === 'newItem',
            item: { id, category, label, description: val('i-desc'), price: Math.round(price), tag: val('i-tag') || undefined, image: val('i-image') || undefined, featured: $('i-featured').checked, data },
        });
        closeDrawer();
    }

    function savePack() {
        const amount = Number(val('k-amount'));
        if (!Number.isInteger(amount) || amount < 1) return toast('Quantité invalide.', 'error');
        if (!val('k-price')) return toast('Indique le prix affiché.', 'error');
        action('savePack', {
            index: A.drawer.type === 'pack' ? A.drawer.index + 1 : undefined, // index Lua (1 = premier)
            pack: { amount, price: val('k-price'), bonus: val('k-bonus') || undefined, popular: $('k-popular').checked },
        });
        closeDrawer();
    }

    function adjust(sign) {
        const amount = Number(val('p-amount'));
        if (!Number.isInteger(amount) || amount < 1) return toast('Montant invalide.', 'error');
        const p = A.data.selectedPlayer;
        const text = `${sign > 0 ? 'Ajouter' : 'Retirer'} ${fmt(amount)} ${unit()} ${sign > 0 ? 'à' : 'à'} ${p.name} ?`;
        askConfirm('Modifier le solde', text, () => action('adjustBalance', { id: p.id, amount: amount * sign, reason: val('p-reason') }));
    }

    document.addEventListener('click', (e) => {
        if (!A.open) return;
        const t = e.target;
        const tab = t.closest('#a-sidebar [data-tab]');
        if (tab) return setTab(tab.dataset.tab);
        if (t.closest('#a-drawer [data-close-drawer]')) return closeDrawer();

        const btn = t.closest('#admin [data-act]');
        if (btn) {
            switch (btn.dataset.act) {
                case 'reset':
                    return askConfirm('Réinitialiser les statistiques', 'Toutes les statistiques du tableau de bord repartiront de zéro. Cette action est définitive.', () => action('resetStats'));
                case 'save-settings':
                    return action('saveSettings', {
                        open: $('s-open').checked, title: val('s-title'), subtitle: val('s-subtitle'),
                        buyUrl: val('s-url'), currencyName: val('s-cname'), currencyShort: val('s-cshort').toUpperCase(),
                    });
                case 'new-item': return openDrawer({ type: 'newItem', category: btn.dataset.cat });
                case 'new-pack': return openDrawer({ type: 'newPack' });
                case 'save-item': return saveItem();
                case 'save-pack': return savePack();
                case 'delete-item': {
                    const item = A.data.items.find((i) => i.id === A.drawer.id);
                    return askConfirm("Supprimer l'article", `« ${item.label} » ne sera plus en vente.`, () => { action('deleteItem', { id: item.id }); closeDrawer(); });
                }
                case 'delete-pack': {
                    const index = A.drawer.index;
                    return askConfirm('Supprimer le pack', `Le pack de ${fmt(A.data.packs[index].amount)} ${unit()} sera retiré.`, () => { action('deletePack', { index: index + 1 }); closeDrawer(); });
                }
                case 'search':
                    A.query = val('p-search');
                    return action('searchPlayers', { query: A.query });
                case 'adjust': return adjust(Number(btn.dataset.sign));
            }
            return;
        }

        const item = t.closest('#a-body [data-item]');
        if (item) return openDrawer({ type: 'item', id: item.dataset.item });
        const pack = t.closest('#a-body [data-pack]');
        if (pack) return openDrawer({ type: 'pack', index: Number(pack.dataset.pack) });
        const player = t.closest('#a-body [data-player]');
        if (player) {
            // Volet en « chargement » le temps que le serveur renvoie la fiche
            A.data.selectedPlayer = null;
            A.drawer = { type: 'player' };
            $('a-drawer').innerHTML = `${drawerHead(I.users, 'Chargement…', '')}`;
            $('a-drawer').classList.add('show');
            $('a-overlay').classList.add('show');
            action('selectPlayer', { id: player.dataset.player });
        }
    });

    document.addEventListener('keydown', (e) => {
        if (!A.open) return;
        if (e.key === 'Enter' && e.target.id === 'p-search') {
            A.query = e.target.value.trim();
            action('searchPlayers', { query: A.query });
        }
        if (e.key !== 'Escape') return;
        if ($('a-modal').classList.contains('show')) closeConfirm();
        else if (A.drawer) closeDrawer();
        else closeAdmin();
    });

    $('a-overlay').addEventListener('click', closeDrawer);
    $('a-close').addEventListener('click', () => closeAdmin());
    $('a-modal-cancel').addEventListener('click', closeConfirm);
    $('a-modal-ok').addEventListener('click', () => { const fn = A.confirm; closeConfirm(); if (fn) fn(); });

    /* ---------- Ouverture / fermeture ---------- */

    function openAdmin(data) {
        A.data = { ...A.data, ...data };
        A.open = true;
        A.tab = 'dashboard';
        A.query = '';
        closeDrawer();
        render();
        $('admin').classList.remove('hidden');
    }

    function closeAdmin(fromServer) {
        if (!A.open) return;
        A.open = false;
        closeDrawer();
        closeConfirm();
        $('admin').classList.add('hidden');
        if (!fromServer && RES) {
            fetch(`https://${RES}/close`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: '{}' }).catch(() => {});
        }
    }

    window.addEventListener('message', (e) => {
        const msg = e.data || {};
        if (msg.action === 'adminOpen') openAdmin(msg.data || {});
        else if (msg.action === 'adminUpdate' && A.open) { A.data = { ...A.data, ...(msg.data || {}) }; render(); }
        else if (msg.action === 'close') closeAdmin(true);
        else if (msg.action === 'toast' && A.open) toast(msg.message, msg.kind);
    });

    /* ---------- Aperçu hors jeu (actions simulées) ---------- */

    const DEMO = {
        since: '26/09/2026',
        settings: { title: 'Boutique OriginRP', subtitle: 'Dépense tes Orins en véhicules, armes, packs et VIP', buyUrl: 'https://originrp.tebex.io', open: true, currencyName: 'Orins', currencyShort: 'OR' },
        stats: { orinsSold: 12400, orders: 18, refunds: 1, pendingAccounts: 2, ingamePurchases: 27, orinsSpent: 9650, vipActive: 6, negativeBalances: 0 },
        breakdown: { vehicles: 12, weapons: 5, packs: 4, vip: 6 },
        categories: [
            { id: 'vehicles', label: 'Véhicules', icon: 'car' }, { id: 'weapons', label: 'Armes', icon: 'weapon' },
            { id: 'packs', label: 'Packs', icon: 'box' }, { id: 'vip', label: 'VIP', icon: 'crown' },
        ],
        items: [
            { id: 'sultanrs', category: 'vehicles', label: 'Karin Sultan RS', description: 'Sportive 4 portes, idéale en ville.', price: 1500, tag: 'Nouveau', featured: true, data: { model: 'sultanrs' } },
            { id: 'comet', category: 'vehicles', label: 'Pfister Comet', description: 'Coupé sport classique.', price: 2200, data: { model: 'comet2' } },
            { id: 'pistol', category: 'weapons', label: 'Pistolet', description: 'Arme de poing + 50 munitions.', price: 600, data: { weapon: 'WEAPON_PISTOL', ammo: 50 } },
            { id: 'starter', category: 'packs', label: 'Pack Démarrage', description: '25 000 $ + téléphone + kit de soin.', price: 800, featured: true, data: { money: 25000 } },
            { id: 'vip_gold', category: 'vip', label: 'VIP Gold · 30 jours', description: 'Salaire +20 %, garage étendu, tenue exclusive.', price: 1200, tag: 'Populaire', featured: true, data: { vip: 'gold', days: 30 } },
        ],
        packs: [
            { amount: 500, price: '4,99 €' }, { amount: 1100, price: '9,99 €', bonus: '+10 %' },
            { amount: 2400, price: '19,99 €', bonus: '+20 %', popular: true }, { amount: 6500, price: '49,99 €', bonus: '+30 %' },
        ],
        recentOrders: [
            { player: 'Malou Malou', label: 'Pack 2 400 OR', price: '19,99 €', date: '27/09 14:02', status: 'ok' },
            { player: 'John Doe', label: 'Pack 1 100 OR', price: '9,99 €', date: '27/09 11:47', status: 'pending' },
            { player: 'Stella Dasilva', label: 'Pack 500 OR', price: '4,99 €', date: '26/09 22:15', status: 'refunded' },
        ],
        recentMoves: [
            { player: 'Malou Malou', label: 'Achat Karin Sultan RS', amount: -1500, date: '27/09 14:05' },
            { player: 'Malou Malou', label: 'Commande site', amount: 2400, date: '27/09 14:02' },
            { player: 'Zqfs Eqqs', label: 'Achat VIP Gold · 30 jours', amount: -1200, date: '26/09 20:31' },
        ],
        players: [],
    };
    const DEMO_PLAYERS = [
        { id: 'license:3f2a9c', name: 'Malou Malou', balance: 350, vip: 'VIP Gold', purchases: 3, online: true, history: [{ label: 'Karin Sultan RS', amount: -1500, date: '27/09 14:05' }, { label: 'Commande site', amount: 2400, date: '27/09 14:02' }] },
        { id: 'license:8b71d0', name: 'John Doe', balance: 0, vip: null, purchases: 0, online: true, history: [] },
        { id: 'license:c04e55', name: 'Zqfs Eqqs', balance: 1850, vip: 'VIP Gold', purchases: 2, online: false, history: [{ label: 'VIP Gold · 30 jours', amount: -1200, date: '26/09 20:31' }] },
    ];

    function demoAction(name, p) {
        const D = DEMO;
        let msg = 'Enregistré.';
        if (name === 'resetStats') { Object.keys(D.stats).forEach((k) => { D.stats[k] = 0; }); Object.keys(D.breakdown).forEach((k) => { D.breakdown[k] = 0; }); D.recentOrders = []; D.recentMoves = []; D.since = new Date().toLocaleDateString('fr-FR'); msg = 'Statistiques réinitialisées.'; }
        else if (name === 'saveSettings') { Object.assign(D.settings, p); msg = 'Configuration enregistrée.'; }
        else if (name === 'saveItem') { const i = D.items.findIndex((x) => x.id === p.item.id); if (i >= 0) D.items[i] = p.item; else D.items.push(p.item); msg = `« ${p.item.label} » enregistré.`; }
        else if (name === 'deleteItem') { D.items = D.items.filter((x) => x.id !== p.id); msg = 'Article supprimé.'; }
        else if (name === 'savePack') { if (p.index) D.packs[p.index - 1] = p.pack; else D.packs.push(p.pack); msg = 'Pack enregistré.'; }
        else if (name === 'deletePack') { D.packs.splice(p.index - 1, 1); msg = 'Pack supprimé.'; }
        else if (name === 'searchPlayers') { const q = p.query.toLowerCase(); D.players = DEMO_PLAYERS.filter((x) => !q || x.name.toLowerCase().includes(q) || x.id.includes(q)); msg = null; }
        else if (name === 'selectPlayer') { D.selectedPlayer = DEMO_PLAYERS.find((x) => x.id === p.id); msg = null; }
        else if (name === 'adjustBalance') {
            const pl = DEMO_PLAYERS.find((x) => x.id === p.id);
            pl.balance += p.amount;
            pl.history.unshift({ label: p.reason || 'Ajustement admin', amount: p.amount, date: new Date().toLocaleString('fr-FR').slice(0, 16) });
            D.recentMoves.unshift({ player: pl.name, label: p.reason || 'Ajustement admin', amount: p.amount, date: 'à l\'instant' });
            D.players = D.players.map((x) => (x.id === pl.id ? pl : x));
            D.selectedPlayer = pl;
            msg = 'Solde modifié.';
        }
        A.data = JSON.parse(JSON.stringify({ ...A.data, ...D }));
        render();
        if (msg) toast(msg, 'success');
    }

    if (!RES && location.hash.startsWith('#admin')) {
        openAdmin(JSON.parse(JSON.stringify(DEMO)));
        const sub = location.hash.split('-')[1];
        if (sub) setTab(sub.startsWith('cat') ? `cat:${sub.slice(3)}` : sub);
    }
})();
