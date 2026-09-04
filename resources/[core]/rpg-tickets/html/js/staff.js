/* ==========================================================================
   rpg-tickets — logica meniului de STAFF  (window.initStaff)
   Depinde de window.TK (definit in player.js).
   ========================================================================== */
(function () {
  'use strict';
  var $ = function (s) { return document.querySelector(s); };
  var TK = window.TK;

  var sActiveId = null;
  var allTickets = [];
  var resetSec = 0;
  var resetTimer = null;

  /* --------------------------- init --------------------------------- */
  window.initStaff = function () {
    TK.rpc('staffBootstrap').then(function (r) {
      if (!r.ok) { TK.toast(r.data.error || 'Fără permisiune.', 'err'); TK.post('close'); TK.hideAll(); return; }
      TK.self = r.data.self || {};
      fillProfile();
      allTickets = r.data.tickets || [];
      renderLists();
      if (r.data.stats) applyStats(r.data.stats);
      showSec('s-dash', '[data-target="s-dash"]');
      loadRewards();
    });
  };

  function fillProfile() {
    $('#s-name').textContent = TK.self.name || '—';
    $('#s-rank').textContent = TK.self.staffLabel || TK.self.staff || '—';
    if (TK.self.staffColor) $('#s-rank').style.color = TK.self.staffColor;
    $('#s-sid').textContent = TK.self.sid != null ? ('SQL ID: ' + TK.self.sid)
                            : (TK.self.accountId != null ? ('SQL ID: ' + TK.self.accountId) : '');
    TK.setAvatar($('#s-avatar'), TK.self.avatar, TK.self.name);
  }

  /* --------------------------- navigatie ---------------------------- */
  function showSec(id, navSel) {
    document.querySelectorAll('#staff-app .s-sec').forEach(function (s) { s.classList.add('hidden'); });
    document.getElementById(id).classList.remove('hidden');
    document.querySelectorAll('#staff-app .s-nav').forEach(function (b) { b.classList.remove('active'); });
    if (navSel) { var n = document.querySelector('#staff-app ' + navSel); if (n) n.classList.add('active'); }
    if (id === 's-stats') TK.rpc('fetchStats').then(function (r) { if (r.ok) applyStats(r.data); });
    if (id === 's-rewards') loadRewards();
  }

  /* --------------------------- liste tickete ----------------------- */
  function ticketCard(t, context) {
    var d = document.createElement('div');
    d.className = 'tk-card';
    var mineTag = (t.claimedBy && TK.self && t.claimedBy === TK.self.license)
      ? '<span class="text-[10px] text-purple-300 ml-1">(al tău)</span>' : '';
    d.innerHTML =
      '<div class="flex items-center gap-4 min-w-0">' +
        '<div class="w-10 h-10 rounded-lg bg-purple-950/60 border border-purple-800/40 flex items-center justify-center text-purple-400"><i class="fa-solid fa-headset"></i></div>' +
        '<div class="min-w-0"><div class="flex items-center gap-2">' +
          '<h4 class="font-bold text-white truncate">#' + t.id + ' · ' + TK.esc(t.category) + '</h4>' +
          '<span class="pill ' + t.status + '">' + (t.status === 'active' ? 'În așteptare' : t.status === 'claimed' ? 'Preluat' : 'Închis') + '</span>' + mineTag +
        '</div>' +
        '<p class="text-xs text-gray-400 mt-1 truncate max-w-[420px]">' +
          TK.esc(t.playerName) + ' [' + TK.esc(t.playerId) + ']' + (t.staffName ? ' · staff: ' + TK.esc(t.staffName) : '') + ' — ' + TK.esc(t.reason) +
        '</p></div>' +
      '</div>' +
      '<div class="flex items-center gap-2 shrink-0">' +
        (t.status === 'active' ? '<button class="btn-purple" data-act="claim"><i class="fa-solid fa-hand"></i> Preia</button>' : '') +
        '<button class="btn-ghost" data-act="open"><i class="fa-solid fa-comments"></i></button>' +
        '<button class="btn-ghost" data-act="tp" title="TP la jucător"><i class="fa-solid fa-location-arrow"></i></button>' +
        '<button class="btn-ghost" data-act="bring" title="Adu jucătorul"><i class="fa-solid fa-people-arrows"></i></button>' +
      '</div>';
    d.querySelectorAll('[data-act]').forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        e.stopPropagation();
        var a = btn.dataset.act;
        if (a === 'claim') doClaim(t.id);
        else if (a === 'open') openChat(t.id);
        else if (a === 'tp') TK.rpc('tpToPlayer', { ticketId: t.id }).then(rpcToast);
        else if (a === 'bring') TK.rpc('bringPlayer', { ticketId: t.id }).then(rpcToast);
      });
    });
    return d;
  }

  function rpcToast(r) {
    if (!r) return;
    if (r.ok) TK.toast('OK', 'ok'); else TK.toast(r.data && r.data.error || 'Eroare', 'err');
  }

  function renderLists() {
    var act = $('#s-active-list'), mine = $('#s-mine-list');
    act.innerHTML = ''; mine.innerHTML = '';
    var open = allTickets.filter(function (t) { return t.status === 'active' || t.status === 'claimed'; });
    var mineArr = open.filter(function (t) { return TK.self && t.claimedBy === TK.self.license; });

    $('#s-badge-active').textContent = open.length;
    $('#s-badge-mine').textContent = mineArr.length;

    if (!open.length) act.innerHTML = '<p class="text-center text-gray-500 py-10">Niciun ticket deschis.</p>';
    else open.forEach(function (t) { act.appendChild(ticketCard(t, 'active')); });

    if (!mineArr.length) mine.innerHTML = '<p class="text-center text-gray-500 py-10">Nu ai tickete preluate.</p>';
    else mineArr.forEach(function (t) { mine.appendChild(ticketCard(t, 'mine')); });
  }

  function refreshTickets() {
    return TK.rpc('fetchStaffTickets').then(function (r) {
      if (r.ok) { allTickets = r.data.tickets || []; renderLists(); }
    });
  }

  /* --------------------------- chat -------------------------------- */
  function openChat(id) {
    TK.rpc('openTicket', { ticketId: id }).then(function (r) {
      if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
      var t = r.data.ticket;
      sActiveId = id;
      $('#s-c-cat').textContent = '#' + t.id + ' · ' + t.category;
      TK.statusPill($('#s-c-status'), t.status);
      $('#s-c-player').textContent = t.playerName + ' [' + t.playerId + ']' + (t.staffName ? ' · preluat de ' + t.staffName : '');
      $('#s-c-claim').classList.toggle('hidden', t.status !== 'active');
      $('#s-c-close').classList.toggle('hidden', t.status === 'closed');
      $('#s-c-input').disabled = (t.status === 'closed');
      TK.renderMessages($('#s-c-msgs'), r.data.messages, true);
      showSec('s-chat', null);
    });
  }

  function doClaim(id) {
    TK.rpc('claimTicket', { ticketId: id }).then(function (r) {
      if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
      TK.toast('Ai preluat ticketul #' + id + '.', 'ok');
      refreshTickets();
      if (sActiveId === id) openChat(id);
    });
  }

  function sSend() {
    var input = $('#s-c-input');
    var text = input.value.trim();
    if (!text || !sActiveId) return;
    input.value = '';
    TK.rpc('sendMessage', { ticketId: sActiveId, message: text }).then(function (r) {
      if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
      TK.appendMsg($('#s-c-msgs'), r.data.message, true);
    });
  }

  /* --------------------------- statistici -------------------------- */
  function applyStats(s) {
    s = s || {};
    var m = s.mine || {}, g = s.global || {};
    $('#d-active').textContent = g.openActive != null ? g.openActive : 0;
    $('#d-claimed').textContent = g.openClaimed != null ? g.openClaimed : 0;
    $('#d-today').textContent = g.closedToday != null ? g.closedToday : 0;

    $('#st-total').textContent = m.closedTotal || 0;
    $('#st-month').textContent = m.closedMonthly || 0;
    $('#st-rating').textContent = (Number(m.rating || 5)).toFixed(1);
    $('#st-resp').textContent = TK.fmtDur(m.avgResponseSeconds);

    $('#st-g-active').textContent = g.openActive || 0;
    $('#st-g-month').textContent = g.closedMonth || 0;
    $('#st-g-claim').textContent = TK.fmtDur(g.avgClaimSeconds);
    $('#st-g-close').textContent = TK.fmtDur(g.avgCloseSeconds);

    if (s.rewards) applyRewards(s.rewards);
  }

  /* --------------------------- rewards ---------------------------- */
  function loadRewards() {
    TK.rpc('fetchRewards').then(function (r) { if (r.ok && r.data.rewards) applyRewards(r.data.rewards); });
  }

  function applyRewards(rw) {
    $('#r-monthly').textContent = rw.monthlyClosed || 0;
    $('#r-milestone').textContent = rw.milestone || 0;
    $('#r-milestone-fpt').textContent = rw.milestoneFpt || 0;
    $('#r-fptper').textContent = rw.fptPerTickets || 100;
    $('#r-money').textContent = TK.fmtMoney(rw.moneyAccrued);
    $('#r-claimable').textContent = TK.fmtMoney(rw.moneyClaimable);
    $('#r-fpt').textContent = rw.fpt || 0;
    $('#r-perticket').textContent = TK.fmtMoney(rw.perTicket);

    var pct = rw.milestone > 0 ? Math.max(0, Math.min(1, (rw.monthlyClosed || 0) / rw.milestone)) : 0;
    $('#r-progfill').style.width = (pct * 100) + '%';

    $('#r-claim').disabled = !(rw.moneyClaimable > 0);

    resetSec = Math.max(0, Math.floor(rw.resetInSeconds || 0));
    tickReset();
    if (!resetTimer) resetTimer = setInterval(tickReset, 1000);
  }

  function tickReset() {
    if (resetSec > 0) resetSec--;
    var d = Math.floor(resetSec / 86400);
    var h = Math.floor((resetSec % 86400) / 3600);
    var mm = Math.floor((resetSec % 3600) / 60);
    $('#r-reset').textContent = d + ' zile · ' + h + ' ore · ' + mm + ' minute';
  }

  /* --------------------------- events DOM ------------------------- */
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('#staff-app .s-nav').forEach(function (b) {
      b.addEventListener('click', function () { showSec(b.dataset.target, '[data-target="' + b.dataset.target + '"]'); });
    });
    $('#s-exit').addEventListener('click', function () { TK.post('close'); TK.hideAll(); });
    $('#s-refresh').addEventListener('click', refreshTickets);

    $('#s-back').addEventListener('click', function () { showSec('s-active', '[data-target="s-active"]'); });
    $('#s-c-send').addEventListener('click', sSend);
    $('#s-c-input').addEventListener('keypress', function (e) { if (e.key === 'Enter') sSend(); });
    $('#s-c-claim').addEventListener('click', function () { if (sActiveId) doClaim(sActiveId); });
    $('#s-c-tp').addEventListener('click', function () { if (sActiveId) TK.rpc('tpToPlayer', { ticketId: sActiveId }).then(rpcToast); });
    $('#s-c-bring').addEventListener('click', function () { if (sActiveId) TK.rpc('bringPlayer', { ticketId: sActiveId }).then(rpcToast); });
    $('#s-c-close').addEventListener('click', function () {
      if (!sActiveId) return;
      TK.rpc('closeTicket', { ticketId: sActiveId }).then(function (r) {
        if (!r.ok) return TK.toast(r.data.error || 'Eroare', 'err');
        TK.toast('Ticket #' + sActiveId + ' închis.', 'ok');
        showSec('s-active', '[data-target="s-active"]');
        refreshTickets();
      });
    });

    document.querySelectorAll('#staff-app .equip-btn').forEach(function (b) {
      b.addEventListener('click', function () {
        var piece = b.dataset.piece;
        TK.post(b.dataset.off ? 'unequip' : 'equip', { piece: piece });
        TK.toast(b.dataset.off ? 'Scos.' : 'Echipat.', 'ok');
      });
    });

    $('#r-claim').addEventListener('click', function () {
      TK.rpc('claimRewards').then(function (r) {
        if (!r.ok) return TK.toast(r.data.error || 'Nimic de revendicat.', 'err');
        TK.toast('Ai revendicat ' + TK.fmtMoney(r.data.claimed) + ' în bancă.', 'ok');
        if (r.data.rewards) applyRewards(r.data.rewards);
      });
    });
  });

  /* --------------------------- push realtime --------------------- */
  TK.onPush('ticketUpsert', function (d) {
    refreshTickets();
    if (sActiveId && d.ticket && d.ticket.id === sActiveId) {
      TK.statusPill($('#s-c-status'), d.ticket.status);
      $('#s-c-claim').classList.toggle('hidden', d.ticket.status !== 'active');
    }
  });
  TK.onPush('message', function (d) {
    if (sActiveId && d.ticketId === sActiveId) TK.appendMsg($('#s-c-msgs'), d, true);
  });
  TK.onPush('ticketClosed', function (d) {
    refreshTickets();
    if (sActiveId && d.ticket && d.ticket.id === sActiveId) {
      TK.statusPill($('#s-c-status'), 'closed');
      $('#s-c-close').classList.add('hidden');
      $('#s-c-claim').classList.add('hidden');
      $('#s-c-input').disabled = true;
    }
  });
  TK.onPush('stats', function (d) { applyStats(d); });

  /* preview browser: ruleaza  previewStaff()  in consola pentru a vedea meniul de staff */
  if (TK.isBrowser) {
    window.previewStaff = function () { TK.showApp('staff'); window.initStaff(); };
  }
})();
