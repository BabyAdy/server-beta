/* ==========================================================================
   Tooltip dinamic. Continutul vine 100% din item (definitie + metadata).
   Fara serial (exclus prin cerinta). Durabilitate afisata ca x/y.
   ========================================================================== */
window.INV = window.INV || {};

INV.tooltip = (function () {
    function box() { return document.getElementById('tooltip'); }

    function esc(s) {
        return String(s).replace(/[&<>"]/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
        });
    }

    const CAT_LABEL = {
        consumable: 'Consumabil', weapon: 'Armă', clothing: 'Îmbrăcăminte',
        armor: 'Protecție', misc: 'Diverse',
    };
    const SHOWN_META = { equipped: 1, durability: 1 }; // deja afisate / ignorate
    const META_LABEL = {
        ammo: 'Muniție', phoneNumber: 'Număr telefon', component: 'Component',
        drawable: 'Model', texture: 'Textură', prop: 'Prop',
    };

    function rows(it) {
        const r = [];
        if (it.stats && it.stats.damage != null) r.push(['Damage', it.stats.damage]);
        if (it.stats && it.stats.caliber) r.push(['Calibru', it.stats.caliber]);

        if (it.durable && it.maxDurability != null) {
            const cur = (it.durability != null) ? it.durability : it.maxDurability;
            r.push(['Durabilitate', cur + ' / ' + it.maxDurability, cur <= 0]);
        }
        if (it.quantity > 1) r.push(['Cantitate', it.quantity + (it.maxStack ? ' / ' + it.maxStack : '')]);

        const md = it.metadata || {};
        Object.keys(md).forEach(function (k) {
            if (SHOWN_META[k] || md[k] == null || md[k] === '') return;
            if (k === 'serial') return; // exclus
            const label = META_LABEL[k] || (k.charAt(0).toUpperCase() + k.slice(1));
            if (typeof md[k] === 'object') return;
            r.push([label, md[k]]);
        });
        return r;
    }

    function render(it) {
        let html = '<div class="tt-name">' + esc(it.label) + '</div>';
        html += '<div class="tt-cat">' + esc(CAT_LABEL[it.category] || it.category) + '</div>';
        const rr = rows(it);
        if (rr.length) {
            html += '<div class="tt-sep"></div>';
            rr.forEach(function (row) {
                html += '<div class="tt-row' + (row[2] ? ' broken' : '') + '">' +
                    '<span>' + esc(row[0]) + '</span><span>' + esc(row[1]) + '</span></div>';
            });
        }
        return html;
    }

    function place(x, y) {
        const b = box();
        const w = b.offsetWidth, h = b.offsetHeight;
        let nx = x + 16, ny = y + 16;
        if (nx + w > window.innerWidth - 12) nx = x - w - 16;
        if (ny + h > window.innerHeight - 12) ny = window.innerHeight - h - 12;
        b.style.left = Math.max(12, nx) + 'px';
        b.style.top = Math.max(12, ny) + 'px';
    }

    function show(it, x, y) {
        if (INV.dnd && INV.dnd.active) return;
        const b = box();
        b.innerHTML = render(it);
        b.classList.add('on');
        place(x, y);
    }
    function move(x, y) { if (box().classList.contains('on')) place(x, y); }
    function hide() { box().classList.remove('on'); }

    return { show: show, move: move, hide: hide };
})();
