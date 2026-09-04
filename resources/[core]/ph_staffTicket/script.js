// Baza de date locală simulată pentru Tickete
let ticketsData = [
  {
    id: 101,
    playerName: "Cristi",
    playerId: "28861",
    time: "01:19",
    reason: "parere no fear + pov + suferinte ooc",
    status: "active", // "active" sau "mine"
    messages: [
      { sender: "Cristi", text: "buna, am o problema cu un player la cazinou", time: "01:19", isStaff: false },
      { sender: "Cristi", text: "parere no fear + pov + suferinte ooc", time: "01:20", isStaff: false }
    ]
  },
  {
    id: 102,
    playerName: "Mihai_13",
    playerId: "11950",
    time: "03:45",
    reason: "dc numi dispar cosurile si cicatricile",
    status: "active",
    messages: [
      { sender: "Mihai_13", text: "dc numi dispar cosurile si cicatricile de pe fata?", time: "03:45", isStaff: false }
    ]
  },
  {
    id: 103,
    playerName: "Alex_Vip",
    playerId: "14433",
    time: "10:07",
    reason: "E BLOCATA CALEA LA MINA MARE",
    status: "mine",
    messages: [
      { sender: "Alex_Vip", text: "e blocata calea cu un camion tir la mina", time: "10:07", isStaff: false },
      { sender: "BabyAdy (Owner)", text: "Salut! Ma celeport acum sa rezolv.", time: "10:08", isStaff: true }
    ]
  }
];

let activeTicketId = null;

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  renderTickets();
  initChatActions();
});

// Schimbarea Secțiunilor
function initNavigation() {
  const navButtons = document.querySelectorAll('.nav-btn');
  const sections = document.querySelectorAll('.content-section');

  navButtons.forEach(button => {
    button.addEventListener('click', () => {
      const targetId = button.getAttribute('data-target');

      navButtons.forEach(btn => btn.classList.remove('active'));
      button.classList.add('active');

      sections.forEach(sec => sec.classList.add('hidden'));
      document.getElementById(targetId).classList.remove('hidden');
    });
  });

  document.getElementById('btn-back-tickets').addEventListener('click', () => {
    document.getElementById('ticket-chat-view').classList.add('hidden');
    document.getElementById('tickete-active').classList.remove('hidden');
  });
}

// Randarea Ticketelor în Liste
function renderTickets() {
  const activeList = document.getElementById('active-tickets-list');
  const myList = document.getElementById('my-tickets-list');

  activeList.innerHTML = '';
  myList.innerHTML = '';

  let activeCount = 0;
  let myCount = 0;

  ticketsData.forEach(ticket => {
    const card = document.createElement('div');
    card.className = "bg-[#18122c]/80 border border-purple-900/40 hover:border-purple-500/50 p-4 rounded-xl flex items-center justify-between cursor-pointer transition-all";
    
    card.innerHTML = `
      <div class="flex items-center gap-4">
        <div class="w-10 h-10 rounded-lg bg-purple-950/60 border border-purple-800/40 flex items-center justify-center text-purple-400 font-bold">
          <i class="fa-solid fa-circle-question"></i>
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h4 class="font-bold text-white">${ticket.playerName}</h4>
            <span class="text-xs text-gray-500">ID: ${ticket.playerId}</span>
            <span class="text-[10px] bg-purple-900/40 text-purple-300 px-2 py-0.5 rounded">${ticket.time}</span>
          </div>
          <p class="text-xs text-gray-400 mt-1">${ticket.reason}</p>
        </div>
      </div>
      <button class="bg-purple-900/40 hover:bg-purple-600 text-purple-200 p-2.5 rounded-xl border border-purple-500/30 transition-all">
        <i class="fa-solid fa-eye"></i>
      </button>
    `;

    card.addEventListener('click', () => openTicketChat(ticket.id));

    if (ticket.status === 'active') {
      activeList.appendChild(card);
      activeCount++;
    } else if (ticket.status === 'mine') {
      myList.appendChild(card);
      myCount++;
    }
  });

  // Actualizare Badges
  document.getElementById('badge-active').innerText = activeCount;
  document.getElementById('badge-mele').innerText = myCount;
}

