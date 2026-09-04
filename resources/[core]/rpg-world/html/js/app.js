(function () {
  'use strict';
  var $ = function (s) { return document.querySelector(s); };

  window.addEventListener('message', function (e) {
    var msg = e.data || {};
    if (msg.action === 'show') {
      $('#nc-bar').classList.remove('hidden');
    } else if (msg.action === 'hide') {
      $('#nc-bar').classList.add('hidden');
    } else if (msg.action === 'speed') {
      $('#nc-speed').textContent = msg.name || 'Normal';
    }
  });

  /* preview in browser */
  if (typeof window.GetParentResourceName !== 'function') {
    document.addEventListener('DOMContentLoaded', function () {
      $('#nc-bar').classList.remove('hidden');
    });
  }
})();
