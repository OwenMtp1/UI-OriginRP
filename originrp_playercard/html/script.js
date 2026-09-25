'use strict';

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;

const el = {
    card: document.getElementById('card'),
    name: document.getElementById('card-name'),
    id: document.getElementById('card-id'),
    job: document.getElementById('card-job'),
    badges: document.getElementById('card-badges'),
    org: document.getElementById('card-org'),
    labelJob: document.getElementById('label-job'),
    labelOrg: document.getElementById('label-org'),
};

const config = {
    position: 'right',
    offset: { x: 24, y: 24 },
    labels: {
        job: 'Emploi',
        organisation: 'Organisation',
        none: 'Aucune',
        active: 'Actif',
        inactive: 'Inactif',
        onDuty: 'En service',
        offDuty: 'Hors service',
    },
};

function applyConfig(data) {
    if (data) {
        config.position = data.position || config.position;
        config.offset = data.offset || config.offset;
        Object.assign(config.labels, data.labels || {});
    }
    el.card.dataset.position = config.position;
    el.labelJob.textContent = config.labels.job;
    el.labelOrg.textContent = config.labels.organisation;
    const root = document.documentElement.style;
    root.setProperty('--offset-x', `${Number(config.offset.x) || 0}px`);
    root.setProperty('--offset-y', `${Number(config.offset.y) || 0}px`);
}

// « LSPD - Patron » : libellé en blanc, grade en gris
function setAffiliation(node, info) {
    node.textContent = '';
    const label = info && info.label;
    node.classList.toggle('none', !label);
    if (!label) {
        node.textContent = config.labels.none;
        return;
    }
    node.append(String(label));
    if (info.grade) {
        const grade = document.createElement('span');
        grade.className = 'grade';
        grade.textContent = ` - ${info.grade}`;
        node.append(grade);
    }
}

function badge(text, on) {
    const span = document.createElement('span');
    span.className = on ? 'badge on' : 'badge';
    span.textContent = text;
    return span;
}

function render(data) {
    const { labels } = config;
    el.name.textContent = data.name || '';
    el.id.textContent = data.id != null && data.id !== '' ? `#${data.id}` : '';

    const job = data.job || null;
    setAffiliation(el.job, job);
    el.badges.textContent = '';
    if (job && job.label) {
        if (job.active != null) el.badges.append(badge(job.active ? labels.active : labels.inactive, job.active));
        if (job.onDuty != null) el.badges.append(badge(job.onDuty ? labels.onDuty : labels.offDuty, job.onDuty));
    }

    setAffiliation(el.org, data.organisation || data.org || null);
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    switch (msg.action) {
        case 'show':
            render(msg.data || {});
            el.card.classList.remove('hidden');
            break;
        case 'hide':
            el.card.classList.add('hidden');
            break;
        case 'pause':
            el.card.classList.toggle('paused', !!msg.paused);
            break;
    }
});

applyConfig();

if (RESOURCE) {
    fetch(`https://${RESOURCE}/ready`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: '{}',
    })
        .then((res) => res.json())
        .then(applyConfig)
        .catch(() => {});
} else {
    // Aperçu hors jeu
    render({
        name: 'Liam Coelho',
        id: 2,
        job: { label: 'LSPD', grade: 'Patron', active: true, onDuty: false },
        organisation: { label: 'Families', grade: 'Recrue' },
    });
    el.card.classList.remove('hidden');
}
