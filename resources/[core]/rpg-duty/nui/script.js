(function () {
  'use strict';
  var isB = typeof window.GetParentResourceName !== 'function';
  var RES = isB ? 'rpg-duty' : window.GetParentResourceName();
  var $ = function (s) { return document.querySelector(s); };

  function post(name, body) {
    if (isB) return Promise.resolve({});
    return fetch('https://' + RES + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {})
    }).then(function (r) { return r.json().catch(function () { return {}; }); }).catch(function () { return {}; });
  }

  function stepper(kind, item, field, label) {
    var wrap = document.createElement('div');
    wrap.className = 'stepper';
    wrap.innerHTML =
      '<span class="tag">' + label + '</span>' +
      '<button data-dir="-1">&#9664;</button>' +
      '<span class="val"></span>' +
      '<button data-dir="1">&#9654;</button>';
    var valEl = wrap.querySelector('.val');
    function paint() {
      var v = item[field];
      var mx = field === 'd' ? item.maxD : item.maxT;
      valEl.textContent = (v == null ? '?' : v) + ' / ' + (mx == null ? '?' : mx);
    }
    paint();
    wrap.querySelectorAll('button').forEach(function (b) {
      b.addEventListener('click', function () {
        post('outfitStep', { kind: kind, id: item.id, field: field, dir: parseInt(b.dataset.dir, 10) })
          .then(function (res) {
            if (res && res.d != null) {
              item.d = res.d; item.t = res.t;
              if (res.maxD != null) item.maxD = res.maxD;
              if (res.maxT != null) item.maxT = res.maxT;
            }
            paint();
            // repictează și celălalt stepper al rândului (maxT se schimbă cu D)
            if (wrap.parentNode) {
              wrap.parentNode.querySelectorAll('.stepper .val').forEach(function (el, i) {
                var f = i === 0 ? 'd' : 't';
                var mx = f === 'd' ? item.maxD : item.maxT;
                el.textContent = item[f] + ' / ' + (mx == null ? '?' : mx);
              });
            }
          });
      });
    });
    return wrap;
  }

  function buildRow(kind, item) {
    var row = document.createElement('div');
    row.className = 'row';
    var lbl = document.createElement('div');
    lbl.className = 'lbl';
    lbl.textContent = item.label;
    row.appendChild(lbl);
    row.appendChild(stepper(kind, item, 'd', 'D'));
    row.appendChild(stepper(kind, item, 't', 'T'));
    return row;
  }

  function openEditor(comps, props) {
    var host = $('#rows');
    host.innerHTML = '';
    (comps || []).forEach(function (c) { host.appendChild(buildRow('comp', c)); });
    (props || []).forEach(function (p) { host.appendChild(buildRow('prop', p)); });
    $('#wrap').classList.remove('hidden');
  }
  function closeEditor() { $('#wrap').classList.add('hidden'); }

  $('#btn-save').addEventListener('click', function () { post('outfitSave'); });
  $('#btn-reset').addEventListener('click', function () { post('outfitCancel'); });
  $('#btn-cancel').addEventListener('click', function () { post('outfitCancel'); });

  window.addEventListener('message', function (e) {
    var m = e.data || {};
    if (m.action === 'openEditor') openEditor(m.comps, m.props);
    else if (m.action === 'closeEditor') closeEditor();
  });
  window.addEventListener('keyup', function (e) {
    if (e.key === 'Escape' && !$('#wrap').classList.contains('hidden')) post('outfitCancel');
  });

  if (isB) {
    openEditor(
      [{ id: 11, label: 'Bluză / Geacă', d: 0, t: 0, maxD: 20, maxT: 3 },
       { id: 4, label: 'Pantaloni', d: 0, t: 0, maxD: 15, maxT: 2 }],
      [{ id: 0, label: 'Șapcă / Cască', d: -1, t: 0, maxD: 30, maxT: 4 }]
    );
  }
})();
