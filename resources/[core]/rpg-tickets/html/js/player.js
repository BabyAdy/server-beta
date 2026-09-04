/* ==========================================================================
   rpg-tickets — bridge NUI comun (window.TK) + logica meniului de PLAYER
   ========================================================================== */
(function () {
  'use strict';

  /* ----------------------------- BRIDGE TK ------------------------------- */
  var isBrowser = typeof window.GetParentResourceName !== 'function';
  var RES = isBrowser ? 'rpg-tickets' : window.GetParentResourceName();

  var seq = 0;
  var pending = {};
  var pushHandlers = {};

  var TK = {
    isBrowser: isBrowser,
    self: null,

    esc: function (s) {
      return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
      });
    },

    fmtMoney: function (n) {
      n = Math.round(Number(n) || 0);
      var neg = n < 0 ? '-' : '';
      var s = String(Math.abs(n)), out = '';
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 === 0) out += '.';
        out += s.charAt(i);
      }
      return neg + '$' + out;
    },

    fmtDur: function (sec) {
      sec = Math.max(0, Math.floor(Number(sec) || 0));
      if (sec < 60) return sec + 's';
      var m = Math.floor(sec / 60), s = sec % 60;
      if (m < 60) return m + 'm' + (s ? ' ' + s + 's' : '');
      var h = Math.floor(m / 60); m = m % 60;
      if (h < 24) return h + 'h' + (m ? ' ' + m + 'm' : '');
      var d = Math.floor(h / 24); h = h % 24;
      return d + 'z' + (h ? ' ' + h + 'h' : '');
    },

    /* RPC cu raspuns: NUI -> client -> server -> client -> aici */
    rpc: function (name, data) {
      if (isBrowser) return Promise.resolve(mockRpc(name, data));
      return fetch('https://' + RES + '/rpc', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ name: name, data: data || {} }),
      }).then(function (r) { return r.json(); })
        .catch(function () { return { ok: false, data: { error: 'net' } }; });
    },

    /* fire-and-forget (close / equip) */
    post: function (name, data) {
      if (isBrowser) return Promise.resolve({});
      return fetch('https://' + RES + '/' + name, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
      }).catch(function () {});
    },

    /* mai multi subscriberi per "kind" (player.js si staff.js se aboneaza ambii) */
    onPush: function (kind, fn) { (pushHandlers[kind] = pushHandlers[kind] || []).push(fn); },

    toast: function (text, kind) {
      var el = document.getElementById('tk-toast');
      el.textContent = text;
      el.className = (kind || '') + ' show';
      el.classList.remove('hidden');
      clearTimeout(TK._tt);
      TK._tt = setTimeout(function () { el.classList.add('hidden'); }, 3200);
    },

    showApp: function (which) {
      ['player-app', 'staff-app'].forEach(function (id) {
        var a = document.getElementById(id);
        a.classList.add('hidden'); a.classList.remove('shown');
      });
      var t = document.getElementById(which === 'staff' ? 'staff-app' : 'player-app');
      t.classList.remove('hidden'); t.classList.add('shown');
    },

    hideAll: function () {
      ['player-app', 'staff-app'].forEach(function (id) {
        var a = document.getElementById(id);
        a.classList.add('hidden'); a.classList.remove('shown');
      });
    },
  };
  window.TK = TK;

  /* mock pt. preview in browser */
  function mockRpc(name) {
    var t = { id: 101, category: 'Player Report', reason: 'test reason lorem ipsum', status: 'active',
              playerName: 'BabyAdy', playerId: 1, time: '01:19', staffName: null };
    if (name === 'bootstrap') return { ok: true, data: { self: { name: 'BabyAdy', id: 1, staff: '' }, tickets: [t] } };
    if (name === 'staffBootstrap') return { ok: true, data: { self: { name: 'imoGen', sid: 66564, staff: 'helper', staffLabel: 'Helper', staffColor: '#37ff00', staffLevel: 20 },
      tickets: [t], stats: mockStats() } };
    if (name === 'fetchStats') return { ok: true, data: mockStats() };
    if (name === 'fetchRewards') return { ok: true, data: { rewards: mockStats().rewards } };
    if (name === 'openTicket') return { ok: true, data: { ticket: t, messages: [
      { sender: 'BabyAdy', isStaff: false, text: 'salut, am o problema', time: '01:19' } ] } };
    return { ok: true, data: {} };
  }
  function mockStats() {
    return {
      mine: { closedTotal: 223, closedMonthly: 223, rating: 4.8, ratingCount: 40, avgResponseSeconds: 95, fpt: 0 },
      global: { openActive: 4, openClaimed: 2, closedToday: 12, closedMonth: 223, avgClaimSeconds: 110, avgCloseSeconds: 640 },
      rewards: { monthlyClosed: 223, totalClosed: 223, moneyAccrued: 111500, moneyClaimed: 0, moneyClaimable: 111500,
        fpt: 0, perTicket: 500, fptPerTickets: 100, milestone: 1000, milestoneReached: false, milestoneFpt: 10,
        resetAt: '2026-10-01', resetInSeconds: 27 * 86400 + 4 * 3600 + 45 * 60 },
    };
  }

  /* ------------------------- listener mesaje client -------------------- */
  window.addEventListener('message', function (e) {
    var m = e.data || {};
    if (m.action === 'open') {
      TK.showApp(m.menu);
      if (m.menu === 'staff') { if (window.initStaff) window.initStaff(); }
      else { initPlayer(); }
    } else if (m.action === 'close') {
      TK.hideAll();
    } else if (m.action === 'push') {
      (pushHandlers[m.kind] || []).forEach(function (fn) {
        try { fn(m.data || {}); } catch (err) { console.error(err); }
      });
    }
  });

  /* ESC -> inchide */
  window.addEventListener('keyup', function (e) {
    if (e.key === 'Escape') { TK.post('close'); TK.hideAll(); }
  });

  /* preview browser: deschide direct meniul de player (schimba in 'staff' ca sa vezi staff-ul) */
  if (isBrowser) {
    document.addEventListener('DOMContentLoaded', function () {
      TK.showApp('player');
      initPlayer();
    });
  }

  /* ======================= LOGICA MENIU PLAYER ======================== */
  var $ = function (s) { return document.querySelector(s); };
  var activeId = null;

  function renderMessages(box, msgs, staffPerspective) {
    box.innerHTML = '';
    (msgs || []).forEach(function (msg) {
      var mine = staffPerspective ? msg.isStaff : !msg.isStaff;
      var row = document.createElement('div');
      row.className = 'flex flex-col ' + (mine ? 'row-me' : 'row-them');
      row.innerHTML =
        '<span class="text-[10px] text-gray-500 mb-1 px-1">' + TK.esc(msg.sender) + ' • ' + TK.esc(msg.time) + '</span>' +
        '<div class="bub ' + (mine ? 'bub-me' : 'bub-them') + '">' + TK.esc(msg.text) + '</div>';
      box.appendChild(row);
    });
    box.scrollTop = box.scrollHeight;
  }
  window.TK.renderMessages = renderMessages;

  function statusPill(el, status) {
    el.className = 'pill ' + status;
    el.textContent = status === 'active' ? 'În așteptare' : status === 'claimed' ? 'Preluat' : 'Închis';
  }
  window.TK.statusPill = statusPill;

  function initPlayer() {
    TK.rpc('bootstrap').then(function (r) {
      if (!r.ok) return;
      TK.self = r.data.self || {};
      $('#p-name').textContent = TK.self.name || '—';
      $('#p-id').textContent = 'ID: ' + (TK.self.id != null ? TK.self.id : '—');
      $('#p-avatar').textContent = (TK.self.name || '?').charAt(0).toUpperCase();

      var sel = $('#p-category');
      var cats = r.data.categories || ['General Problem / Confusion', 'Player Report', 'Bug / Technical Issues', 'Item Pick-up / Losses', 'Other'];
      sel.innerHTML = cats.map(function (c) { return '<option>' + TK.esc(c) + '</option>'; }).join('');
      renderList(r.data.tickets || []);
      showSec('p-create', '[data-target="p-create"]');
    });
  }

  function showSec(id, navSel) {
    document.querySelectorAll('#player-app .p-sec').forEach(function (s) { s.classList.add('hidden'); });
    document.getElementById(id).classList.remove('hidden');
    document.querySelectorAll('#player-app .p-nav').forEach(function (b) { b.classList.remove('active'); });
    if (navSel) { var n = document.querySelector('#player-app ' + navSel); if (n) n.classList.add('active'); }
  }

  function renderList(tickets) {
    var box = $('#p-tickets');
    $('#p-badge').textContent = tickets.length;
    if (!tickets.length) {
      box.innerHTML = '<p class="text-center text-gray-500 py-10">Nu ai niciun ticket deschis.</p>';
      return;
    }
    box.innerHTML = '';
    tickets.forEach(function (t) {
      var d = document.createElement('div');
      d.className = 'tk-card cursor-pointer';
      d.innerHTML =
        '<div class="flex items-center gap-4">' +
          '<div class="w-10 h-10 rounded-lg bg-purple-950/60 border border-purple-800/40 flex items-center justify-center text-purple-400"><i class="fa-solid fa-headset"></i></div>' +
          '<div><div class="flex items-center gap-2">' +
            '<h4 class="font-bold text-white">#' + t.id + ' · ' + TK.esc(t.category) + '</h4>' +
            '<span class="pill ' + t.status + '">' + (t.status === 'active' ? 'În așteptare' : t.status === 'claimed' ? 'Preluat' : 'Închis') + '</span>' +
            '<span class="text-[10px] text-gray-500">' + TK.esc(t.time) + '</span></div>' +
            '<p class="text-xs text-gray-400 mt-1 truncate max-w-[420px]">' + TK.esc(t.reason) + '</p></div>' +
        '</div>' +
        '<button class="btn-purple"><i class="fa-solid fa-comments"></i></button>';
      d.addEventListener('click', function () { openChat(t.id); });
      box.appendChild(d);
    });
  }

  function openChat(id) {
    TK.rpc('openTicket', { ticketId: id }).then(function (r) {
      if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
      var t = r.data.ticket;
      activeId = id;
      $('#p-c-cat').textContent = '#' + t.id + ' · ' + t.category;
      statusPill($('#p-c-status'), t.status);
      $('#p-c-desc').textContent = t.reason;
      $('#p-c-close').classList.toggle('hidden', t.status === 'closed');
      renderMessages($('#p-c-msgs'), r.data.messages, false);
      showSec('p-chat', null);
    });
  }

  function sendMsg() {
    var input = $('#p-c-input');
    var text = input.value.trim();
    if (!text || !activeId) return;
    input.value = '';
    TK.rpc('sendMessage', { ticketId: activeId, message: text }).then(function (r) {
      if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
      appendMsg($('#p-c-msgs'), r.data.message, false);
    });
  }

  function appendMsg(box, msg, staffPerspective) {
    if (!msg) return;
    var mine = staffPerspective ? msg.isStaff : !msg.isStaff;
    var row = document.createElement('div');
    row.className = 'flex flex-col ' + (mine ? 'row-me' : 'row-them');
    row.innerHTML =
      '<span class="text-[10px] text-gray-500 mb-1 px-1">' + TK.esc(msg.sender) + ' • ' + TK.esc(msg.time) + '</span>' +
      '<div class="bub ' + (mine ? 'bub-me' : 'bub-them') + '">' + TK.esc(msg.text) + '</div>';
    box.appendChild(row);
    box.scrollTop = box.scrollHeight;
  }
  window.TK.appendMsg = appendMsg;

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('#player-app .p-nav').forEach(function (b) {
      b.addEventListener('click', function () { showSec(b.dataset.target, '[data-target="' + b.dataset.target + '"]'); });
    });
    $('#p-form').addEventListener('submit', function (e) {
      e.preventDefault();
      var reason = $('#p-reason').value.trim();
      if (reason.length < 10) return TK.toast('Descriere prea scurtă (min. 10 caractere).', 'err');
      TK.rpc('createTicket', { category: $('#p-category').value, reason: reason }).then(function (r) {
        if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
        $('#p-reason').value = '';
        renderList(r.data.tickets || []);
        showSec('p-list', '[data-target="p-list"]');
        TK.toast('Ticket #' + r.data.ticket.id + ' trimis.', 'ok');
      });
    });
    $('#p-back').addEventListener('click', function () { showSec('p-list', '[data-target="p-list"]'); });
    $('#p-c-send').addEventListener('click', sendMsg);
    $('#p-c-input').addEventListener('keypress', function (e) { if (e.key === 'Enter') sendMsg(); });
    $('#p-c-close').addEventListener('click', function () {
      if (!activeId) return;
      TK.rpc('closeTicket', { ticketId: activeId }).then(function (r) {
        if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
        TK.toast('Ticket închis.', 'ok');
        showSec('p-list', '[data-target="p-list"]');
        TK.rpc('fetchMyTickets').then(function (x) { if (x.ok) renderList(x.data.tickets || []); });
      });
    });
  });

  /* push realtime (player) */
  TK.onPush('ticketUpsert', function (d) {
    if (activeId && d.ticket && d.ticket.id === activeId) statusPill($('#p-c-status'), d.ticket.status);
    if (!document.getElementById('p-list').classList.contains('hidden')) {
      TK.rpc('fetchMyTickets').then(function (x) { if (x.ok) renderList(x.data.tickets || []); });
    }
  });
  TK.onPush('message', function (d) {
    if (activeId && d.ticketId === activeId) appendMsg($('#p-c-msgs'), d, false);
  });
  TK.onPush('ticketClosed', function (d) {
    if (activeId && d.ticket && d.ticket.id === activeId) {
      statusPill($('#p-c-status'), 'closed');
      $('#p-c-close').classList.add('hidden');
      TK.toast('Ticketul #' + d.ticket.id + ' a fost închis.', 'ok');
    }
  });
})();
