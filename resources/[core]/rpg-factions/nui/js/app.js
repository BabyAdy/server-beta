(function () {
  'use strict';
  var isB = typeof window.GetParentResourceName !== 'function';
  var RES = isB ? 'rpg-factions' : window.GetParentResourceName();
  var $ = function (s) { return document.querySelector(s); };
  var $$ = function (s) { return Array.prototype.slice.call(document.querySelectorAll(s)); };
  function post(n, b) { if (isB) return Promise.resolve({}); return fetch('https://' + RES + '/' + n, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(b || {}) }).catch(function () {}); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function num(n) { return Number(n || 0).toLocaleString('en-US'); }

  var S = { self: { inFaction: false }, members: [], logsPage: 1, logsPages: 1, permKeys: [] };

  /* ---------------- toast / prompt ---------------- */
  function toast(t, k) { if (!t) return; var e = document.createElement('div'); e.className = 'toast ' + (k === 'success' ? 'success' : k === 'error' ? 'error' : ''); e.textContent = t; $('#toasts').appendChild(e); setTimeout(function () { if (e.parentNode) e.parentNode.removeChild(e); }, 3300); }
  function hqPrompt(kind) { var el = $('#hqprompt'); if (!kind) { el.classList.add('hidden'); return; } $('#hqprompt-lbl').textContent = kind === 'enter' ? 'Enter HQ' : 'Leave HQ'; el.classList.remove('hidden'); }

  /* ---------------- navigation ---------------- */
  var PAGES = ['dash', 'members', 'applications', 'logs', 'manage', 'nofaction'];
  function show(page) {
    PAGES.forEach(function (p) { $('#' + p).classList.toggle('hidden', p !== page); });
    $('#back').classList.toggle('hidden', page === 'dash' || page === 'nofaction');
    if (page === 'members') { post('members'); }
    if (page === 'applications') { post('applications'); }
    if (page === 'logs') { S.logsPage = 1; post('logs', { page: 1 }); }
    if (page === 'manage') fillManage();
    if (page === 'nofaction') { post('browse'); post('myApplications'); }
  }
  $('#back').addEventListener('click', function () { show('dash'); });
  $('#close').addEventListener('click', function () { post('close'); $('#app').classList.add('hidden'); });

  /* ---------------- dashboard ---------------- */
  function P(k) { return S.self && S.self.perms && S.self.perms[k] === true; }

  function renderDash() {
    var s = S.self;
    $('#app').classList.remove('hidden');
    if (!s.inFaction) {
      $('#fac-type').textContent = 'FACTION';
      $('#fac-name').textContent = 'Unemployed';
      show('nofaction');
      return;
    }
    S.permKeys = s.permKeys || [];
    $('#fac-type').textContent = (s.faction.type || 'faction').toUpperCase();
    $('#fac-name').textContent = s.faction.name;
    $('#d-rank').textContent = s.rank.label + (s.rank.isLeader ? ' (Leader)' : s.rank.isColeader ? ' (Co-Leader)' : '');
    $('#d-sup').textContent = s.supervisor ? 'YES' : 'NO';
    $('#d-test').textContent = s.tester ? 'YES' : 'NO';
    $('#d-members').textContent = s.faction.members;
    $('#d-warn').textContent = s.warning + ' / ' + s.warningMax;
    $('#d-warnfill').style.width = Math.min(100, (s.warning / s.warningMax) * 100) + '%';
    $('#d-join').textContent = (s.joinDate || '—').replace('T', ' ').slice(0, 16);

    var m = $('#dash-menu'); m.innerHTML = '';
    var opts = [];
    if (P('view_members')) opts.push(['members', 'Members']);
    if (P('view_applications')) opts.push(['applications', 'Applications']);
    if (P('view_logs')) opts.push(['logs', 'Logs']);
    var canManage = P('manage_settings') || P('set_leader') || P('set_manager') || P('manage_hq') || P('manage_ranks');
    if (canManage) opts.push(['manage', 'Manage']);
    if (s.faction.hasHQ) opts.push(['hq', 'Go to HQ']);
    opts.push(['leave', 'Leave Faction']);

    opts.forEach(function (o) {
      var b = document.createElement('button');
      b.className = 'btn' + (o[0] === 'leave' ? ' danger' : '');
      b.textContent = o[1];
      b.addEventListener('click', function () {
        if (o[0] === 'hq') { post('hqEnter'); }
        else if (o[0] === 'leave') { if (confirm('Leave the faction?')) post('leaveFaction'); }
        else show(o[0]);
      });
      m.appendChild(b);
    });
    show('dash');
  }

  /* ---------------- members ---------------- */
  function renderMembers() {
    var q = ($('#m-search').value || '').toLowerCase();
    var host = $('#m-list'); host.innerHTML = '';
    S.members.filter(function (m) {
      return !q || m.name.toLowerCase().indexOf(q) >= 0 || String(m.id).indexOf(q) >= 0 || m.rank.toLowerCase().indexOf(q) >= 0;
    }).forEach(function (m) {
      var el = document.createElement('div'); el.className = 'item';
      var tags = '';
      if (m.supervisor) tags += '<span class="tag sup">SUP</span>';
      if (m.tester) tags += '<span class="tag tst">TEST</span>';
      el.innerHTML =
        '<div class="top"><span class="name"><span class="dot ' + (m.online ? 'on' : '') + '"></span>' + esc(m.name) + ' <small style="color:var(--faint)">#' + m.id + '</small></span><span class="tags">' + tags + '</span></div>' +
        '<div class="meta"><span>Rank: <b>' + esc(m.rank) + '</b></span><span>Joined: <b>' + esc((m.joinDate || '').slice(0, 10)) + '</b></span>' +
        '<span>Warnings: <b>' + m.warning + '</b></span><span>Lvl <b>' + m.level + '</b></span><span><b>' + m.hours + 'h</b></span></div>' +
        '<div class="acts"></div>';
      var acts = el.querySelector('.acts');
      function act(label, cls, fn) { var b = document.createElement('button'); b.className = 'btn mini ' + (cls || ''); b.textContent = label; b.addEventListener('click', fn); acts.appendChild(b); }

      if (P('promote')) act('Promote', '', function () { post('promote', { userId: m.id, reason: prompt('Reason?') || '' }); });
      if (P('demote'))  act('Demote', '', function () { post('demote', { userId: m.id, reason: prompt('Reason?') || '' }); });
      if (P('manage_warnings')) {
        act('+ Warn', 'danger', function () { var d = parseInt(prompt('Warning points to ADD (1-100):'), 10); if (d > 0) post('warning', { userId: m.id, delta: d, reason: prompt('Reason?') || '' }); });
        act('- Warn', '', function () { var d = parseInt(prompt('Warning points to REMOVE (1-100):'), 10); if (d > 0) post('warning', { userId: m.id, delta: -d, reason: prompt('Reason?') || '' }); });
      }
      if (P('manage_supervisors')) act(m.supervisor ? 'Unset Sup' : 'Set Sup', 'sup', function () { post('supervisor', { userId: m.id, value: !m.supervisor }); });
      if (P('manage_testers'))     act(m.tester ? 'Unset Test' : 'Set Test', 'tst', function () { post('tester', { userId: m.id, value: !m.tester }); });
      if (P('kick')) act('Kick', 'danger', function () { if (confirm('Kick ' + m.name + '?')) post('kick', { userId: m.id, reason: prompt('Reason?') || '' }); });
      if (P('set_leader')) act('Make Leader', 'primary', function () { if (confirm('Transfer leadership to ' + m.name + '?')) post('setLeader', { userId: m.id }); });
      if (P('set_manager')) act('Make Manager', '', function () { post('setManager', { userId: m.id }); });
      if (P('manage_permissions')) act('Permissions', '', function () { openPerms(el, m); });
      host.appendChild(el);
    });
  }
  $('#m-search').addEventListener('input', renderMembers);

  function openPerms(rowEl, m) {
    if (rowEl.querySelector('.perms')) { rowEl.querySelector('.perms').remove(); rowEl.querySelector('.perms-save') && rowEl.querySelector('.perms-save').remove(); return; }
    var wrap = document.createElement('div'); wrap.className = 'perms';
    var cur = m.individual || {};
    S.permKeys.forEach(function (k) {
      var id = 'pm_' + m.id + '_' + k;
      wrap.innerHTML += '<label><input type="checkbox" id="' + id + '"' + (cur[k] === true ? ' checked' : '') + '> ' + k + '</label>';
    });
    rowEl.querySelector('.acts').appendChild(wrap);
    var save = document.createElement('button'); save.className = 'btn mini primary perms-save'; save.textContent = 'Save permissions';
    save.addEventListener('click', function () {
      var map = {};
      S.permKeys.forEach(function (k) { if ($('#pm_' + m.id + '_' + k).checked) map[k] = true; });
      post('permissions', { userId: m.id, perms: map });
      wrap.remove(); save.remove();
    });
    rowEl.querySelector('.acts').appendChild(save);
  }

  /* ---------------- applications ---------------- */
  function renderApps(d) {
    var host = $('#a-list'); host.innerHTML = '';
    $('#a-empty').classList.toggle('hidden', (d.applications || []).length > 0);
    (d.applications || []).forEach(function (a) {
      var el = document.createElement('div'); el.className = 'item';
      el.innerHTML = '<div class="top"><span class="name">' + esc(a.name) + ' <small style="color:var(--faint)">#' + a.userId + '</small></span></div>' +
        '<div class="meta"><span>Level <b>' + a.level + '</b></span><span><b>' + a.hours + 'h</b></span><span>' + esc((a.date || '').slice(0, 16)) + '</span></div>' +
        (a.message ? '<div class="meta">"' + esc(a.message) + '"</div>' : '') +
        '<div class="acts"></div>';
      if (d.canManage) {
        var acts = el.querySelector('.acts');
        var ok = document.createElement('button'); ok.className = 'btn mini primary'; ok.textContent = 'Accept';
        ok.addEventListener('click', function () { post('acceptApplication', { id: a.id }); });
        var no = document.createElement('button'); no.className = 'btn mini danger'; no.textContent = 'Reject';
        no.addEventListener('click', function () { post('rejectApplication', { id: a.id, reason: prompt('Reason?') || '' }); });
        acts.appendChild(ok); acts.appendChild(no);
      }
      host.appendChild(el);
    });
  }

  /* ---------------- logs ---------------- */
  function renderLogs(d) {
    S.logsPage = d.page; S.logsPages = d.pages || 1;
    $('#l-page').textContent = d.page + ' / ' + Math.max(1, d.pages || 1);
    var host = $('#l-list'); host.innerHTML = '';
    (d.rows || []).forEach(function (r) {
      var bad = /^INVALID_/.test(r.action);
      var el = document.createElement('div'); el.className = 'item log' + (bad ? ' bad' : '');
      var chg = '';
      if (r.old || r.new) chg = '<div class="chg">' + esc(JSON.stringify(r.old || {})) + '  →  ' + esc(JSON.stringify(r.new || {})) + '</div>';
      el.innerHTML = '<div class="top"><span class="act">' + esc(r.action) + '</span><small style="color:var(--faint)">' + esc((r.date || '').slice(0, 16)) + '</small></div>' +
        '<div class="meta"><span>Actor: <b>' + esc(r.actor ? r.actor.name + ' #' + r.actor.id : 'system') + '</b></span>' +
        (r.target ? '<span>Target: <b>' + esc(r.target.name + ' #' + r.target.id) + '</b></span>' : '') +
        (r.reason ? '<span>Reason: <b>' + esc(r.reason) + '</b></span>' : '') + '</div>' + chg;
      host.appendChild(el);
    });
  }
  $('#l-prev').addEventListener('click', function () { if (S.logsPage > 1) post('logs', { page: S.logsPage - 1 }); });
  $('#l-next').addEventListener('click', function () { if (S.logsPage < S.logsPages) post('logs', { page: S.logsPage + 1 }); });

  /* ---------------- manage ---------------- */
  function fillManage() {
    var f = S.self.faction || {};
    $('#s-color').value = f.color || '';
    $('#s-type').value = f.type || '';
    $('#s-minlevel').value = f.minLevel != null ? f.minLevel : '';
    $('#s-minhours').value = f.minHours != null ? f.minHours : '';
    $('#s-maxmembers').value = f.maxMembers != null ? f.maxMembers : '';
    $('#s-application').checked = f.application === true;
    $('#hq-vw').value = (f.hq && f.hq.vw) || 0;
    $('#mg-manager').value = f.manager || 0;
  }
  $('#s-save').addEventListener('click', function () {
    var c = {};
    if ($('#s-color').value) c.color = $('#s-color').value;
    if ($('#s-type').value) c.type = $('#s-type').value;
    if ($('#s-minlevel').value !== '') c.minLevel = parseInt($('#s-minlevel').value, 10);
    if ($('#s-minhours').value !== '') c.minHours = parseInt($('#s-minhours').value, 10);
    if ($('#s-maxmembers').value !== '') c.maxMembers = parseInt($('#s-maxmembers').value, 10);
    c.application = $('#s-application').checked;
    post('updateSettings', c);
  });
  $('#mg-leader-btn').addEventListener('click', function () { var v = parseInt($('#mg-leader').value, 10); if (v > 0 && confirm('Transfer leadership to user #' + v + '?')) post('setLeader', { userId: v }); });
  $('#mg-manager-btn').addEventListener('click', function () { post('setManager', { userId: parseInt($('#mg-manager').value, 10) || 0 }); });
  $$('[data-hq]').forEach(function (b) { b.addEventListener('click', function () { post('setHQ', { point: b.dataset.hq }); }); });
  $('#hq-vw-btn').addEventListener('click', function () { post('setHQ', { vw: parseInt($('#hq-vw').value, 10) || 0 }); });

  /* ---------------- nofaction / apply ---------------- */
  function renderFactionsList(d) {
    $('#nf-me').textContent = 'Level ' + (d.me.level || 0) + ' · ' + (d.me.hours || 0) + 'h';
    var host = $('#nf-list'); host.innerHTML = '';
    $('#nf-empty').classList.toggle('hidden', (d.factions || []).length > 0);
    (d.factions || []).forEach(function (f) {
      var eligible = !d.me.inFaction && d.me.level >= f.minLevel && d.me.hours >= f.minHours;
      var el = document.createElement('div'); el.className = 'item';
      el.innerHTML = '<div class="top"><span class="name">' + esc(f.name) + ' <span class="tag">' + esc(f.type) + '</span></span></div>' +
        '<div class="meta"><span>Min level <b>' + f.minLevel + '</b></span><span>Min hours <b>' + f.minHours + '</b></span></div><div class="acts"></div>';
      var b = document.createElement('button'); b.className = 'btn mini primary'; b.textContent = eligible ? 'Apply' : 'Not eligible'; b.disabled = !eligible;
      b.addEventListener('click', function () { post('apply', { factionId: f.id, message: prompt('Optional message:') || '' }); });
      el.querySelector('.acts').appendChild(b);
      host.appendChild(el);
    });
  }
  function renderMyApps(d) {
    var host = $('#nf-mine'); host.innerHTML = '';
    if (!(d.list || []).length) { host.innerHTML = '<div class="empty">No pending applications.</div>'; return; }
    d.list.forEach(function (a) {
      var el = document.createElement('div'); el.className = 'item';
      el.innerHTML = '<div class="top"><span class="name">' + esc(a.faction) + '</span><button class="btn mini danger">Cancel</button></div><div class="meta">' + esc((a.date || '').slice(0, 16)) + '</div>';
      el.querySelector('button').addEventListener('click', function () { post('cancelApplication', { id: a.id }); });
      host.appendChild(el);
    });
  }

  /* ---------------- invite popup ---------------- */
  function showInvite(d) {
    if (!d) { $('#invite').classList.add('hidden'); return; }
    $('#invite-text').innerHTML = '<b>' + esc(d.by) + '</b> invited you to <b style="color:' + esc(d.color || '#3b82f6') + '">' + esc(d.name) + '</b>.';
    $('#invite').classList.remove('hidden');
  }
  $$('#invite [data-inv]').forEach(function (b) { b.addEventListener('click', function () { post('inviteResponse', { accept: b.dataset.inv === '1' }); $('#invite').classList.add('hidden'); }); });

  /* ---------------- bus ---------------- */
  window.addEventListener('message', function (e) {
    var m = e.data || {};
    switch (m.action) {
      case 'open': S.self = m.self || { inFaction: false }; renderDash(); break;
      case 'self': S.self = m.self || { inFaction: false }; if (!$('#app').classList.contains('hidden')) { if (($('#dash').classList.contains('hidden')) === false) renderDash(); } break;
      case 'close': $('#app').classList.add('hidden'); break;
      case 'toast': toast(m.text, m.kind); break;
      case 'hqPrompt': hqPrompt(m.kind); break;
      case 'invite': showInvite(m.data); break;
      case 'membersData': S.members = (m.data && m.data.members) || []; renderMembers(); break;
      case 'applicationsData': renderApps(m.data || {}); break;
      case 'logsData': renderLogs(m.data || {}); break;
      case 'factionsList': renderFactionsList(m.data || { me: {} }); break;
      case 'myApplications': renderMyApps(m.data || {}); break;
    }
  });
  window.addEventListener('keyup', function (e) {
    if (e.key !== 'Escape') return;
    if (!$('#invite').classList.contains('hidden')) { post('inviteResponse', { accept: false }); $('#invite').classList.add('hidden'); }
    else if (!$('#app').classList.contains('hidden')) { post('close'); $('#app').classList.add('hidden'); }
  });

  if (isB) {
    S.self = { inFaction: true, faction: { id: 1, name: 'Los Santos Police', type: 'police', color: '#3b82f6', members: 34, hasHQ: true, hq: { vw: 1001 } },
      rank: { order: 3, label: 'Sergeant', isLeader: false, isColeader: false }, supervisor: true, tester: false, warning: 15, warningMax: 100,
      joinDate: '2026-01-04T12:00:00', permKeys: ['invite', 'kick', 'promote', 'demote', 'manage_warnings'],
      perms: { view_members: true, view_applications: true, view_logs: true, invite: true, kick: true, promote: true, demote: true, manage_warnings: true, manage_supervisors: true } };
    renderDash();
  }
})();
