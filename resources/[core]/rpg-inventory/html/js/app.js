/* ==========================================================================
   rpg-inventory — nucleu NUI: mesaje, helper-e comune, actiuni, modale.
   Arhitectura: NUI -> Client -> Server -> DB. NUI nu atinge DB-ul.
   ========================================================================== */
window.INV = window.INV || {};

(function () {
    'use strict';

    function resName() {
        return (typeof window.GetParentResourceName === 'function')
            ? window.GetParentResourceName() : 'rpg-inventory';
    }

    INV.state = { snapshot: null, nearby: null, config: null, search: '' };

    INV.post = function (name, data) {
        return fetch('https://' + resName() + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).then(function (r) { return r.json().catch(function () { return {}; }); })
          .catch(function () { return {}; });
    };
    INV.request = function (action, payload) {
        return INV.post('request', { action: action, payload: payload || {} });
    };
    INV.def = function (id) {
        return (INV.state.snapshot && INV.state.snapshot.definitions || {})[id];
    };

    /* ------------------------------------------------- helper-e slot --- */
    INV.iconEl = function (view) {
        const wrap = document.createElement('div');
        wrap.className = 'icon';
        const img = document.createElement('img');
        img.src = 'assets/icons/' + (view.icon || 'placeholder.svg');
        img.onerror = function () {
            if (img.parentNode) img.parentNode.removeChild(img);
            wrap.classList.add('mono');
            wrap.dataset.cat = view.category || 'misc';
            const t = (view.label || '?').replace(/[^A-Za-zĂÂÎȘȚăâîșț]/g, '').slice(0, 2).toUpperCase();
            wrap.textContent = t || '?';
        };
        wrap.appendChild(img);
        return wrap;
    };

    INV.buildSlot = function (view, opts) {
        opts = opts || {};
        const s = document.createElement('div');
        s.className = 'slot';
        if (opts.idxLabel) {
            const i = document.createElement('span'); i.className = 'idx'; i.textContent = opts.idxLabel; s.appendChild(i);
        }
        if (opts.keyLabel) {
            const k = document.createElement('span'); k.className = 'key'; k.textContent = opts.keyLabel; s.appendChild(k);
        }
        if (!view) return s;
        s.classList.add('filled');

        const strip = document.createElement('div');
        strip.className = 'cat-strip';
        strip.dataset.cat = view.category || 'misc';
        s.appendChild(strip);

        s.appendChild(INV.iconEl(view));

        if (view.quantity > 1) {
            const q = document.createElement('span'); q.className = 'qty'; q.textContent = '×' + view.quantity; s.appendChild(q);
        }

        if (view.durable && view.maxDurability) {
            const cur = (view.durability != null) ? view.durability : view.maxDurability;
            const pct = Math.max(0, Math.min(1, cur / view.maxDurability));
            const d = document.createElement('div');
            d.className = 'dura' + (pct <= 0.15 ? ' low' : (pct <= 0.4 ? ' mid' : ''));
            const fill = document.createElement('i'); fill.style.width = (pct * 100) + '%';
            d.appendChild(fill); s.appendChild(d);
        }

        const md = view.metadata || {};
        const extra = Object.keys(md).some(function (k) {
            return ['equipped', 'durability'].indexOf(k) === -1 && md[k] != null && md[k] !== '';
        });
        if (extra) { const t = document.createElement('div'); t.className = 'tag-meta'; s.appendChild(t); }

        return s;
    };

    INV.wireItem = function (el, view, source) {
        INV.dnd.makeDraggable(el, function () {
            return {
                kind: 'item',
                container: source.container,
                slot: source.slot,
                rowId: source.rowId || view.rowId,
                itemId: view.itemId,
                view: view,
            };
        });
        el.addEventListener('pointerenter', function (e) { INV.tooltip.show(view, e.clientX, e.clientY); });
        el.addEventListener('pointermove', function (e) { INV.tooltip.move(e.clientX, e.clientY); });
        el.addEventListener('pointerleave', function () { INV.tooltip.hide(); });
        el.addEventListener('contextmenu', function (e) {
            e.preventDefault();
            INV.tooltip.hide();
            INV.ctx.open(view, source, e.clientX, e.clientY);
        });
    };

    INV.matchesSearch = function (view) {
        const q = (INV.state.search || '').trim().toLowerCase();
        if (!q) return true;
        return (view.label || '').toLowerCase().indexOf(q) !== -1
            || (view.itemId || '').toLowerCase().indexOf(q) !== -1
            || (view.category || '').toLowerCase().indexOf(q) !== -1;
    };

    /* --------------------------------------------------- mutare item --- */
    INV.move = function (p, dest) {
        if (!p || !dest) return;
        if (p.container === dest.container && p.slot === dest.slot) return;
        INV.request('move', {
            from: { container: p.container, slot: p.slot, rowId: p.rowId },
            to: { container: dest.container, slot: (dest.slot === undefined ? null : dest.slot) },
        }).then(INV.afterAction);
    };

    /* ---------------------------------------------------- context menu -- */
    INV.actions = {
        use: function (v, s) { INV.request('use', { slot: s.slot }).then(INV.afterAction); },
        equip: function (v, s) { INV.request('equip', { slot: s.slot }).then(INV.afterAction); },
        unequip: function (v, s) { INV.request('unequip', { slot: s.slot }).then(INV.afterAction); },
        inspect: function (v, s) {
            INV.request('inspect', { slot: s.slot });
            INV.toast('Inspectezi „' + v.label + '”.', 'ok');
        },
        split: function (v, s) {
            if (!(v.quantity > 1)) return;
            INV.modalSplit(v.quantity).then(function (n) {
                if (!n) return;
                INV.request('split', {
                    from: { container: s.container, slot: s.slot, rowId: s.rowId },
                    to: { container: s.container, slot: null },
                    quantity: n,
                }).then(INV.afterAction);
            });
        },
        drop: function (v, s) {
            const cfg = (INV.state.config && INV.state.config.dropConfirm) || {};
            const def = INV.def(v.itemId);
            const valuable = (cfg.categories && cfg.categories[v.category])
                || (def && def.value != null && def.value >= (cfg.minValue || 1e9));
            const go = function () {
                INV.request('drop', { slot: s.slot, quantity: v.quantity }).then(INV.afterAction);
            };
            if (valuable) {
                INV.modalConfirm({
                    title: 'Sigur arunci?',
                    bodyHtml: '<span class="modal-item">' + v.label + '</span>' + (v.quantity > 1 ? ' ×' + v.quantity : ''),
                    okLabel: 'Aruncă', danger: true,
                }).then(function (ok) { if (ok) go(); });
            } else { go(); }
        },
        give: function (v, s) {
            INV.post('nearbyPlayers', {}).then(function (list) {
                list = list || [];
                if (!list.length) { INV.toast('Nimeni în apropiere.', 'error'); return; }
                const send = function (target) {
                    INV.request('give', { slot: s.slot, quantity: v.quantity, target: target }).then(INV.afterAction);
                };
                if (list.length === 1) { send(list[0].serverId); return; }
                INV.modalList('Dă către...', list.map(function (p) {
                    var tag = (p.sqlId != null && p.sqlId !== '') ? '  (' + p.sqlId + ')' : '';
                    return { label: p.name + tag, value: p.serverId };
                })).then(function (val) { if (val) send(val); });
            });
        },
    };

    /* -------------------------------------------------------- capacity - */
    INV.capacity = function () {
        const snap = INV.state.snapshot;
        if (!snap) return;
        const used = snap.used || 0, total = snap.slots || 0;
        document.getElementById('cap-cur').textContent = used;
        document.getElementById('cap-max').textContent = total;
        const pct = total ? Math.min(1, used / total) : 0;
        const bar = document.querySelector('.cap-bar');
        bar.classList.toggle('mid', pct >= 0.7 && pct < 0.9);
        bar.classList.toggle('full', pct >= 0.9);
        document.getElementById('cap-fill').style.width = (pct * 100) + '%';
    };

    INV.render = function () {
        INV.capacity();
        INV.grid.render();
        INV.equipment.render();
        INV.fastslots.render();
        INV.nearby.render();
    };

    /* --------------------------------------------------------- modale -- */
    function scrim() { return document.getElementById('modal-scrim'); }
    function mbox() { return document.getElementById('modal'); }
    function closeModal() { scrim().classList.remove('on'); mbox().innerHTML = ''; }

    INV.modalConfirm = function (o) {
        return new Promise(function (res) {
            const b = mbox();
            b.innerHTML =
                '<h3>' + (o.title || 'Confirmi?') + '</h3><p>' + (o.bodyHtml || '') + '</p>' +
                '<div class="modal-row"><button class="btn btn-ghost" data-x>Anulează</button>' +
                '<button class="btn ' + (o.danger ? 'btn-danger' : 'btn-primary') + '" data-ok>' + (o.okLabel || 'OK') + '</button></div>';
            scrim().classList.add('on');
            b.querySelector('[data-x]').onclick = function () { closeModal(); res(false); };
            b.querySelector('[data-ok]').onclick = function () { closeModal(); res(true); };
        });
    };

    INV.modalSplit = function (max) {
        return new Promise(function (res) {
            const b = mbox();
            const half = Math.max(1, Math.floor(max / 2));
            b.innerHTML =
                '<h3>Împarte stack-ul</h3><p>Câte bucăți muți într-un slot nou?</p>' +
                '<input type="range" min="1" max="' + (max - 1) + '" value="' + half + '">' +
                '<div class="split-val"><b>' + half + '</b> / ' + max + '</div>' +
                '<div class="modal-row"><button class="btn btn-ghost" data-x>Anulează</button>' +
                '<button class="btn btn-primary" data-ok>Împarte</button></div>';
            scrim().classList.add('on');
            const r = b.querySelector('input'), v = b.querySelector('.split-val b');
            r.oninput = function () { v.textContent = r.value; };
            b.querySelector('[data-x]').onclick = function () { closeModal(); res(null); };
            b.querySelector('[data-ok]').onclick = function () { const n = parseInt(r.value, 10); closeModal(); res(n); };
        });
    };

    INV.modalList = function (title, opts) {
        return new Promise(function (res) {
            const b = mbox();
            b.innerHTML = '<h3>' + title + '</h3><div class="modal-list"></div>' +
                '<div class="modal-row"><button class="btn btn-ghost" data-x>Anulează</button></div>';
            const list = b.querySelector('.modal-list');
            opts.forEach(function (o) {
                const btn = document.createElement('button');
                btn.textContent = o.label;
                btn.onclick = function () { closeModal(); res(o.value); };
                list.appendChild(btn);
            });
            scrim().classList.add('on');
            b.querySelector('[data-x]').onclick = function () { closeModal(); res(null); };
        });
    };

    INV.miniMenu = function (x, y, items) {
        INV.ctx.close();
        const b = document.getElementById('ctxmenu');
        b.innerHTML = '';
        items.forEach(function (it) {
            const btn = document.createElement('button');
            if (it.danger) btn.className = 'danger';
            btn.textContent = it.label;
            btn.onclick = function () { b.classList.remove('on'); b.innerHTML = ''; it.run(); };
            b.appendChild(btn);
        });
        b.classList.add('on');
        const w = b.offsetWidth, h = b.offsetHeight;
        b.style.left = Math.min(x, window.innerWidth - w - 12) + 'px';
        b.style.top = Math.min(y, window.innerHeight - h - 12) + 'px';
    };

    INV.toast = function (msg, kind) {
        const host = document.getElementById('inv-toasts');
        const t = document.createElement('div');
        t.className = 'toast ' + (kind || '');
        t.textContent = msg;
        host.appendChild(t);
        setTimeout(function () { t.remove(); }, 3200);
    };
    INV.afterAction = function (res) {
        if (res && res.ok === false && res.error) INV.toast(res.error, 'error');
        return res;
    };

    /* --------------------------------------------------- mesaje NUI --- */
    function show() { document.getElementById('inv').classList.remove('hidden'); }
    function hide() {
        document.getElementById('inv').classList.add('hidden');
        INV.tooltip.hide(); INV.ctx.close();
        scrim().classList.remove('on');
    }

    window.addEventListener('message', function (e) {
        const d = e.data || {};
        if (d.action === 'open') {
            INV.state.config = d.config || {};
            INV.state.search = '';
            document.getElementById('inv-search').value = '';
            show();
            if (INV.state.snapshot) INV.render();
        } else if (d.action === 'sync') {
            INV.state.snapshot = d.snapshot;
            INV.render();
        } else if (d.action === 'nearby') {
            INV.state.nearby = d.nearby;
            if (INV.nearby) INV.nearby.render();
        } else if (d.action === 'close') {
            hide();
        }
    });

    document.getElementById('inv-search').addEventListener('input', function (e) {
        INV.state.search = e.target.value;
        INV.grid.render();
    });
    document.getElementById('inv-close').addEventListener('click', function () { INV.post('close', {}); });

    window.addEventListener('keydown', function (e) {
        if (document.getElementById('inv').classList.contains('hidden')) return;
        if (scrim().classList.contains('on')) return;
        const typing = document.activeElement && document.activeElement.tagName === 'INPUT';
        if (e.key === 'Escape' || (e.key === 'Backspace' && !typing)) INV.post('close', {});
    });

    /* --------------------------------------------- preview in browser - */
    if (typeof window.GetParentResourceName !== 'function') {
        document.body.classList.add('preview');
        INV.state.config = {
            grid: { columns: 5, rows: 5 }, nearby: { columns: 5, rows: 4 }, fastCount: 5,
            equipment: [
                { key: 'hat', label: 'Pălărie', accept: ['clothing'] },
                { key: 'mask', label: 'Mască', accept: ['clothing'] },
                { key: 'glasses', label: 'Ochelari', accept: ['clothing'] },
                { key: 'shirt', label: 'Tricou', accept: ['clothing'] },
                { key: 'armor', label: 'Vestă', accept: ['armor'] },
                { key: 'pants', label: 'Pantaloni', accept: ['clothing'] },
                { key: 'shoes', label: 'Încălț.', accept: ['clothing'] },
            ],
            dropConfirm: { minValue: 500, categories: { weapon: true } },
        };
        const D = {
            water: { id: 'water', label: 'Sticlă cu apă', category: 'consumable', weight: .5, maxStack: 24, value: 5 },
            bandage: { id: 'bandage', label: 'Bandaj', category: 'consumable', weight: .2, maxStack: 20, value: 15 },
            weapon_pistol: { id: 'weapon_pistol', label: 'Pistol compact', category: 'weapon', weight: 1.1, maxStack: 1, value: 1200, durable: true, maxDurability: 40, stats: { damage: 32, caliber: '9mm' } },
            tshirt: { id: 'tshirt', label: 'Tricou simplu', category: 'clothing', weight: .4, maxStack: 1, value: 45, equipSlot: 'shirt' },
            phone: { id: 'phone', label: 'Telefon', category: 'misc', weight: .3, maxStack: 1, value: 400 },
        };
        const mk = function (id, slot, qty, meta) {
            const d = D[id];
            return {
                rowId: 'd' + slot, itemId: id, slot: slot, label: d.label, category: d.category,
                quantity: qty, weight: d.weight, totalWeight: +(d.weight * qty).toFixed(1), icon: id + '.png',
                stackable: d.maxStack > 1, maxStack: d.maxStack, usable: d.category === 'consumable',
                durable: !!d.durable, durability: meta && meta.durability, maxDurability: d.maxDurability,
                equipped: !!(meta && meta.equipped), stats: d.stats || {}, metadata: meta || {}, equipSlot: d.equipSlot,
                context: d.category === 'consumable' ? ['use', 'split', 'drop', 'give', 'inspect']
                    : ['equip', 'drop', 'give', 'inspect'],
            };
        };
        INV.state.snapshot = {
            container: 'char:1', slots: 100, used: 5, definitions: D,
            grid: {
                '1': mk('water', 1, 12), '2': mk('bandage', 2, 6),
                '4': mk('weapon_pistol', 4, 1, { durability: 31 }),
                '7': mk('phone', 7, 1, { phoneNumber: '555 0134' }),
                '9': mk('tshirt', 9, 1),
            },
            equipment: {}, fastSlots: { '1': 1, '2': 2, '3': false, '4': false, '5': false },
        };
        INV.state.nearby = { items: [mk('water', 0, 3), mk('bandage', 1, 1)], slots: 20 };
        show();
        INV.render();
    }
})();
