(function () {
  'use strict';
  var host = document.getElementById('tags');
  var nodes = {};   // [serverId] = { el, voiceEl, badgesEl, idEl, nameEl, sig }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  function build() {
    var el = document.createElement('div');
    el.className = 'nt';
    el.innerHTML =
      '<div class="nt-voice" hidden>' +
        '<svg viewBox="0 0 24 24" aria-hidden="true">' +
          '<path class="spk-cone" d="M4 9h3.5L12 5v14L7.5 15H4z"/>' +
          '<path class="spk-w spk-w1" d="M15.4 9.3a3.8 3.8 0 0 1 0 5.4"/>' +
          '<path class="spk-w spk-w2" d="M17.7 7a7 7 0 0 1 0 10"/>' +
        '</svg>' +
      '</div>' +
      '<div class="nt-badges" hidden></div>' +
      '<div class="nt-line"><span class="nt-id"></span><span class="nt-name"></span></div>';
    host.appendChild(el);
    return {
      el: el,
      voiceEl: el.querySelector('.nt-voice'),
      badgesEl: el.querySelector('.nt-badges'),
      idEl: el.querySelector('.nt-id'),
      nameEl: el.querySelector('.nt-name'),
      sig: ''
    };
  }

  // randul de badge-uri: [icon grad staff?] apoi [icoane subscriptii] (ordine Legend|Platinum|Gold,
  // ordonarea o face serverul). Daca nu e staff -> doar subscriptiile, in acelasi loc.
  function badgesHtml(t) {
    var parts = '';
    if (t.icon) {
      parts += '<span class="nt-b nt-staff" style="color:' + (t.color || '#fff') + '">' +
               '<svg viewBox="0 0 24 24">' + t.icon + '</svg></span>';
    }
    (t.subs || []).forEach(function (s) {
      parts += '<span class="nt-b nt-sub" style="color:' + (s.color || '#fff') + '">' +
               '<svg viewBox="0 0 24 24">' + s.icon + '</svg></span>';
    });
    return parts;
  }

  function subsSig(t) {
    return (t.subs || []).map(function (s) { return s.color; }).join(',');
  }

  function render(list) {
    var seen = {};
    (list || []).forEach(function (t) {
      seen[t.id] = true;
      var n = nodes[t.id];
      if (!n) { n = build(); nodes[t.id] = n; }

      // continut (rebuild doar cand se schimba) — iconurile sunt trusted (staff.lua / subs.lua)
      var sig = t.sqlId + '|' + t.name + '|' + (t.color || '') + '|' + (t.icon || '') + '|' + subsSig(t);
      if (sig !== n.sig) {
        n.sig = sig;
        n.idEl.textContent = '[' + esc(t.sqlId) + ']';
        n.nameEl.textContent = t.name || 'Player';
        var html = badgesHtml(t);
        n.badgesEl.innerHTML = html;
        n.badgesEl.hidden = (html === '');
      }

      // difuzor animat cand jucatorul vorbeste (se schimba des -> in afara sig-ului)
      n.voiceEl.hidden = !t.talk;

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
    var GEM = '<path fill="currentColor" d="M5 3h14l3 6-10 12L2 9l3-6z"/>';
    render([
      { id: 1, sqlId: 152, name: 'John Doe', x: 0.5, y: 0.4, s: 1, a: 1, talk: true,
        color: '#5100ff', icon: '<path fill="currentColor" d="M2 8l4.5 3L12 4l5.5 7L22 8l-2 12H4L2 8z"/>',
        subs: [ { icon: GEM, color: '#3d9bff' }, { icon: GEM, color: '#a855f7' }, { icon: GEM, color: '#ffd633' } ] },
      { id: 2, sqlId: 77, name: 'Jane Smith', x: 0.3, y: 0.62, s: 0.85, a: 0.9,
        subs: [ { icon: GEM, color: '#a855f7' }, { icon: GEM, color: '#ffd633' } ] },
      { id: 3, sqlId: 210, name: 'Civilian Guy', x: 0.7, y: 0.55, s: 0.9, a: 1, talk: true }
    ]);
  }
})();
