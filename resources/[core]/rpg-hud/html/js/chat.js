/* ==========================================================================
   rpg-hud — CHAT (mereu local; fara canale GLOBAL/LOCAL de ales)
   Mesaj normal:  21:29  Player: text
   Staff chat  :  (icon) [Grad] Nume (id): text     (/a  ·  /hc)
   Sistem      :  21:30  [SISTEM] text
   ========================================================================== */
HUD.mods.chat = (function () {
    var log = function () { return HUD.$('#chat-log'); };
    var wrap = function () { return HUD.$('#chat-input-wrap'); };
    var input = function () { return HUD.$('#chat-input'); };

    var cfg = {
        lifetime: 5000, fade: 1000, maxMessages: 100,
        channels: {}, placeholder: '',
        lines: { default: 8, min: 3, max: 20 },
        font: { default: 12.5, min: 10, max: 18 },
    };
    var active = false;
    var history = [];
    var histIdx = -1;
    var fadeTimers = [];
    var settingsOpen = false;
    var settings = { lines: 8, font: 12.5 };

    var ICON_ADMIN = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l7 3v5c0 4.5-3 8.3-7 9.5C8 19.3 5 15.5 5 11V6l7-3z" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    var ICON_HELPER = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3.5"/><path d="M5.6 5.6l3.6 3.6M14.8 14.8l3.6 3.6M18.4 5.6l-3.6 3.6M9.2 14.8l-3.6 3.6" stroke-linecap="round"/></svg>';

    function esc(s) {
        return String(s).replace(/[&<>"]/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
        });
    }

    function config(c) {
        if (!c.chat) return;
        cfg = Object.assign(cfg, c.chat);
        input().placeholder = cfg.placeholder || '';
        initSettings();
    }

    /* ---- setari jucator (linii vizibile + marime text), persistente ---- */
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

    function applySettings() {
        var chat = HUD.$('#chat');
        var px = settings.font;
        var h = Math.round(settings.lines * (px * 1.5 + 5) + 16);
        chat.style.setProperty('--chat-font', px + 'px');
        chat.style.setProperty('--chat-h', h + 'px');
        var lv = HUD.$('#cs-lines-v'), fv = HUD.$('#cs-font-v');
        if (lv) lv.textContent = settings.lines;
        if (fv) fv.textContent = px + 'px';
    }

    function saveSettings() {
        try { localStorage.setItem('rpg_hud_chat', JSON.stringify(settings)); } catch (e) {}
    }

    function initSettings() {
        var L = cfg.lines || { default: 8, min: 3, max: 20 };
        var F = cfg.font || { default: 12.5, min: 10, max: 18 };
        settings = { lines: L.default, font: F.default };
        try {
            var raw = localStorage.getItem('rpg_hud_chat');
            if (raw) {
                var s = JSON.parse(raw);
                if (typeof s.lines === 'number') settings.lines = clamp(s.lines, L.min, L.max);
                if (typeof s.font === 'number') settings.font = clamp(s.font, F.min, F.max);
            }
        } catch (e) {}

        var rl = HUD.$('#cs-lines'), rf = HUD.$('#cs-font');
        rl.min = L.min; rl.max = L.max; rl.value = settings.lines;
        rf.min = F.min; rf.max = F.max; rf.step = 0.5; rf.value = settings.font;
        applySettings();
    }

    function toggleSettings(force) {
        settingsOpen = (force === undefined) ? !settingsOpen : force;
        HUD.$('#chat-settings').hidden = !settingsOpen;
        wrap().classList.toggle('settings-open', settingsOpen);
        if (!settingsOpen) setTimeout(function () { input().focus(); }, 10);
    }

    /* ---- fade ---- */
    function clearFadeTimers() { fadeTimers.forEach(clearTimeout); fadeTimers = []; }

    function scheduleFade() {
        clearFadeTimers();
        Array.prototype.slice.call(log().children).forEach(function (c) { c.classList.remove('fade', 'gone'); });
        if (active) return;
        fadeTimers.push(setTimeout(function () {
            Array.prototype.slice.call(log().children).forEach(function (c) { c.classList.add('fade'); });
        }, cfg.lifetime));
        fadeTimers.push(setTimeout(function () {
            Array.prototype.slice.call(log().children).forEach(function (c) { c.classList.add('gone'); });
        }, cfg.lifetime + cfg.fade));
    }

    /* ---- render mesaj ---- */
    function addMessage(msg) {
        if (!msg) return;
        var chKey = msg.channel ? String(msg.channel).toUpperCase() : '';
        var el = document.createElement('div');
        el.className = 'cmsg' + (chKey ? ' ch-' + chKey : ' ch-PLAIN');

        var html = '<span class="c-time">' + esc(msg.time || '') + '</span>';

        if (msg.staff) {
            var icon = (msg.staff.kind === 'helper') ? ICON_HELPER : ICON_ADMIN;
            var rc = msg.staff.color || '#fff';
            html += '<span class="c-sicon">' + icon + '</span>';
            html += '<span class="c-badge" style="color:' + rc + ';border-color:' + rc + '">' + esc(msg.staff.label || '') + '</span>';
            html += '<span class="c-auth">' + esc(msg.author || '') + '</span>';
            if (msg.staff.id != null) html += '<span class="c-sid">(' + esc(msg.staff.id) + ')</span>';
            html += '<span class="c-text"' + (msg.color ? ' style="color:' + msg.color + '"' : '') + '>: ' + esc(msg.text || '') + '</span>';
        } else if (chKey && cfg.channels && cfg.channels[chKey]) {
            var ch = cfg.channels[chKey];
            html += '<span class="c-chan" style="color:' + ch.color + '">[' + esc(ch.label) + ']</span>';
            html += '<span class="c-text">' + esc(msg.text || '') + '</span>';
        } else {
            // mesaj normal:  (sql id) Nume: text
            if (msg.id != null && msg.id !== '') html += '<span class="c-sid">(' + esc(msg.id) + ')</span>';
            if (msg.author) html += '<span class="c-auth">' + esc(msg.author) + ':</span>';
            html += '<span class="c-text">' + esc(msg.text || '') + '</span>';
        }

        el.innerHTML = html;
        var host = log();
        host.appendChild(el);
        while (host.children.length > (cfg.maxMessages || 100)) host.removeChild(host.firstChild);
        host.scrollTop = host.scrollHeight;

        scheduleFade();   // mesaj nou => reseteaza timer-ul de fade
    }

    /* ---- open / close ---- */
    function open(payload) {
        active = true;
        HUD.$('#chat').classList.add('active');
        wrap().hidden = false;
        clearFadeTimers();
        Array.prototype.slice.call(log().children).forEach(function (c) { c.classList.remove('fade', 'gone'); });
        input().value = (payload && payload.prefill) || '';
        histIdx = -1;
        setTimeout(function () { input().focus(); }, 20);
    }

    function hideUI() {
        active = false;
        HUD.$('#chat').classList.remove('active');
        wrap().hidden = true;
        input().value = '';
        histIdx = -1;
        toggleSettings(false);
        scheduleFade();
    }

    function submit() {
        var text = input().value;
        if (text.trim()) { history.unshift(text); if (history.length > 50) history.pop(); }
        HUD.post('chatSubmit', { text: text });
        hideUI();
    }

    /* ---- rotita de setari ---- */
    HUD.$('#chat-cog').addEventListener('click', function (e) {
        e.preventDefault();
        toggleSettings();
    });
    HUD.$('#cs-lines').addEventListener('input', function (e) {
        settings.lines = parseInt(e.target.value, 10);
        applySettings(); saveSettings();
    });
    HUD.$('#cs-font').addEventListener('input', function (e) {
        settings.font = parseFloat(e.target.value);
        applySettings(); saveSettings();
    });
    HUD.$('#cs-reset').addEventListener('click', function () {
        var L = cfg.lines, F = cfg.font;
        settings = { lines: L.default, font: F.default };
        HUD.$('#cs-lines').value = settings.lines;
        HUD.$('#cs-font').value = settings.font;
        applySettings(); saveSettings();
    });

    input().addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && settingsOpen) { e.preventDefault(); toggleSettings(false); return; }
        if (e.key === 'Enter') { e.preventDefault(); submit(); }
        else if (e.key === 'Escape') { e.preventDefault(); hideUI(); HUD.post('chatClose', {}); }
        else if (e.key === 'ArrowUp') {
            if (history.length) { histIdx = Math.min(histIdx + 1, history.length - 1); input().value = history[histIdx]; }
        } else if (e.key === 'ArrowDown') {
            if (histIdx > 0) { histIdx--; input().value = history[histIdx]; }
            else { histIdx = -1; input().value = ''; }
        }
    });

    return {
        config: config,
        rootVisible: function (v) { HUD.$('#chat').classList.toggle('root-hidden', !v); },
        on: function (action, value) {
            if (action === 'open') open(value);
            else if (action === 'close') hideUI();
            else if (action === 'message') addMessage(value);
            else if (action === 'clear') log().innerHTML = '';
        },
    };
})();
