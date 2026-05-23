# FlexCore — Spor Salonu Otomasyonu 🏋️

FlexCore, modern ve ultra-minimalist bir tasarıma sahip, tam kapsamlı bir Spor Salonu Otomasyon Sistemidir. Node.js arka ucu ve Microsoft SQL Server veritabanı ile çalışır.

## Özellikler ✨

- **Ultra-Minimalist Arayüz:** Linear ve Vercel'den ilham alınan, dikkat dağıtmayan kurumsal frontend mimarisi.
- **Koyu Mod (Dark Mode):** Otomatik karanlık/aydınlık tema algılama ve geçiş butonu.
- **Dinamik Gösterge Paneli (Dashboard):** Gerçek zamanlı doluluk oranları, yaklaşan üyelik bitişleri, aylık gelir hesaplaması ve son giriş kayıtları.
- **Üye Yönetimi:** Yeni üye ekleme, listeleme, paket belirleme ve ödeme takibi. Özel kayıt tarihi atayabilme.
- **Eğitmen & Ders Programı:** Eğitmenleri ve detaylı ders programlarını veritabanı ile senkronize yönetme.

## Kullanılan Teknolojiler 🛠️

- **Frontend:** HTML5, Vanilla CSS (CSS Variables, Grid/Flexbox), Vanilla JS (DOM Manipülasyonu, Fetch API)
- **Backend:** Node.js, Express.js
- **Veritabanı:** Microsoft SQL Server (MSSQL), Tedious

## Kurulum 🚀

1. Bu depoyu klonlayın:
   ```bash
   git clone <repo-url>
   cd "Veri Tabanı"
   ```

2. Gerekli paketleri yükleyin:
   ```bash
   npm install
   ```

3. Veritabanınızı (MSSQL) yapılandırın:
   - `spor_salonu_veritabani.sql` dosyasını SSMS veya Azure Data Studio üzerinde çalıştırarak veritabanınızı oluşturun.
   - `server.js` dosyasındaki `config` değişkenini kendi veritabanı şifrenizle (`Eowkai57`) ve sunucunuzla uyumlu olacak şekilde güncelleyin.

4. Sunucuyu başlatın:
   ```bash
   npm start
   ```

5. Tarayıcınızdan uygulamayı açın:
   [http://localhost:3000](http://localhost:3000)

---
*Geliştirme amacıyla oluşturulmuş bir tam kapsamlı eğitim ve otomasyon projesidir.*
