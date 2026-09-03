/* ==========================================================================
   FAST SLOTS (1..5). Leaga un slot din grid; tastele 1..5 il folosesc/echipeaza.
   Legaturile se salveaza per personaj (server).
   ========================================================================== */
window.INV = window.INV || {};

INV.fastslots = (function () {
    function row() { return document.getElementById('fast-row'); }

    function render() {
        const host = row();
        const snap = INV.state.snapshot;
        const count = (INV.state.config && INV.state.config.fastCount) || 5;
        if (!snap) return;

        host.innerHTML = '';
        for (let i = 1; i <= count; i++) {
            const gridSlot = snap.fastSlots[String(i)];
            const view = (gridSlot && snap.grid[String(gridSlot)]) || null;
            const slot = INV.buildSlot(view, { keyLabel: String(i) });

            // primeste doar iteme din grid -> creeaza legatura
            INV.dnd.register(slot,
                function (p) {
                    return p && p.kind === 'item' && p.container === snap.container
                        && typeof p.slot === 'number';
                },
                function (p) {
                    INV.request('bindFast', { index: i, slot: p.slot }).then(INV.afterAction);
                });

            if (view) {
                INV.wireItem(slot, view, {
                    container: snap.container, slot: gridSlot, kind: 'grid',
                });
                // click dreapta pe fast slot: optiune de eliberare
                slot.addEventListener('contextmenu', function (e) {
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    INV.miniMenu(e.clientX, e.clientY, [
                        { label: 'Elimină din slot rapid', danger: true, run: function () {
                            INV.request('bindFast', { index: i, slot: null }).then(INV.afterAction);
                        } },
                    ]);
                }, true);
            }
            host.appendChild(slot);
        }
    }

    return { render: render };
})();
