'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
const $ = (id) => document.getElementById(id);
const stroke = (d, w = 2) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;

const ICONS = {
    identity: stroke('<rect x="2" y="5" width="20" height="14" rx="2"/><circle cx="8" cy="12" r="2.2"/><path d="M14 10h4M14 14h4"/>'),
    heritage: stroke('<circle cx="7" cy="7" r="3"/><circle cx="17" cy="7" r="3"/><path d="M7 10v3a5 5 0 0 0 10 0v-3"/><circle cx="12" cy="20" r="1.5"/>'),
    face: stroke('<circle cx="12" cy="12" r="9"/><path d="M9 10h.01M15 10h.01M9 15c1.5 1.5 4.5 1.5 6 0"/>'),
    appearance: stroke('<path d="M4 20c0-6 3-9 8-9s8 3 8 9"/><path d="M6 11C6 6 8.5 3 12 3s6 3 6 8"/><path d="M9 7c2 1 4 1 6-1"/>'),
    clothes: stroke('<path d="M20.4 3.5 16 2a4 4 0 0 1-8 0L3.6 3.5a2 2 0 0 0-1.3 2.2l.6 3.5a1 1 0 0 0 1 .8H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.2a1 1 0 0 0 1-.8l.6-3.5a2 2 0 0 0-1.4-2.2z"/>'),
    summary: stroke('<path d="M9 11l3 3 8-8"/><path d="M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h9"/>'),
    check: stroke('<path d="m5 12.5 4.5 4.5L19 7.5"/>', 2.8),
    prev: stroke('<path d="m15 5-7 7 7 7"/>', 2.4),
    next: stroke('<path d="m9 5 7 7-7 7"/>', 2.4),
    dice: stroke('<rect x="3" y="3" width="18" height="18" rx="4"/><path d="M8 8h.01M16 8h.01M12 12h.01M8 16h.01M16 16h.01"/>', 2.6),
    reset: stroke('<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>'),
    info: stroke('<circle cx="12" cy="12" r="9"/><path d="M12 16v-4.5M12 8h.01"/>'),
    male: stroke('<circle cx="10" cy="14" r="6"/><path d="m14.5 9.5 6-6M15 3.5h5.5V9"/>'),
    female: stroke('<circle cx="12" cy="9" r="6"/><path d="M12 15v7M9 19h6"/>'),
    top: stroke('<path d="M20.4 3.5 16 2a4 4 0 0 1-8 0L3.6 3.5a2 2 0 0 0-1.3 2.2l.6 3.5a1 1 0 0 0 1 .8H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.2a1 1 0 0 0 1-.8l.6-3.5a2 2 0 0 0-1.4-2.2z"/>'),
    undershirt: stroke('<path d="M8 3v3a4 4 0 0 0 8 0V3M8 3 5 4v17h14V4l-3-1"/>'),
    arms: stroke('<path d="M7 21v-6L4 11a1.5 1.5 0 0 1 2-2l2 2V4a1.5 1.5 0 0 1 3 0v5V3a1.5 1.5 0 0 1 3 0v6V4.5a1.5 1.5 0 0 1 3 0V15l-2 6z"/>'),
    pants: stroke('<path d="M6 3h12l1 18h-5l-2-11-2 11H5z"/><path d="M6 7h12"/>'),
    shoes: stroke('<path d="M3 17V9h5l3 3 6 1a4 4 0 0 1 4 4v1H3z"/><path d="M3 20h18"/>'),
    chain: stroke('<path d="M6 3c0 6 2.5 10 6 10s6-4 6-10"/><circle cx="12" cy="16" r="2.5"/>'),
    hat: stroke('<path d="M4 16a8 8 0 0 1 16 0"/><path d="M2 16h20v2H2z"/>'),
    glasses: stroke('<circle cx="6" cy="15" r="4"/><circle cx="18" cy="15" r="4"/><path d="M10 15h4M2 15l2-7h3M22 15l-2-7h-3"/>'),
    outfit: stroke('<path d="M12 4a2 2 0 1 1 2 2c-1 0-2 .9-2 2v1"/><path d="M12 9 2.5 16.5A1 1 0 0 0 3 18h18a1 1 0 0 0 .5-1.5z"/>'),
};

const STEPS = [
    { id: 'identity', label: 'Identité', title: 'Identité', desc: 'Ton nom, ta date de naissance et ta taille. Elle sera définitive.', cam: 'body' },
    { id: 'heritage', label: 'Héritage', title: 'Héritage', desc: 'Choisis tes parents puis dose la ressemblance et le teint de peau.', cam: 'face' },
    { id: 'face', label: 'Visage', title: 'Traits du visage', desc: 'Affine chaque partie du visage. 0 = trait hérité des parents.', cam: 'face' },
    { id: 'appearance', label: 'Apparence', title: 'Apparence', desc: 'Cheveux, pilosité, yeux, maquillage et peau.', cam: 'face' },
    { id: 'clothes', label: 'Vêtements', title: 'Tenue de départ', desc: 'Pars d\'une tenue prête à porter puis ajuste chaque pièce.', cam: 'body' },
    { id: 'summary', label: 'Résumé', title: 'Récapitulatif', desc: 'Vérifie tout avant d\'entrer en ville.', cam: 'body' },
];

