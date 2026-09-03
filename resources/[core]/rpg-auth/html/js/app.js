(function () {
    'use strict';

    var isBrowser = typeof window.GetParentResourceName !== 'function';
    var RES = isBrowser ? 'rpg-auth' : window.GetParentResourceName();

    var $  = function (s, r) { return (r || document).querySelector(s); };
    var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };

    var app = $('#app');
    var screens = {
        login:    $('[data-screen="login"]'),
        register: $('[data-screen="register"]')
    };
    var current = 'login';

    var cfg = { minUsername: 3, maxUsername: 20, minPassword: 6 };

    var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
    var USER_RE  = /^[A-Za-z0-9_.-]+$/;

    var ICON = {
        warn:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 9v4m0 4h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" stroke-linecap="round" stroke-linejoin="round"/></svg>',
        check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m20 6-11 11-5-5" stroke-linecap="round" stroke-linejoin="round"/></svg>',
        info:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 11v5m0-8h.01" stroke-linecap="round"/></svg>'
    };

    /* ------------------------------------------------------- NUI fetch --- */
    function post(name, data) {
        return fetch('https://' + RES + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {})
        }).then(function (r) {
            return r.json().catch(function () { return {}; });
        }).catch(function () { return {}; });
    }

    /* ------------------------------------------------- screen switching --- */
    function show(name) {
        if (!screens[name]) return;
        Object.keys(screens).forEach(function (k) {
            var el = screens[k];
            var on = k === name;
            el.hidden = !on;
            if (on) {
                el.classList.remove('anim-in');
                void el.offsetWidth;
                el.classList.add('anim-in');
            }
        });
        current = name;
        clearErrors();
        var first = screens[name].querySelector('input:not([type=checkbox])');
        if (first) setTimeout(function () { first.focus(); }, 60);
    }

    /* --------------------------------------------------- open / close --- */
    function openApp(screen, config) {
        if (config) {
            cfg.minUsername = config.minUsername || cfg.minUsername;
            cfg.maxUsername = config.maxUsername || cfg.maxUsername;
            cfg.minPassword = config.minPassword || cfg.minPassword;
            if (config.logo) $$('.logo').forEach(function (i) { i.src = config.logo; });
        }
        app.classList.remove('hidden');
        show(screen || 'login');

        try {
            var saved = localStorage.getItem('rpg_auth_user');
            if (saved) {
                $('#login-username').value = saved;
                $('#login-remember').checked = true;
                setTimeout(function () { $('#login-password').focus(); }, 80);
            }
        } catch (e) {}
    }

    function closeApp() {
        app.classList.add('hidden');
        $('#form-login').reset();
        $('#form-register').reset();
        resetStrength();
        clearErrors();
    }

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        switch (d.action) {
            case 'open':   openApp(d.screen, d.config); break;
            case 'close':  closeApp(); break;
            case 'screen': show(d.screen); break;
            case 'notify': toast(d.message, d.type || 'info'); break;
        }
    });

    document.addEventListener('keyup', function (e) {
        if (e.key === 'Escape' && current === 'register') show('login');
    });

    /* --------------------------------------------------- validation ----- */
    function setErr(input, msg) {
        var field = input.closest('.field');
        var wrap = input.closest('.input');
        var err = field && field.querySelector('.err');
        if (wrap) wrap.classList.add('invalid');
        if (err) { err.textContent = msg; err.classList.add('show'); }
    }

    function clearErr(input) {
        var field = input.closest('.field');
        var wrap = input.closest('.input');
        var err = field && field.querySelector('.err');
        if (wrap) wrap.classList.remove('invalid');
        if (err) { err.textContent = ''; err.classList.remove('show'); }
    }

    function clearErrors() {
        $$('.input.invalid').forEach(function (w) { w.classList.remove('invalid'); });
        $$('.err.show').forEach(function (e) { e.textContent = ''; e.classList.remove('show'); });
    }

    /* ------------------------------------------------------ loading ----- */
    function setLoading(btn, on) {
        btn.classList.toggle('loading', on);
        btn.disabled = on;
    }

    /* ------------------------------------------------------- toasts ----- */
    var toastsEl = $('#toasts');

    function escapeHtml(s) {
        return String(s).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
        });
    }

    function toast(msg, type, ttl) {
        if (!msg) return;
        type = type || 'info';
        ttl = ttl || 3800;
        var el = document.createElement('div');
        el.className = 'toast ' + type;
        var ic = type === 'error' ? ICON.warn : type === 'success' ? ICON.check : ICON.info;
        el.innerHTML = '<span class="ic">' + ic + '</span><span>' + escapeHtml(msg) + '</span>';
        toastsEl.appendChild(el);
        var kill = function () {
            el.classList.add('leaving');
            el.addEventListener('animationend', function () { el.remove(); }, { once: true });
        };
        var t = setTimeout(kill, ttl);
        el.addEventListener('click', function () { clearTimeout(t); kill(); });
    }

    /* -------------------------------------------------- password UI ----- */
    $$('.toggle-pass').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var input = btn.parentElement.querySelector('input');
            var reveal = input.type === 'password';
            input.type = reveal ? 'text' : 'password';
            btn.classList.toggle('on', reveal);
            input.focus();
        });
    });

    var strengthEl = $('#reg-strength');
    var strengthLabel = $('#reg-strength-label');
    var STRENGTH_NAMES = ['Foarte slabă', 'Slabă', 'Medie', 'Bună', 'Puternică'];

    function scorePass(v) {
        var s = 0;
        if (v.length >= 6) s++;
        if (v.length >= 10) s++;
        if (/[a-z]/.test(v) && /[A-Z]/.test(v)) s++;
        if (/\d/.test(v)) s++;
        if (/[^A-Za-z0-9]/.test(v)) s++;
        return Math.min(s, 4);
    }

    function resetStrength() {
        strengthEl.className = 'strength s0';
        strengthLabel.textContent = '';
    }

    $('#reg-password').addEventListener('input', function (e) {
        var v = e.target.value;
        var s = scorePass(v);
        strengthEl.className = 'strength s' + s;
        strengthLabel.textContent = v ? STRENGTH_NAMES[s] : '';
    });

    /* --------------------------------------------------- navigation ---- */
    $('#go-register').addEventListener('click', function () { show('register'); });
    $('#go-login').addEventListener('click', function () { show('login'); });
    $('#go-recover').addEventListener('click', onRecover);

    $$('input').forEach(function (i) {
        i.addEventListener('input', function () { clearErr(i); });
    });

    /* ------------------------------------------------------- LOGIN ----- */
    $('#form-login').addEventListener('submit', function (e) {
        e.preventDefault();
        var u = $('#login-username'), p = $('#login-password');
        clearErr(u); clearErr(p);

        var bad = false;
        if (!u.value.trim()) { setErr(u, 'Introdu username-ul.'); bad = true; }
        if (!p.value) { setErr(p, 'Introdu parola.'); bad = true; }
        if (bad) return;

        var btn = $('#btn-login');
        setLoading(btn, true);

        post('login', {
            username: u.value.trim(),
            password: p.value,
            remember: $('#login-remember').checked
        }).then(function (res) {
            setLoading(btn, false);
            if (res && res.ok) {
                try {
                    if ($('#login-remember').checked) localStorage.setItem('rpg_auth_user', u.value.trim());
                    else localStorage.removeItem('rpg_auth_user');
                } catch (err) {}
                toast(res.message || 'Autentificare reușită.', 'success');
            } else {
                var m = (res && res.message) || 'Autentificare eșuată.';
                setErr(p, m);
                toast(m, 'error');
            }
        });
    });

    /* ----------------------------------------------------- REGISTER --- */
    $('#form-register').addEventListener('submit', function (e) {
        e.preventDefault();
        var u = $('#reg-username'), em = $('#reg-email'), p = $('#reg-password'), c = $('#reg-confirm');
        [u, em, p, c].forEach(clearErr);

        var bad = false;
        var un = u.value.trim();

        if (un.length < cfg.minUsername || un.length > cfg.maxUsername) {
            setErr(u, 'Username între ' + cfg.minUsername + ' și ' + cfg.maxUsername + ' caractere.');
            bad = true;
        } else if (!USER_RE.test(un)) {
            setErr(u, 'Doar litere, cifre și . _ -');
            bad = true;
        }
        if (!EMAIL_RE.test(em.value.trim())) { setErr(em, 'Adresă de email invalidă.'); bad = true; }
        if (p.value.length < cfg.minPassword) {
            setErr(p, 'Parola trebuie să aibă minim ' + cfg.minPassword + ' caractere.');
            bad = true;
        }
        if (c.value !== p.value) { setErr(c, 'Parolele nu coincid.'); bad = true; }
        if (bad) return;

        var btn = $('#btn-register');
        setLoading(btn, true);

        post('register', {
            username: un,
            email: em.value.trim(),
            password: p.value,
            confirm: c.value
        }).then(function (res) {
            setLoading(btn, false);
            if (res && res.ok) {
                toast(res.message || 'Cont creat! Te poți autentifica acum.', 'success');
                $('#form-register').reset();
                resetStrength();
                $('#login-username').value = un;
                show('login');
                setTimeout(function () { $('#login-password').focus(); }, 120);
            } else {
                var m = (res && res.message) || 'Înregistrare eșuată.';
                toast(m, 'error');
                if (/username/i.test(m)) setErr(u, m);
                else if (/email/i.test(m)) setErr(em, m);
            }
        });
    });

    function onRecover() {
        var u = $('#login-username').value.trim();
        post('recover', { username: u }).then(function (res) {
            toast((res && res.message) || 'Dacă adresa există, vei primi instrucțiuni de recuperare.', 'info', 5000);
        });
    }

    /* -------------------------------------------------------- boot ----- */
    if (isBrowser) {
        document.body.classList.add('preview');
        openApp('login', {});
    } else {
        post('ready', {});
    }
})();
