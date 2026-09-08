(function () {
  'use strict';
  var host = document.getElementById('houses');
  var nodes = {};   // [houseId] = DOM node

  var isBrowser = typeof window.GetParentResourceName !== 'function';
  var RES = isBrowser ? 'rpg-housing' : window.GetParentResourceName();

  function post(name, body) {
    if (isBrowser) return;
    fetch('https://' + RES + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {})
    }).catch(function () {});
  }

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

  /* ===================== popup /buyhouse ===================== */
  var buyEl = document.getElementById('buy');
  var stepConfirm = document.getElementById('buy-confirm');
  var stepMethod = document.getElementById('buy-method');
  var buyPrice = 0;

  function openBuy(d) {
    buyPrice = Math.round(Number(d.price) || 0);
    document.getElementById('buy-confirm-text').innerHTML =
      'Ești pe cale să cumperi <b>House #' + esc(d.houseId) + '</b> deținută de <b>' +
      esc(d.ownerLabel || 'State') + '</b> pentru suma de <b class="amt">' + fmtMoney(buyPrice) + '</b>.';

    // pas 2 pregatit din datele deja primite (fara request la server pt. buline)
    setPay('cash', Number(d.cash) || 0);
    setPay('bank', Number(d.bank) || 0);

    stepMethod.classList.add('hidden');
    stepConfirm.classList.remove('hidden');
    buyEl.classList.remove('hidden');
  }

  function setPay(which, amount) {
    var enough = amount >= buyPrice;
    var dot = document.getElementById('dot-' + which);
    var btn = document.getElementById('pay-' + which);
    var amt = document.getElementById('amt-' + which);
    dot.className = 'dot ' + (enough ? 'ok' : 'no');
    btn.disabled = !enough;
    amt.textContent = fmtMoney(amount);
  }

  function closeBuy() { buyEl.classList.add('hidden'); }

  document.getElementById('buy-no').addEventListener('click', function () { closeBuy(); post('buyCancel'); });
  document.getElementById('buy-cancel').addEventListener('click', function () { closeBuy(); post('buyCancel'); });
  document.getElementById('buy-yes').addEventListener('click', function () {
    stepConfirm.classList.add('hidden');
    stepMethod.classList.remove('hidden');
  });
  document.getElementById('pay-cash').addEventListener('click', function () {
    if (this.disabled) return;
    closeBuy(); post('buyPay', { method: 'cash' });
  });
  document.getElementById('pay-bank').addEventListener('click', function () {
    if (this.disabled) return;
    closeBuy(); post('buyPay', { method: 'bank' });
  });
  document.addEventListener('keyup', function (e) {
    if (e.key === 'Escape' && !buyEl.classList.contains('hidden')) { closeBuy(); post('buyCancel'); }
  });

  window.addEventListener('message', function (e) {
    var msg = e.data || {};
    if (msg.action === 'houses') render(msg.list);
    else if (msg.action === 'prompt') setPrompt(msg.text);
    else if (msg.action === 'buyOpen') openBuy(msg.data || {});
    else if (msg.action === 'buyClose') closeBuy();
  });

  /* preview in browser */
  if (isBrowser) {
    render([
      { houseId: 3, x: 0.5, y: 0.55, owner: 'ADMBOT', price: 250000, interior: 'High End House 1 (3655 Wild Oats Drive)' },
    ]);
    setPrompt('for enter home');
    openBuy({ houseId: 12, ownerLabel: 'State', price: 250000, cash: 40000, bank: 900000 });
  }
})();
