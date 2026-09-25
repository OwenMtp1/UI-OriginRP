'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
const $ = (id) => document.getElementById(id);

const ICON = {
    chevron: '<svg class="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 5 7 7-7 7"/></svg>',
    clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>',
    plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
    close: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>',
    up: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 14 6-6 6 6"/></svg>',
    down: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m6 10 6 6 6-6"/></svg>',
    kick: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="4"/><path d="M2.5 20v-.5A5.5 5.5 0 0 1 8 14h2a5.5 5.5 0 0 1 5.5 5.5v.5"/><path d="M16 11h6"/></svg>',
};

const state = {
    open: false,
    data: null,
    subtitle: '',
    permissions: [
        { key: 'coffre', label: 'Accès au coffre' },
        { key: 'tablette', label: 'Accès à la tablette' },
        { key: 'service', label: 'Prise de service' },
        { key: 'recrutement', label: 'Recrutement' },
        { key: 'grades', label: 'Gestion des grades' },
    ],
    tab: 'members',
    filter: 'all',
    search: '',
    drawer: null, // { type: 'member', id } | { type: 'grade', level } | { type: 'newGrade' }
};

/* ---------- Utilitaires ---------- */

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text == null ? '' : String(text);
    return div.innerHTML;
}

function initials(name) {
    return String(name || '?').trim().split(/\s+/).slice(0, 2).map((w) => w[0]).join('').toUpperCase();
}

function formatTime(minutes) {
    const m = Math.max(0, Math.round(Number(minutes) || 0));
    const h = Math.floor(m / 60);
    return h ? `${h}h ${String(m % 60).padStart(2, '0')}min` : `${m}min`;
}