// Parents GTA (identifiants du jeu)
const MOTHERS = ['Hannah', 'Audrey', 'Jasmine', 'Giselle', 'Amelia', 'Isabella', 'Zoe', 'Ava', 'Camila', 'Violet', 'Sophia',
    'Evelyn', 'Nicole', 'Ashley', 'Grace', 'Brianna', 'Natalie', 'Olivia', 'Elizabeth', 'Charlotte', 'Emma']
    .map((name, i) => ({ id: 21 + i, name })).concat([{ id: 45, name: 'Misty' }]);
const FATHERS = ['Benjamin', 'Daniel', 'Joshua', 'Noah', 'Andrew', 'Juan', 'Alex', 'Isaac', 'Evan', 'Ethan', 'Vincent',
    'Angel', 'Diego', 'Adrian', 'Gabriel', 'Michael', 'Santiago', 'Kevin', 'Louis', 'Samuel', 'Anthony']
    .map((name, i) => ({ id: i, name })).concat([{ id: 42, name: 'Claude' }, { id: 43, name: 'Niko' }, { id: 44, name: 'John' }]);

// Traits du visage (index GTA 0-19), regroupés
const FACE_GROUPS = [
    { label: 'Nez', items: [[0, 'Largeur'], [1, 'Hauteur'], [2, 'Longueur'], [3, 'Arête'], [4, 'Pointe'], [5, 'Déviation']] },
    { label: 'Sourcils', items: [[6, 'Hauteur'], [7, 'Profondeur']] },
    { label: 'Pommettes', items: [[8, 'Hauteur'], [9, 'Largeur'], [10, 'Joues']] },
    { label: 'Yeux', items: [[11, 'Ouverture des yeux'], [12, 'Épaisseur des lèvres']] },
    { label: 'Mâchoire', items: [[13, 'Largeur'], [14, 'Forme'], [15, 'Hauteur du menton'], [16, 'Longueur du menton'], [17, 'Largeur du menton'], [18, 'Fossette'], [19, 'Épaisseur du cou']] },
];

// Calques de tête (index GTA) ; color : 'hair' ou 'makeup'
const OVERLAYS = {
    0: { label: 'Imperfections' },
    1: { label: 'Barbe', color: 'hair', sex: 'm' },
    2: { label: 'Sourcils', color: 'hair' },
    3: { label: 'Vieillissement' },
    4: { label: 'Maquillage des yeux' },
    5: { label: 'Blush', color: 'makeup' },
    6: { label: 'Teint' },
    7: { label: 'Dommages solaires' },
    8: { label: 'Rouge à lèvres', color: 'makeup' },
    9: { label: 'Grains de beauté' },
    10: { label: 'Pilosité du torse', color: 'hair', sex: 'm' },
};

const APPEARANCE_TABS = [
    { id: 'hair', label: 'Cheveux' },
    { id: 'hairy', label: 'Pilosité', overlays: [1, 2, 10] },
    { id: 'eyes', label: 'Yeux' },
    { id: 'makeup', label: 'Maquillage', overlays: [4, 5, 8] },
    { id: 'skin', label: 'Peau', overlays: [3, 6, 0, 7, 9] },
];

const EYE_COLORS = ['#3d8c4a', '#2e6f9e', '#5aa2d6', '#6b4a2b', '#3b2618', '#8a6a3b', '#7a7f86', '#9db4c4', '#b3913e', '#5e7d3a',
    '#2c4f75', '#1d1d1d', '#a33b2b', '#d6d6d6', '#6a2c8a', '#c9a227', '#98c3d9', '#4a6b2f', '#8d5c33', '#4b3a2a',
    '#9e2e2e', '#2f2f6b', '#e0e0e0', '#c06a1a', '#55a0a0', '#305030', '#7d3c98', '#b0b0b0', '#333366', '#663333', '#ffcc00', '#00aaff'];

const CLOTHES = [
    { id: 'tops', label: 'Haut', icon: 'top' },
    { id: 'undershirt', label: 'Sous-haut', icon: 'undershirt' },
    { id: 'arms', label: 'Bras', icon: 'arms' },
    { id: 'pants', label: 'Pantalon', icon: 'pants' },
    { id: 'shoes', label: 'Chaussures', icon: 'shoes' },
    { id: 'chain', label: 'Chaîne', icon: 'chain' },
    { id: 'hat', label: 'Chapeau', icon: 'hat', prop: true },
    { id: 'glasses', label: 'Lunettes', icon: 'glasses', prop: true },
];

