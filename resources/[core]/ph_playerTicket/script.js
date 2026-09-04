// Baza de date simulată pentru Tichetele Jucătorului
let playerTickets = [
  {
    id: 101,
    category: "Report Player",
    reason: "parere no fear + pov + suferinte ooc",
    time: "01:19",
    status: "In pending", // "In Asteptare", "Preluat", "Inchis"
    messages: [
      { sender: "You (BabyAdy)", text: "buna, am o problema cu un player la cazinou", time: "01:19", isStaff: false },
      { sender: "You (BabyAdy)", text: "parere no fear + pov + suferinte ooc", time: "01:20", isStaff: false }
    ]
  }
];

let activePlayerTicketId = null;

document.addEventListener('DOMContentLoaded', () => {
  initPlayerNavigation();
  renderPlayerTickets();
  initFormAndChat();
});

// Schimbare Pagini Meniu
function initPlayerNavigation() {
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

  document.getElementById('btn-back-player-list').addEventListener('click', () => {
    document.getElementById('player-chat-view').classList.add('hidden');
    document.getElementById('my-tickets').classList.remove('hidden');
  });
}

// Afișare Lista de Tichete create
function renderPlayerTickets() {
  const container = document.getElementById('player-tickets-list');
  container.innerHTML = '';

  document.getElementById('player-badge-count').innerText = playerTickets.length;

  if (playerTickets.length === 0) {
    container.innerHTML = `<p class="text-center text-gray-500 py-8">You do not have any open tickets at this time.</p>`;
    return;
  }

  playerTickets.forEach(ticket => {
    const item = document.createElement('div');
    item.className = "bg-[#18122c]/80 border border-purple-900/40 hover:border-purple-500/50 p-4 rounded-xl flex items-center justify-between cursor-pointer transition-all";
    
    let statusClass = "bg-purple-900/40 text-purple-300 border-purple-800/40";
    if (ticket.status === 'Preluat') statusClass = "bg-emerald-950 text-emerald-400 border-emerald-800/40";

    item.innerHTML = `
      <div class="flex items-center gap-4">
        <div class="w-10 h-10 rounded-lg bg-purple-950/60 border border-purple-800/40 flex items-center justify-center text-purple-400 font-bold">
          <i class="fa-solid fa-headset"></i>
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h4 class="font-bold text-white">${ticket.category}</h4>
            <span class="text-[10px] px-2 py-0.5 rounded border ${statusClass}">${ticket.status}</span>
            <span class="text-[10px] text-gray-500">${ticket.time}</span>
          </div>
          <p class="text-xs text-gray-400 mt-1 truncate max-w-[350px]">${ticket.reason}</p>
        </div>
      </div>
      <button class="bg-purple-900/40 hover:bg-purple-600 text-purple-200 p-2.5 rounded-xl border border-purple-500/30 transition-all">
        <i class="fa-solid fa-comments"></i>
      </button>
    `;

    item.addEventListener('click', () => openPlayerChat(ticket.id));
    container.appendChild(item);
  });
}

// Trimitere Formular & Creare Ticket Nou
function initFormAndChat() {
  const form = document.getElementById('ticket-form');
  
  form.addEventListener('submit', (e) => {
    e.preventDefault();

    const category = document.getElementById('ticket-category').value;
    const reason = document.getElementById('ticket-reason').value.trim();

    if (!reason) return;

    const newTicket = {
      id: Date.now(),
      category: category,
      reason: reason,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      status: "In pending",
      messages: [
        {
          sender: "You (BabyAdy)",
          text: reason,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          isStaff: false
        }
      ]
    };

    playerTickets.unshift(newTicket);
    document.getElementById('ticket-reason').value = '';

    renderPlayerTickets();

    // Navighează automat la My Tickets
    document.querySelector('[data-target="my-tickets"]').click();
  });

  // Trimitere Mesaj în Chat
  const sendPlayerMsg = () => {
    const input = document.getElementById('player-chat-input');
    const text = input.value.trim();
    if (!text || !activePlayerTicketId) return;

    const ticket = playerTickets.find(t => t.id === activePlayerTicketId);
    if (ticket) {
      ticket.messages.push({
        sender: "BabyAdy (You)",
        text: text,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        isStaff: false
      });

      input.value = '';
      renderPlayerChatMessages(ticket.messages);
    }
  };

  document.getElementById('btn-player-send').addEventListener('click', sendPlayerMsg);
  document.getElementById('player-chat-input').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendPlayerMsg();
  });

  // Închidere Ticket de către Player
  document.getElementById('btn-player-close').addEventListener('click', () => {
    if (!activePlayerTicketId) return;

    playerTickets = playerTickets.filter(t => t.id !== activePlayerTicketId);
    renderPlayerTickets();
    document.getElementById('btn-back-player-list').click();
  });
}

// Deschiderea Chatului de către Jucător
function openPlayerChat(ticketId) {
  const ticket = playerTickets.find(t => t.id === ticketId);
  if (!ticket) return;

  activePlayerTicketId = ticketId;

  document.getElementById('view-ticket-category').innerText = ticket.category;
  document.getElementById('view-ticket-status').innerText = ticket.status;
  document.getElementById('view-ticket-desc').innerText = ticket.reason;

  renderPlayerChatMessages(ticket.messages);

  document.querySelectorAll('.content-section').forEach(sec => sec.classList.add('hidden'));
  document.getElementById('player-chat-view').classList.remove('hidden');
}

// Randarea Mesajelor
function renderPlayerChatMessages(messages) {
  const container = document.getElementById('player-chat-messages');
  container.innerHTML = '';

  messages.forEach(msg => {
    const msgDiv = document.createElement('div');
    // Mesajele staff-ului vin pe dreapta (sau stânga în funcție de rol)
    msgDiv.className = `flex flex-col ${msg.isStaff ? 'items-start' : 'items-end'}`;

    msgDiv.innerHTML = `
      <span class="text-[10px] text-gray-500 mb-1 px-1">${msg.sender} • ${msg.time}</span>
      <div class="px-4 py-2.5 max-w-[70%] text-sm text-gray-200 ${msg.isStaff ? 'chat-bubble-player border-purple-500/40' : 'chat-bubble-staff'}">
        ${msg.text}
      </div>
    `;

    container.appendChild(msgDiv);
  });

  container.scrollTop = container.scrollHeight;
}