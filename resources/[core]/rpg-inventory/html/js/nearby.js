/* ==========================================================================
   NEARBY ITEMS + DROP ZONE.
   Nearby = loot pe jos / containere in raza (validate de server).
   Clientul NU decide ca a luat un item: doar cere mutarea.
   ========================================================================== */
window.INV = window.INV || {};

INV.nearby = (function () {
    function gridEl() { return document.getElementById('nearby-grid'); }
    function dropEl() { return document.getElementById('dropzone'); }

    function render() {
        const host = gridEl();
        const data = INV.state.nearby || { items: [], slots: 20 };
        const snap = INV.state.snapshot;
        const total = (INV.state.config && INV.state.config.nearby)
            ? INV.state.config.nearby.columns * INV.state.config.nearby.rows
            : (data.slots || 20);

        host.innerHTML = '';
        for (let i = 0; i < total; i++) {
            const view = data.items[i] || null;
            const slot = INV.buildSlot(view, {});

            // primeste iteme din inventarul playerului -> arunca pe jos (pila la picioare)
            INV.dnd.register(slot,
                function (p) { return p && p.kind === 'item' && p.kind !== 'nearby'; },
                function (p) {
                    if (p.container && p.container.indexOf('ground:') === 0) return; // deja pe jos
                    INV.move(p, { container: 'drop' });
                });

            if (view) {
                INV.wireItem(slot, view, {
                    container: view.container, slot: view.slot, kind: 'nearby', rowId: view.rowId,
                });
            }
            host.appendChild(slot);
        }

        // DROP ZONE
        const dz = dropEl();
        if (!dz._wired) {
            INV.dnd.register(dz,
                function (p) { return p && p.kind === 'item' && (!p.container || p.container.indexOf('ground:') !== 0); },
                function (p) { INV.actions.drop(p.view, { container: p.container, slot: p.slot, rowId: p.rowId }); });
            dz._wired = true;
        }
        void snap;
    }

    return { render: render };
})();
