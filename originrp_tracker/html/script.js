const $ = (sel) => document.querySelector(sel);
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'originrp_tracker';

let state = { mine: [], pocket: [], messages: [] };
let maxName = 24;

function post(name, body = {}) {
    return fetch(`https://${resource}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(body),
    }).then((r) => r.json()).catch(() => null);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text ?? '';
    return div.innerHTML;
}

let toastTimer;
function toast(text, kind) {
    const el = $('#toast');
    el.textContent = text;
    el.className = `toast ${kind || ''}`;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.add('hidden'), 3500);
}

// ─── Modale (confirmation / saisie) ───────────────────────────────────────
function modal({ title, text, input, okLabel = 'Valider', danger = false }) {
    return new Promise((resolve) => {
        $('#modal-title').textContent = title;
        $('#modal-text').textContent = text || '';
        const field = $('#modal-input');
        field.classList.toggle('hidden', input === undefined);
        field.value = input ?? '';
        field.maxLength = maxName;
        const ok = $('#modal-ok');
        ok.textContent = okLabel;
        ok.className = danger ? 'btn danger' : 'btn';
        $('#modal').classList.remove('hidden');
        if (input !== undefined) setTimeout(() => field.focus(), 30);

        const done = (value) => {
            $('#modal').classList.add('hidden');
            ok.onclick = null; $('#modal-cancel').onclick = null; field.onkeydown = null;
            resolve(value);
        };
        ok.onclick = () => done(input !== undefined ? field.value : true);
        $('#modal-cancel').onclick = () => done(null);
        field.onkeydown = (e) => { if (e.key === 'Enter') ok.onclick(); };
    });
}

// ─── Rendu ────────────────────────────────────────────────────────────────
const LOCATIONS = { world: 'Posé / collé', pocket: 'Dans une poche', lost: 'Signal perdu' };

function renderMine() {
    const el = $('#tab-mine');
    if (!state.mine.length) {
        el.innerHTML = `<div class="empty">Aucun traceur synchronisé.<br>Mets un traceur dans ta poche puis va dans l'onglet « Synchroniser ».</div>`;
        return;
    }
    el.innerHTML = state.mine.map((t) => `
        <div class="card">
            <span class="dot ${t.active ? 'on' : ''}"></span>
            <div class="info">
                <strong>${escapeHtml(t.label)}</strong>
                <span>#${t.serial} · ${t.active ? 'Actif' : 'Désactivé'} · ${LOCATIONS[t.location] || ''}</span>
            </div>
            <div class="actions">
                <button class="btn ghost" data-rename="${t.serial}">Renommer</button>
                <button class="btn ghost" data-forget="${t.serial}" title="Désynchroniser">✕</button>
            </div>
            <div class="switch ${t.active ? 'on' : ''}" data-toggle="${t.serial}" title="${t.active ? 'Désactiver' : 'Activer'}"></div>
        </div>`).join('');
}

function renderPocket() {
    const el = $('#tab-pocket');
    if (!state.pocket.length) {
        el.innerHTML = `<div class="empty">Aucun traceur non synchronisé détecté dans ta poche.</div>`;
        return;
    }
    el.innerHTML = state.pocket.map((t) => `
        <div class="card">
            <span class="dot ${t.status === 'active' ? 'warn' : ''}"></span>
            <div class="info">
                <strong>Traceur #${t.serial}</strong>
                <span>${t.status === 'new' ? 'Nouveau traceur détecté' : t.status === 'active' ? 'Déjà actif sur un autre appareil' : 'Lié à un autre appareil (inactif)'}</span>
            </div>
            <button class="btn" data-sync="${t.slot}">Synchroniser</button>
        </div>`).join('');
}

function renderLog() {
    const el = $('#tab-log');
    if (!state.messages.length) {
        el.innerHTML = `<div class="empty">Aucune notification.</div>`;
        return;
    }
    el.innerHTML = state.messages.map((m) => `
        <div class="card log">
            <div class="info">
                <time>${new Date(m.time * 1000).toLocaleString('fr-FR')}</time>
                ${escapeHtml(m.text)}
            </div>
        </div>`).join('');
}

function render() {
    renderMine(); renderPocket(); renderLog();
    $('#count-mine').textContent = state.mine.length;
    const pocket = $('#count-pocket');
    pocket.textContent = state.pocket.length;
    pocket.toggleAttribute('data-zero', state.pocket.length === 0);
    $('#count-log').textContent = state.messages.length;
}

function showTab(name) {
    document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === name));
    document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('hidden', p.id !== `tab-${name}`));
}

// ─── Actions ──────────────────────────────────────────────────────────────
async function sync(slot) {
    let res = await post('sync', { slot });
    if (res && res.needForce) {
        const yes = await modal({
            title: 'Traceur déjà actif',
            text: 'Ce tracker est déjà actif. Voulez-vous forcer la déconnexion ?',
            okLabel: 'Oui, forcer',
            danger: true,
        });
        if (!yes) return;
        res = await post('sync', { slot, force: true });
    }
    if (res && res.message) toast(res.message, res.ok ? '' : 'error');
    if (res && res.ok) showTab('mine');
}

document.addEventListener('click', async (e) => {
    const t = e.target.closest('[data-tab],[data-toggle],[data-rename],[data-forget],[data-sync],[data-close]');
    if (!t) return;
    if (t.dataset.tab) showTab(t.dataset.tab);
    else if (t.dataset.toggle) post('toggle', { serial: t.dataset.toggle });
    else if (t.dataset.sync) sync(Number(t.dataset.sync));
    else if (t.dataset.rename) {
        const tracker = state.mine.find((x) => x.serial === t.dataset.rename);
        const name = await modal({
            title: 'Renommer le traceur',
            text: 'Il apparaîtra sur la carte sous « Tracker : nom ».',
            input: tracker?.name || '',
        });
        if (name !== null) post('rename', { serial: t.dataset.rename, name });
    } else if (t.dataset.forget) {
        const yes = await modal({ title: 'Désynchroniser', text: 'Retirer ce traceur de ta tablette ?', okLabel: 'Retirer', danger: true });
        if (yes) post('forget', { serial: t.dataset.forget });
    } else if (t.hasAttribute('data-close')) post('close');
});

document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    if (!$('#modal').classList.contains('hidden')) $('#modal-cancel').click();
    else post('close');
});

window.addEventListener('message', ({ data }) => {
    switch (data.action) {
        case 'open':
            state = data.data; maxName = data.maxName || 24;
            render();
            showTab(state.pocket.length ? 'pocket' : 'mine');
            $('#tablet').classList.remove('hidden');
            break;
        case 'update':
            state = data.data; render();
            break;
        case 'message':
            state.messages.unshift(data.message); render();
            toast(data.message.text, 'error');
            break;
        case 'close':
            $('#tablet').classList.add('hidden');
            $('#modal').classList.add('hidden');
            break;
    }
});
