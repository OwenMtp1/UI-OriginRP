const $ = (s) => document.getElementById(s);
const VIS = ['OPTIQUE', 'THERMIQUE', 'NOCTURNE'];
const REASONS = {
  destroyed: 'Votre drone a été détruit',
  jammed: 'Le réseau rencontre des perturbations',
  range: 'Hors de portée · retour automatique en cours',
};
let reason = null;
const cv = $('noise'), g = cv.getContext('2d');
function noise() {
  if (reason) {
    cv.width = 320; cv.height = 180; const im = g.createImageData(320, 180);
    for (let i = 0; i < im.data.length; i += 4) { const v = Math.random() * 255; im.data[i] = im.data[i + 1] = im.data[i + 2] = v; im.data[i + 3] = 255; }
    g.putImageData(im, 0, 0);
  }
  requestAnimationFrame(noise);
}
noise();
function noSignal(r) {
  reason = r;
  $('nosig').classList.toggle('hidden', !r);
  if (r) $('nosigTxt').textContent = REASONS[r] || '';
}
function bar(el, v) { el.style.width = Math.max(0, Math.min(100, v)) + '%'; el.className = v <= 20 ? 'low' : v <= 50 ? 'mid' : ''; }
const pad = (n) => String(Math.floor(n)).padStart(2, '0');
window.addEventListener('message', ({ data: d }) => {
  if (d.action === 'open') { $('hud').classList.remove('hidden'); $('serial').textContent = d.serial || 'OR-D2'; noSignal(null); }
  if (d.action === 'close') { $('hud').classList.add('hidden'); noSignal(null); }
  if (d.action === 'hit') { bar($('hp'), d.hp); const e = $('dmg'); e.classList.add('on'); setTimeout(() => e.classList.remove('on'), 120); }
  if (d.action === 'nosignal') noSignal(d.reason);
  if (d.action === 'update') {
    $('alt').textContent = d.alt.toFixed(1); $('spd').textContent = Math.round(d.spd); $('dist').textContent = Math.round(d.dist); $('hdg').textContent = pad(d.hdg).padStart(3, '0');
    bar($('hp'), d.hp); $('hpTxt').textContent = Math.round(d.hp) + ' %';
    bar($('bat'), d.bat); const mins = d.bat / 100 * 120; $('batTxt').textContent = `${Math.round(d.bat)} % · ${Math.floor(mins / 60)}:${pad(mins % 60)}`;
    $('mode').textContent = `${VIS[d.vision]} · ZOOM ${d.zoom.toFixed(1)}×`;
    const r = $('rec'); r.classList.toggle('on', d.rec); r.textContent = `● REC ${pad(d.recT / 60)}:${pad(d.recT % 60)}`;
    $('sig').textContent = d.signal === 'ok' ? '▂▄▆█' : d.signal === 'weak' ? '▂▄__' : '____';
    $('state').textContent = d.auto === 'rth' ? 'RETOUR AU PILOTE' : d.auto === 'land' ? 'ATTERRISSAGE' : d.signal === 'jammed' ? `SIGNAL BROUILLÉ · ${Math.round(d.jamT)} s` : d.flying ? 'EN VOL · GPS' : 'AU SOL · PRÊT';
    if (reason !== 'destroyed') noSignal(d.signal === 'jammed' || d.signal === 'range' ? d.signal : null);
  }
});
