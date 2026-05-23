// ═══════════════════════════════════════════════
// FLEXCORE — Frontend Logic (Full CRUD)
// Ultra-minimalist Admin Dashboard
// ═══════════════════════════════════════════════

// --- AUTHENTICATION CHECK ---
const token = localStorage.getItem('token');
if (!token && !window.location.pathname.includes('login.html')) {
    window.location.href = 'login.html';
}

// --- GLOBAL FETCH INTERCEPTOR FOR AUTH ---
const originalFetch = window.fetch;
window.fetch = async function () {
    let [resource, config] = arguments;
    if (!config) config = {};
    if (!config.headers) config.headers = {};
    
    // Sadece /api/ isteklerine token ekle
    if (typeof resource === 'string' && resource.includes('/api/')) {
        config.headers['Authorization'] = `Bearer ${token}`;
    }
    
    const response = await originalFetch(resource, config);
    if (response.status === 401 || response.status === 403) {
        // Token expired or invalid
        localStorage.removeItem('token');
        window.location.href = 'login.html';
    }
    return response;
};

// --- LOGOUT & USER INITIALIZATION ---
function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('username');
    localStorage.removeItem('role');
    window.location.href = 'login.html';
}

document.addEventListener('DOMContentLoaded', () => {
    const uname = localStorage.getItem('username');
    if (uname) {
        const avatarStr = uname.substring(0, 2).toUpperCase();
        const avatarEl = document.getElementById('userAvatar');
        if (avatarEl) avatarEl.textContent = avatarStr;
    }
});

const API = 'http://localhost:3000/api';
let allMembers = [];
let memberFilterVal = 'all';
let pendingDeleteCb = null;

// ─── SAAT ───
function startClock() {
  const el = document.getElementById('clock');
  const tick = () => {
    const now = new Date();
    el.textContent = now.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
  };
  tick(); setInterval(tick, 1000);
}

// ─── NAVİGASYON ───
const breadcrumbs = {
  dashboard: 'Genel Bakış',
  members: 'Üyeler',
  trainers: 'Eğitmenler',
  schedule: 'Ders Programı',
  payments: 'Ödemeler',
  equipment: 'Ekipman'
};

function goTo(page) {
  document.querySelectorAll('.rail-item').forEach(li => li.classList.remove('active'));
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const li = document.querySelector(`.rail-item[data-page="${page}"]`);
  const pg = document.getElementById('page-' + page);
  if (li) li.classList.add('active');
  if (pg) pg.classList.add('active');
  document.getElementById('breadcrumb').textContent = breadcrumbs[page] || page;
  if (page === 'trainers')  loadTrainers();
  if (page === 'payments')  loadPayments();
  if (page === 'equipment') loadEquipment();
  if (page === 'schedule') {
    const active = document.querySelector('.day-chip.active');
    loadSchedule(active ? active.dataset.day : 'Pazartesi');
  }
}

document.querySelectorAll('.rail-item[data-page]').forEach(li => {
  li.addEventListener('click', () => goTo(li.dataset.page));
});

// ─── THEME TOGGLE ───
const themeToggleBtn = document.getElementById('themeToggle');
const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
const savedTheme = localStorage.getItem('theme');
const currentTheme = savedTheme || (prefersDark ? 'dark' : 'light');

document.documentElement.setAttribute('data-theme', currentTheme);

if (themeToggleBtn) {
  themeToggleBtn.innerHTML = currentTheme === 'dark' ? '<i class="fas fa-sun"></i>' : '<i class="fas fa-moon"></i>';
  themeToggleBtn.addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const newTheme = isDark ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    themeToggleBtn.innerHTML = newTheme === 'dark' ? '<i class="fas fa-sun"></i>' : '<i class="fas fa-moon"></i>';
  });
}

