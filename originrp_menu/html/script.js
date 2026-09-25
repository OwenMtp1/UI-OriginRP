'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;

/* ---------- Icônes (24x24) ---------- */

const stroke = (paths) =>
    `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${paths}</svg>`;
const filled = (paths) =>
    `<svg viewBox="0 0 24 24" fill="currentColor" fill-rule="evenodd">${paths}</svg>`;

const ICONS = {
    user: stroke('<circle cx="12" cy="8" r="4"/><path d="M4.5 20.5v-.5a6 6 0 0 1 6-6h3a6 6 0 0 1 6 6v.5z"/>'),
    briefcase: filled('<path d="M9 3h6a2 2 0 0 1 2 2v1h3a2 2 0 0 1 2 2v3H2V8a2 2 0 0 1 2-2h3V5a2 2 0 0 1 2-2zm0 3h6V5H9z"/><path d="M2 13h8v1a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-1h8v6a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2z"/>'),
    phone: filled('<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"/>'),
    car: filled('<path d="M5.5 5.5A2 2 0 0 1 7.4 4h9.2a2 2 0 0 1 1.9 1.5L19.8 10h.2a2 2 0 0 1 2 2v5a1 1 0 0 1-1 1h-1v1.5a1.5 1.5 0 0 1-3 0V18H7v1.5a1.5 1.5 0 0 1-3 0V18H3a1 1 0 0 1-1-1v-5a2 2 0 0 1 2-2h.2zM7.6 6l-1 4h10.8l-1-4zM6.5 15.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zm11 0a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z"/>'),
    run: stroke('<circle cx="15" cy="4" r="2" fill="currentColor" stroke="none"/><path d="M13 8.5 11 14"/><path d="M6.5 11 9 8.5l4 .2 2.5 3.3H19"/><path d="M11 14l3 3-1 5"/><path d="M11 14l-2 4H5"/>'),
    settings: stroke('<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>'),
    idcard: stroke('<rect x="2" y="5" width="20" height="14" rx="2"/><circle cx="8" cy="12" r="2"/><path d="M14 10h4M14 14h4"/>'),
    bell: stroke('<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>'),
    eye: stroke('<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>'),
    home: stroke('<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>'),
    key: stroke('<circle cx="7.5" cy="15.5" r="5.5"/><path d="m21 2-9.6 9.6"/><path d="m15.5 7.5 3 3L22 7l-3-3"/>'),
    wallet: stroke('<path d="M20 12V8H6a2 2 0 0 1-2-2c0-1.1.9-2 2-2h12v4"/><path d="M4 6v12c0 1.1.9 2 2 2h14v-4"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/>'),
    map: stroke('<path d="M3 6l6-3 6 3 6-3v15l-6 3-6-3-6 3z"/><path d="M9 3v15M15 6v15"/>'),
    shield: stroke('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>'),
    heart: stroke('<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7z"/>'),
    shirt: stroke('<path d="M20.38 3.46 16 2a4 4 0 0 1-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23z"/>'),
    file: stroke('<path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5z"/><path d="M14 2v6h6"/>'),
    star: filled('<path d="M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6-4.9-4.6 6.6-.8z"/>'),
    badge: stroke('<path d="M12 2 4 5v6c0 5 3.4 9.4 8 11 4.6-1.6 8-6 8-11V5z"/><path d="m9 12 2 2 4-4"/>'),
    flag: stroke('<path d="M4 22V4"/><path d="M4 4h13l-2 4.5L17 13H4"/>'),
    users: stroke('<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20v-.5A5.5 5.5 0 0 1 8 14h2a5.5 5.5 0 0 1 5.5 5.5v.5"/><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8"/><path d="M18.5 14.2a5.5 5.5 0 0 1 3 4.8v1"/>'),
    server: stroke('<rect x="3" y="3" width="18" height="7" rx="2"/><rect x="3" y="14" width="18" height="7" rx="2"/><path d="M7 6.5h.01M7 17.5h.01M11 6.5h6M11 17.5h6"/>'),
    ban: stroke('<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>'),
    tablet: stroke('<rect x="4" y="2" width="16" height="20" rx="2.5"/><path d="M11 18h2"/>'),
    info: stroke('<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>'),
};

const CHEVRON = stroke('<path d="m9 5 7 7-7 7"/>');
const CHECK = stroke('<path d="m5 12.5 4.5 4.5L19 7.5"/>');
const BACK = stroke('<path d="m15 5-7 7 7 7"/>');

const LOGO = `
<svg viewBox="0 0 48 48">
    <defs>
        <linearGradient id="logo-grad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stop-color="#d9c2ff"/>
            <stop offset="1" stop-color="#8b5cf6"/>
        </linearGradient>
    </defs>
    <path fill="url(#logo-grad)" d="M19 4h9l17 40h-9L23.5 14 11 44H3z"/>
    <path fill="#c4a4ff" d="M20.5 44l8-18.5 4 9.5-3.8 9z"/>
</svg>`;

/* ---------- Données d'aperçu (navigateur uniquement) ---------- */