/* ---------- État ---------- */

const state = {
    open: false,
    step: 0,
    visited: 0,
    sub: { face: 0, appearance: 0 },
    char: null,
    counts: null,
    palette: { hair: [], makeup: [] },
    config: { minAge: 18, maxAge: 90, heightMin: 150, heightMax: 210, outfits: { m: [], f: [] } },
    outfit: null,
    confirmed: false,
    camera: 'body',
};

function defaultChar(sex = 'm') {
    const overlays = {};
    Object.keys(OVERLAYS).forEach((i) => { overlays[i] = { style: -1, opacity: 100, color: 0 }; });
    overlays[2] = { style: sex === 'm' ? 0 : 1, opacity: 100, color: 0 };
    const clothes = {};
    CLOTHES.forEach((c) => { clothes[c.id] = { d: c.prop ? -1 : 0, t: 0 }; });
    return {
        identity: { firstname: '', lastname: '', day: '', month: '', year: '', sex, height: 175 },
        heritage: { mother: 21, father: 0, shape: 50, skin: 50 },
        face: Array(20).fill(0),
        hair: { style: 0, color: 0, highlight: 0 },
        eyes: 0,
        overlays,
        clothes,
    };
}

/* ---------- Utilitaires ---------- */

function esc(text) {
    const div = document.createElement('div');
    div.textContent = text == null ? '' : String(text);
    return div.innerHTML;
}

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const pick = (list) => list[rand(0, list.length - 1)];

function post(name, data = {}) {
    if (!RESOURCE) return Promise.resolve(preview(name, data));
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).then((r) => r.json()).catch(() => null);
}

let toastTimer = null;
function toast(message) {
    const node = $('toast');
    node.textContent = message;
    node.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => node.classList.remove('show'), 2600);
}

// Envoi de l'apparence au jeu, regroupé pour rester fluide pendant les glissements
let applyTimer = null;
function apply() {
    clearTimeout(applyTimer);
    applyTimer = setTimeout(() => {
        post('apply', { char: state.char }).then((res) => {
            if (res && res.counts) {
                const needsRender = JSON.stringify(res.counts) !== JSON.stringify(state.counts);
                state.counts = res.counts;
                if (needsRender) renderContent(false, true);
            }
        });
    }, 40);
}

const counts = () => state.counts || {};
const overlayCount = (i) => counts().overlays?.[i] ?? 20;
const clothCount = (id) => counts().clothes?.[id] || { drawables: 100, textures: 10 };

/* ---------- Identité : validation ---------- */

const NAME_RE = /^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ' -]{1,19}$/;

function identityErrors() {
    const id = state.char.identity;
    const cfg = state.config;
    const errors = {};
    if (!NAME_RE.test(id.firstname.trim())) errors.firstname = '2 à 20 lettres, sans chiffres.';
    if (!NAME_RE.test(id.lastname.trim())) errors.lastname = '2 à 20 lettres, sans chiffres.';
    const d = Number(id.day), m = Number(id.month), y = Number(id.year);
    const date = new Date(y, m - 1, d);
    if (!d || !m || !y || date.getDate() !== d || date.getMonth() !== m - 1) {
        errors.dob = 'Date invalide (JJ / MM / AAAA).';
    } else {
        const now = new Date();
        let age = now.getFullYear() - y;
        if (now < new Date(now.getFullYear(), m - 1, d)) age--;
        if (age < cfg.minAge) errors.dob = `Ton personnage doit avoir au moins ${cfg.minAge} ans.`;
        else if (age > cfg.maxAge) errors.dob = `Ton personnage doit avoir moins de ${cfg.maxAge} ans.`;
    }
    return errors;
}

