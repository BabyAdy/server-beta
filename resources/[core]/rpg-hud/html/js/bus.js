/* ==========================================================================
   rpg-hud — message bus.  Client -> SendNUIMessage({ mod, action, value })
   Fiecare modul isi inregistreaza  HUD.mods.<name> = { on, config?, rootVisible? }
   ========================================================================== */
window.HUD = { mods: {}, cfg: { chat: {}, speedo: {} } };

HUD.$ = function (s) { return document.querySelector(s); };

function hudRes() {
    return (typeof window.GetParentResourceName === 'function')
        ? window.GetParentResourceName() : 'rpg-hud';
}

HUD.post = function (name, data) {
    return fetch('https://' + hudRes() + '/' + name, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).then(function (r) { return r.json().catch(function () { return {}; }); })
      .catch(function () { return {}; });
};

window.addEventListener('message', function (e) {
    var d = e.data || {};
    if (!d.mod) return;

    if (d.mod === 'root') {
        if (d.action === 'config') {
            HUD.cfg = Object.assign(HUD.cfg, d.value || {});
            Object.keys(HUD.mods).forEach(function (k) {
                if (HUD.mods[k].config) HUD.mods[k].config(HUD.cfg);
            });
        } else if (d.action === 'visible') {
            var v = !!d.value;
            HUD.$('#hud').hidden = !v;
            Object.keys(HUD.mods).forEach(function (k) {
                if (HUD.mods[k].rootVisible) HUD.mods[k].rootVisible(v);
            });
        }
        return;
    }

    var m = HUD.mods[d.mod];
    if (m && m.on) m.on(d.action, d.value);
});

document.addEventListener('DOMContentLoaded', function () {
    HUD.post('ready', {});
    if (typeof window.GetParentResourceName !== 'function') {
        document.body.classList.add('preview');
        setTimeout(function () { if (HUD.demo) HUD.demo(); }, 30);
    }
});
