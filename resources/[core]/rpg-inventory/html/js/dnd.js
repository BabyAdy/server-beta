/* ==========================================================================
   Drag & drop (pointer-based; HTML5 DnD e instabil in CEF).
   INV.dnd.makeDraggable(el, getPayload)
   INV.dnd.register(el, accept(payload), onDrop(payload, ev))  -> unregister()
   ========================================================================== */
window.INV = window.INV || {};

INV.dnd = (function () {
    let drag = null;                 // { payload, origin, ghost, hot }
    const targets = [];

    function register(el, accept, onDrop) {
        const t = { el, accept, onDrop };
        targets.push(t);
        return function () {
            const i = targets.indexOf(t);
            if (i >= 0) targets.splice(i, 1);
        };
    }

    function begin(ev, payload, origin) {
        drag = { payload, origin, ghost: null, hot: null };

        const ghost = document.createElement('div');
        ghost.className = 'drag-ghost';
        const inner = origin.querySelector('.icon');
        if (inner) ghost.appendChild(inner.cloneNode(true));
        document.body.appendChild(ghost);
        drag.ghost = ghost;

        origin.classList.add('dragging');
        INV.tooltip && INV.tooltip.hide();
        INV.ctx && INV.ctx.close();

        move(ev);
        window.addEventListener('pointermove', move);
        window.addEventListener('pointerup', end, { once: true });
    }

    function move(ev) {
        if (!drag) return;
        drag.ghost.style.left = ev.clientX + 'px';
        drag.ghost.style.top = ev.clientY + 'px';

        const under = document.elementFromPoint(ev.clientX, ev.clientY);
        drag.hot = null;
        targets.forEach(function (t) {
            const inside = under && t.el.contains(under);
            let good = false;
            if (inside) {
                try { good = t.accept(drag.payload) !== false; } catch (e) { good = false; }
            }
            t.el.classList.toggle('drop-hot', inside && good);
            t.el.classList.toggle('bad-hot', inside && !good);
            if (inside && good) drag.hot = t;
        });
    }

    function end(ev) {
        window.removeEventListener('pointermove', move);
        const d = drag;
        drag = null;
        if (d.ghost) d.ghost.remove();
        d.origin.classList.remove('dragging');
        targets.forEach(function (t) { t.el.classList.remove('drop-hot', 'bad-hot'); });
        if (d.hot) {
            try { d.hot.onDrop(d.payload, ev); } catch (e) { /* noop */ }
        }
    }

    function makeDraggable(el, getPayload) {
        el.addEventListener('pointerdown', function (ev) {
            if (ev.button !== 0) return;
            const payload = getPayload();
            if (!payload) return;
            ev.preventDefault();
            begin(ev, payload, el);
        });
    }

    return { register: register, makeDraggable: makeDraggable, get active() { return !!drag; } };
})();
