/* ==========================================================================
   rpg-hud — HUD (player, money, status bars, paycheck, voice, activity)
   ========================================================================== */
HUD.mods.hud = (function () {
    var $ = HUD.$;

    /* ---- bars ---- */
    function setBar(name, pct) {
        pct = Math.max(0, Math.min(100, Math.round(pct)));
        var b = $('#b-' + name), p = $('#b-' + name + '-p');
        if (b) b.style.width = pct + '%';
        if (p) p.textContent = pct + '%';
        var bar = b && b.closest('.bar');
        if (bar) {
            bar.classList.toggle('low', pct <= 20);
            bar.classList.toggle('mid', pct > 20 && pct <= 45);
        }
    }

    function money(sel, v) {
        var el = $(sel);
        if (el) el.textContent = '$' + Number(v || 0).toLocaleString('en-US');
    }

    /* ---- paycheck countdown (tick local, seed de la client/server) ---- */
    var pc = { seconds: 0, running: false, t: null };
    function renderPc() {
        var m = Math.floor(pc.seconds / 60), s = pc.seconds % 60;
        $('#pc-time').textContent = (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
    }
    function startPaycheck(d) {
        d = d || {};
        pc.seconds = Math.max(0, Math.floor(d.seconds || 0));
        pc.running = d.running !== false;
        if (pc.t) clearInterval(pc.t);
        renderPc();
        pc.t = setInterval(function () {
            if (pc.running && pc.seconds > 0) { pc.seconds--; renderPc(); }
        }, 1000);
    }

    /* ---- activity / status container (reutilizabil) ---- */
    var act = { timer: 0, t: null };
    function fmtDur(s) {
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), x = s % 60;
        return (h > 0 ? (h < 10 ? '0' : '') + h + ':' : '') +
            (m < 10 ? '0' : '') + m + ':' + (x < 10 ? '0' : '') + x;
    }
    function setActivity(d) {
        if (!d) return clearActivity();
        $('#hud-activity').hidden = false;
        $('#a-title').textContent = d.title || 'ACTIVITATE';
        if (act.t) { clearInterval(act.t); act.t = null; }

        if (typeof d.timer === 'number') {
            act.timer = Math.floor(d.timer);
            var tick = function () {
                $('#a-sub').textContent = fmtDur(Math.max(0, act.timer));
                if (act.timer <= 0) { clearInterval(act.t); act.t = null; }
                else act.timer--;
            };
            tick();
            act.t = setInterval(tick, 1000);
        } else {
            $('#a-sub').textContent = d.text || '';
        }

        var barWrap = $('#hud-activity .a-bar');
        if (typeof d.progress === 'number') {
            barWrap.hidden = false;
            $('#a-fill').style.width = Math.round(Math.max(0, Math.min(1, d.progress)) * 100) + '%';
        } else {
            barWrap.hidden = true;
        }
    }
    function clearActivity() {
        $('#hud-activity').hidden = true;
        if (act.t) { clearInterval(act.t); act.t = null; }
    }

    return {
        on: function (action, value) {
            switch (action) {
                case 'health': setBar('health', value); break;
                case 'food': setBar('food', value); break;
                case 'water': setBar('water', value); break;
                case 'player':
                    $('#p-name').textContent = (value && value.username) || '—';
                    $('#p-id').textContent = '#' + (value && value.id != null ? value.id : '—');
                    break;
                case 'online': $('#p-online').textContent = value; break;
                case 'money': money('#m-cash', value); break;
                case 'bank': money('#m-bank', value); break;
                case 'paycheck': startPaycheck(value); break;
                case 'voice': $('#voice').className = 'voice ' + (value || 'idle'); break;
                case 'activity': setActivity(value); break;
                case 'activityClear': clearActivity(); break;
            }
        },
    };
})();
