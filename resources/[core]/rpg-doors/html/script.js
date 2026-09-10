(function () {
  'use strict';

  var isBrowser = typeof window.GetParentResourceName !== 'function';
  var RES = isBrowser ? 'rpg-doors' : window.GetParentResourceName();
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

  var doors = [];

  /* ------------------------------------------------------- toasts */
  function toast(text) {
    if (!text) return;
    var t = document.createElement('div');
    t.className = 'toast';
    t.textContent = text;
    $('#toasts').appendChild(t);
    setTimeout(function () { if (t.parentNode) t.parentNode.removeChild(t); }, 3600);
  }

  /* ------------------------------------------------------- list */
  function render() {
    var host = $('#list');
    host.innerHTML = '';
    $('#count').textContent = doors.length;

    if (!doors.length) {
      var e = document.createElement('div');
      e.className = 'empty';
      e.textContent = 'Nicio ușă înregistrată. Folosește „Selectează ușă în lume".';
      host.appendChild(e);
      return;
    }

    doors.forEach(function (d) {
      var row = document.createElement('div');
      row.className = 'door';
      row.innerHTML =
        '<span class="pill ' + (d.locked ? 'locked' : 'unlocked') + '">' +
          (d.locked ? 'Încuiată' : 'Descuiată') + '</span>' +
        '<div class="d-main">' +
          '<div class="d-name" data-name></div>' +
          '<div class="d-sub">#' + d.id + ' · model ' + esc(d.model) +
            ' · ' + d.x.toFixed(1) + ', ' + d.y.toFixed(1) + ', ' + d.z.toFixed(1) + '</div>' +
        '</div>' +
        '<div class="d-actions">' +
          '<button class="btn mini" data-a="toggle">' + (d.locked ? 'Descuie' : 'Încuie') + '</button>' +
          '<button class="btn mini ghost" data-a="tp">TP</button>' +
          '<button class="btn mini ghost" data-a="rename">Nume</button>' +
          '<button class="btn mini danger" data-a="remove">Șterge</button>' +
        '</div>';

      row.querySelector('[data-name]').textContent = d.label;

      row.querySelector('[data-a="toggle"]').addEventListener('click', function () {
        post('toggle', { id: d.id });
      });
      row.querySelector('[data-a="tp"]').addEventListener('click', function () {
        post('tp', { id: d.id });
      });
      row.querySelector('[data-a="remove"]').addEventListener('click', function () {
        if (confirmInline(row)) return;
        post('remove', { id: d.id });
      });
      row.querySelector('[data-a="rename"]').addEventListener('click', function () {
        startRename(row, d);
      });

      host.appendChild(row);
    });
  }

  // click "Șterge" o data -> devine "Sigur?"; al doilea click trimite. Revine dupa 3s.
  function confirmInline(row) {
    var btn = row.querySelector('[data-a="remove"]');
    if (btn.dataset.armed === '1') { return false; }
    btn.dataset.armed = '1';
    var prev = btn.textContent;
    btn.textContent = 'Sigur?';
    setTimeout(function () {
      if (btn.dataset.armed === '1') { btn.dataset.armed = ''; btn.textContent = prev; }
    }, 3000);
    return true;
  }

  function startRename(row, d) {
    var nameEl = row.querySelector('[data-name]');
    if (nameEl.querySelector('input')) return;
    var inp = document.createElement('input');
    inp.type = 'text';
    inp.maxLength = 64;
    inp.value = d.label;
    nameEl.textContent = '';
    nameEl.appendChild(inp);
    inp.focus();
    inp.select();
    var commit = function () {
      var v = inp.value.trim();
      if (v && v !== d.label) post('rename', { id: d.id, label: v });
      else render();
    };
    inp.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); commit(); }
      else if (e.key === 'Escape') { e.preventDefault(); render(); }
    });
    inp.addEventListener('blur', commit);
  }

  /* ------------------------------------------------------- pick / add */
  function resetScanUI() {
    $('#scan-box').classList.add('hidden');
    $('#scan-name').value = '';
  }

  $('#btn-pick').addEventListener('click', function () {
    resetScanUI();
    post('pick');
    $('#wrap').classList.add('hidden');   // clientul inchide oricum focus-ul
  });
  $('#btn-cancel').addEventListener('click', resetScanUI);
  $('#btn-add').addEventListener('click', function () {
    post('add', { label: $('#scan-name').value.trim() || 'Ușă' });
    resetScanUI();
  });
  $('#scan-name').addEventListener('keydown', function (e) {
    if (e.key === 'Enter') { e.preventDefault(); $('#btn-add').click(); }
  });

  $('#btn-close').addEventListener('click', function () { post('close'); });

  /* ------------------------------------------------------- bus */
  window.addEventListener('message', function (ev) {
    var m = ev.data || {};
    if (m.action === 'open') {
      doors = m.doors || [];
      resetScanUI();
      $('#wrap').classList.remove('hidden');
      render();
    } else if (m.action === 'close') {
      $('#wrap').classList.add('hidden');
    } else if (m.action === 'list') {
      doors = m.doors || [];
      render();
    } else if (m.action === 'scanResult') {
      if (m.ok) {
        $('#scan-info').textContent = 'Ușă nouă — model ' + m.model + ' @ ' + m.x + ', ' + m.y + ', ' + m.z;
        $('#scan-box').classList.remove('hidden');
        $('#scan-name').focus();
      } else {
        $('#scan-box').classList.add('hidden');
      }
    } else if (m.action === 'toast') {
      toast(m.text);
    }
  });

  window.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !$('#wrap').classList.contains('hidden')) {
      var typing = document.activeElement && document.activeElement.tagName === 'INPUT';
      if (typing) return;
      post('close');
    }
  });

  /* ------------------------------------------------------- preview */
  if (isBrowser) {
    doors = [
      { id: 1, label: 'Poartă depozit', model: 1234567, x: 123.4, y: -456.7, z: 30.1, locked: true },
      { id: 2, label: 'Ușă birou', model: 987654, x: 200.0, y: -100.2, z: 25.5, locked: false },
    ];
    $('#wrap').classList.remove('hidden');
    render();
  }
})();