const PREVIEW = {
    root: 'main',
    menus: {
        main: {
            title: 'Menu F5',
            subtitle: 'Accédez à toutes les options du serveur',
            key: 'F5',
            items: [
                { icon: 'user', label: 'Identité', description: 'Voir et modifier votre identité', close: true },
                { icon: 'briefcase', label: 'Emplois', description: 'Consulter les différents emplois', close: true },
                { icon: 'phone', label: 'Téléphone', description: 'Vos contacts et messages', close: true },
                { icon: 'car', label: 'Véhicules', description: 'Gérer vos véhicules', close: true },
                { icon: 'run', label: 'Animations', description: 'Accéder aux animations', close: true },
                { icon: 'settings', label: 'Paramètres', description: 'Régler vos préférences', submenu: 'parametres' },
            ],
        },
        organisation: {
            title: 'Cartelgoon',
            subtitle: 'Menu organisation',
            key: 'F7',
            items: [
                { icon: 'star', label: 'Grade', description: "Votre rang dans l'organisation", value: 'Chef', static: true },
                { icon: 'badge', label: 'Prendre son service', description: 'Passer en service ou hors service', checkbox: true, checked: false },
                { icon: 'tablet', label: 'Ouvrir la tablette', description: "Accéder à la tablette de l'organisation", close: true },
            ],
        },
        staff: {
            title: 'Menu Staff',
            subtitle: 'Outils de modération',
            key: 'F10',
            counter: true,
            hints: true,
            items: [
                { icon: 'flag', label: 'Reports', description: 'Traiter les signalements des joueurs', value: '0 en attente', close: true },
                { icon: 'user', label: 'Moi', description: 'Noclip, invisibilité, téléportation', close: true },
                { icon: 'users', label: 'Joueurs', description: 'Liste et actions sur les joueurs', value: '2 en ligne', close: true },
                { icon: 'server', label: 'Gestion du serveur', description: 'Météo, heure, annonces', close: true },
                { icon: 'ban', label: 'Bans', description: 'Consulter et gérer les bannissements', close: true },
                { icon: 'settings', label: 'Paramètres', description: 'Préférences du staff', close: true },
            ],
        },
        parametres: {
            title: 'Paramètres',
            subtitle: 'Exemple de sous-menu',
            items: [
                { icon: 'bell', label: 'Notifications', description: 'Activer ou couper les notifications', close: true },
                { icon: 'eye', label: 'Affichage', description: 'Masquer ou afficher le HUD', close: true },
            ],
        },
    },
};

/* ---------- État ---------- */

const el = {
    menu: document.getElementById('menu'),
    back: document.getElementById('menu-back'),
    logo: document.getElementById('menu-logo'),
    title: document.getElementById('menu-title'),
    subtitle: document.getElementById('menu-subtitle'),
    key: document.getElementById('menu-key'),
    counter: document.getElementById('menu-counter'),
    hintBack: document.getElementById('hint-back'),
    items: document.getElementById('menu-items'),
};

const state = {
    open: false,
    menus: {},
    stack: [], // ids des menus ouverts, le dernier est affiché
    active: 0,
};

el.back.innerHTML = BACK;

function post(name, data = {}) {
    if (!RESOURCE) {
        console.log(`[aperçu] ${name}`, data);
        return Promise.resolve();
    }
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

const currentId = () => state.stack[state.stack.length - 1];
const currentMenu = () => state.menus[currentId()];

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text == null ? '' : String(text);
    return div.innerHTML;
}

/* ---------- Rendu ---------- */

function setLogo(logo) {
    if (logo) {
        el.logo.innerHTML = '';
        const img = document.createElement('img');
        img.src = logo;
        img.alt = '';
        el.logo.appendChild(img);
    } else {
        el.logo.innerHTML = LOGO;
    }
}

function render(direction) {
    const menu = currentMenu();
    if (!menu) return;

    el.menu.classList.toggle('has-back', state.stack.length > 1);
    el.title.textContent = menu.title || '';
    el.subtitle.textContent = menu.subtitle || '';
    el.key.firstElementChild.textContent = menu.key || '';
    el.key.classList.toggle('empty', !menu.key);
    el.menu.classList.toggle('has-counter', !!menu.counter);
    el.menu.classList.toggle('has-hints', !!menu.hints);
    el.hintBack.hidden = state.stack.length < 2;

    const items = menu.items || [];
    el.items.innerHTML = items.map((item, index) => `
        <li class="${itemClass(item)}" role="${item.checkbox ? 'menuitemcheckbox' : 'menuitem'}"${item.checkbox ? ` aria-checked="${!!item.checked}"` : ''} data-index="${index}">
            <div class="item-icon">${ICONS[item.icon] || ICONS.info}</div>
            <div class="item-text">
                <div class="item-label">${escapeHtml(item.label)}</div>
                ${item.description ? `<div class="item-description">${escapeHtml(item.description)}</div>` : ''}
            </div>
            ${itemEnd(item)}
        </li>`).join('');

    if (direction) {
        el.items.classList.remove('slide-in', 'slide-back');
        void el.items.offsetWidth; // relance l'animation
        el.items.classList.add(direction === 'back' ? 'slide-back' : 'slide-in');
    }

    setActive(firstEnabled(state.active), false);
}

