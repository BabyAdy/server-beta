(function () {
  'use strict';

  var isBrowser = typeof window.GetParentResourceName !== 'function';
  var RES = isBrowser ? 'rpg-drivingschool' : window.GetParentResourceName();
  var $ = function (s) { return document.querySelector(s); };

  function post(name, body) {
    if (isBrowser) return Promise.resolve({});
    return fetch('https://' + RES + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {}),
    }).catch(function () {});
  }

  var state = { questions: [], idx: 0, answers: [] };

  function renderQuestion() {
    var q = state.questions[state.idx];
    if (!q) return;

    $('#q-num').textContent = state.idx + 1;
    $('#q-total').textContent = state.questions.length;
    $('#q-text').textContent = q.text;

    var box = $('#q-answers');
    box.innerHTML = '';
    (q.answers || []).forEach(function (label, i) {
      var btn = document.createElement('button');
      btn.className = 'ans-btn';
      btn.type = 'button';
      btn.textContent = label;
      btn.addEventListener('click', function () { pick(i + 1, btn); });
      box.appendChild(btn);
    });

    // progres = intrebari deja RASPUNSE (0% la prima intrebare, 100% dupa a 5-a)
    var pct = (state.idx / state.questions.length) * 100;
    $('#prog-fill').style.width = pct + '%';
  }

  function pick(answerIndex, btn) {
    // fara feedback corect/gresit -- doar marcam alegerea si avansam
    var box = $('#q-answers');
    Array.prototype.forEach.call(box.children, function (b) { b.disabled = true; });
    btn.classList.add('picked');

    state.answers[state.idx] = answerIndex;

    setTimeout(function () {
      state.idx++;
      if (state.idx >= state.questions.length) {
        finish();
      } else {
        renderQuestion();
      }
    }, 280);
  }

  function finish() {
    $('#prog-fill').style.width = '100%';
    post('submitTheory', { answers: state.answers });
    setTimeout(function () {
      $('#quiz').classList.add('hidden');
    }, 150);
  }

  window.addEventListener('message', function (e) {
    var msg = e.data || {};
    if (msg.action === 'openTheory') {
      state.questions = msg.questions || [];
      state.idx = 0;
      state.answers = [];
      $('#quiz').classList.remove('hidden');
      renderQuestion();
    }
  });

  /* preview in browser */
  if (isBrowser) {
    document.body.classList.add('preview');
    window.dispatchEvent(new MessageEvent('message', {
      data: {
        action: 'openTheory',
        questions: [
          { text: 'Care este limita de viteză cu care poți circula pe autostradă?', answers: ['100 km/h', '120 km/h', '70 km/h', 'Nu există limită'] },
          { text: 'Ce faci dacă ești somat de un polițist pentru a trage pe dreapta?', answers: ['Fug', 'Îl împușc și îi zic "Sit câine"', 'Îi fac reclamație pe UCP', 'Trag pe dreapta și mă conformez'] },
        ],
      },
    }));
  }
})();
