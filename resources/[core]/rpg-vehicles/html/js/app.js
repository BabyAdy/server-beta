(function () {
  'use strict';
  var isBrowser = typeof window.GetParentResourceName !== 'function';
  var RES = isBrowser ? 'rpg-vehicles' : window.GetParentResourceName();
  var $ = function (s) { return document.querySelector(s); };

  function post(name, body) {
    if (isBrowser) return Promise.resolve({});
    return fetch('https://' + RES + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {}),
    }).catch(function () {});
  }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  function actionBtn(id, act, label, ghost) {
    var b = document.createElement('button');
    b.className = 'btn' + (ghost ? ' ghost' : '');
    b.textContent = label;
    b.addEventListener('click', function () { post('action', { act: act, id: id }); });
    return b;
  }

  function render(list) {
    var host = $('#list');
    host.innerHTML = '';
    list = list || [];
    $('#empty').classList.toggle('hidden', list.length > 0);

    list.forEach(function (v) {
      var km = Math.max(0, Math.round(v.odometer || 0));
      var days = Math.max(0, Math.floor(v.days || 0));
      var row = document.createElement('div');
      row.className = 'veh';
      row.innerHTML =
        '<div class="veh-top">' +
          '<span class="veh-model">' + esc(v.model) + '</span>' +
          '<span class="veh-plate">' + esc(v.plate) + '</span>' +
          '<span class="pill ' + (v.spawned ? 'out' : 'parked') + '">' + (v.spawned ? 'Spawnat' : 'Parcat') + '</span>' +
        '</div>' +
        '<div class="veh-meta">' +
          '<span>' + km.toLocaleString('ro-RO') + ' km</span>' +
          '<span class="' + (v.locked ? 'lk' : 'ul') + '">' + (v.locked ? 'Închis' : 'Deschis') + '</span>' +
          '<span>' + days + (days === 1 ? ' zi' : ' zile') + '</span>' +
        '</div>';

      var actions = document.createElement('div');
      actions.className = 'veh-actions';

      if (!v.spawned) actions.appendChild(actionBtn(v.id, 'spawn', 'Spawn'));
      if (v.spawned)  actions.appendChild(actionBtn(v.id, 'despawn', 'Despawn'));
      actions.appendChild(actionBtn(v.id, 'unstuck', 'Unstuck', true));
      if (v.spawned)  actions.appendChild(actionBtn(v.id, 'locate', 'Locate', true));
      actions.appendChild(actionBtn(v.id, 'lock', v.locked ? 'Unlock' : 'Lock', true));

      row.appendChild(actions);
      host.appendChild(row);
    });
  }

  window.addEventListener('message', function (e) {
    var msg = e.data || {};
    if (msg.action === 'open') {
      render(msg.vehicles);
      $('#menu').classList.remove('hidden');
    } else if (msg.action === 'refresh') {
      render(msg.vehicles);
    } else if (msg.action === 'close') {
      $('#menu').classList.add('hidden');
    }
  });

  $('#btn-close').addEventListener('click', function () {
    $('#menu').classList.add('hidden');
    post('close');
  });

  /* preview browser */
  if (isBrowser) {
    render([
      { id: 1, model: 'nkcypher', plate: 'ABX7K2Q1', spawned: false, locked: true, odometer: 1240, days: 12 },
      { id: 2, model: 'gemera', plate: 'ZZ4M8P0R', spawned: true, locked: false, odometer: 87, days: 1 },
    ]);
    $('#menu').classList.remove('hidden');
  }
})();