function itemClass(item) {
    let name = 'menu-item';
    if (item.disabled) name += ' disabled';
    if (item.static) name += ' static';
    if (item.checkbox && item.checked) name += ' checked';
    return name;
}

// Élément à droite de la rubrique : case à cocher, valeur et/ou chevron
function itemEnd(item) {
    if (item.checkbox) return `<span class="item-checkbox">${CHECK}</span>`;
    let html = '';
    if (item.value != null && item.value !== '') html += `<span class="item-value">${escapeHtml(item.value)}</span>`;
    if (!item.static) html += `<span class="item-chevron">${CHEVRON}</span>`;
    return html;
}

function firstEnabled(from) {
    const items = currentMenu().items || [];
    if (!items.length) return -1;
    const start = Math.min(Math.max(from, 0), items.length - 1);
    for (let i = 0; i < items.length; i++) {
        const index = (start + i) % items.length;
        if (!items[index].disabled) return index;
    }
    return -1;
}

function setActive(index, scroll = true) {
    state.active = index;
    el.items.querySelectorAll('.menu-item').forEach((node, i) => {
        node.classList.toggle('active', i === index);
        if (i === index && scroll) node.scrollIntoView({ block: 'nearest' });
    });
    const total = (currentMenu().items || []).length;
    el.counter.textContent = total ? `${index + 1} / ${total}` : '';
}

function move(step) {
    const items = currentMenu().items || [];
    if (!items.length) return;
    let index = state.active;
    for (let i = 0; i < items.length; i++) {
        index = (index + step + items.length) % items.length;
        if (!items[index].disabled) break;
    }
    setActive(index);
}

/* ---------- Actions ---------- */

function open(data) {
    state.menus = data.menus || {};
    state.stack = [data.root];
    state.active = 0;
    state.open = true;
    setLogo(data.logo);
    render();
    el.menu.classList.remove('hidden');
}

function hide() {
    state.open = false;
    el.menu.classList.add('hidden');
}

function close() {
    if (!state.open) return;
    hide();
    post('close');
}

function back() {
    if (state.stack.length > 1) {
        const leaving = state.stack.pop();
        const items = currentMenu().items || [];
        const parentIndex = items.findIndex((item) => item.submenu === leaving);
        state.active = parentIndex >= 0 ? parentIndex : 0;
        render('back');
    } else {
        close();
    }
}

function select(index) {
    const item = (currentMenu().items || [])[index];
    if (!item || item.disabled) return;

    if (item.static) return;

    if (item.checkbox) {
        item.checked = !item.checked;
        const node = el.items.children[index];
        node.classList.toggle('checked', item.checked);
        node.setAttribute('aria-checked', String(item.checked));
        post('select', { menu: currentId(), index });
        return;
    }

    if (item.submenu) {
        if (!state.menus[item.submenu]) return;
        state.stack.push(item.submenu);
        state.active = 0;
        render('forward');
        return;
    }

    post('select', { menu: currentId(), index });
    if (item.close !== false) hide();
}

/* ---------- Événements ---------- */

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') open(data);
    else if (data.action === 'close') hide();
    else if (data.action === 'refresh' && state.open) {
        state.menus = data.menus || state.menus;
        state.stack = state.stack.filter((id) => state.menus[id]);
        if (state.stack.length) render();
        else hide();
    }
});

el.items.addEventListener('mousemove', (event) => {
    const node = event.target.closest('.menu-item');
    if (!node || node.classList.contains('disabled')) return;
    const index = Number(node.dataset.index);
    if (index !== state.active) setActive(index, false);
});

el.items.addEventListener('click', (event) => {
    const node = event.target.closest('.menu-item');
    if (node) select(Number(node.dataset.index));
});

el.back.addEventListener('click', back);

document.addEventListener('contextmenu', (event) => {
    event.preventDefault();
    if (state.open) back();
});

document.addEventListener('keydown', (event) => {
    if (!state.open) return;
    const menuKey = (currentMenu().key || '').toUpperCase();

    switch (event.key) {
        case 'ArrowDown':
            move(1);
            break;
        case 'ArrowUp':
            move(-1);
            break;
        case 'Enter':
        case ' ':
            select(state.active);
            break;
        case 'Backspace':
        case 'ArrowLeft':
            back();
            break;
        case 'Escape':
            close();
            break;
        default:
            if (menuKey && event.key.toUpperCase() === menuKey) close();
            else return;
    }
    event.preventDefault();
});

/* ---------- Aperçu hors jeu ---------- */

if (!RESOURCE) {
    document.body.classList.add('preview');
    // index.html#organisation (ou #staff) ouvre directement ce menu
    const previewRoot = () => (PREVIEW.menus[location.hash.slice(1)] ? location.hash.slice(1) : PREVIEW.root);
    open({ ...PREVIEW, root: previewRoot() });
    document.addEventListener('keydown', (event) => {
        if (state.open) return;
        const root = { F5: 'main', F7: 'organisation', F10: 'staff' }[event.key];
        if (root) {
            event.preventDefault();
            open({ ...PREVIEW, root });
        }
    });
}