// Deschiderea Chat-ului pentru un Ticket Selectat
function openTicketChat(ticketId) {
  const ticket = ticketsData.find(t => t.id === ticketId);
  if (!ticket) return;

  activeTicketId = ticketId;

  // Setare Date Header
  document.getElementById('chat-player-name').innerText = ticket.playerName;
  document.getElementById('chat-player-id').innerText = `ID: ${ticket.playerId}`;
  document.getElementById('chat-ticket-reason').innerText = ticket.reason;

  // Stare Butoane Jos (Preia / Scrie)
  const claimBar = document.getElementById('claim-ticket-bar');
  const inputBar = document.getElementById('chat-input-bar');

  if (ticket.status === 'active') {
    claimBar.classList.remove('hidden');
    inputBar.classList.add('hidden');
  } else {
    claimBar.classList.add('hidden');
    inputBar.classList.remove('hidden');
  }

  renderMessages(ticket.messages);

  // Afișare Secțiune Chat
  document.querySelectorAll('.content-section').forEach(sec => sec.classList.add('hidden'));
  document.getElementById('ticket-chat-view').classList.remove('hidden');
}

// Randarea Mesajelor din Chat
function renderMessages(messages) {
  const chatContainer = document.getElementById('chat-messages');
  chatContainer.innerHTML = '';

  messages.forEach(msg => {
    const msgDiv = document.createElement('div');
    msgDiv.className = `flex flex-col ${msg.isStaff ? 'items-end' : 'items-start'}`;

    msgDiv.innerHTML = `
      <span class="text-[10px] text-gray-500 mb-1 px-1">${msg.sender} • ${msg.time}</span>
      <div class="px-4 py-2.5 max-w-[70%] text-sm text-gray-200 ${msg.isStaff ? 'chat-bubble-staff' : 'chat-bubble-player'}">
        ${msg.text}
      </div>
    `;

    chatContainer.appendChild(msgDiv);
  });

  chatContainer.scrollTop = chatContainer.scrollHeight;
}

// Acțiuni Chat (Preia, Trimite, Închide)
function initChatActions() {
  // Preluare Ticket
  document.getElementById('btn-claim-ticket').addEventListener('click', () => {
    const ticket = ticketsData.find(t => t.id === activeTicketId);
    if (ticket) {
      ticket.status = 'mine';
      ticket.messages.push({
        sender: "Sistem",
        text: "BabyAdy a preluat acest ticket.",
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        isStaff: true
      });

      renderTickets();
      openTicketChat(activeTicketId);
    }
  });

  // Trimitere Mesaj
  const sendMsg = () => {
    const input = document.getElementById('chat-input');
    const text = input.value.trim();
    if (!text || !activeTicketId) return;

    const ticket = ticketsData.find(t => t.id === activeTicketId);
    if (ticket) {
      ticket.messages.push({
        sender: "BabyAdy (Owner)",
        text: text,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        isStaff: true
      });

      input.value = '';
      renderMessages(ticket.messages);
    }
  };

  document.getElementById('btn-send-msg').addEventListener('click', sendMsg);
  document.getElementById('chat-input').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendMsg();
  });

  // Închidere Ticket
  document.getElementById('btn-close-ticket').addEventListener('click', () => {
    if (!activeTicketId) return;

    ticketsData = ticketsData.filter(t => t.id !== activeTicketId);
    
    // Incrementare contor lunar
    const countEl = document.getElementById('monthly-count');
    countEl.innerText = parseInt(countEl.innerText) + 1;

    renderTickets();
    document.getElementById('btn-back-tickets').click();
  });
}