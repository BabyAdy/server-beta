(function () {
  'use strict';
  var host = document.getElementById('tags');
  var nodes = {};   // [serverId] = { el, iconWrap, idEl, nameEl, sig }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  function build() {
    var el = document.createElement('div');
    el.className = 'nt';
    el.innerHTML =
      '<div class="nt-icon" hidden></div>' +
      '<div class="nt-line"><span class="nt-id"></span><span class="nt-name"></span></div>';
    host.appendChild(el);
    return {
      el: el,
      iconWrap: el.querySelector('.nt-icon'),
      idEl: el.querySelector('.nt-id'),
      nameEl: el.querySelector('.nt-name'),
      sig: ''
    };
  }

  function render(list) {
    var seen = {};
    (list || []).forEach(function (t) {
      seen[t.id] = true;
      var n = nodes[t.id];
      if (!n) { n = build(); nodes[t.id] = n; }

      // continut (rebuild doar cand se schimba) — icon-ul de grad e trusted (staff.lua)
      var sig = t.sqlId + '|' + t.name + '|' + (t.color || '') + '|' + (t.icon || '');
      if (sig !== n.sig) {
        n.sig = sig;
        n.idEl.textContent = '[' + esc(t.sqlId) + ']';
        n.nameEl.textContent = t.name || 'Player';
        if (t.icon) {
          n.iconWrap.hidden = false;
          n.iconWrap.style.color = t.color || '#fff';
          n.iconWrap.innerHTML = '<svg viewBox="0 0 24 24">' + t.icon + '</svg>';
        } else {
          n.iconWrap.hidden = true;
          n.iconWrap.innerHTML = '';
        }
      }

      // pozitie + scalare + fade
      n.el.style.left = (t.x * 100) + '%';
      n.el.style.top = (t.y * 100) + '%';
      n.el.style.transform = 'translate(-50%, -100%) scale(' + (t.s || 1) + ')';
      n.el.style.opacity = (t.a == null ? 1 : t.a);
    });

    Object.keys(nodes).forEach(function (id) {
      if (!seen[id]) { nodes[id].el.remove(); delete nodes[id]; }
    });
  }

  window.addEventListener('message', function (e) {
    var m = e.data || {};
    if (m.action === 'tags') render(m.list);
  });

  /* preview in browser */
  if (typeof window.GetParentResourceName !== 'function') {
    render([
      { id: 1, sqlId: 152, name: 'John Doe', x: 0.5, y: 0.42, s: 1, a: 1,
        color: '#5100ff', icon: '<path fill="currentColor" d="M2 8l4.5 3L12 4l5.5 7L22 8l-2 12H4L2 8z"/>' },
      { id: 2, sqlId: 77, name: 'Jane Smith', x: 0.32, y: 0.6, s: 0.8, a: 0.85,
        color: '#ff6a00', icon: '<path fill="currentColor" d="M12 2l8 3v6c0 5.05-3.4 8.9-8 11-4.6-2.1-8-5.95-8-11V5l8-3z"/>' },
      { id: 3, sqlId: 210, name: 'Civilian Guy', x: 0.68, y: 0.55, s: 0.9, a: 1 }
    ]);
  }
})();
