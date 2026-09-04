(function () {
    'use strict';

    var isBrowser = typeof window.GetParentResourceName !== 'function';
    var RES = isBrowser ? 'rpg-level' : window.GetParentResourceName();
    var $ = function (s) { return document.querySelector(s); };

    /* formatter reutilizabil: separator de mii cu punct. (NU se salveaza formatat)
       fmtMoney(1000000)       -> "1.000.000$"   (sufix, folosit in /stats)
       fmtMoney(100, true)     -> "$100"         (prefix, folosit in notificarea Payday) */
    function fmtMoney(n, prefix) {
        n = Math.round(Number(n) || 0);
        var neg = n < 0 ? '-' : '';
        var s = String(Math.abs(n));
        var out = '';
        for (var i = 0; i < s.length; i++) {
            if (i > 0 && (s.length - i) % 3 === 0) out += '.';
            out += s.charAt(i);
        }
        return prefix ? (neg + '$' + out) : (neg + out + '$');
    }

    /* formatter reutilizabil: secunde -> "HH.MM"  (MM = 00-59, NU zecimală) */
    function fmtPlaytime(sec) {
        sec = Math.max(0, Math.floor(Number(sec) || 0));
        var h = Math.floor(sec / 3600);
        var m = Math.floor((sec % 3600) / 60);
        return h + '.' + (m < 10 ? '0' : '') + m;
    }

    function post(name, body) {
        if (isBrowser) return Promise.resolve({});
        return fetch('https://' + RES + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {}),
        }).catch(function () {});
    }

    function render(d) {
        d = d || {};
        $('#s-id').textContent = (d.id != null ? d.id : '—');
        $('#s-name').textContent = d.username || '—';
        $('#s-level').textContent = (d.level != null ? d.level : '—');
        $('#s-hours').textContent = fmtPlaytime(d.playtime);

        $('#s-money').textContent = fmtMoney(d.money);
        $('#s-bank').textContent = fmtMoney(d.bank);

        // nu există level maxim -> mereu afișăm cerințele pentru următorul level
        var req = $('#s-req'), fill = $('#s-progfill');
        var nxt = d.next || {};
        var rpNow = Number(d.rp) || 0;
        var rpReq = Number(nxt.rp) || 0;
        var mReq = Number(nxt.money) || 0;

        // format cerut: Level: 1 (5/3 RP and 1.000$ for next level)
        req.textContent = '(' + rpNow + '/' + rpReq + ' RP and ' + fmtMoney(mReq) + ' for next level)';

        var pct = rpReq > 0 ? Math.max(0, Math.min(1, rpNow / rpReq)) : 1;
        fill.style.width = (pct * 100) + '%';
    }

    function open(d) {
        render(d);
        $('#stats').classList.remove('hidden');
    }
    function close() {
        $('#stats').classList.add('hidden');
    }

    /* -------------------------------------------------- notificare Payday -- */
    var pnTimers = [];
    function showPayday(d) {
        d = d || {};
        pnTimers.forEach(clearTimeout); pnTimers = [];
        $('#pn-hours').textContent = fmtPlaytime(d.activeSeconds);
        $('#pn-rp').textContent = (d.rp != null ? d.rp : 1);
        $('#pn-salary').textContent = fmtMoney(d.salary != null ? d.salary : 100, true);
        $('#pn-interest').textContent = fmtMoney(d.interest || 0, true);

        var el = $('#pnotif');
        el.classList.remove('out', 'hidden');
        void el.offsetWidth;                      // restart animației
        pnTimers.push(setTimeout(function () { el.classList.add('out'); }, 8000));
        pnTimers.push(setTimeout(function () { el.classList.add('hidden'); el.classList.remove('out'); }, 8350));
    }

    window.addEventListener('message', function (e) {
        var msg = e.data || {};
        if (msg.action === 'open') open(msg.data);
        else if (msg.action === 'close') close();
        else if (msg.action === 'payday') showPayday(msg.data);
    });

    $('#s-close').addEventListener('click', function () { post('close'); });

    window.addEventListener('keyup', function (e) {
        if (e.key === 'Escape' && !$('#stats').classList.contains('hidden')) post('close');
    });

    /* preview in browser */
    if (isBrowser) {
        document.body.classList.add('preview');
        open({ id: 1524, username: 'ShadowFox', level: 1, rp: 5, money: 5000, bank: 1000,
               playtime: 80943, next: { rp: 3, money: 1000 } });
        window.__payday = function () {
            showPayday({ activeSeconds: 1801, rp: 1, salary: 100, interest: 30 });
        };
    }
})();