function post(name, data = {}) {
    if (!RESOURCE) return Promise.resolve(preview(name, data));
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

function action(name, payload) {
    post('action', { action: name, payload });
}

let toastTimer = null;
function toast(message, kind = '') {
    const node = $('toast');
    node.textContent = message;
    node.className = `toast show ${kind}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => node.classList.remove('show'), 2800);
}

/* ---------- Données ---------- */

const grades = () => [...(state.data?.grades || [])].sort((a, b) => b.level - a.level);
const gradeOf = (level) => grades().find((g) => g.level === level);
const me = () => state.data?.me || {};
const myGrade = () => gradeOf(me().grade);
const can = (perm) => (myGrade()?.permissions || []).includes(perm);
const permLabel = (key) => state.permissions.find((p) => p.key === key)?.label || key;

// On ne gère que les membres strictement en dessous de soi
const canManage = (member) => member && member.id !== me().id && member.grade < me().grade;

function neighbourGrade(level, direction) {
    const list = grades();
    const index = list.findIndex((g) => g.level === level);
    return list[index + (direction === 'up' ? -1 : 1)];
}

/* ---------- Rendu ---------- */

function renderHeader() {
    const data = state.data;
    $('org-name').textContent = data.name || '';
    $('org-logo').textContent = initials(data.name);
    $('org-subtitle').textContent = state.subtitle || '';
    $('btn-recruit').hidden = !can('recrutement');

    $('stat-type').textContent = data.type || '-';
    $('stat-xp').textContent = data.xp != null ? Number(data.xp).toLocaleString('fr-FR') : '-';
    $('stat-grade').textContent = myGrade()?.name || '-';

    const members = data.members || [];
    $('count-members').textContent = members.length;
    $('count-grades').textContent = grades().length;
    const online = members.filter((m) => m.online).length;
    $('online-count').textContent = `${online} en ligne · ${members.filter((m) => m.onDuty).length} en service`;
}

function renderMembers() {
    const search = state.search.trim().toLowerCase();
    const members = [...(state.data.members || [])]
        .filter((m) => state.filter !== 'online' || m.online)
        .filter((m) => state.filter !== 'duty' || m.onDuty)
        .filter((m) => !search || String(m.name).toLowerCase().includes(search))
        .sort((a, b) => b.grade - a.grade || (b.online - a.online) || String(a.name).localeCompare(b.name));

    if (!members.length) {
        $('members').innerHTML = '<li class="empty">Aucun membre trouvé.</li>';
        return;
    }

    $('members').innerHTML = members.map((m) => `
        <li class="row" data-member="${escapeHtml(m.id)}">
            <div class="avatar">${escapeHtml(initials(m.name))}<span class="dot${m.online ? ' online' : ''}"></span></div>
            <div class="row-main">
                <div class="row-title">${escapeHtml(m.name)}${m.id === me().id ? ' <span class="muted">(toi)</span>' : ''}</div>
                <div class="row-sub">
                    <span class="chip">${escapeHtml(gradeOf(m.grade)?.name || '?')}</span>
                    <span class="meta">${ICON.clock}Temps de service : ${formatTime(m.serviceTime)}</span>
                </div>
            </div>
            ${m.onDuty ? '<span class="badge-duty">En service</span>' : ''}
            ${ICON.chevron}
        </li>`).join('');
}

function renderGrades() {
    const list = grades();
    const members = state.data.members || [];
    const html = list.map((g, index) => {
        const count = members.filter((m) => m.grade === g.level).length;
        const perms = g.permissions || [];
        return `
        <li class="row${index === 0 ? ' top' : ''}" data-grade="${g.level}">
            <div class="level">${g.level}<small>Niv.</small></div>
            <div class="row-main">
                <div class="row-title">${escapeHtml(g.name)} <span class="muted">· ${count} membre${count > 1 ? 's' : ''}</span></div>
                <div class="tags">${perms.length
                    ? perms.map((p) => `<span class="chip">${escapeHtml(permLabel(p))}</span>`).join('')
                    : '<span class="none">Aucune permission</span>'}</div>
            </div>
            ${ICON.chevron}
        </li>`;
    }).join('');

    const add = can('grades') ? `
        <li class="row add" data-new-grade>
            <div class="level">${ICON.plus}</div>
            <div class="row-main"><div class="row-title">Ajouter un grade</div></div>
            ${ICON.chevron}
        </li>` : '';

    $('grades').innerHTML = html + add;
}

function renderAll() {
    if (!state.data) return;
    renderHeader();
    renderMembers();
    renderGrades();
    if (state.drawer) renderDrawer();
}

/* ---------- Volet : fiche membre ---------- */

function memberDrawer(member) {
    const grade = gradeOf(member.grade);
    const up = neighbourGrade(member.grade, 'up');
    const down = neighbourGrade(member.grade, 'down');
    const manage = canManage(member);
    const canPromote = manage && can('grades') && up && up.level < me().grade;
    const canDemote = manage && can('grades') && !!down;
    const canKick = manage && can('recrutement');

    let note = '';
    if (member.id === me().id) note = "C'est toi : tu ne peux pas modifier ton propre grade.";
    else if (!manage) note = 'Ce membre a un grade égal ou supérieur au tien.';
    else if (!can('grades') && !can('recrutement')) note = "Ton grade n'a pas les permissions pour gérer les membres.";

    return `
        <div class="drawer-head">
            <div class="avatar lg">${escapeHtml(initials(member.name))}<span class="dot${member.online ? ' online' : ''}"></span></div>
            <div>
                <p class="drawer-title">${escapeHtml(member.name)}</p>
                <p class="drawer-sub"><span class="chip">${escapeHtml(grade?.name || '?')}</span>${member.onDuty ? '<span class="badge-duty">En service</span>' : ''}</p>
            </div>
            <button class="icon-btn" data-close-drawer type="button" aria-label="Fermer">${ICON.close}</button>
        </div>
        <div class="drawer-body">
            <div class="info-grid">
                <div class="info"><p>Statut</p><p>${member.online ? 'En ligne' : 'Hors ligne'}</p></div>
                <div class="info"><p>Service</p><p>${member.onDuty ? 'En service' : 'Hors service'}</p></div>
                <div class="info wide"><p>Temps de service</p><p>${formatTime(member.serviceTime)}</p></div>
            </div>
            ${note ? `<p class="note">${note}</p>` : ''}
        </div>
        <div class="drawer-foot">
            <div class="btn-row">
                <button class="btn btn-ghost" data-act="promote" type="button" ${canPromote ? '' : 'disabled'}>${ICON.up}${up ? escapeHtml(up.name) : 'Promouvoir'}</button>
                <button class="btn btn-ghost" data-act="demote" type="button" ${canDemote ? '' : 'disabled'}>${ICON.down}${down ? escapeHtml(down.name) : 'Rétrograder'}</button>
            </div>
            <button class="btn btn-danger" data-act="ask-kick" type="button" ${canKick ? '' : 'disabled'}>${ICON.kick}Exclure</button>
            <div class="confirm" id="confirm-kick">
                Exclure <strong>${escapeHtml(member.name)}</strong> ? Cette action est immédiate.
                <div class="btn-row">
                    <button class="btn btn-ghost" data-act="cancel-kick" type="button">Annuler</button>
                    <button class="btn btn-danger" data-act="kick" type="button">Confirmer</button>
                </div>
            </div>
        </div>`;
}

/* ---------- Volet : grade ---------- */

function gradeDrawer(grade) {
    const isNew = !grade;
    const editable = can('grades') && (isNew || grade.level < me().grade);
    const list = grades();
    const nextLevel = list.length ? Math.max(...list.map((g) => g.level)) + 1 : 0;
    const perms = grade?.permissions || [];
    const members = (state.data.members || []).filter((m) => grade && m.grade === grade.level).length;

    let note = '';
    if (!can('grades')) note = "Ton grade n'a pas la permission « Gestion des grades ».";
    else if (!isNew && !editable) note = 'Tu ne peux pas modifier un grade égal ou supérieur au tien.';

    return `
        <div class="drawer-head">
            <div class="level">${isNew ? ICON.plus : `${grade.level}<small>Niv.</small>`}</div>
            <div>
                <p class="drawer-title">${isNew ? 'Nouveau grade' : escapeHtml(grade.name)}</p>
                <p class="drawer-sub">${isNew ? 'Choisis un nom, un niveau et des permissions' : `${members} membre${members > 1 ? 's' : ''}`}</p>
            </div>
            <button class="icon-btn" data-close-drawer type="button" aria-label="Fermer">${ICON.close}</button>
        </div>
        <div class="drawer-body">
            <div class="field">
                <label class="field-label" for="grade-name">Nom du grade</label>
                <input id="grade-name" class="input" type="text" maxlength="32" value="${escapeHtml(grade?.name || '')}" ${editable ? '' : 'disabled'}>
            </div>
            <div class="field">
                <label class="field-label" for="grade-level">Niveau</label>
                <input id="grade-level" class="input" type="number" min="0" value="${isNew ? Math.min(nextLevel, Math.max(0, me().grade - 1)) : grade.level}" ${isNew && editable ? '' : 'disabled'}>
            </div>
            <div class="field">
                <span class="field-label">Permissions</span>
                ${state.permissions.map((p) => `
                    <label class="perm${editable ? '' : ' locked'}">
                        <span>${escapeHtml(p.label)}</span>
                        <input type="checkbox" value="${escapeHtml(p.key)}" ${perms.includes(p.key) ? 'checked' : ''} ${editable ? '' : 'disabled'}>
                        <i class="switch"></i>
                    </label>`).join('')}
            </div>
            ${note ? `<p class="note">${note}</p>` : ''}
        </div>
        <div class="drawer-foot">
            <button class="btn btn-primary" data-act="save-grade" type="button" ${editable ? '' : 'disabled'}>${isNew ? 'Créer le grade' : 'Enregistrer'}</button>
            ${isNew ? '' : `<button class="btn btn-danger" data-act="delete-grade" type="button" ${editable && members === 0 ? '' : 'disabled'}>
                ${members ? 'Supprimer (grade encore utilisé)' : 'Supprimer le grade'}</button>`}
        </div>`;
}

function renderDrawer() {
    const d = state.drawer;
    let html = '';
    if (d.type === 'member') {
        const member = (state.data.members || []).find((m) => m.id === d.id);
        if (!member) return closeDrawer();
        html = memberDrawer(member);
    } else if (d.type === 'grade') {
        const grade = gradeOf(d.level);
        if (!grade) return closeDrawer();
        html = gradeDrawer(grade);
    } else {
        html = gradeDrawer(null);
    }
    $('drawer').innerHTML = html;
}

function openDrawer(drawer) {
    state.drawer = drawer;
    renderDrawer();
    $('drawer').classList.add('show');
    $('overlay').classList.add('show');
}

function closeDrawer() {
    state.drawer = null;
    $('drawer').classList.remove('show');
    $('overlay').classList.remove('show');
}

/* ---------- Ouverture / fermeture ---------- */

function openTablet(msg) {
    state.data = msg.data || {};
    state.subtitle = msg.subtitle || '';
    if (Array.isArray(msg.permissions) && msg.permissions.length) state.permissions = msg.permissions;
    state.open = true;
    closeDrawer();
    closeModal();
    renderAll();
    $('tablet').classList.remove('hidden');
}

function hideTablet() {
    state.open = false;
    closeDrawer();
    closeModal();
    $('tablet').classList.add('hidden');
}

function closeTablet() {
    if (!state.open) return;
    hideTablet();
    post('close');
}

function openModal() {
    $('recruit-id').value = '';
    $('modal').classList.add('show');
}

function closeModal() {
    $('modal').classList.remove('show');
}

function setTab(tab) {
    state.tab = tab;
    document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === tab));
    document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('active', p.id === `tab-${tab}`));
}

/* ---------- Événements ---------- */

document.querySelectorAll('.tab').forEach((tab) => tab.addEventListener('click', () => setTab(tab.dataset.tab)));

document.querySelectorAll('.chip-btn').forEach((chip) => chip.addEventListener('click', () => {
    state.filter = chip.dataset.filter;
    document.querySelectorAll('.chip-btn').forEach((c) => c.classList.toggle('active', c === chip));
    renderMembers();
}));

$('search').addEventListener('input', (event) => {
    state.search = event.target.value;
    renderMembers();
});

$('members').addEventListener('click', (event) => {
    const row = event.target.closest('[data-member]');
    if (row) openDrawer({ type: 'member', id: row.dataset.member });
});

$('grades').addEventListener('click', (event) => {
    const row = event.target.closest('[data-grade], [data-new-grade]');
    if (!row) return;
    if (row.hasAttribute('data-new-grade')) openDrawer({ type: 'newGrade' });
    else openDrawer({ type: 'grade', level: Number(row.dataset.grade) });
});

$('drawer').addEventListener('click', (event) => {
    if (event.target.closest('[data-close-drawer]')) return closeDrawer();
    const button = event.target.closest('[data-act]');
    if (!button || button.disabled) return;
    const d = state.drawer;

    switch (button.dataset.act) {
        case 'promote':
        case 'demote':
            action(button.dataset.act, { id: d.id });
            break;
        case 'ask-kick':
            $('confirm-kick').classList.add('show');
            button.hidden = true;
            break;
        case 'cancel-kick':
            $('confirm-kick').classList.remove('show');
            $('drawer').querySelector('[data-act="ask-kick"]').hidden = false;
            break;
        case 'kick':
            action('kick', { id: d.id });
            closeDrawer();
            break;
        case 'save-grade': {
            const name = $('grade-name').value.trim();
            if (!name) return toast('Donne un nom au grade.', 'error');
            const level = Number($('grade-level').value);
            if (d.type === 'newGrade' && (!Number.isInteger(level) || level < 0)) return toast('Niveau invalide.', 'error');
            if (d.type === 'newGrade' && gradeOf(level)) return toast('Ce niveau existe déjà.', 'error');
            if (d.type === 'newGrade' && level >= me().grade) return toast('Le niveau doit être inférieur au tien.', 'error');
            const permissions = [...$('drawer').querySelectorAll('.perm input:checked')].map((i) => i.value);
            action('saveGrade', { level, name, permissions, new: d.type === 'newGrade' });
            closeDrawer();
            break;
        }
        case 'delete-grade':
            action('deleteGrade', { level: d.level });
            closeDrawer();
            break;
    }
});

$('overlay').addEventListener('click', closeDrawer);
$('btn-close').addEventListener('click', closeTablet);
$('btn-recruit').addEventListener('click', openModal);
$('modal-cancel').addEventListener('click', closeModal);
$('modal').addEventListener('click', (event) => { if (event.target === $('modal')) closeModal(); });

$('recruit-closest').addEventListener('click', () => {
    action('recruit', { closest: true });
    closeModal();
});

$('recruit-by-id').addEventListener('click', () => {
    const target = Number($('recruit-id').value);
    if (!Number.isInteger(target) || target < 1) return toast('Entre un ID de joueur valide.', 'error');
    action('recruit', { target });
    closeModal();
});

document.addEventListener('keydown', (event) => {
    if (!state.open || event.key !== 'Escape') return;
    if ($('modal').classList.contains('show')) closeModal();
    else if (state.drawer) closeDrawer();
    else closeTablet();
});

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    switch (msg.action) {
        case 'open':
            openTablet(msg);
            break;
        case 'update':
            state.data = msg.data || state.data;
            renderAll();
            break;
        case 'close':
            hideTablet();
            break;
        case 'toast':
            toast(msg.message, msg.kind);
            break;
    }
});

/* ---------- Aperçu hors jeu (données de démo, actions simulées) ---------- */

const DEMO = {
    name: 'Cartelgoon',
    type: 'Cartel',
    xp: 200,
    me: { id: 'malou', grade: 4 },
    grades: [
        { level: 4, name: 'Chef', permissions: ['coffre', 'tablette', 'service', 'recrutement', 'grades'] },
        { level: 3, name: 'Bras droit', permissions: ['coffre', 'tablette', 'service', 'recrutement', 'grades'] },
        { level: 2, name: 'Lieutenant', permissions: ['coffre', 'service', 'recrutement'] },
        { level: 1, name: 'Membre', permissions: ['coffre', 'service'] },
        { level: 0, name: 'Recrue', permissions: ['service'] },
    ],
    members: [
        { id: 'zqfs', name: 'Zqfs Eqqs', grade: 4, online: false, onDuty: false, serviceTime: 82 },
        { id: 'malou', name: 'Malou Malou', grade: 4, online: true, onDuty: true, serviceTime: 2 },
        { id: 'john', name: 'John Doe', grade: 0, online: true, onDuty: false, serviceTime: 0 },
        { id: 'stella', name: 'Stella Dasilva', grade: 0, online: false, onDuty: false, serviceTime: 0 },
    ],
};

function preview(name, data) {
    if (name !== 'action') return;
    const { action: act, payload } = data;
    const member = DEMO.members.find((m) => m.id === payload.id);
    const levels = DEMO.grades.map((g) => g.level).sort((a, b) => a - b);
    let message = 'Action effectuée.';

    if (act === 'promote' && member) {
        member.grade = levels[levels.indexOf(member.grade) + 1];
        message = `${member.name} a été promu.`;
    } else if (act === 'demote' && member) {
        member.grade = levels[levels.indexOf(member.grade) - 1];
        message = `${member.name} a été rétrogradé.`;
    } else if (act === 'kick' && member) {
        DEMO.members = DEMO.members.filter((m) => m !== member);
        message = `${member.name} a été exclu.`;
    } else if (act === 'saveGrade') {
        const existing = DEMO.grades.find((g) => g.level === payload.level);
        if (existing) Object.assign(existing, { name: payload.name, permissions: payload.permissions });
        else DEMO.grades.push({ level: payload.level, name: payload.name, permissions: payload.permissions });
        message = `Grade « ${payload.name} » enregistré.`;
    } else if (act === 'deleteGrade') {
        DEMO.grades = DEMO.grades.filter((g) => g.level !== payload.level);
        message = 'Grade supprimé.';
    } else if (act === 'recruit') {
        DEMO.members.push({ id: `new${Date.now()}`, name: 'Nouvelle Recrue', grade: Math.min(...levels), online: true, onDuty: false, serviceTime: 0 });
        message = 'Invitation envoyée.';
    }

    toast(message, 'success');
    state.data = JSON.parse(JSON.stringify(DEMO));
    renderAll();
}

if (!RESOURCE) {
    openTablet({ data: JSON.parse(JSON.stringify(DEMO)), subtitle: "Tablette de l'organisation" });
    if (location.hash === '#grades') setTab('grades');
}
