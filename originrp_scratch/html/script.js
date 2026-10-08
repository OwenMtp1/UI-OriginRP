const $ = (s) => document.querySelector(s);
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'originrp_scratch';
const fmt = (n) => `${Number(n).toLocaleString('fr-FR')} $`;

function post(name, body = {}) {
    return fetch(`https://${resource}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(body),
    }).then((r) => r.json()).catch(() => null);
}

// ─── Borne ────────────────────────────────────────────────────────────────
const shop = { price: 500, remaining: 40, limit: 40, money: 0, qty: 1, busy: false };

function renderShop() {
    const max = Math.max(shop.remaining, 1);
    shop.qty = Math.min(Math.max(shop.qty, 1), max);
    $('#qty').textContent = shop.qty;
    $('#slider').max = max;
    $('#slider').value = shop.qty;
    $('#slider').disabled = shop.remaining <= 1;
    $('#price').textContent = fmt(shop.price);
    $('#total').textContent = fmt(shop.qty * shop.price);
    $('#remaining').textContent = `${shop.remaining} / ${shop.limit}`;
    $('#money').textContent = fmt(shop.money);
    const tooPoor = shop.qty * shop.price > shop.money;
    $('#buy').disabled = shop.busy || shop.remaining <= 0 || tooPoor;
    $('#buy').textContent = shop.remaining <= 0 ? 'LIMITE ATTEINTE' : tooPoor ? 'LIQUIDE INSUFFISANT' : `ACHETER ${shop.qty} TICKET${shop.qty > 1 ? 'S' : ''}`;
    document.querySelectorAll('#chips button').forEach((b) => {
        const q = b.dataset.q === 'max' ? shop.remaining : Number(b.dataset.q);
        b.disabled = q > shop.remaining || q < 1;
        b.classList.toggle('on', q === shop.qty);
    });
}

function setMsg(text, ok) {
    const m = $('#msg');
    m.textContent = text || '';
    m.className = 'msg ' + (ok ? 'ok' : 'err');
}

document.querySelectorAll('.step').forEach((b) => b.onclick = () => { shop.qty += Number(b.dataset.step); renderShop(); });
$('#slider').oninput = (e) => { shop.qty = Number(e.target.value); renderShop(); };
$('#chips').onclick = (e) => {
    const b = e.target.closest('button'); if (!b || b.disabled) return;
    shop.qty = b.dataset.q === 'max' ? shop.remaining : Number(b.dataset.q);
    renderShop();
};
$('#buy').onclick = async () => {
    if (shop.busy) return;
    shop.busy = true; renderShop(); setMsg('');
    const res = await post('buy', { qty: shop.qty });
    shop.busy = false;
    if (res) {
        if (typeof res.remaining === 'number') shop.remaining = res.remaining;
        if (typeof res.money === 'number') shop.money = res.money;
        setMsg(res.message, res.ok);
        if (res.ok) {
            const p = $('#printed');
            p.classList.remove('out'); void p.offsetWidth; p.classList.add('out');
            setTimeout(() => p.classList.remove('out'), 1600);
            shop.qty = 1;
        }
    }
    renderShop();
};

// ─── Ticket ───────────────────────────────────────────────────────────────
let ticket = null;

function drawFoil(canvas) {
    const rect = canvas.getBoundingClientRect();
    canvas.width = rect.width; canvas.height = rect.height;
    const g = canvas.getContext('2d');
    const grad = g.createLinearGradient(0, 0, canvas.width, canvas.height);
    grad.addColorStop(0, '#9aa1ab'); grad.addColorStop(.35, '#eef0f3'); grad.addColorStop(.55, '#b9bfc8'); grad.addColorStop(1, '#8a919c');
    g.fillStyle = grad; g.fillRect(0, 0, canvas.width, canvas.height);
    for (let i = 0; i < 2500; i++) {
        g.fillStyle = `rgba(${Math.random() < .5 ? 255 : 60},${Math.random() < .5 ? 255 : 60},${Math.random() < .5 ? 255 : 60},${Math.random() * .12})`;
        g.fillRect(Math.random() * canvas.width, Math.random() * canvas.height, 1.5, 1.5);
    }
    g.fillStyle = 'rgba(80,86,96,.55)';
    g.font = '900 15px Arial'; g.textAlign = 'center'; g.textBaseline = 'middle';
    for (let y = 18; y < canvas.height; y += 30) {
        for (let x = (y / 30) % 2 ? 30 : 60; x < canvas.width; x += 90) g.fillText('GRATTEZ', x, y);
    }
    g.globalCompositeOperation = 'destination-out';
}

function clearedRatio(canvas) {
    const g = canvas.getContext('2d');
    const data = g.getImageData(0, 0, canvas.width, canvas.height).data;
    let clear = 0, total = 0;
    for (let i = 3; i < data.length; i += 4 * 12) { total++; if (data[i] < 40) clear++; }
    return clear / total;
}

function reveal(caseEl) {
    if (caseEl.classList.contains('done')) return;
    caseEl.classList.add('done');
    if (!ticket) return;
    ticket.revealed++;
    if (ticket.revealed === 3) finishTicket();
}

let lastSound = 0;
function setupCase(caseEl, value) {
    const v = caseEl.querySelector('.value');
    v.textContent = fmt(value);
    v.classList.toggle('win', value > 0);
    caseEl.classList.remove('done');
    const canvas = caseEl.querySelector('canvas');
    drawFoil(canvas);
    const g = canvas.getContext('2d');
    let down = false, last = null, moves = 0;

    const pos = (e) => { const r = canvas.getBoundingClientRect(); return { x: e.clientX - r.left, y: e.clientY - r.top }; };
    const scratch = (p) => {
        g.lineWidth = 34; g.lineCap = 'round'; g.lineJoin = 'round';
        g.beginPath();
        g.moveTo(last ? last.x : p.x, last ? last.y : p.y);
        g.lineTo(p.x, p.y);
        g.stroke();
        last = p;
        if (++moves % 8 === 0 && clearedRatio(canvas) > 0.55) reveal(caseEl);
        const now = Date.now();
        if (now - lastSound > 140) { lastSound = now; post('scratchSound'); }
    };
    canvas.onpointerdown = (e) => { down = true; last = null; canvas.setPointerCapture(e.pointerId); scratch(pos(e)); };
    canvas.onpointermove = (e) => { if (down) scratch(pos(e)); };
    canvas.onpointerup = () => { down = false; last = null; };
}

async function finishTicket() {
    const total = ticket.cases.reduce((a, b) => a + b, 0);
    const r = $('#result');
    setTimeout(() => {
        r.className = 'result' + (total > 0 ? '' : ' lose');
        r.innerHTML = total > 0 ? `GAGNÉ ${fmt(total)}<small>Le gain a été ajouté à ton liquide</small>` : `PERDU<small>Retente ta chance !</small>`;
    }, 500);
    if (!ticket.claimed) { ticket.claimed = true; await post('claim'); }
}

function openTicket(cases) {
    ticket = { cases, revealed: 0, claimed: false };
    $('#result').className = 'result hidden';
    $('#ticket').classList.remove('hidden');
    $('#shop').classList.add('hidden');
    requestAnimationFrame(() => {
        document.querySelectorAll('.case').forEach((c, i) => setupCase(c, cases[i]));
    });
}

$('#scratchAll').onclick = () => document.querySelectorAll('.case').forEach(reveal);

// pièce qui suit la souris pendant le grattage
const coin = document.createElement('div');
coin.className = 'coin';
document.body.appendChild(coin);
document.addEventListener('pointermove', (e) => {
    const onCase = e.target.closest && e.target.closest('.case:not(.done)');
    coin.style.display = onCase ? 'block' : 'none';
    coin.style.left = e.clientX + 'px'; coin.style.top = e.clientY + 'px';
});

// ─── Fermeture ────────────────────────────────────────────────────────────
async function close() {
    if (ticket && !ticket.claimed) { ticket.claimed = true; await post('claim'); }
    post('close');
}
document.querySelectorAll('[data-close]').forEach((b) => b.onclick = close);
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });

window.addEventListener('message', ({ data }) => {
    if (data.action === 'shop') {
        Object.assign(shop, { price: data.price, remaining: data.remaining, limit: data.limit, money: data.money, qty: 1, busy: false });
        setMsg('');
        renderShop();
        $('#ticket').classList.add('hidden');
        $('#shop').classList.remove('hidden');
    } else if (data.action === 'ticket') {
        openTicket(data.cases);
    } else if (data.action === 'close') {
        $('#shop').classList.add('hidden');
        $('#ticket').classList.add('hidden');
        ticket = null;
    }
});
