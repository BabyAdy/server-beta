(function () {
    'use strict';

    var isBrowser = typeof window.GetParentResourceName !== 'function';
    var RES = isBrowser ? 'rpg-characters' : window.GetParentResourceName();

    var $ = function (s, r) { return (r || document).querySelector(s); };

    /* ------------------------------------------------------- palete ----- */
    // Aproximari vizuale. Indexul (0..63) e ce conteaza pentru joc.
    var HAIR_COLORS = [
        '#1c1c1c','#242121','#2b2523','#332b26','#3d332c','#4a3b31','#574539','#6b5240','#7d5f49','#8f6b52',
        '#241d16','#31261b','#3f3123','#4d3b2a','#5c4630','#6e5539','#816545','#957552','#a9885f','#c0a074',
        '#d8b878','#e2c78d','#e9d3a3','#efdcb4','#f2e3c3','#f6ead2','#d9c9a3','#c9b489','#b89f72','#a68a5c',
        '#9e9e9e','#b0b0b0','#c4c4c4','#d7d7d7','#e9e9e9','#f4f4f4','#8a8a8a','#767676','#636363','#525252',
        '#5b2f22','#6e3a27','#82452c','#973f2b','#a84a30','#b85a3a','#c56a46','#8f2f28','#a13a30','#7a271f',
        '#7b4b8f','#5f4b9c','#4b57a8','#3f7bb0','#3fae9a','#46b06a','#8fb046','#b0a046','#b06e46','#b04682',
        '#c04691','#9146b0','#4661b0','#46a0b0'
    ];
    var EYE_COLORS = [
        '#3a2a1c','#4a3521','#5c4326','#6e532c','#7d6136','#8a7245','#6b5a3e','#544636',
        '#2f4f6b','#3a5f80','#456f94','#5a83a6','#6f97b6','#84abc6','#9ec2d8','#b7d6e6',
        '#3a5f3a','#456f45','#537d53','#639163','#77a577','#8fb98f','#5b6b5b','#6b7b6b',
        '#7a7a7a','#8f8f8f','#a3a3a3','#b7b7b7','#8a6f8a','#6f6f9a','#9a6f6f','#c9c9c9'
    ];

    var FACE_GROUPS = [
        { title: 'Nas', items: [
            [0, 'Lățime'], [1, 'Înălțime vârf'], [2, 'Lungime vârf'],
            [3, 'Punte'], [4, 'Coborâre vârf'], [5, 'Răsucire']
        ]},
        { title: 'Sprâncene', items: [ [6, 'Înălțime'], [7, 'Adâncime'] ] },
        { title: 'Pomeți', items: [ [8, 'Înălțime'], [9, 'Lățime laterală'], [10, 'Lățime'] ] },
        { title: 'Ochi & buze', items: [ [11, 'Deschidere ochi'], [12, 'Grosime buze'] ] },
        { title: 'Maxilar', items: [ [13, 'Lățime'], [14, 'Lungime'] ] },
        { title: 'Bărbie', items: [ [15, 'Coborâre'], [16, 'Lungime'], [17, 'Mărime'], [18, 'Gropiță'] ] },
        { title: 'Gât', items: [ [19, 'Grosime'] ] }
    ];

    var OVERLAY_META = {
        0:  { label: 'Imperfecțiuni piele', max: 23, color: false },
        1:  { label: 'Barbă',               max: 28, color: true },
        2:  { label: 'Sprâncene',           max: 33, color: true },
        3:  { label: 'Îmbătrânire',         max: 14, color: false },
        4:  { label: 'Machiaj',             max: 74, color: true },
        5:  { label: 'Fard obraji',         max: 6,  color: true },
        6:  { label: 'Ten',                 max: 11, color: false },
        7:  { label: 'Arsură solară',       max: 10, color: false },
        8:  { label: 'Ruj',                 max: 9,  color: true },
        9:  { label: 'Pistrui / alunițe',   max: 17, color: false },
        10: { label: 'Păr pe piept',        max: 16, color: true },
        11: { label: 'Pete corp',           max: 11, color: false }
    };

    var TABS = [
        { id: 'gen',      label: 'Gen' },
        { id: 'mostenire', label: 'Moștenire' },
        { id: 'fata',     label: 'Față' },
        { id: 'par',      label: 'Păr & pilozitate' },
        { id: 'ochi',     label: 'Ochi' },
        { id: 'ten',      label: 'Ten & machiaj' }
    ];

    /* --------------------------------------------------------- state ---- */
    var state = null;
    var activeTab = 'gen';
    var els = {
        root: $('#cc'), tabs: $('#cc-tabs'), body: $('#cc-body'),
        user: $('#cc-user'), confirm: $('#cc-confirm'), random: $('#cc-random'),
        toasts: $('#cc-toasts')
    };

    /* --------------------------------------------------------- NUI ------ */
    function post(name, data) {
        return fetch('https://' + RES + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {})
        }).then(function (r) { return r.json().catch(function () { return {}; }); })
          .catch(function () { return {}; });
    }

    /* ----------------------------------------------------- helpers UI --- */
    function el(tag, cls, html) {
        var n = document.createElement(tag);
        if (cls) n.className = cls;
        if (html != null) n.innerHTML = html;
        return n;
    }

    function groupTitle(t) { return el('div', 'group-title', t); }

    function slider(label, value, min, max, step, fmt, onInput) {
        var wrap = el('div', 'ctrl');
        var lab = el('div', 'ctrl-label', '<span>' + label + '</span><span class="val"></span>');
        var val = lab.querySelector('.val');
        var input = el('input');
        input.type = 'range';
        input.min = min; input.max = max; input.step = step; input.value = value;
        var render = function () { val.textContent = fmt(parseFloat(input.value)); };
        render();
        input.addEventListener('input', function () { render(); onInput(parseFloat(input.value)); });
        wrap.appendChild(lab); wrap.appendChild(input);
        return wrap;
    }

    function segmented(options, current, onPick) {
        var wrap = el('div', 'seg');
        options.forEach(function (o) {
            var b = el('button', o.value === current ? 'on' : null, o.label);
            b.addEventListener('click', function () {
                wrap.querySelectorAll('button').forEach(function (x) { x.classList.remove('on'); });
                b.classList.add('on');
                onPick(o.value);
            });
            wrap.appendChild(b);
        });
        return wrap;
    }

    function swatches(label, colors, current, extraCls, onPick) {
        var wrap = el('div', 'ctrl');
        wrap.appendChild(el('div', 'ctrl-label', '<span>' + label + '</span>'));
        var grid = el('div', 'swatches' + (extraCls ? ' ' + extraCls : ''));
        colors.forEach(function (hex, i) {
            var s = el('div', 'swatch' + (i === current ? ' on' : ''));
            s.style.background = hex;
            s.title = String(i);
            s.addEventListener('click', function () {
                grid.querySelectorAll('.swatch').forEach(function (x) { x.classList.remove('on'); });
                s.classList.add('on');
                onPick(i);
            });
            grid.appendChild(s);
        });
        wrap.appendChild(grid);
        return wrap;
    }

    var f2 = function (v) { return (v >= 0 ? '+' : '') + v.toFixed(2); };
    var pct = function (v) { return Math.round(v * 100) + '%'; };
    var intf = function (v) { return String(Math.round(v)); };

    /* ------------------------------------------------------- renderers -- */
    function renderTabs() {
        els.tabs.innerHTML = '';
        TABS.forEach(function (t) {
            var b = el('button', t.id === activeTab ? 'on' : null, t.label);
            b.addEventListener('click', function () { activeTab = t.id; renderTabs(); renderBody(); });
            els.tabs.appendChild(b);
        });
    }

    function renderBody() {
        els.body.innerHTML = '';
        var fn = ({
            gen: tabGen, mostenire: tabMostenire, fata: tabFata,
            par: tabPar, ochi: tabOchi, ten: tabTen
        })[activeTab];
        if (fn) fn(els.body);
        els.body.scrollTop = 0;
    }

    function tabGen(c) {
        c.appendChild(groupTitle('Sex'));
        c.appendChild(segmented(
            [{ value: 'male', label: 'Masculin' }, { value: 'female', label: 'Feminin' }],
            state.sex,
            function (sex) {
                state.sex = sex;
                state.model = sex === 'female' ? 'mp_f_freemode_01' : 'mp_m_freemode_01';
                post('model', { sex: sex });
            }
        ));
        c.appendChild(el('div', 'hint',
            'Serverul e RPG — numele personajului este username-ul ales la înregistrare, ' +
            'nu se cere prenume / nume / dată naștere.'));
    }

    function tabMostenire(c) {
        var hb = state.headBlend;
        c.appendChild(groupTitle('Părinți'));
        c.appendChild(slider('Mamă', hb.mother, 0, 45, 1, intf, function (v) {
            hb.mother = Math.round(v); sendHeritage();
        }));
        c.appendChild(slider('Tată', hb.father, 0, 45, 1, intf, function (v) {
            hb.father = Math.round(v); sendHeritage();
        }));
        c.appendChild(groupTitle('Amestec'));
        c.appendChild(slider('Formă chip (mamă ↔ tată)', hb.shapeMix, 0, 1, 0.01, pct, function (v) {
            hb.shapeMix = v; sendHeritage();
        }));
        c.appendChild(slider('Ton piele (mamă ↔ tată)', hb.skinMix, 0, 1, 0.01, pct, function (v) {
            hb.skinMix = v; sendHeritage();
        }));
    }

    function tabFata(c) {
        FACE_GROUPS.forEach(function (g) {
            c.appendChild(groupTitle(g.title));
            g.items.forEach(function (it) {
                var idx = it[0];
                c.appendChild(slider(it[1], state.faceFeatures[idx], -1, 1, 0.05, f2, function (v) {
                    state.faceFeatures[idx] = v;
                    post('face', { index: idx, value: v });
                }));
            });
        });
    }

    function overlayBlock(c, id, withStyle) {
        var m = OVERLAY_META[id];
        var o = state.headOverlays[id];
        c.appendChild(groupTitle(m.label));
        if (withStyle !== false) {
            c.appendChild(slider('Stil', o.style, 0, m.max, 1, intf, function (v) {
                o.style = Math.round(v); sendOverlay(id);
            }));
        }
        c.appendChild(slider('Intensitate', o.opacity, 0, 1, 0.05, pct, function (v) {
            o.opacity = v; sendOverlay(id);
        }));
        if (m.color) {
            c.appendChild(swatches('Culoare', HAIR_COLORS, o.color, null, function (i) {
                o.color = i; o.secondColor = i; sendOverlay(id);
            }));
        }
    }

    function tabPar(c) {
        c.appendChild(groupTitle('Păr'));
        c.appendChild(slider('Stil', state.hair.style, 0, 73, 1, intf, function (v) {
            state.hair.style = Math.round(v); sendHair();
        }));
        c.appendChild(swatches('Culoare păr', HAIR_COLORS, state.hair.color, null, function (i) {
            state.hair.color = i; sendHair();
        }));
        c.appendChild(swatches('Șuvițe', HAIR_COLORS, state.hair.highlight, null, function (i) {
            state.hair.highlight = i; sendHair();
        }));
        overlayBlock(c, 2);  // sprancene
        overlayBlock(c, 1);  // barba
        if (state.sex === 'male') overlayBlock(c, 10); // par piept
    }

    function tabOchi(c) {
        c.appendChild(groupTitle('Culoare ochi'));
        c.appendChild(swatches('Culoare', EYE_COLORS, state.eyeColor, 'eyes', function (i) {
            state.eyeColor = i; post('eyes', { value: i });
        }));
    }

    function tabTen(c) {
        [6, 0, 3, 9, 7, 11].forEach(function (id) { overlayBlock(c, id); });
        c.appendChild(groupTitle('Machiaj'));
        [4, 5, 8].forEach(function (id) { overlayBlock(c, id); });
    }

    /* ------------------------------------------------ trimitere spre joc */
    function sendHeritage() {
        post('heritage', {
            mother: state.headBlend.mother, father: state.headBlend.father,
            shapeMix: state.headBlend.shapeMix, skinMix: state.headBlend.skinMix
        });
    }
    function sendOverlay(id) {
        var o = state.headOverlays[id];
        post('overlay', { id: id, style: o.style, opacity: o.opacity, color: o.color, secondColor: o.secondColor });
    }
    function sendHair() {
        post('hair', { style: state.hair.style, color: state.hair.color, highlight: state.hair.highlight });
    }

    /* ---------------------------------------------------------- random -- */
    function ri(a, b) { return Math.floor(Math.random() * (b - a + 1)) + a; }
    function rf(a, b) { return Math.random() * (b - a) + a; }

    function randomize() {
        state.headBlend.mother = ri(0, 45);
        state.headBlend.father = ri(0, 45);
        state.headBlend.shapeMix = Math.round(rf(0.1, 0.9) * 100) / 100;
        state.headBlend.skinMix = Math.round(rf(0.1, 0.9) * 100) / 100;
        for (var i = 0; i < 20; i++) state.faceFeatures[i] = Math.round(rf(-0.6, 0.6) * 20) / 20;
        state.hair.style = ri(0, 25);
        state.hair.color = ri(0, 30);
        state.hair.highlight = state.hair.color;
        state.eyeColor = ri(0, EYE_COLORS.length - 1);
        // sprancene vizibile, restul curat
        state.headOverlays.forEach(function (o, id) {
            o.style = 0; o.opacity = 0; o.color = state.hair.color; o.secondColor = o.color;
            if (id === 2) o.opacity = 1;
        });
        state.headOverlays[2].style = ri(0, 15);
        if (state.sex === 'male' && Math.random() < 0.5) {
            state.headOverlays[1].style = ri(0, 15);
            state.headOverlays[1].opacity = Math.round(rf(0.5, 1) * 20) / 20;
        }
        post('apply', { appearance: state });
        renderBody();
    }

    /* ------------------------------------------------------- lifecycle - */
    function open(msg) {
        state = msg.appearance;
        els.user.textContent = msg.username || 'personaj';
        activeTab = 'gen';
        renderTabs();
        renderBody();
        els.confirm.classList.remove('loading');
        els.root.classList.remove('hidden');
    }
    function close() {
        els.root.classList.add('hidden');
        els.confirm.classList.remove('loading');
    }

    function toast(text, kind) {
        if (!text) return;
        var t = el('div', 'toast ' + (kind || ''), '<span>' + text + '</span>');
        els.toasts.appendChild(t);
        var kill = function () {
            t.classList.add('leaving');
            t.addEventListener('animationend', function () { t.remove(); }, { once: true });
        };
        setTimeout(kill, 4000);
        t.addEventListener('click', kill);
    }

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        if (d.action === 'open') open(d);
        else if (d.action === 'close') close();
        else if (d.action === 'toast') { toast(d.message, d.kind); els.confirm.classList.remove('loading'); }
    });

    /* --------------------------------------------------------- events -- */
    els.confirm.addEventListener('click', function () {
        if (els.confirm.classList.contains('loading')) return;
        els.confirm.classList.add('loading');
        post('confirm', {});
    });
    els.random.addEventListener('click', randomize);

    document.querySelectorAll('.stage .rot').forEach(function (b) {
        b.addEventListener('click', function () {
            post('camera', { rotate: parseInt(b.getAttribute('data-rot'), 10) });
        });
    });
    document.querySelectorAll('#cc-zoom button').forEach(function (b) {
        b.addEventListener('click', function () {
            document.querySelectorAll('#cc-zoom button').forEach(function (x) { x.classList.remove('on'); });
            b.classList.add('on');
            post('camera', { mode: b.getAttribute('data-zoom') });
        });
    });

    /* -------------------------------------------------- preview browser */
    if (isBrowser) {
        document.body.classList.add('preview');
        var demo = {
            sex: 'male', model: 'mp_m_freemode_01',
            headBlend: { mother: 0, father: 0, shapeMix: 0.5, skinMix: 0.5 },
            faceFeatures: Array(20).fill(0),
            headOverlays: Array.from({ length: 12 }, function (_, i) {
                return { style: 0, opacity: i === 2 ? 1 : 0, color: 0, secondColor: 0 };
            }),
            hair: { style: 0, color: 0, highlight: 0 }, eyeColor: 0
        };
        open({ appearance: demo, username: 'DemoUser' });
    }
})();
