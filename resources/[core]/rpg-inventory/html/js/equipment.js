/* ==========================================================================
   Sloturi de echipament din jurul personajului + rotire preview.
   Pregatit pentru clothing system (verifica compatibilitatea cu slotul).
   ========================================================================== */
window.INV = window.INV || {};

INV.equipment = (function () {
    function slotEls() {
        return Array.prototype.slice.call(document.querySelectorAll('.char-view .eq'));
    }

    function accepts(slotDef, view) {
        if (!view) return false;
        if (view.equipSlot && view.equipSlot === slotDef.key) return true;
        return (slotDef.accept || []).indexOf(view.category) !== -1
            && (!view.equipSlot || view.equipSlot === slotDef.key);
    }

    function render() {
        const snap = INV.state.snapshot;
        const cfg = INV.state.config;
        if (!snap || !cfg) return;

        const defByKey = {};
        (cfg.equipment || []).forEach(function (e) { defByKey[e.key] = e; });

        slotEls().forEach(function (host) {
            const key = host.dataset.eq;
            const def = defByKey[key] || { key: key, label: key, accept: [] };
            host.setAttribute('data-label', def.label);
            host.innerHTML = '';

            const view = snap.equipment[key] || null;
            if (view) {
                const inner = INV.buildSlot(view, {});
                inner.style.position = 'absolute';
                inner.style.inset = '0';
                host.appendChild(inner);
                INV.wireItem(inner, view, { container: snap.container, slot: key, kind: 'equip' });
            }

            INV.dnd.register(host,
                function (p) { return p && p.kind === 'item' && accepts(def, p.view); },
                function (p) {
                    INV.move(p, { container: snap.container, slot: key });
                });
        });
    }

    // rotire ped (butoanele ‹ ›)
    document.querySelectorAll('.char-rot').forEach(function (b) {
        b.addEventListener('click', function () {
            INV.post('rotate', { delta: parseFloat(b.dataset.rot) || 0 });
        });
    });

    return { render: render };
})();
