(function () {
  'use strict';

  var isBrowser = typeof window.GetParentResourceName !== 'function';
  var RES = isBrowser ? 'rpg-garages' : window.GetParentResourceName();
  var $ = function (s) { return document.querySelector(s); };
  var $$ = function (s) { return Array.prototype.slice.call(document.querySelectorAll(s)); };

  function post(name, body) {
    if (isBrowser) return Promise.resolve({});
    return fetch('https://' + RES + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {})
    }).catch(function () {});
  }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function nfmt(n) { return Number(n || 0).toLocaleString('en-US'); }

  var ICON = {
    fuel: '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 22h10M5 22V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v17M5 12h8M15 8l3 3v7a1.5 1.5 0 0 0 3 0V9l-3-4"/></svg>',
    odo:  '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19a9 9 0 1 1 16 0"/><path d="M12 15l4-5"/><circle cx="12" cy="15" r="1.4" fill="currentColor" stroke="none"/></svg>'
  };

  /* --------------------------------------------------------- PROMPT ---- */
  var PROMPTS = {
    access: { t: 'GARAGE ACCESS', s: 'Press E to access your vehicle list!' },
    park:   { t: 'GARAGE PARK',   s: 'Press E to put vehicle in garage!' },
    dealer: { t: 'DEALERSHIP',    s: 'Press E to browse vehicles' }
  };
  function setPrompt(kind) {
    var el = $('#prompt'), p = PROMPTS[kind];
    if (!p) { el.classList.add('hidden'); return; }
    $('#p-title').textContent = p.t;
    $('#p-sub').textContent = p.s;
    el.classList.remove('hidden');
  }

  /* --------------------------------------------------------- MODAL ----- */
  function showModal() { $('#overlay').classList.remove('hidden'); }
  function hideModal() {
    $('#overlay').classList.add('hidden');
    $('#m-list').innerHTML = '';
    garageState = null;
    spawningBtn = null;
  }

  /* ---- state pt. lista de garage (search / sort se fac LOCAL, spec §19) ---- */
  var garageState = null;   // { data, search, sort }
  var spawningBtn = null;

  var EMPTY = {
    Vehicle: ['NO VEHICLES', "You don't have any vehicles available in this garage."],
    Heli:    ['NO AIRCRAFT', "You don't have any helicopters or planes available."],
    Boat:    ['NO BOATS',    "You don't have any boats available."]
  };

  function vehicleImg(v) {
    return 'images/vehicles/' + (v.image || (String(v.model_name || 'unknown') + '.png'));
  }

  function vehicleCard(v) {
    var el = document.createElement('article');
    el.className = 'v';
    var locked = v.status !== 1;
    var out = !!v.spawned;

    el.innerHTML =
      '<div class="v-img">' +
        '<img src="' + esc(vehicleImg(v)) + '" alt="" ' +
             'onerror="this.parentNode.classList.add(\'noimg\');this.remove();" />' +
        '<span class="v-img-ph">No image</span>' +
      '</div>' +
      '<div class="v-body">' +
        '<div class="v-row1">' +
          '<span class="v-name">' + esc(v.display_name || v.model_name) + '</span>' +
          '<span class="v-badge ' + (locked ? 'locked' : 'unlocked') + '">' +
            (locked ? 'Locked' : 'Unlocked') + '</span>' +
        '</div>' +
        '<div class="v-sub">' + esc(String(v.model_name || '').toUpperCase()) + ' &bull; #' + v.id + '</div>' +
        '<div class="v-stats">' +
          '<span class="v-stat">' + ICON.fuel + '<b>' + Math.round(v.fuel || 0) + '%</b></span>' +
          '<span class="v-stat">' + ICON.odo + '<b>' + nfmt(v.odometer) + ' KM</b></span>' +
        '</div>' +
        '<button class="v-spawn"' + (out ? ' disabled' : '') + '>' +
          (out ? 'Already out' : 'Spawn Vehicle') + '</button>' +
      '</div>';

    var btn = el.querySelector('.v-spawn');
    if (!out) btn.addEventListener('click', function () { requestSpawn(btn, v.id); });
    return el;
  }

  function paintGarage() {
    if (!garageState) return;
    var d = garageState.data;
    $('#m-kicker').textContent = 'GARAGE #' + d.garageId;
    $('#m-title').textContent = (d.title || 'Vehicles').toUpperCase();

    var q = (garageState.search || '').trim().toLowerCase();
    var list = (d.vehicles || []).filter(function (v) {
      if (!q) return true;
      return (v.display_name || '').toLowerCase().indexOf(q) >= 0
          || (v.model_name || '').toLowerCase().indexOf(q) >= 0
          || String(v.id).indexOf(q.replace('#', '')) >= 0;
    });

    var s = garageState.sort;
    list.sort(function (a, b) {
      switch (s) {
        case 'name-asc': return (a.display_name || '').localeCompare(b.display_name || '');
        case 'odo-desc': return (b.odometer || 0) - (a.odometer || 0);
        case 'fuel-desc': return (b.fuel || 0) - (a.fuel || 0);
        case 'new': return b.id - a.id;
        case 'old': return a.id - b.id;
        default: return a.id - b.id;
      }
    });

    $('#m-count').textContent = list.length + (list.length === 1 ? ' vehicle' : ' vehicles');

    var host = $('#m-list');
    host.innerHTML = '';
    if (list.length === 0) {
      var e = q ? ['NO RESULTS', 'No vehicles match "' + q + '".'] : (EMPTY[d.garageType] || EMPTY.Vehicle);
      $('#e-title').textContent = e[0];
      $('#e-sub').textContent = e[1];
      $('#m-empty').classList.remove('hidden');
      return;
    }
    $('#m-empty').classList.add('hidden');
    list.forEach(function (v) { host.appendChild(vehicleCard(v)); });
  }

  /* ---- spawn flow: loading state -> asteapta rezultat de la Lua/server ---- */
  function requestSpawn(btn, pvId) {
    if (btn.disabled) return;
    spawningBtn = btn;
    btn.classList.add('loading');
    btn.textContent = 'Spawning...';
    $$('.v-spawn').forEach(function (b) { b.disabled = true; });
    post('spawn', { pvId: pvId });
  }

  function onSpawnResult(ok, text) {
    if (ok) return;                       // Lua inchide modalul la succes
    if (garageState) paintGarage();       // reface cardurile (stari corecte)
    spawningBtn = null;
    toast('err', text || 'Failed to spawn vehicle.');
  }

  /* --------------------------------------------------------- DEALER ---- */
  function renderDealer(d) {
    garageState = null;
    $('#m-tools').classList.add('hidden');
    $('#m-kicker').textContent = esc(d.label || 'Dealership');
    $('#m-title').textContent = 'DEALERSHIP';
    var payWord = d.payFrom === 'cash' ? 'cash' : 'bank';

    var host = $('#m-list');
    host.innerHTML = '';
    var items = d.items || [];
    if (items.length === 0) {
      $('#e-title').textContent = 'NOTHING FOR SALE';
      $('#e-sub').textContent = 'This dealership has no vehicles right now.';
      $('#m-empty').classList.remove('hidden');
    } else {
      $('#m-empty').classList.add('hidden');
      items.forEach(function (it) {
        var el = document.createElement('article');
        el.className = 'v deal';
        el.innerHTML =
          '<div class="v-img">' +
            '<img src="images/vehicles/' + esc(it.model) + '.png" alt="" ' +
                 'onerror="this.parentNode.classList.add(\'noimg\');this.remove();" />' +
            '<span class="v-img-ph">No image</span>' +
          '</div>' +
          '<div class="v-body">' +
            '<div class="v-row1">' +
              '<span class="v-name">' + esc(it.name) + '</span>' +
              '<span class="v-tag">' + esc(it.type) + '</span>' +
            '</div>' +
            '<div class="v-sub">' + esc(String(it.model).toUpperCase()) + '</div>' +
            '<div class="v-stats"><span class="v-price">' + nfmt(it.price) + '$</span>' +
              '<span>paid from ' + payWord + '</span></div>' +
            '<button class="v-spawn">Buy</button>' +
          '</div>';
        el.querySelector('.v-spawn').addEventListener('click', function () {
          post('buy', { model: it.model });
        });
        host.appendChild(el);
      });
    }
    $('#m-count').textContent = items.length + (items.length === 1 ? ' model' : ' models');
    showModal();
  }

  /* --------------------------------------------------------- TOAST ----- */
  function toast(kind, text) {
    if (!text) return;
    var t = document.createElement('div');
    t.className = 'toast ' + (kind === 'ok' ? 'ok' : kind === 'err' ? 'err' : '');
    t.textContent = text;
    $('#toasts').appendChild(t);
    setTimeout(function () { if (t.parentNode) t.parentNode.removeChild(t); }, 3300);
  }

  /* --------------------------------------------------------- BUS ------- */
  window.addEventListener('message', function (e) {
    var m = e.data || {};
    switch (m.action) {
      case 'prompt': setPrompt(m.kind); break;
      case 'openGarage':
        garageState = { data: m.data || {}, search: '', sort: 'id-asc' };
        $('#m-search-input').value = '';
        $('#m-sort').value = 'id-asc';
        $('#m-tools').classList.remove('hidden');
        paintGarage();
        showModal();
        setTimeout(function () { $('#m-search-input').focus(); }, 40);
        break;
      case 'openDealer': renderDealer(m.data || {}); break;
      case 'close': hideModal(); break;
      case 'toast': toast(m.kind, m.text); break;
      case 'spawnResult': onSpawnResult(m.ok === true, m.text); break;
    }
  });

  /* search / sort — LOCAL, fara request la server */
  $('#m-search-input').addEventListener('input', function (e) {
    if (garageState) { garageState.search = e.target.value; paintGarage(); }
  });
  $('#m-sort').addEventListener('change', function (e) {
    if (garageState) { garageState.sort = e.target.value; paintGarage(); }
  });

  $('#m-close').addEventListener('click', function () { hideModal(); post('close'); });
  $('#m-esc-btn').addEventListener('click', function () { hideModal(); post('close'); });
  $('#overlay').addEventListener('mousedown', function (e) {
    if (e.target === $('#overlay')) { hideModal(); post('close'); }
  });
  document.addEventListener('keyup', function (e) {
    if (e.key === 'Escape' && !$('#overlay').classList.contains('hidden')) {
      hideModal(); post('close');
    }
  });

  /* --------------------------------------------------------- preview -- */
  if (isBrowser) {
    setPrompt('access');
    garageState = {
      data: {
        garageId: 12, garageType: 'Vehicle', title: 'Vehicles',
        vehicles: [
          { id: 152, model_name: 'sultan', display_name: 'Sultan', odometer: 12452, fuel: 78, status: 0, spawned: false, image: 'sultan.png' },
          { id: 184, model_name: 'elegy2', display_name: 'Elegy Retro Custom', odometer: 4125, fuel: 92, status: 1, spawned: false, image: 'elegy2.png' },
          { id: 190, model_name: 'kuruma', display_name: 'Kuruma', odometer: 240, fuel: 44, status: 0, spawned: true, image: 'kuruma.png' }
        ]
      }, search: '', sort: 'id-asc'
    };
    paintGarage(); showModal();
  }
})();
