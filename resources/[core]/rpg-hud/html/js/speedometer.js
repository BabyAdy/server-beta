/* ==========================================================================
   rpg-hud — SPEEDOMETER (afisat doar in vehicul)
   ========================================================================== */
HUD.mods.speedo = (function () {
    var $ = HUD.$;
    var arcLen = 0;
    var maxSpeed = 300;
    var inVeh = false;
    var rootVis = true;

    function ensureArc() {
        var a = $('#sp-arc');
        if (a && !arcLen) {
            arcLen = a.getTotalLength();
            a.style.strokeDasharray = arcLen;
            a.style.strokeDashoffset = arcLen;
        }
    }

    function applyVis() {
        $('#speedo').classList.toggle('show', inVeh && rootVis);
    }

    function clearPv() {
        var pv = $('#sp-pv');
        if (pv) pv.hidden = true;
    }

    function setSpeed(v) {
        ensureArc();
        v = Math.max(0, Math.min(999, v | 0));
        $('#sp-speed').textContent = String(v).padStart(3, '0');
        var frac = Math.max(0, Math.min(1, v / maxSpeed));
        var a = $('#sp-arc');
        if (a && arcLen) a.style.strokeDashoffset = arcLen * (1 - frac);
    }

    return {
        config: function (c) {
            if (!c.speedo) return;
            maxSpeed = c.speedo.maxSpeed || 300;
            $('#sp-unit').textContent = c.speedo.unit || 'KM/H';
        },
        rootVisible: function (v) { rootVis = v; applyVis(); },
        on: function (action, value) {
            switch (action) {
                case 'show': inVeh = true; ensureArc(); applyVis(); clearPv(); break;
                case 'hide': inVeh = false; applyVis(); clearPv(); break;
                case 'speed': setSpeed(value); break;
                case 'gear': $('#sp-gear').textContent = value; break;
                case 'rpm': $('#speedo').style.setProperty('--rpm', (value / 100).toFixed(2)); break;
                case 'fuel': {
                    var f = $('#sp-fuel');
                    var pct = Math.max(0, Math.min(100, value));
                    f.style.width = pct + '%';
                    var low = pct <= 15;
                    f.closest('.vs-bar').classList.toggle('low', low);
                    var fp = $('#sp-fuel-pct');
                    if (fp) {
                        fp.textContent = Math.round(pct) + '%';
                        fp.closest('.vs-fuel').classList.toggle('low', low);
                    }
                    break;
                }
                case 'pvinfo': {
                    var pv = $('#sp-pv');
                    if (!pv) break;
                    if (!value) { pv.hidden = true; break; }
                    var km = Math.max(0, Math.round(value.odometer || 0));
                    $('#sp-odo').textContent = km.toLocaleString('ro-RO') + ' km';
                    var st = $('#sp-status');
                    st.textContent = value.locked ? 'Închis' : 'Deschis';
                    st.className = 'vpv-v ' + (value.locked ? 'locked' : 'unlocked');
                    var d = Math.max(0, Math.floor(value.days || 0));
                    $('#sp-age').textContent = d + (d === 1 ? ' zi' : ' zile');
                    pv.hidden = false;
                    break;
                }
                case 'engine': {
                    var e = $('#vi-engine');
                    e.classList.toggle('on', !!(value && value.on));
                    e.classList.toggle('warn', !!(value && value.health < 50));
                    break;
                }
                case 'seatbelt': {
                    $('#vi-belt').classList.toggle('on', value === true);
                    $('#speedo').classList.toggle('nobelt', value !== true);
                    break;
                }
                case 'lights': {
                    var l = $('#vi-lights');
                    l.classList.remove('on', 'high');
                    if (value === 1) l.classList.add('on');
                    if (value === 2) l.classList.add('on', 'high');
                    break;
                }
            }
        },
    };
})();

/* ---- demo pentru preview in browser ---- */
HUD.demo = function () {
    HUD.$('#hud').hidden = false;
    var C = { chat: { placeholder: "Scrie un mesaj  ·  '/' pentru comenzi", lifetime: 999999, fade: 1000,
        maxMessages: 100, visibleInactive: 6, lineHeight: 1.45, width: 470,
        channels: { SYSTEM: { label: 'SISTEM', color: '#9aa0aa' }, SUCCESS: { label: 'OK', color: '#46d6a2' },
            STAFF: { label: 'STAFF', color: '#f0a85b' } } },
        speedo: { unit: 'KM/H', maxSpeed: 300 } };
    Object.keys(HUD.mods).forEach(function (k) { if (HUD.mods[k].config) HUD.mods[k].config(C); });

    var chat = HUD.mods.chat;
    var names = [['Andrei', 137], ['Mihai', 92], ['Ioana', 44], ['Radu', 301], ['Vlad', 88], ['Ana', 205]];
    var lines = ['Salut, cine e prin zonă?', 'Sunt lângă benzinărie.', 'Vând Sultan, cine e interesat?', 'Unde?',
        'La dealership-ul din centru.', 'ok, vin acum', 'ai pe /me activ?', 'da, te aștept afară', 'cât ceri?',
        'negociem pe loc', 'bag și eu un anunț mai târziu', 'mișto, mersi'];
    for (var i = 0; i < 18; i++) {
        var n = names[i % names.length];
        chat.on('message', { time: '21:' + (20 + i), id: n[1], author: n[0], text: lines[i % lines.length] });
    }
    chat.on('message', { time: '21:39', channel: 'SYSTEM', text: 'Ai primit $500 (salariu).' });
    chat.on('message', { time: '21:39', channel: 'STAFF_ADMIN', author: 'Vlad', text: 'preiau ticketul #42', color: '#F5B427',
        staff: { label: 'Head Admin', color: '#ff6a00', id: 88, kind: 'admin' } });
    chat.on('message', { time: '21:39', channel: 'STAFF_HELPER', author: 'Ana', text: 'raspund eu pe /report', color: '#F5E427',
        staff: { label: 'Helper', color: '#37ff00', id: 205, kind: 'helper' } });

    var h = HUD.mods.hud;
    h.on('player', { username: 'Andrei Popescu', id: 137 });
    h.on('online', 133);
    h.on('money', 69344);
    h.on('bank', 4751813);
    h.on('health', 90);
    h.on('food', 82);
    h.on('water', 76);
    h.on('paycheck', { seconds: 1797, running: true });
    h.on('voice', 'talking');
    h.on('activity', { title: 'EXTRACȚIE PETROL', timer: 10651 });

    var s = HUD.mods.speedo;
    s.rootVisible(true);
    s.on('show', true);
    s.on('speed', 95);
    s.on('gear', '3');
    s.on('fuel', 82);
    s.on('engine', { on: true, health: 88 });
    s.on('seatbelt', true);
    s.on('lights', 1);
};
