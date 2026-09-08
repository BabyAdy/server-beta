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
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
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
  function setHud(d) {
    var el = $('#hud');
    if (!d.show) { el.classList.add('hidden'); return; }
    var i = d.index || 0, t = d.total || 1;
    $('#hud-i').textContent = i;
    $('#hud-t').textContent = t;
    $('#hud-fill').style.width = Math.max(0, Math.min(100, (i / t) * 100)) + '%';
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
      $('#m-mult').textContent = '(+' + (d.multiplierPct || 0) + '%)';
      $('#m-shifts').textContent = d.completedShifts;
      $('#m-salary').textContent = money(d.estMin) + ' – ' + money(d.estMax);
      if (d.nextSkillShifts != null) {
        var have = d.completedShifts, need = d.nextSkillShifts;
        $('#m-next').textContent = 'Skill ' + d.nextSkill + ' @ ' + need + ' shifts';
        var prevNeed = 0;
        $('#m-bar').style.width = Math.max(0, Math.min(100, ((have - prevNeed) / Math.max(1, need - prevNeed)) * 100)) + '%';
      } else {
        $('#m-next').textContent = 'Max skill reached';
        $('#m-bar').style.width = '100%';
      }
    }

    var canGet = !d.hasJob && (d.playerLevel >= d.minLevel);
    $('#b-get').disabled = !canGet;
    $('#b-quit').disabled = !d.hasJob || d.isWorking;
    $('#b-start').disabled = !d.hasJob || d.isWorking;

    var hint = '';
    if (!d.hasJob && d.playerLevel < d.minLevel) hint = 'Requires level ' + d.minLevel + ' (you are ' + d.playerLevel + ').';
    else if (d.isWorking) hint = 'You are on a shift. Finish it first.';
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
  var MG = null;   // { token, game, startTs, deadline, raf, timerInt }

  var WIRE_SVG = {
    straight: '<path d="M2 12h20" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round"/>',
    corner:   '<path d="M12 22V12h10" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round"/>',
    tee:      '<path d="M2 12h20M12 12v10" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round"/>'
  };

  function openMg(game) {
    $('#mg-circuit').classList.toggle('hidden', game !== 'circuit');
    $('#mg-voltage').classList.toggle('hidden', game !== 'voltage');
    $('#mg-overlay').classList.remove('hidden');
  }
  function closeMg() {
    $('#mg-overlay').classList.add('hidden');
    if (MG) {
      if (MG.raf) cancelAnimationFrame(MG.raf);
      if (MG.timerInt) clearInterval(MG.timerInt);
      if (MG._keyStop) window.removeEventListener('keydown', MG._keyStop);
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

  /* ---- CIRCUIT ---- */
  function startCircuit(token, p) {
    var n = p.n || 4;
    var rots = (p.start || []).slice(0, n);
    var target = (p.target || []).slice(0, n);
    var types = p.types || [];

    var grid = $('#circuit-grid');
    grid.innerHTML = '';
    var tiles = [];
    for (var i = 0; i < n; i++) {
      var tp = types[i] || 'straight';
      var el = document.createElement('div');
      el.className = 'wire';
      el.innerHTML =
        '<div class="ghost"><svg viewBox="0 0 24 24" style="transform:rotate(' + (target[i] * 90) + 'deg)">' + WIRE_SVG[tp] + '</svg></div>' +
        '<div class="live"><svg viewBox="0 0 24 24" style="transform:rotate(' + (rots[i] * 90) + 'deg)">' + WIRE_SVG[tp] + '</svg></div>';
      (function (idx, node, type) {
        node.addEventListener('click', function () {
          rots[idx] = (rots[idx] + 1) % 4;
          node.querySelector('.live svg').style.transform = 'rotate(' + (rots[idx] * 90) + 'deg)';
          refresh();
        });
      })(i, el, tp);
      grid.appendChild(el);
      tiles.push(el);
    }

    function refresh() {
      var allOk = true;
      for (var k = 0; k < n; k++) {
        var ok = rots[k] === target[k];
        tiles[k].classList.toggle('ok', ok);
        if (!ok) allOk = false;
      }
      $('#circuit-confirm').disabled = !allOk;
    }
    refresh();

    $('#circuit-confirm').onclick = function () {
      if (this.disabled) return;
      submitMg({ rot: rots, elapsed: Date.now() - MG.startTs });
    };

    MG = { token: token, game: 'circuit', startTs: Date.now(), total: p.timeMs || 20000, deadline: Date.now() + (p.timeMs || 20000) };
    openMg('circuit');
    $('#mg-timer-fill').style.width = '100%';
    MG.timerInt = setInterval(mgTimerTick, 100);
  }

  /* ---- VOLTAGE ---- */
  function tri(x) { x = ((x % 2) + 2) % 2; return x < 1 ? x : 2 - x; }

  function startVoltage(token, p) {
    var zs = p.zoneStart || 0.4, zw = p.zoneWidth || 0.2, speed = p.speed || 0.6, ph0 = p.phase0 || 0;
    $('#volt-zone').style.left = (zs * 100) + '%';
    $('#volt-zone').style.width = (zw * 100) + '%';

    MG = { token: token, game: 'voltage', startTs: Date.now(), total: p.timeMs || 9000, deadline: Date.now() + (p.timeMs || 9000), speed: speed, ph0: ph0 };
    openMg('voltage');
    $('#mg-timer-fill').style.width = '100%';

    var cursor = $('#volt-cursor');
    function frame() {
      if (!MG) return;
      var t = (Date.now() - MG.startTs) / 1000;
      cursor.style.left = (tri(ph0 + t * speed) * 100) + '%';
      mgTimerTick();
      if (!MG) return;                       // mgTimerTick a putut inchide minigame-ul (timeout)
      MG.raf = requestAnimationFrame(frame);
    }
    MG.raf = requestAnimationFrame(frame);

    function stop() {
      if (!MG || MG.game !== 'voltage') return;
      var elapsedMs = Date.now() - MG.startTs;
      var pos = tri(MG.ph0 + (elapsedMs / 1000) * MG.speed);
      submitMg({ stop: pos, elapsedMs: elapsedMs });
    }
    $('#volt-stop').onclick = stop;
    MG._keyStop = function (e) { if (e.code === 'Space') { e.preventDefault(); stop(); } };
    window.addEventListener('keydown', MG._keyStop);
  }

  /* ======================================================= SHIFT COMPLETE */
  function showDone(d) {
    $('#d-reward').textContent = '+' + money(d.reward);
    $('#d-sub').textContent = 'Completed shifts: ' + d.completedShifts + '  ·  Skill ' + d.skill;
    var lu = $('#d-levelup');
    if (d.leveledUp) {
      lu.textContent = 'Congratulations! You reached ' + (d.jobLabel || 'Electrician') + ' Skill ' + d.skill +
        '. Your income multiplier is now +' + d.newPct + '%.';
      lu.classList.remove('hidden');
    } else lu.classList.add('hidden');
    $('#done-overlay').classList.remove('hidden');
  }
  $('#d-close').addEventListener('click', function () { $('#done-overlay').classList.add('hidden'); });

  /* ======================================================= BUS */
  window.addEventListener('message', function (e) {
    var m = e.data || {};
    switch (m.action) {
      case 'prompt': setPrompt(m.show, m.label); break;
      case 'hud': setHud(m); break;
      case 'toast': toast(m.text, m.kind); break;
      case 'menu': renderMenu(m.data || {}); break;
      case 'closeMenu': closeMenu(); break;
      case 'minigame':
        if (m.game === 'circuit') startCircuit(m.token, m.params || {});
        else if (m.game === 'voltage') startVoltage(m.token, m.params || {});
        break;
      case 'shiftComplete':
        closeMg(); showDone(m.data || {});
        break;
    }
  });

  // ESC in orice overlay -> inchide (Lua reface focus-ul)
  window.addEventListener('keyup', function (e) {
    if (e.key !== 'Escape') return;
    if (!$('#menu-overlay').classList.contains('hidden')) { closeMenu(); post('closeMenu'); }
    else if (!$('#mg-overlay').classList.contains('hidden')) { var tk = MG && MG.token; closeMg(); if (tk) post('minigameAbort', { token: tk }); }
    else if (!$('#done-overlay').classList.contains('hidden')) { $('#done-overlay').classList.add('hidden'); }
  });

  /* preview */
  if (isBrowser) {
    renderMenu({ jobLabel: 'Electrician', hasJob: true, currentJobLabel: 'Electrician', skill: 2, maxSkill: 5,
      completedShifts: 24, nextSkill: 3, nextSkillShifts: 30, multiplierPct: 20, minLevel: 1, playerLevel: 8,
      estMin: 1200, estMax: 2400, isWorking: false });
  }
})();
