(function () {
  'use strict';

  var isBrowser = typeof window.GetParentResourceName !== 'function';
  var RES = isBrowser ? 'rpg-jobs' : window.GetParentResourceName();
  var $ = function (s) { return document.querySelector(s); };

  function post(name, body) {
    if (isBrowser) return Promise.resolve({});
    return fetch('https://' + RES + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {})
    }).catch(function () {});
  }
  function money(n) { return '$' + Number(n || 0).toLocaleString('en-US'); }

  /* ------------------------------------------------------- TOAST / PROMPT / HUD */
  function toast(text, kind) {
    if (!text) return;
    var t = document.createElement('div');
    t.className = 'toast ' + (kind === 'success' ? 'success' : kind === 'error' ? 'error' : '');
    t.textContent = text;
    $('#toasts').appendChild(t);
    setTimeout(function () { if (t.parentNode) t.parentNode.removeChild(t); }, 3300);
  }
  function setPrompt(show, label) {
    var el = $('#prompt');
    if (show) { $('#prompt-lbl').textContent = label || 'Talk'; el.classList.remove('hidden'); }
    else el.classList.add('hidden');
  }
  function setWorkPrompt(show, label) {
    var el = $('#wprompt');
    if (show) { $('#wprompt-lbl').textContent = label || 'Start the repair'; el.classList.remove('hidden'); }
    else el.classList.add('hidden');
  }
  function setHud(d) {
    var el = $('#hud');
    if (d.show === false) { el.classList.add('hidden'); return; }
    $('#hud-done').textContent = d.done || 0;
    $('#hud-earned').textContent = money(d.earned || 0);
    el.classList.remove('hidden');
  }

  /* ------------------------------------------------------- MENU */
  function renderMenu(d) {
    var menu = $('#menu');
    $('#m-job').textContent = (d.jobLabel || 'Job').toUpperCase();
    $('#m-current').textContent = d.hasJob ? (d.jobLabel || 'Employed') : (d.currentJobLabel || 'Unemployed');
    menu.classList.toggle('no-job', !d.hasJob);

    if (d.hasJob) {
      $('#m-skill').textContent = d.skill;
      $('#m-mult').textContent = (d.avgPay != null) ? '(~' + money(d.avgPay) + ')' : '';
      $('#m-shifts').textContent = d.completedShifts;
      $('#m-salary').textContent = money(d.estMin) + ' – ' + money(d.estMax);
      if (d.nextSkillShifts != null) {
        var have = d.completedShifts, need = d.nextSkillShifts;
        $('#m-next').textContent = 'Skill ' + d.nextSkill + ' @ ' + need + ' panels';
        $('#m-bar').style.width = Math.max(0, Math.min(100, (have / Math.max(1, need)) * 100)) + '%';
      } else {
        $('#m-next').textContent = 'Max skill reached';
        $('#m-bar').style.width = '100%';
      }
    }

    var canGet = !d.hasJob && (d.playerLevel >= d.minLevel);
    $('#b-get').disabled = !canGet;
    $('#b-quit').disabled = !d.hasJob;
    $('#b-start').disabled = !d.hasJob || d.isWorking;

    var hint = '';
    if (!d.hasJob && d.playerLevel < d.minLevel) hint = 'Requires level ' + d.minLevel + ' (you are ' + d.playerLevel + ').';
    else if (d.isWorking) hint = 'You are working. Use /stopwork or Quit Job to stop.';
    $('#m-hint').textContent = hint;

    $('#menu-overlay').classList.remove('hidden');
  }
  function closeMenu() { $('#menu-overlay').classList.add('hidden'); }

  document.querySelectorAll('#menu .btn[data-a]').forEach(function (b) {
    b.addEventListener('click', function () {
      if (b.disabled) return;
      post('menuAction', { action: b.dataset.a });
      if (b.dataset.a === 'close' || b.dataset.a === 'startWork') closeMenu();
    });
  });

  /* ======================================================= MINIGAMES */
  var MG = null;   // { token, game, startTs, deadline, total, timerInt, raf, _keyStop, _cleanup, _apply }
  var WIRE_COLORS = { RED: '#f0453a', YELLOW: '#f5c518', BLUE: '#3a7bf0', PURPLE: '#a24bf0', GREEN: '#3fd06a' };

  function openMg(game) {
    ['wires', 'flow', 'code'].forEach(function (g) {
      $('#mg-' + g).classList.toggle('hidden', g !== game);
    });
    $('#mg-overlay').classList.remove('hidden');
  }
  function closeMg() {
    $('#mg-overlay').classList.add('hidden');
    if (MG) {
      if (MG.raf) cancelAnimationFrame(MG.raf);
      if (MG.timerInt) clearInterval(MG.timerInt);
      if (MG._keyStop) window.removeEventListener('keydown', MG._keyStop);
      if (MG._cleanup) MG._cleanup();
    }
    MG = null;
  }
  function mgTimerTick() {
    if (!MG) return;
    var left = MG.deadline - Date.now();
    var frac = Math.max(0, left / MG.total);
    $('#mg-timer-fill').style.width = (frac * 100) + '%';
    if (left <= 0) {
      var token = MG.token;
      closeMg();
      post('minigameAbort', { token: token });   // server -> timeout/fail
    }
  }
  function submitMg(result) {
    if (!MG) return;
    var token = MG.token;
    closeMg();
    post('minigameResult', { token: token, result: result });
  }

  /* ---- 1 · WIRES CONNECT ---- */
  function startWires(token, p) {
    var left = p.left || [], right = p.right || [], n = left.length;
    var wrap = $('#wires-wrap');
    wrap.innerHTML = '<svg id="wires-lines"></svg><div class="wcol wcol-l"></div><div class="wcol wcol-r"></div>';
    var colL = wrap.querySelector('.wcol-l');
    var colR = wrap.querySelector('.wcol-r');
    var svg = wrap.querySelector('#wires-lines');
    var links = []; for (var z = 0; z < n; z++) links.push(0);   // links[i] = right row 1..n or 0
    var sel = -1;

    function node(color, row) {
      var d = document.createElement('div');
      d.className = 'wnode';
      d.style.setProperty('--wc', WIRE_COLORS[color] || '#888');
      d.dataset.row = row;
      d.innerHTML = '<i></i>';
      return d;
    }
    for (var i = 0; i < n; i++) colL.appendChild(node(left[i], i + 1));
    for (var j = 0; j < n; j++) colR.appendChild(node(right[j], j + 1));

    function redraw() {
      var wb = wrap.getBoundingClientRect();
      svg.setAttribute('viewBox', '0 0 ' + wb.width + ' ' + wb.height);
      svg.innerHTML = '';
      for (var i = 0; i < n; i++) {
        if (!links[i]) continue;
        var a = colL.children[i].querySelector('i').getBoundingClientRect();
        var b = colR.children[links[i] - 1].querySelector('i').getBoundingClientRect();
        var ln = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        ln.setAttribute('x1', a.left + a.width / 2 - wb.left);
        ln.setAttribute('y1', a.top + a.height / 2 - wb.top);
        ln.setAttribute('x2', b.left + b.width / 2 - wb.left);
        ln.setAttribute('y2', b.top + b.height / 2 - wb.top);
        ln.setAttribute('stroke', WIRE_COLORS[left[i]] || '#888');
        ln.setAttribute('stroke-width', '4');
        ln.setAttribute('stroke-linecap', 'round');
        svg.appendChild(ln);
      }
      var usedR = links.filter(Boolean);
      for (var k = 0; k < n; k++) {
        var okLink = links[k] && right[links[k] - 1] === left[k];
        colL.children[k].classList.toggle('sel', k === sel);
        colL.children[k].classList.toggle('done', !!links[k]);
        colL.children[k].classList.toggle('bad', links[k] && !okLink);
        colR.children[k].classList.toggle('done', usedR.indexOf(k + 1) !== -1);
      }
    }
    function allMatched() {
      for (var i = 0; i < n; i++) if (!links[i] || right[links[i] - 1] !== left[i]) return false;
      return true;
    }

    colL.addEventListener('click', function (e) {
      var nd = e.target.closest('.wnode'); if (!nd) return;
      var row = +nd.dataset.row - 1;
      if (links[row]) { links[row] = 0; sel = -1; redraw(); return; }
      sel = (sel === row) ? -1 : row;
      redraw();
    });
    colR.addEventListener('click', function (e) {
      var nd = e.target.closest('.wnode'); if (sel < 0 || !nd) return;
      var rr = +nd.dataset.row;
      for (var i = 0; i < n; i++) if (links[i] === rr) links[i] = 0;
      links[sel] = rr;
      sel = -1;
      redraw();
      // se inchide DOAR cand fiecare fir e legat la culoarea lui (serverul re-valideaza)
      if (allMatched()) submitMg({ links: links.slice(), elapsed: Date.now() - MG.startTs });
    });

    MG = { token: token, game: 'wires', startTs: Date.now(), total: p.timeMs || 22000, deadline: Date.now() + (p.timeMs || 22000) };
    openMg('wires');
    $('#mg-timer-fill').style.width = '100%';
    MG.timerInt = setInterval(mgTimerTick, 100);
    redraw();
    var onResize = function () { redraw(); };
    window.addEventListener('resize', onResize);
    MG._cleanup = function () { window.removeEventListener('resize', onResize); };
  }

  /* ---- 2 · CONNECT TO ELECTRICITY (flow) ---- */
  function startFlow(token, p) {
    var n = p.n || 5;
    var rots = (p.start || []).slice(0, n);
    while (rots.length < n) rots.push(0);

    var row = $('#flow-row');
    row.innerHTML = '<div class="tube fixed start"><i></i><b>START</b></div>';
    var tiles = [];
    for (var i = 0; i < n; i++) {
      var el = document.createElement('div');
      el.className = 'tube';
      el.innerHTML = '<i></i>';
      el.style.setProperty('--rot', (rots[i] * 90) + 'deg');
      (function (idx, node) {
        node.addEventListener('click', function () {
          if (MG && MG._solving) return;
          rots[idx] = (rots[idx] + 1) % 4;
          node.style.setProperty('--rot', (rots[idx] * 90) + 'deg');
          check();
        });
      })(i, el);
      row.appendChild(el);
      tiles.push(el);
    }
    row.insertAdjacentHTML('beforeend', '<div class="tube fixed end"><i></i><b>END</b></div>');
    var endTile = row.querySelector('.tube.end');

    function conducts(r) { return r % 2 === 0; }
    function check() {
      if (!MG || MG._solving) return;
      if (!rots.every(conducts)) { tiles.forEach(function (t) { t.classList.remove('lit'); }); return; }
      MG._solving = true;
      row.querySelector('.tube.start').classList.add('lit');
      var k = 0;
      (function step() {
        if (!MG) return;
        if (k < n) { tiles[k].classList.add('lit'); k++; setTimeout(step, 130); }
        else {
          endTile.classList.add('lit');
          setTimeout(function () { submitMg({ rot: rots.slice(), elapsed: Date.now() - MG.startTs }); }, 220);
        }
      })();
    }

    MG = { token: token, game: 'flow', startTs: Date.now(), total: p.timeMs || 18000, deadline: Date.now() + (p.timeMs || 18000) };
    openMg('flow');
    $('#mg-timer-fill').style.width = '100%';
    MG.timerInt = setInterval(mgTimerTick, 100);
  }

  /* ---- 3 · SEARCH THE CODE ---- */
  function startCode(token, p) {
    var digits = p.digits || 3;
    var box = $('#code-digits');
    box.innerHTML = '';
    var vals = [], locked = [], els = [];

    for (var i = 0; i < digits; i++) {
      vals.push(0); locked.push(false);
      var d = document.createElement('div');
      d.className = 'cdig';
      d.innerHTML = '<button class="cbtn cup">&#9650;</button><span class="cval">0</span><button class="cbtn cdn">&#9660;</button>';
      (function (idx, node) {
        node.querySelector('.cup').addEventListener('click', function () {
          if (locked[idx]) return;
          vals[idx] = (vals[idx] + 1) % 10; node.querySelector('.cval').textContent = vals[idx];
        });
        node.querySelector('.cdn').addEventListener('click', function () {
          if (locked[idx]) return;
          vals[idx] = (vals[idx] + 9) % 10; node.querySelector('.cval').textContent = vals[idx];
        });
      })(i, d);
      box.appendChild(d);
      els.push(d);
    }

    function sendGuess() {
      if (!MG || MG.game !== 'code' || MG._done) return;
      post('codeGuess', { token: token, guess: vals.slice() });
    }
    $('#code-enter').onclick = sendGuess;

    MG = {
      token: token, game: 'code', startTs: Date.now(),
      total: p.timeMs || 28000, deadline: Date.now() + (p.timeMs || 28000),
      _apply: function (lockedArr, solved) {
        for (var i = 0; i < digits; i++) {
          if (lockedArr[i] && !locked[i]) { locked[i] = true; els[i].classList.add('locked'); }
        }
        if (solved) { MG._done = true; $('#code-lock').classList.add('open'); }
      }
    };
    MG._keyStop = function (e) { if (e.code === 'Enter' || e.code === 'NumpadEnter') { e.preventDefault(); sendGuess(); } };
    window.addEventListener('keydown', MG._keyStop);

    $('#code-lock').classList.remove('open');
    openMg('code');
    $('#mg-timer-fill').style.width = '100%';
    MG.timerInt = setInterval(mgTimerTick, 100);
  }

  /* ======================================================= SESSION SUMMARY */
  function showDone(d) {
    $('#d-reward').textContent = '+' + money(d.earned || 0);
    $('#d-sub').textContent = 'Panels repaired this session: ' + (d.panels || 0);
    $('#d-levelup').classList.add('hidden');
    $('#done-overlay').classList.remove('hidden');
  }
  function closeDone() { $('#done-overlay').classList.add('hidden'); post('doneClose'); }
  $('#d-close').addEventListener('click', closeDone);

  /* ======================================================= BUS */
  window.addEventListener('message', function (e) {
    var m = e.data || {};
    switch (m.action) {
      case 'prompt': setPrompt(m.show, m.label); break;
      case 'wprompt': setWorkPrompt(m.show, m.label); break;
      case 'hud': setHud(m); break;
      case 'toast': toast(m.text, m.kind); break;
      case 'menu': renderMenu(m.data || {}); break;
      case 'closeMenu': closeMenu(); break;
      case 'minigame':
        if (m.game === 'wires') startWires(m.token, m.params || {});
        else if (m.game === 'flow') startFlow(m.token, m.params || {});
        else if (m.game === 'code') startCode(m.token, m.params || {});
        break;
      case 'codeResult':
        if (MG && MG.game === 'code' && MG._apply) MG._apply(m.locked || [], m.solved === true);
        break;
      case 'mgDone':
      case 'mgClose':
        closeMg();
        break;
      case 'shiftComplete':
        closeMg(); showDone(m.data || {});
        break;
      case 'forceCloseDone':
        $('#done-overlay').classList.add('hidden');
        break;
    }
  });

  // ESC in orice overlay -> inchide (Lua reface focus-ul)
  window.addEventListener('keyup', function (e) {
    if (e.key !== 'Escape') return;
    if (!$('#menu-overlay').classList.contains('hidden')) { closeMenu(); post('closeMenu'); }
    else if (!$('#mg-overlay').classList.contains('hidden')) { var tk = MG && MG.token; closeMg(); if (tk) post('minigameAbort', { token: tk }); }
    else if (!$('#done-overlay').classList.contains('hidden')) { closeDone(); }
  });

  /* preview in browser */
  if (isBrowser) {
    renderMenu({ jobLabel: 'Electrician', hasJob: true, currentJobLabel: 'Electrician', skill: 2, maxSkill: 6,
      completedShifts: 84, nextSkill: 3, nextSkillShifts: 140, avgPay: 85, minLevel: 1, playerLevel: 8,
      estMin: 70, estMax: 100, isWorking: false });
  }
})();
