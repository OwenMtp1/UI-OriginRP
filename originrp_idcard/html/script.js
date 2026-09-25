'use strict';

const card = document.getElementById('card');
const $ = (id) => document.getElementById(id);

/* ---------- Mise en forme ---------- */

function formatDate(value) {
    if (!value) return '';
    const text = String(value).trim();
    let m = text.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})/);
    if (m) return `${m[3].padStart(2, '0')}/${m[2].padStart(2, '0')}/${m[1]}`;
    m = text.match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})/);
    if (m) return `${m[1].padStart(2, '0')}/${m[2].padStart(2, '0')}/${m[3]}`;
    return text;
}

function formatSex(value) {
    const v = String(value ?? '').trim().toLowerCase();
    if (['m', 'h', 'homme', 'male', 'man', '0'].includes(v)) return 'Homme';
    if (['f', 'femme', 'female', 'woman', '1'].includes(v)) return 'Femme';
    return value ? String(value) : '';
}

function formatHeight(value) {
    if (value == null || value === '') return '';
    const n = Number(value);
    return Number.isFinite(n) ? `${n} cm` : String(value);
}

function capitalize(text) {
    return String(text || '').replace(/(^|[\s-])(\p{L})/gu, (_, sep, c) => sep + c.toUpperCase());
}

/* ---------- Bande de lecture ---------- */

function mrzText(value) {
    return String(value || '')
        .normalize('NFD').replace(/[̀-ͯ]/g, '')
        .toUpperCase().replace(/[^A-Z0-9]+/g, '<');
}

function pad(text, length) {
    return (text + '<'.repeat(length)).slice(0, length);
}

const DOCS = {
    id: { title: "Carte d'identité", subtitle: 'Identity card', created: 'Date de création', code: 'ID' },
    license: { title: 'Permis de conduire', subtitle: 'Driver license', created: 'Délivré le', code: 'DL' },
};

function buildMrz(data, birthdate) {
    const d = birthdate.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
    const yymmdd = d ? d[3].slice(2) + d[2] + d[1] : '<<<<<<';
    const sex = formatSex(data.sex) === 'Femme' ? 'F' : 'M';
    const code = (DOCS[data.type] || DOCS.id).code;
    const line1 = pad(`${code}LSC${mrzText(data.number)}`, 30);
    const line2 = pad(`${yymmdd}${sex}<${mrzText(data.lastname)}<<${mrzText(data.firstname)}`, 30);
    return `${line1}\n${line2}`;
}

/* ---------- Affichage ---------- */

function render(data) {
    const doc = DOCS[data.type] ? data.type : 'id';
    card.dataset.doc = doc;
    $('doc-title').textContent = DOCS[doc].title;
    $('doc-subtitle').textContent = DOCS[doc].subtitle;
    $('created-label').textContent = DOCS[doc].created;

    const licenses = data.licenses || {};
    ['car', 'bike', 'truck'].forEach((key) => $(`cat-${key}`).classList.toggle('on', licenses[key] === true));

    const lastname = capitalize(data.lastname);
    const firstname = capitalize(data.firstname);
    const birthdate = formatDate(data.birthdate || data.dateofbirth);

    $('f-lastname').textContent = lastname || '-';
    $('f-firstname').textContent = firstname || '-';
    $('f-sex').textContent = formatSex(data.sex ?? data.gender) || '-';
    $('f-birthdate').textContent = birthdate || '-';
    $('f-height').textContent = formatHeight(data.height) || '-';
    $('f-birthplace').textContent = data.birthplace || '-';
    $('id-signature').textContent = [firstname, lastname].filter(Boolean).join(' ');

    const created = formatDate(data.created);
    $('f-created').textContent = created;
    $('row-created').classList.toggle('off', !created);
    $('f-number').textContent = data.number || '';
    $('row-number').classList.toggle('off', !data.number);

    const photo = $('id-photo-img');
    const frame = photo.parentElement;
    if (data.photo) {
        photo.onerror = () => frame.classList.remove('has-photo');
        photo.src = data.photo;
        frame.classList.add('has-photo');
    } else {
        photo.removeAttribute('src');
        frame.classList.remove('has-photo');
    }

    $('id-mrz').textContent = buildMrz(data, birthdate);
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') {
        if (msg.position) card.dataset.position = msg.position;
        render(msg.data || {});
        card.classList.remove('hidden');
    } else if (msg.action === 'close') {
        card.classList.add('hidden');
    }
});

/* ---------- Aperçu hors jeu ---------- */

if (typeof GetParentResourceName !== 'function') {
    // index.html#permis affiche le permis de conduire
    const license = location.hash === '#permis';
    card.dataset.position = 'center';
    render({
        type: license ? 'license' : 'id',
        licenses: { car: true, bike: true, truck: false },
        lastname: 'Azar',
        firstname: 'Raph',
        sex: 'm',
        birthdate: '22/11/2001',
        height: 185,
        birthplace: 'Los Santos',
        created: '31/07/2025',
    });
    requestAnimationFrame(() => card.classList.remove('hidden'));
}
