/* ==========================================================================
   Context menu (click dreapta). Optiunile vin din item.context (server),
   deci sunt configurabile per item / per categorie.
   ========================================================================== */
window.INV = window.INV || {};

INV.ctx = (function () {
    const LABEL = {
        use: 'Folosește', equip: 'Echipează', unequip: 'Dezechipează',
        split: 'Împarte', drop: 'Aruncă', give: 'Dă', inspect: 'Inspectează',
    };
    const DANGER = { drop: 1 };

    function box() { return document.getElementById('ctxmenu'); }

    function close() {
        const b = box();
        b.classList.remove('on');
        b.innerHTML = '';
    }

    function open(it, source, x, y) {
        const b = box();
        b.innerHTML = '';

        const head = document.createElement('div');
        head.className = 'ctx-head';
        head.textContent = it.label + (it.quantity > 1 ? '  ×' + it.quantity : '');
        b.appendChild(head);

        (it.context || []).forEach(function (act) {
            if (!LABEL[act]) return;
            const btn = document.createElement('button');
            if (DANGER[act]) btn.className = 'danger';
            btn.textContent = LABEL[act];
            btn.addEventListener('click', function () {
                close();
                if (INV.actions && INV.actions[act]) INV.actions[act](it, source);
            });
            b.appendChild(btn);
        });

        b.classList.add('on');
        const w = b.offsetWidth, h = b.offsetHeight;
        b.style.left = Math.min(x, window.innerWidth - w - 12) + 'px';
        b.style.top = Math.min(y, window.innerHeight - h - 12) + 'px';
    }

    window.addEventListener('pointerdown', function (e) {
        const b = box();
        if (b.classList.contains('on') && !b.contains(e.target)) close();
    });
    window.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });

    return { open: open, close: close };
})();