// ─── FORM YARDIMCILARI ───
function showForm(id) {
  const el = document.getElementById(id);
  el.classList.add('open');
  el.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
function hideForm(id) {
  document.getElementById(id).classList.remove('open');
}
function showAddForm() { showForm('addMemberForm'); loadPackages(); }
function showPaymentForm() { showForm('addPaymentForm'); loadUyelerSelect(); }

// ─── DASHBOARD ───
async function loadDashboard() {
  try {
    const [stats, girisler, bitenler] = await Promise.all([
      fetch(`${API}/dashboard`).then(r => r.json()),
      fetch(`${API}/dashboard/son-girisler`).then(r => r.json()),
      fetch(`${API}/dashboard/bitis-yaklasan`).then(r => r.json())
    ]);
    animateNumber('stat-uye', stats.toplam_uye);
    animateNumber('stat-uyelik', stats.aktif_uyelik);
    animateNumber('stat-egitmen', stats.toplam_egitmen);
    document.getElementById('stat-gelir').textContent = '₺' + Number(stats.aylik_gelir).toLocaleString('tr-TR');

    const currentOcc = stats.icerideki_uye || 0;
    const maxOcc = 100;
    const occPercent = Math.min(Math.round((currentOcc / maxOcc) * 100), 100);
    const occCurEl = document.querySelector('.occupancy-current');
    if (occCurEl) occCurEl.textContent = currentOcc;
    const occMaxEl = document.querySelector('.occupancy-max');
    if (occMaxEl) occMaxEl.textContent = maxOcc;
    const occFillEl = document.querySelector('.progress-fill');
    if (occFillEl) occFillEl.style.width = occPercent + '%';

    const girisBody = document.getElementById('recentEntriesBody');
    girisBody.innerHTML = !girisler.length
      ? '<div class="loading-row">Giriş kaydı bulunamadı</div>'
      : girisler.map(g => `
          <div class="mini-row">
            <div class="mini-row-left">
              <div class="mini-row-avatar">${g.ad[0]}${g.soyad[0]}</div>
              <div>
                <div class="mini-row-name">${g.ad} ${g.soyad}</div>
                <div class="mini-row-time">${formatDateTime(g.giris_zamani)}</div>
              </div>
            </div>
            <span class="badge blue">${g.giris_yontemi}</span>
          </div>`).join('');

    const bitenBody = document.getElementById('expiringBody');
    bitenBody.innerHTML = !bitenler.length
      ? '<tr><td colspan="3" class="empty-row">Yaklaşan bitiş yok</td></tr>'
      : bitenler.map(b => `
          <tr>
            <td class="name-cell">${b.ad} ${b.soyad}</td>
            <td>${b.paket_adi}</td>
            <td><span class="badge ${b.kalan_gun <= 3 ? 'red' : 'orange'}">${b.kalan_gun} gün</span></td>
          </tr>`).join('');
  } catch (err) { console.error('Dashboard yüklenemedi:', err); }
}

function animateNumber(id, target) {
  const el = document.getElementById(id);
  if (!el) return;
  const dur = 600, t0 = performance.now();
  const step = now => {
    const p = Math.min((now - t0) / dur, 1);
    const eased = 1 - Math.pow(1 - p, 3);
    el.textContent = Math.round(target * eased);
    if (p < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

// ═══════════════════════════════════════════════
// ÜYELER
// ═══════════════════════════════════════════════
async function loadAndStoreMembers() {
  try {
    allMembers = await fetch(`${API}/uyeler`).then(r => r.json());
    renderMembers(allMembers);
  } catch (err) {
    document.getElementById('membersBody').innerHTML = '<tr><td colspan="7" class="empty-row">Sunucu bağlantı hatası</td></tr>';
  }
}

function setFilter(btn, val) {
  document.querySelectorAll('.seg').forEach(s => s.classList.remove('active'));
  btn.classList.add('active');
  memberFilterVal = val;
  renderMembers(allMembers);
}

function renderMembers(members) {
  const search = document.getElementById('memberSearch')?.value?.toLowerCase() || '';
  let list = [...members];
  if (memberFilterVal === 'Aktif') list = list.filter(m => m.uyelik_durum === 'Aktif');
  else if (memberFilterVal === 'Süresi Dolmuş') list = list.filter(m => m.uyelik_durum !== 'Aktif');
  if (search) list = list.filter(m => `${m.ad} ${m.soyad}`.toLowerCase().includes(search));

  const body = document.getElementById('membersBody');
  if (!list.length) { body.innerHTML = '<tr><td colspan="7" class="empty-row">Kayıt bulunamadı</td></tr>'; return; }

  body.innerHTML = list.map(m => {
    const durum = m.uyelik_durum || 'Pasif';
    const bc = durum === 'Aktif' ? 'green' : durum === 'Süresi Dolmuş' ? 'orange' : 'red';
    return `<tr>
      <td class="name-cell">${m.ad} ${m.soyad}</td>
      <td class="mono-cell">${m.tc_kimlik}</td>
      <td>${m.telefon}</td>
      <td>${m.paket_adi || '—'}</td>
      <td class="muted-cell">${m.bitis_tarihi ? formatDate(m.bitis_tarihi) : '—'}</td>
      <td><span class="badge ${bc}">${durum}</span></td>
      <td><button class="del-btn" onclick="confirmDel('${m.ad} ${m.soyad} üyesini silmek istiyor musunuz?', () => deleteMember(${m.uye_id}, '${m.ad} ${m.soyad}'))"><i class="fas fa-trash-can"></i></button></td>
    </tr>`;
  }).join('');
}

async function loadPackages() {
  try {
    const paketler = await fetch(`${API}/paketler`).then(r => r.json());
    document.getElementById('inp_paket').innerHTML =
      '<option value="">Paket Seçin</option>' +
      paketler.map(p => `<option value="${p.paket_id}">${p.paket_adi} — ₺${Number(p.fiyat).toLocaleString('tr-TR')}</option>`).join('');
  } catch (err) { console.error(err); }
}

async function addMember(e) {
  e.preventDefault();
  const btn = e.target.querySelector('[type=submit]');
  setLoading(btn, true);
  const data = {
    tc_kimlik: v('inp_tc'), ad: v('inp_ad'), soyad: v('inp_soyad'),
    cinsiyet: v('inp_cinsiyet'), dogum_tarihi: v('inp_dogum'),
    telefon: v('inp_tel'), email: v('inp_email'), adres: v('inp_adres'),
    paket_id: parseInt(v('inp_paket')), odeme_yontemi: v('inp_odeme') || 'Nakit',
    kayit_tarihi: v('inp_kayit') || null
  };
  try {
    const res = await fetch(`${API}/uyeler`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data) });
    const result = await res.json();
    if (res.ok) {
      showToast(`${data.ad} ${data.soyad} başarıyla eklendi`);
      hideForm('addMemberForm'); e.target.reset();
      loadAndStoreMembers(); loadDashboard();
    } else { showToast(result.error || 'Hata oluştu', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
  finally { setLoading(btn, false, '<i class="fas fa-check"></i> Kaydet'); }
}

async function deleteMember(id, name) {
  try {
    const res = await fetch(`${API}/uyeler/${id}`, { method:'DELETE' });
    if (res.ok) { showToast(`${name} silindi`); loadAndStoreMembers(); loadDashboard(); }
    else { const r = await res.json(); showToast(r.error || 'Silme hatası', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
}

// ═══════════════════════════════════════════════
// EĞİTMENLER
// ═══════════════════════════════════════════════
async function loadTrainers() {
  try {
    const trainers = await fetch(`${API}/egitimenler`).then(r => r.json());
    document.getElementById('trainersGrid').innerHTML = !trainers.length
      ? '<div class="loading-row" style="padding:40px">Henüz eğitmen kaydı yok</div>'
      : trainers.map(t => {
          const tags = (t.uzmanliklar || '').split(', ').filter(Boolean);
          return `
            <div class="trainer-card">
              <div class="trainer-top">
                <div class="trainer-avatar">${t.ad[0]}${t.soyad[0]}</div>
                <div class="trainer-info">
                  <div class="trainer-name">${t.ad} ${t.soyad}</div>
                  <div class="trainer-exp">${t.deneyim_yili} yıl deneyim</div>
                </div>
              </div>
              <div class="trainer-detail">
                ${t.sertifikalar ? `<div class="trainer-certs"><i class="fas fa-award"></i> ${t.sertifikalar}</div>` : ''}
                <div class="trainer-meta">
                  ${t.telefon ? `<span><i class="fas fa-phone"></i> ${t.telefon}</span>` : ''}
                  ${t.email ? `<span><i class="fas fa-envelope"></i> ${t.email}</span>` : ''}
                </div>
              </div>
              <div class="tag-list">${tags.map(u => `<span class="tag">${u}</span>`).join('')}</div>
              <div class="trainer-actions">
                <button class="del-btn" onclick="confirmDel('${t.ad} ${t.soyad} eğitmenini pasife almak istiyor musunuz?', () => deleteTrainer(${t.egitmen_id}, '${t.ad} ${t.soyad}'))">
                  <i class="fas fa-trash-can"></i> Kaldır
                </button>
              </div>
            </div>`;
        }).join('');
  } catch (err) { console.error(err); }
}

async function loadUzmanliklar() {
  try {
    const uzmanliklar = await fetch(`${API}/uzmanliklar`).then(r => r.json());
    document.getElementById('uzmanlik_checkboxes').innerHTML = uzmanliklar.map(u =>
      `<label class="check-item">
        <input type="checkbox" name="uzmanlik" value="${u.uzmanlik_id}">
        <span>${u.uzmanlik_adi}</span>
      </label>`
    ).join('');
  } catch (err) { console.error(err); }
}

async function addTrainer(e) {
  e.preventDefault();
  const btn = e.target.querySelector('[type=submit]');
  setLoading(btn, true);
  const uzmanlik_ids = [...document.querySelectorAll('input[name="uzmanlik"]:checked')].map(c => parseInt(c.value));
  const data = {
    tc_kimlik: v('t_tc'), ad: v('t_ad'), soyad: v('t_soyad'),
    telefon: v('t_tel'), email: v('t_email'),
    deneyim_yili: v('t_deneyim') || 0, sertifikalar: v('t_sertifika'),
    maas: v('t_maas') || null, ise_baslama_tarihi: v('t_baslama'),
    uzmanlik_ids
  };
  try {
    const res = await fetch(`${API}/egitimenler`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data) });
    const result = await res.json();
    if (res.ok) {
      showToast(`${data.ad} ${data.soyad} eklendi`);
      hideForm('addTrainerForm'); e.target.reset();
      loadTrainers(); loadDashboard();
    } else { showToast(result.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
  finally { setLoading(btn, false, '<i class="fas fa-check"></i> Eğitmeni Kaydet'); }
}

async function deleteTrainer(id, name) {
  try {
    const res = await fetch(`${API}/egitimenler/${id}`, { method:'DELETE' });
    if (res.ok) { showToast(`${name} pasife alındı`); loadTrainers(); loadDashboard(); }
    else { const r = await res.json(); showToast(r.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
}

// ═══════════════════════════════════════════════
// DERS PROGRAMI
// ═══════════════════════════════════════════════
let activeDay = 'Pazartesi';

async function loadScheduleDropdowns() {
  try {
    const [dersler, egitimenler, salonlar] = await Promise.all([
      fetch(`${API}/dersler`).then(r => r.json()),
      fetch(`${API}/egitimenler`).then(r => r.json()),
      fetch(`${API}/salonlar`).then(r => r.json())
    ]);
    document.getElementById('s_ders').innerHTML = '<option value="">Ders Seçin</option>' +
      dersler.map(d => `<option value="${d.ders_id}">${d.ders_adi} (${d.sure_dakika} dk)</option>`).join('');
    document.getElementById('s_egitmen').innerHTML = '<option value="">Eğitmen Seçin</option>' +
      egitimenler.map(e => `<option value="${e.egitmen_id}">${e.ad} ${e.soyad}</option>`).join('');
    document.getElementById('s_salon').innerHTML = '<option value="">Salon Seçin</option>' +
      salonlar.map(s => `<option value="${s.salon_id}">${s.salon_adi} (${s.kapasite} kişi)</option>`).join('');
  } catch (err) { console.error(err); }
}

async function loadSchedule(day = 'Pazartesi') {
  activeDay = day;
  const grid = document.getElementById('scheduleGrid');
  grid.innerHTML = '<div class="loading-row" style="padding:40px;text-align:center"><i class="fas fa-spinner fa-spin"></i></div>';
  try {
    const classes = await fetch(`${API}/ders-programi?gun=${encodeURIComponent(day)}`).then(r => r.json());
    if (!classes.length) {
      grid.innerHTML = '<div class="loading-row" style="padding:40px;text-align:center;color:var(--text-tertiary)"><i class="fas fa-calendar-xmark" style="font-size:20px;margin-bottom:8px;display:block"></i>Bu gün ders yok</div>';
      return;
    }
    const accentColors = ['#0044FF','#059669','#D97706','#7C3AED','#DC2626','#0891B2','#65A30D'];
    grid.innerHTML = classes.map((c, i) => `
      <div class="class-card" style="border-left-color:${accentColors[i % accentColors.length]}">
        <div class="class-time"><i class="fas fa-clock"></i> ${formatTime(c.baslangic_saati)} – ${formatTime(c.bitis_saati)}</div>
        <div class="class-name">${c.ders_adi}</div>
        <div class="class-meta">
          <div class="class-meta-item"><i class="fas fa-user-tie"></i> ${c.egitmen}</div>
          <div class="class-meta-item"><i class="fas fa-location-dot"></i> ${c.salon_adi}</div>
          <div class="class-meta-item"><i class="fas fa-users"></i> Max ${c.max_katilimci} · ${c.seviye}</div>
        </div>
        <button class="del-btn" style="margin-top:12px" onclick="confirmDel('Bu ders programını silmek istiyor musunuz?', () => deleteSchedule(${c.program_id}))">
          <i class="fas fa-trash-can"></i> Kaldır
        </button>
      </div>`).join('');
  } catch (err) { console.error(err); }
}

document.querySelectorAll('.day-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    document.querySelectorAll('.day-chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    loadSchedule(chip.dataset.day);
  });
});

async function addSchedule(e) {
  e.preventDefault();
  const btn = e.target.querySelector('[type=submit]');
  setLoading(btn, true);
  const data = {
    ders_id: parseInt(v('s_ders')), egitmen_id: parseInt(v('s_egitmen')),
    salon_id: parseInt(v('s_salon')), gun: v('s_gun'),
    baslangic_saati: v('s_bas'), bitis_saati: v('s_bit')
  };
  try {
    const res = await fetch(`${API}/ders-programi`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data) });
    const result = await res.json();
    if (res.ok) {
      showToast('Ders programa eklendi');
      hideForm('addScheduleForm'); e.target.reset();
      loadSchedule(activeDay);
    } else { showToast(result.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
  finally { setLoading(btn, false, '<i class="fas fa-check"></i> Programa Ekle'); }
}

async function deleteSchedule(id) {
  try {
    const res = await fetch(`${API}/ders-programi/${id}`, { method:'DELETE' });
    if (res.ok) { showToast('Ders programdan kaldırıldı'); loadSchedule(activeDay); }
    else { const r = await res.json(); showToast(r.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
}

// ═══════════════════════════════════════════════
// ÖDEMELER
// ═══════════════════════════════════════════════
async function loadUyelerSelect() {
  try {
    const uyeler = await fetch(`${API}/uyeler/liste`).then(r => r.json());
    document.getElementById('p_uye').innerHTML = '<option value="">Üye Seçin</option>' +
      uyeler.map(u => `<option value="${u.uye_id}">${u.ad} ${u.soyad}</option>`).join('');
  } catch (err) { console.error(err); }
}

async function loadPayments() {
  try {
    const payments = await fetch(`${API}/odemeler`).then(r => r.json());
    document.getElementById('paymentsBody').innerHTML = !payments.length
      ? '<tr><td colspan="7" class="empty-row">Ödeme kaydı bulunamadı</td></tr>'
      : payments.map(p => `
          <tr>
            <td class="name-cell">${p.uye}</td>
            <td><strong class="amount-cell">₺${Number(p.tutar).toLocaleString('tr-TR')}</strong></td>
            <td class="muted-cell">${p.odeme_yontemi}</td>
            <td><span class="badge purple">${p.odeme_turu}</span></td>
            <td class="muted-cell">${formatDate(p.odeme_tarihi)}</td>
            <td><span class="badge ${p.durum==='Tamamlandı'?'green':'orange'}">${p.durum}</span></td>
            <td><button class="del-btn" onclick="confirmDel('Bu ödeme kaydını silmek istiyor musunuz?', () => deletePayment(${p.odeme_id}))"><i class="fas fa-trash-can"></i></button></td>
          </tr>`).join('');
  } catch (err) { console.error(err); }
}

async function addPayment(e) {
  e.preventDefault();
  const btn = e.target.querySelector('[type=submit]');
  setLoading(btn, true);
  const data = {
    uye_id: parseInt(v('p_uye')), tutar: parseFloat(v('p_tutar')),
    odeme_yontemi: v('p_yontem'), odeme_turu: v('p_tur'), aciklama: v('p_aciklama')
  };
  try {
    const res = await fetch(`${API}/odemeler`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data) });
    const result = await res.json();
    if (res.ok) {
      showToast('Ödeme kaydedildi');
      hideForm('addPaymentForm'); e.target.reset();
      loadPayments(); loadDashboard();
    } else { showToast(result.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
  finally { setLoading(btn, false, '<i class="fas fa-check"></i> Ödemeyi Kaydet'); }
}

async function deletePayment(id) {
  try {
    const res = await fetch(`${API}/odemeler/${id}`, { method:'DELETE' });
    if (res.ok) { showToast('Ödeme silindi'); loadPayments(); loadDashboard(); }
    else { const r = await res.json(); showToast(r.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
}

// ═══════════════════════════════════════════════
// EKİPMANLAR
// ═══════════════════════════════════════════════
async function loadSalonlarSelect() {
  try {
    const salonlar = await fetch(`${API}/salonlar`).then(r => r.json());
    document.getElementById('e_salon').innerHTML = '<option value="">Salon Seçin</option>' +
      salonlar.map(s => `<option value="${s.salon_id}">${s.salon_adi}</option>`).join('');
  } catch (err) { console.error(err); }
}

async function loadEquipment() {
  try {
    const equip = await fetch(`${API}/ekipmanlar`).then(r => r.json());
    document.getElementById('equipmentGrid').innerHTML = !equip.length
      ? '<div class="loading-row" style="padding:40px">Ekipman kaydı bulunamadı</div>'
      : equip.map(e => {
          const sc = e.durum === 'Aktif' ? 'green' : e.durum === 'Bakımda' ? 'orange' : 'red';
          return `
            <div class="equip-card">
              <div class="equip-header">
                <div class="equip-name">${e.ekipman_adi}</div>
                <span class="badge ${sc}">${e.durum}</span>
              </div>
              <div class="equip-brand">${e.marka_model?.trim() || '—'}</div>
              <div class="equip-footer">
                <span class="equip-salon"><i class="fas fa-location-dot"></i> ${e.salon_adi}</span>
                <button class="del-btn" onclick="confirmDel('${e.ekipman_adi} ekipmanını silmek istiyor musunuz?', () => deleteEquipment(${e.ekipman_id}, '${e.ekipman_adi}'))">
                  <i class="fas fa-trash-can"></i>
                </button>
              </div>
            </div>`;
        }).join('');
  } catch (err) { console.error(err); }
}

async function addEquipment(e) {
  e.preventDefault();
  const btn = e.target.querySelector('[type=submit]');
  setLoading(btn, true);
  const data = {
    salon_id: parseInt(v('e_salon')), ekipman_adi: v('e_ad'),
    marka: v('e_marka'), model: v('e_model'), satin_alma_tarihi: v('e_tarih')
  };
  try {
    const res = await fetch(`${API}/ekipmanlar`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data) });
    const result = await res.json();
    if (res.ok) {
      showToast('Ekipman eklendi');
      hideForm('addEquipmentForm'); e.target.reset();
      loadEquipment();
    } else { showToast(result.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
  finally { setLoading(btn, false, '<i class="fas fa-check"></i> Ekipmanı Kaydet'); }
}

async function deleteEquipment(id, name) {
  try {
    const res = await fetch(`${API}/ekipmanlar/${id}`, { method:'DELETE' });
    if (res.ok) { showToast(`${name} silindi`); loadEquipment(); }
    else { const r = await res.json(); showToast(r.error || 'Hata', true); }
  } catch { showToast('Sunucu bağlantı hatası', true); }
}

// ═══════════════════════════════════════════════
// CONFIRM MODAL
// ═══════════════════════════════════════════════
function confirmDel(msg, cb) {
  pendingDeleteCb = cb;
  document.getElementById('confirmMsg').textContent = msg;
  document.getElementById('confirmOverlay').classList.add('open');
}
function closeConfirm() {
  document.getElementById('confirmOverlay').classList.remove('open');
  pendingDeleteCb = null;
}
document.getElementById('confirmYes').addEventListener('click', () => {
  if (pendingDeleteCb) { pendingDeleteCb(); closeConfirm(); }
});
document.getElementById('confirmOverlay').addEventListener('click', e => {
  if (e.target === e.currentTarget) closeConfirm();
});

// ═══════════════════════════════════════════════
// YARDIMCILAR
// ═══════════════════════════════════════════════
const v = id => document.getElementById(id)?.value?.trim() || '';

function setLoading(btn, on, offHtml = '') {
  if (on) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'; }
  else { btn.disabled = false; btn.innerHTML = offHtml; }
}

function showToast(msg, isError = false) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = 'toast show' + (isError ? ' error' : '');
  clearTimeout(t._timer);
  t._timer = setTimeout(() => { t.className = 'toast'; }, 3000);
}

function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('tr-TR', { day:'2-digit', month:'2-digit', year:'numeric' });
}
function formatDateTime(d) {
  if (!d) return '—';
  const dt = new Date(d);
  return dt.toLocaleDateString('tr-TR', { day:'2-digit', month:'2-digit' }) + ' ' +
    dt.toLocaleTimeString('tr-TR', { hour:'2-digit', minute:'2-digit' });
}
function formatTime(t) {
  if (!t) return '';
  if (t.includes('T')) return new Date(t).toLocaleTimeString('tr-TR', { hour:'2-digit', minute:'2-digit' });
  return t.substring(0, 5);
}

// ─── BAŞLAT ───
document.addEventListener('DOMContentLoaded', () => {
  startClock();
  loadDashboard();
  loadAndStoreMembers();
  loadScheduleDropdowns();
  loadUzmanliklar();
  loadSalonlarSelect();
});
