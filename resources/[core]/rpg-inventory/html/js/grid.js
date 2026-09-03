/* ==========================================================================
   Inventarul principal. Capacitate pe SLOTURI (X / N). Grid cu scroll;
   sloturile goale raman vizibile.
   ========================================================================== */
window.INV = window.INV || {};

INV.grid = (function () {
    function el() { return document.getElementById('inv-grid'); }

    function render() {
        const host = el();
        const snap = INV.state.snapshot;
        if (!snap) return;
        const total = snap.slots || 100;

        host.innerHTML = '';
        for (let i = 1; i <= total; i++) {
            const view = snap.grid[String(i)] || null;
            const slot = INV.buildSlot(view, { idxLabel: String(i).padStart(2, '0') });

            // drop target: mereu (chiar si slot gol)
            INV.dnd.register(slot,
                function (p) { return p && p.kind === 'item'; },
                function (p) {
                    INV.move(p, { container: snap.container, slot: i });
                });

            if (view) {
                INV.wireItem(slot, view, { container: snap.container, slot: i, kind: 'grid' });
                if (!INV.matchesSearch(view)) slot.classList.add('dim');
                if (view.equipped) slot.classList.add('equipped-here');
            }
            host.appendChild(slot);
        }
    }

    return { render: render };
})();
