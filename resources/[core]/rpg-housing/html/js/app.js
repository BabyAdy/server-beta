(function () {
  'use strict';
  var host = document.getElementById('houses');
  var nodes = {};   // [houseId] = DOM node

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  function fmtMoney(n) {
    n = Math.round(Number(n) || 0);
    var s = String(Math.abs(n)), out = '';
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 === 0) out += '.';
      out += s.charAt(i);
    }
    return (n < 0 ? '-' : '') + out + '$';
  }

  function render(list) {
    var seen = {};
    (list || []).forEach(function (h) {
      seen[h.houseId] = true;
      var el = nodes[h.houseId];
      if (!el) {
        el = document.createElement('div');
        el.className = 'house-card';
        el.innerHTML =
          '<div class="hc-id">House ID: #' + esc(h.houseId) + '</div>' +
          '<div class="hc-row"><span>Owner</span><b class="hc-owner"></b></div>' +
          '<div class="hc-row hc-price"><span>Price</span><b class="hc-price-v"></b></div>' +
          '<div class="hc-row"><span>Type</span><b class="hc-type"></b></div>';
        host.appendChild(el);
        nodes[h.houseId] = el;
      }
      el.style.left = (h.x * 100) + '%';
      el.style.top = (h.y * 100) + '%';
      el.querySelector('.hc-owner').textContent = h.owner || 'ADMBOT';
      el.querySelector('.hc-price-v').textContent = fmtMoney(h.price);
      el.querySelector('.hc-type').textContent = h.interior || '—';
    });

    Object.keys(nodes).forEach(function (id) {
      if (!seen[id]) {
        nodes[id].remove();
        delete nodes[id];
      }
    });
  }

  var promptEl = document.getElementById('prompt');
  var promptTextEl = document.getElementById('prompt-text');

  function setPrompt(text) {
    if (text) {
      promptTextEl.textContent = text;
      promptEl.classList.remove('hidden');
    } else {
      promptEl.classList.add('hidden');
    }
  }

  window.addEventListener('message', function (e) {
    var msg = e.data || {};
    if (msg.action === 'houses') render(msg.list);
    else if (msg.action === 'prompt') setPrompt(msg.text);
  });

  /* preview in browser */
  if (typeof window.GetParentResourceName !== 'function') {
    render([
      { houseId: 3, x: 0.5, y: 0.55, owner: 'ADMBOT', price: 250000, interior: 'High End House 1 (3655 Wild Oats Drive)' },
    ]);
    setPrompt('for enter home');
  }
})();