const capitalize = (s) => s.trim().toLowerCase().replace(/(^|[\s'-])(\p{L})/gu, (_, sep, c) => sep + c.toUpperCase());

/* ---------- Rendu : composants ---------- */

function sliderHtml(key, label, value, { min = 0, max = 100, center = false, ends } = {}) {
    let style;
    if (center) {
        const p = ((value - min) / (max - min)) * 100;
        style = `--from:${Math.min(50, p)}%;--to:${Math.max(50, p)}%`;
    } else {
        style = `--fill:${((value - min) / (max - min)) * 100}%`;
    }
    return `
        <div class="slider">
            <div class="label"><span>${esc(label)}</span><strong>${value > 0 && center ? '+' : ''}${value}</strong></div>
            <input class="range${center ? ' center' : ''}" type="range" min="${min}" max="${max}" value="${value}" data-slider="${key}" style="${style}">
            ${ends ? `<div class="ends"><span>${ends[0]}</span><span>${ends[1]}</span></div>` : ''}
        </div>`;
}

function stepperHtml(key, text) {
    return `<div class="stepper"><button data-step="${key}" data-dir="-1" type="button">${ICONS.prev}</button><span>${text}</span><button data-step="${key}" data-dir="1" type="button">${ICONS.next}</button></div>`;
}

function swatchesHtml(key, colors, active, extraClass = '') {
    return `<div class="swatches ${extraClass}">${colors.map((c, i) => `<button class="swatch${i === active ? ' active' : ''}" data-swatch="${key}" data-value="${i}" style="background:${c}" type="button"></button>`).join('')}</div>`;
}

function headHtml(step, tools) {
    return `
        <div class="section-head">
            <div><h2>${step.title}</h2><p>${step.desc}</p></div>
            ${tools ? `<div class="tools">
                <button class="tool" data-tool="random" title="Aléatoire" type="button">${ICONS.dice}</button>
                <button class="tool" data-tool="reset" title="Réinitialiser" type="button">${ICONS.reset}</button>
            </div>` : ''}
        </div>`;
}

function subtabsHtml(group, tabs, active) {
    return `<div class="subtabs">${tabs.map((t, i) => `<button class="subtab${i === active ? ' active' : ''}" data-sub="${group}" data-value="${i}" type="button">${esc(t.label)}</button>`).join('')}</div>`;
}

/* ---------- Rendu : étapes ---------- */

function identityHtml() {
    const id = state.char.identity;
    const err = state.showErrors ? identityErrors() : {};
    const cfg = state.config;
    return `
        ${headHtml(STEPS[0])}
        <div class="grid2">
            <div class="field"><div class="label">Prénom</div>
                <input class="input${err.firstname ? ' invalid' : ''}" data-id="firstname" value="${esc(id.firstname)}" maxlength="20" placeholder="Warner">
                ${err.firstname ? `<p class="error">${err.firstname}</p>` : ''}</div>
            <div class="field"><div class="label">Nom</div>
                <input class="input${err.lastname ? ' invalid' : ''}" data-id="lastname" value="${esc(id.lastname)}" maxlength="20" placeholder="Bross">
                ${err.lastname ? `<p class="error">${err.lastname}</p>` : ''}</div>
        </div>
        <div class="field"><div class="label">Date de naissance</div>
            <div class="dob">
                <input class="input${err.dob ? ' invalid' : ''}" data-id="day" value="${esc(id.day)}" maxlength="2" inputmode="numeric" placeholder="JJ">
                <input class="input${err.dob ? ' invalid' : ''}" data-id="month" value="${esc(id.month)}" maxlength="2" inputmode="numeric" placeholder="MM">
                <input class="input${err.dob ? ' invalid' : ''}" data-id="year" value="${esc(id.year)}" maxlength="4" inputmode="numeric" placeholder="AAAA">
            </div>
            ${err.dob ? `<p class="error">${err.dob}</p>` : ''}</div>
        <div class="field"><div class="label">Sexe</div>
            <div class="segmented">
                <button class="${id.sex === 'm' ? 'active' : ''}" data-sex="m" type="button">${ICONS.male}Homme</button>
                <button class="${id.sex === 'f' ? 'active' : ''}" data-sex="f" type="button">${ICONS.female}Femme</button>
            </div></div>
        ${sliderHtml('height', 'Taille (cm)', id.height, { min: cfg.heightMin, max: cfg.heightMax, ends: [`${cfg.heightMin} cm`, `${cfg.heightMax} cm`] })}
        <div class="note">${ICONS.info}<span>Ton identité est <strong>définitive</strong> une fois validée. Choisis un nom réaliste et conforme au règlement RP du serveur.</span></div>`;
}

function heritageHtml() {
    const h = state.char.heritage;
    const mother = MOTHERS.find((p) => p.id === h.mother) || MOTHERS[0];
    const father = FATHERS.find((p) => p.id === h.father) || FATHERS[0];
    return `
        ${headHtml(STEPS[1], true)}
        <div class="parents">
            <div class="parent"><div class="avatar">${esc(mother.name[0])}</div><small>Mère</small>${stepperHtml('mother', esc(mother.name))}</div>
            <div class="parent"><div class="avatar">${esc(father.name[0])}</div><small>Père</small>${stepperHtml('father', esc(father.name))}</div>
        </div>
        ${sliderHtml('shape', 'Ressemblance', h.shape, { ends: ['Mère', 'Père'] })}
        ${sliderHtml('skin', 'Teint de peau', h.skin, { ends: ['Mère', 'Père'] })}`;
}

function faceHtml() {
    const g = FACE_GROUPS[state.sub.face];
    return `
        ${headHtml(STEPS[2], true)}
        ${subtabsHtml('face', FACE_GROUPS, state.sub.face)}
        ${g.items.map(([i, label]) => sliderHtml(`face:${i}`, label, state.char.face[i], { min: -100, max: 100, center: true })).join('')}`;
}

function overlayHtml(i) {
    const meta = OVERLAYS[i];
    const o = state.char.overlays[i];
    const count = overlayCount(i);
    const text = o.style < 0 ? 'Aucun' : `Style ${o.style + 1} <em>/ ${count}</em>`;
    const colors = meta.color ? state.palette[meta.color] : null;
    return `
        <div class="block">
            <div class="block-title">${esc(meta.label)}</div>
            ${stepperHtml(`overlay:${i}`, text)}
            ${o.style >= 0 ? sliderHtml(`opacity:${i}`, 'Intensité', o.opacity) : ''}
            ${o.style >= 0 && colors?.length ? swatchesHtml(`ocolor:${i}`, colors, o.color) : ''}
        </div>`;
}

function appearanceHtml() {
    const tab = APPEARANCE_TABS[state.sub.appearance];
    const ch = state.char;
    let body = '';
    if (tab.id === 'hair') {
        body = `
            <div class="block"><div class="block-title">Coupe</div>${stepperHtml('hair', `Coupe ${ch.hair.style + 1} <em>/ ${counts().hair ?? 80}</em>`)}</div>
            <div class="block"><div class="block-title">Couleur</div>${swatchesHtml('hairColor', state.palette.hair, ch.hair.color)}</div>
            <div class="block"><div class="block-title">Mèches</div>${swatchesHtml('hairHighlight', state.palette.hair, ch.hair.highlight)}</div>`;
    } else if (tab.id === 'eyes') {
        body = `<div class="block"><div class="block-title">Couleur des yeux</div>${swatchesHtml('eyes', EYE_COLORS, ch.eyes, 'eyes')}</div>`;
    } else {
        body = tab.overlays.filter((i) => !OVERLAYS[i].sex || OVERLAYS[i].sex === ch.identity.sex).map(overlayHtml).join('');
    }
    return `${headHtml(STEPS[3], true)}${subtabsHtml('appearance', APPEARANCE_TABS, state.sub.appearance)}${body}`;
}

function clothesHtml() {
    const sex = state.char.identity.sex;
    const outfits = state.config.outfits?.[sex] || [];
    const rows = CLOTHES.map((c) => {
        const v = state.char.clothes[c.id];
        const n = clothCount(c.id);
        const model = c.prop && v.d < 0 ? 'Aucun' : `${v.d + 1} <em>/ ${n.drawables}</em>`;
        const tex = c.prop && v.d < 0 ? '—' : `${v.t + 1} <em>/ ${Math.max(1, n.textures)}</em>`;
        return `<div class="cloth-row"><span class="name">${ICONS[c.icon]}${esc(c.label)}</span>${stepperHtml(`cloth:${c.id}`, model)}${stepperHtml(`tex:${c.id}`, tex)}</div>`;
    }).join('');
    return `
        ${headHtml(STEPS[4], true)}
        ${outfits.length ? `<div class="label"><span>Tenues prêtes à porter</span></div>
        <div class="outfits">${outfits.map((o, i) => `<button class="outfit${state.outfit === i ? ' active' : ''}" data-outfit="${i}" type="button">${ICONS.outfit}${esc(o.label)}</button>`).join('')}</div>` : ''}
        <div class="block">
            <div class="cloth-head"><span>Pièce</span><span>Modèle</span><span>Couleur</span></div>
            ${rows}
        </div>`;
}

function summaryHtml() {
    const id = state.char.identity;
    const h = state.char.heritage;
    const mother = MOTHERS.find((p) => p.id === h.mother)?.name;
    const father = FATHERS.find((p) => p.id === h.father)?.name;
    const name = `${capitalize(id.firstname)} ${capitalize(id.lastname)}`;
    const edit = (step) => `<button class="edit" data-goto="${step}" type="button">Modifier</button>`;
    return `
        ${headHtml(STEPS[5])}
        <div class="summary">
            <div class="summary-head"><div class="avatar">${esc((id.firstname[0] || '?') + (id.lastname[0] || ''))}</div>
                <div><strong>${esc(name)}</strong><small>${id.sex === 'm' ? 'Homme' : 'Femme'} · ${id.height} cm</small></div></div>
            <dl>
                <div><dt>Naissance ${edit(0)}</dt><dd>${esc(`${String(id.day).padStart(2, '0')}/${String(id.month).padStart(2, '0')}/${id.year}`)}</dd></div>
                <div><dt>Parents ${edit(1)}</dt><dd>${esc(`${mother} & ${father}`)}</dd></div>
                <div><dt>Coiffure ${edit(3)}</dt><dd>Coupe ${state.char.hair.style + 1}</dd></div>
                <div><dt>Tenue ${edit(4)}</dt><dd>${esc(state.outfit != null ? (state.config.outfits?.[id.sex]?.[state.outfit]?.label || 'Personnalisée') : 'Personnalisée')}</dd></div>
            </dl>
        </div>
        <div class="check${state.confirmed ? ' on' : ''}" data-confirm>
            <span class="box">${ICONS.check}</span>
            <span><strong>Je confirme mon personnage.</strong> Je ne pourrai plus changer mon identité ; l'apparence restera modifiable chez le coiffeur, le chirurgien et dans les magasins.</span>
        </div>`;
}

const RENDERERS = { identity: identityHtml, heritage: heritageHtml, face: faceHtml, appearance: appearanceHtml, clothes: clothesHtml, summary: summaryHtml };

/* ---------- Rendu général ---------- */

function canLeaveIdentity() {
    return Object.keys(identityErrors()).length === 0;
}

function renderHeader() {
    const step = STEPS[state.step];
    $('step-label').textContent = `Étape ${state.step + 1} / ${STEPS.length} · ${step.label}`;
    $('progress-bar').style.width = `${((state.step + 1) / STEPS.length) * 100}%`;
    const identityOk = canLeaveIdentity();
    $('steps').innerHTML = STEPS.map((s, i) => {
        const done = i < state.step || (i <= state.visited && i !== state.step);
        const locked = i > 0 && !identityOk;
        return `<button class="step${i === state.step ? ' active' : ''}${done ? ' done' : ''}" data-goto="${i}" type="button" ${locked ? 'disabled' : ''}>
            <span class="step-dot">${done ? ICONS.check : ICONS[s.id]}</span>${s.label}</button>`;
    }).join('');
    const last = state.step === STEPS.length - 1;
    $('btn-back').disabled = state.step === 0;
    $('btn-next').textContent = last ? 'Valider le personnage' : 'Continuer';
    $('btn-next').disabled = last ? !state.confirmed : false;
}

// keep = ne pas perdre le champ en cours de saisie / la position de défilement
function renderContent(animate, keep) {
    const content = $('content');
    const scroll = content.scrollTop;
    const active = document.activeElement;
    const activeKey = active?.dataset?.id;
    const caret = activeKey ? active.selectionStart : null;
    content.innerHTML = RENDERERS[STEPS[state.step].id]();
    content.classList.remove('slide');
    if (animate) { void content.offsetWidth; content.classList.add('slide'); content.scrollTop = 0; }
    else if (keep) content.scrollTop = scroll;
    if (activeKey) {
        const input = content.querySelector(`[data-id="${activeKey}"]`);
        if (input) { input.focus(); input.setSelectionRange(caret, caret); }
    }
    renderHeader();
}

function setCamera(preset) {
    state.camera = preset;
    document.querySelectorAll('#cam-presets button').forEach((b) => b.classList.toggle('active', b.dataset.cam === preset));
    post('camera', { preset });
}

function goTo(index) {
    if (index === state.step || index < 0 || index >= STEPS.length) return;
    if (index > 0 && !canLeaveIdentity()) {
        state.showErrors = true;
        renderContent(false, true);
        return toast('Complète ton identité avant de continuer.');
    }
    state.step = index;
    state.visited = Math.max(state.visited, index);
    setCamera(STEPS[index].cam);
    renderContent(true);
}

/* ---------- Aléatoire / réinitialiser ---------- */

function randomize() {
    const ch = state.char;
    const id = STEPS[state.step].id;
    if (id === 'heritage') {
        ch.heritage = { mother: pick(MOTHERS).id, father: pick(FATHERS).id, shape: rand(15, 85), skin: rand(10, 90) };
    } else if (id === 'face') {
        ch.face = ch.face.map(() => rand(-45, 45));
    } else if (id === 'appearance') {
        ch.hair = { style: rand(0, (counts().hair ?? 30) - 1), color: rand(0, Math.min(20, state.palette.hair.length - 1)), highlight: rand(0, Math.min(20, state.palette.hair.length - 1)) };
        ch.eyes = rand(0, 8);
        if (ch.identity.sex === 'm') ch.overlays[1] = { style: rand(-1, overlayCount(1) - 1), opacity: rand(60, 100), color: ch.hair.color };
        ch.overlays[2] = { style: rand(0, overlayCount(2) - 1), opacity: rand(70, 100), color: ch.hair.color };
    } else if (id === 'clothes') {
        CLOTHES.filter((c) => !c.prop).forEach((c) => { ch.clothes[c.id] = { d: rand(0, Math.min(40, clothCount(c.id).drawables - 1)), t: 0 }; });
        state.outfit = null;
    }
    apply();
    renderContent(false, true);
}

function resetStep() {
    const fresh = defaultChar(state.char.identity.sex);
    const id = STEPS[state.step].id;
    if (id === 'heritage') state.char.heritage = fresh.heritage;
    else if (id === 'face') state.char.face = fresh.face;
    else if (id === 'appearance') Object.assign(state.char, { hair: fresh.hair, eyes: fresh.eyes, overlays: fresh.overlays });
    else if (id === 'clothes') { state.char.clothes = fresh.clothes; state.outfit = null; }
    apply();
    renderContent(false, true);
}

/* ---------- Interactions ---------- */

function cycle(value, dir, min, max) {
    if (value + dir > max) return min;
    if (value + dir < min) return max;
    return value + dir;
}

function onStep(key, dir) {
    const ch = state.char;
    const [kind, arg] = key.split(':');
    if (kind === 'mother' || kind === 'father') {
        const list = kind === 'mother' ? MOTHERS : FATHERS;
        const index = list.findIndex((p) => p.id === ch.heritage[kind]);
        ch.heritage[kind] = list[cycle(index, dir, 0, list.length - 1)].id;
    } else if (kind === 'hair') {
        ch.hair.style = cycle(ch.hair.style, dir, 0, (counts().hair ?? 80) - 1);
    } else if (kind === 'overlay') {
        const o = ch.overlays[arg];
        o.style = cycle(o.style, dir, -1, overlayCount(arg) - 1);
    } else if (kind === 'cloth') {
        const c = CLOTHES.find((x) => x.id === arg);
        const v = ch.clothes[arg];
        v.d = cycle(v.d, dir, c.prop ? -1 : 0, clothCount(arg).drawables - 1);
        v.t = 0;
        state.outfit = null;
    } else if (kind === 'tex') {
        const v = ch.clothes[arg];
        if (v.d < 0) return;
        v.t = cycle(v.t, dir, 0, Math.max(1, clothCount(arg).textures) - 1);
        state.outfit = null;
    }
    apply();
    renderContent(false, true);
}

function onSlider(key, value) {
    const ch = state.char;
    const [kind, arg] = key.split(':');
    if (kind === 'height') ch.identity.height = value;
    else if (kind === 'shape' || kind === 'skin') ch.heritage[kind] = value;
    else if (kind === 'face') ch.face[arg] = value;
    else if (kind === 'opacity') ch.overlays[arg].opacity = value;
    if (kind !== 'height') apply();
}

document.addEventListener('input', (e) => {
    const t = e.target;
    if (t.dataset.slider) {
        const value = Number(t.value);
        onSlider(t.dataset.slider, value);
        // Mise à jour légère du curseur sans tout redessiner
        const min = Number(t.min), max = Number(t.max);
        if (t.classList.contains('center')) {
            const p = ((value - min) / (max - min)) * 100;
            t.style.setProperty('--from', `${Math.min(50, p)}%`);
            t.style.setProperty('--to', `${Math.max(50, p)}%`);
        } else {
            t.style.setProperty('--fill', `${((value - min) / (max - min)) * 100}%`);
        }
        const label = t.parentElement.querySelector('.label strong');
        if (label) label.textContent = `${value > 0 && t.classList.contains('center') ? '+' : ''}${value}`;
    } else if (t.dataset.id) {
        let v = t.value;
        if (['day', 'month', 'year'].includes(t.dataset.id)) v = v.replace(/\D/g, '');
        state.char.identity[t.dataset.id] = v;
        if (t.value !== v) t.value = v;
        if (state.showErrors) renderContent(false, true);
        else renderHeader();
    }
});

document.addEventListener('focusout', (e) => {
    const key = e.target.dataset?.id;
    if (key === 'firstname' || key === 'lastname') {
        state.char.identity[key] = capitalize(state.char.identity[key]);
        e.target.value = state.char.identity[key];
    }
});

document.addEventListener('click', (e) => {
    if (!state.open) return;
    const t = e.target;
    const go = t.closest('[data-goto]');
    if (go && !go.disabled) return goTo(Number(go.dataset.goto));
    const st = t.closest('[data-step]');
    if (st) return onStep(st.dataset.step, Number(st.dataset.dir));
    const sw = t.closest('[data-swatch]');
    if (sw) {
        const v = Number(sw.dataset.value);
        const [kind, arg] = sw.dataset.swatch.split(':');
        if (kind === 'hairColor') state.char.hair.color = v;
        else if (kind === 'hairHighlight') state.char.hair.highlight = v;
        else if (kind === 'eyes') state.char.eyes = v;
        else if (kind === 'ocolor') state.char.overlays[arg].color = v;
        apply();
        return renderContent(false, true);
    }
    const sub = t.closest('[data-sub]');
    if (sub) { state.sub[sub.dataset.sub] = Number(sub.dataset.value); return renderContent(false); }
    const sex = t.closest('[data-sex]');
    if (sex && sex.dataset.sex !== state.char.identity.sex) {
        const keep = state.char.identity;
        state.char = defaultChar(sex.dataset.sex);
        state.char.identity = { ...keep, sex: sex.dataset.sex };
        state.outfit = null;
        state.counts = null;
        post('sex', { sex: sex.dataset.sex }).then(() => apply());
        return renderContent(false, true);
    }
    const tool = t.closest('[data-tool]');
    if (tool) return tool.dataset.tool === 'random' ? randomize() : resetStep();
    const outfit = t.closest('[data-outfit]');
    if (outfit) {
        const o = state.config.outfits[state.char.identity.sex][Number(outfit.dataset.outfit)];
        Object.entries(o.clothes || {}).forEach(([k, v]) => { state.char.clothes[k] = { d: v[0], t: v[1] || 0 }; });
        state.outfit = Number(outfit.dataset.outfit);
        apply();
        return renderContent(false, true);
    }
    if (t.closest('[data-confirm]')) { state.confirmed = !state.confirmed; return renderContent(false, true); }
    const cam = t.closest('[data-cam]');
    if (cam) return setCamera(cam.dataset.cam);
    const rot = t.closest('[data-rotate]');
    if (rot) return post('rotate', { direction: Number(rot.dataset.rotate) });
});

$('btn-back').addEventListener('click', () => goTo(state.step - 1));
$('btn-next').addEventListener('click', () => {
    if (state.step < STEPS.length - 1) return goTo(state.step + 1);
    if (!state.confirmed) return;
    const id = state.char.identity;
    id.firstname = capitalize(id.firstname);
    id.lastname = capitalize(id.lastname);
    post('finish', { char: state.char });
    hide();
});

// Caméra : molette (hors panneau), Z/S hauteur, A/E rotation
document.addEventListener('wheel', (e) => {
    if (!state.open || e.target.closest('.panel')) return;
    post('zoom', { delta: e.deltaY > 0 ? 1 : -1 });
}, { passive: true });

document.addEventListener('keydown', (e) => {
    if (!state.open || e.target.tagName === 'INPUT' && e.target.type !== 'range') return;
    const k = e.key.toLowerCase();
    if (k === 'a' || k === 'q') post('rotate', { direction: -1 });
    else if (k === 'e') post('rotate', { direction: 1 });
    else if (k === 'z' || k === 'w') post('height', { delta: 1 });
    else if (k === 's') post('height', { delta: -1 });
    else return;
    e.preventDefault();
});

/* ---------- Ouverture ---------- */

function open(data = {}) {
    Object.assign(state.config, data.config || {});
    state.palette = data.palette || state.palette;
    state.char = defaultChar(data.sex || 'm');
    if (data.identity) Object.assign(state.char.identity, data.identity);
    state.counts = data.counts || null;
    state.step = 0;
    state.visited = 0;
    state.confirmed = false;
    state.showErrors = false;
    state.outfit = null;
    state.open = true;
    renderContent(true);
    setCamera(STEPS[0].cam);
    $('app').classList.remove('hidden');
    apply();
}

function hide() {
    state.open = false;
    $('app').classList.add('hidden');
}

window.addEventListener('message', (e) => {
    const msg = e.data || {};
    if (msg.action === 'open') open(msg.data);
    else if (msg.action === 'close') hide();
    else if (msg.action === 'toast') toast(msg.message);
});

/* ---------- Aperçu hors jeu ---------- */

function demoPalette(n, fn) { return Array.from({ length: n }, (_, i) => fn(i, n)); }

function preview(name) {
    if (name === 'apply') {
        return { counts: { hair: 76, overlays: { 0: 24, 1: 29, 2: 34, 3: 15, 4: 75, 5: 7, 6: 12, 7: 11, 8: 10, 9: 18, 10: 17 },
            clothes: { tops: { drawables: 389, textures: 6 }, undershirt: { drawables: 188, textures: 4 }, arms: { drawables: 196, textures: 2 }, pants: { drawables: 143, textures: 5 },
                shoes: { drawables: 101, textures: 8 }, chain: { drawables: 152, textures: 3 }, hat: { drawables: 186, textures: 6 }, glasses: { drawables: 38, textures: 7 } } } };
    }
    if (name === 'finish') setTimeout(() => open(DEMO), 900);
    return null;
}

const DEMO = {
    sex: 'm',
    identity: { firstname: 'Warner', lastname: 'Bross', day: '07', month: '01', year: '2000' },
    palette: {
        hair: demoPalette(64, (i, n) => `hsl(${(i * 37) % 360}, ${i < 20 ? 25 : 60}%, ${i < 20 ? 8 + i * 3.5 : 45}%)`),
        makeup: demoPalette(64, (i) => `hsl(${(i * 23 + 330) % 360}, 60%, ${35 + (i % 5) * 7}%)`),
    },
    config: {
        outfits: {
            m: [{ label: 'Décontracté', clothes: {} }, { label: 'Sportswear', clothes: {} }, { label: 'Chic', clothes: {} }],
            f: [{ label: 'Décontractée', clothes: {} }, { label: 'Sportswear', clothes: {} }, { label: 'Chic', clothes: {} }],
        },
    },
};

if (!RESOURCE) {
    open(DEMO);
    const step = Number(location.hash.slice(1));
    if (step) { state.step = step; state.visited = step; renderContent(false); }
}
