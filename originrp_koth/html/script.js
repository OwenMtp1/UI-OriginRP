'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;

const el = {
    board: document.getElementById('board'),
    title: document.getElementById('board-title'),
    subtitle: document.getElementById('board-subtitle'),
    rows: document.getElementById('board-rows'),
};

const config = {
    title: 'KOTH',
    subtitle: '',
    maxRows: 5,
    pointsLabel: 'pts',
    position: 'top-left',
    offset: { x: 24, y: 24 },
};

const nodes = new Map(); // clé du joueur -> <li>

/* ---------- Configuration ---------- */

function applyConfig(data) {
    Object.assign(config, data || {});
    el.title.textContent = config.title || '';
    el.subtitle.textContent = config.subtitle || '';
    el.board.dataset.position = config.position;
    const root = document.documentElement.style;
    root.setProperty('--offset-x', `${Number(config.offset?.x) || 0}px`);
    root.setProperty('--offset-y', `${Number(config.offset?.y) || 0}px`);
}

/* ---------- Classement ---------- */

function createRow() {
    const li = document.createElement('li');
    li.className = 'board-row enter';
    li.innerHTML = '<span class="row-rank"></span><span class="row-name"></span><span class="row-points"><b></b><small></small></span>';
    li.addEventListener('animationend', () => li.classList.remove('enter'), { once: true });
    return li;
}

function fillRow(li, entry) {
    li.querySelector('.row-rank').textContent = entry.rank;
    li.querySelector('.row-name').textContent = entry.name;
    li.querySelector('.row-points small').textContent = config.pointsLabel || '';

    const points = li.querySelector('.row-points');
    const value = points.querySelector('b');
    const text = String(entry.points);
    if (value.textContent !== '' && value.textContent !== text) {
        points.classList.remove('bump');
        void points.offsetWidth; // relance l'animation
        points.classList.add('bump');
    }
    value.textContent = text;

    li.classList.toggle('leader', entry.rank === 1);
    li.classList.toggle('top', entry.rank <= 3);
    li.classList.toggle('me', !!entry.me);
}

function update(entries) {
    const ranked = (entries || [])
        .map((entry, i) => ({ ...entry, key: String(entry.key ?? entry.name ?? i), points: Number(entry.points) || 0 }))
        .sort((a, b) => b.points - a.points)
        .map((entry, i) => ({ ...entry, rank: i + 1 }));

    const max = Math.max(1, Number(config.maxRows) || 5);
    let shown = ranked.slice(0, max);
    const me = ranked.find((entry) => entry.me);
    if (me && me.rank > max) shown = [...ranked.slice(0, max - 1), me];

    // Positions avant la mise à jour (animation de reclassement)
    const before = new Map();
    nodes.forEach((node, key) => before.set(key, node.getBoundingClientRect().top));

    const keep = new Set();
    shown.forEach((entry) => {
        keep.add(entry.key);
        let node = nodes.get(entry.key);
        if (!node) {
            node = createRow();
            nodes.set(entry.key, node);
        }
        fillRow(node, entry);
        el.rows.appendChild(node);
    });

    nodes.forEach((node, key) => {
        if (!keep.has(key)) {
            node.remove();
            nodes.delete(key);
        }
    });

    nodes.forEach((node, key) => {
        if (!before.has(key)) return;
        const delta = before.get(key) - node.getBoundingClientRect().top;
        if (!delta) return;
        node.style.transition = 'none';
        node.style.transform = `translateY(${delta}px)`;
        void node.offsetHeight;
        node.style.transition = '';
        node.style.transform = '';
    });

    el.board.classList.toggle('empty', shown.length === 0);
}

/* ---------- Messages Lua ---------- */

window.addEventListener('message', (event) => {
    const data = event.data || {};
    switch (data.action) {
        case 'update':
            if (data.title) {
                config.title = data.title;
                el.title.textContent = data.title;
            }
            update(data.entries);
            break;
        case 'show':
            el.board.classList.remove('hidden');
            break;
        case 'hide':
            el.board.classList.add('hidden');
            break;
        case 'pause':
            el.board.classList.toggle('paused', !!data.paused);
            break;
    }
});

/* ---------- Démarrage ---------- */

if (RESOURCE) {
    fetch(`https://${RESOURCE}/ready`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: '{}',
    })
        .then((res) => res.json())
        .then((state) => {
            applyConfig(state.config);
            update(state.entries);
            el.board.classList.toggle('hidden', !state.visible);
        })
        .catch(() => {});
} else {
    // Aperçu hors jeu : données de démo qui évoluent
    applyConfig({ subtitle: 'Classement en direct' });
    const demo = [
        { key: '1', name: 'cartelgoon', points: 0, me: true },
        { key: '2', name: 'Nyxo', points: 0 },
        { key: '3', name: 'Rafa_LS', points: 0 },
        { key: '4', name: 'Kenzo', points: 0 },
        { key: '5', name: 'Lina.V', points: 0 },
    ];
    update(demo);
    el.board.classList.remove('hidden');
    setInterval(() => {
        const player = demo[Math.floor(Math.random() * demo.length)];
        player.points += 5 * (1 + Math.floor(Math.random() * 3));
        update(demo);
    }, 1500);
}
