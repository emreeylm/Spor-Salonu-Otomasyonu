const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

const dbConfig = {
    user: 'sa',
    password: 'Eowkai57',
    server: 'localhost',
    port: 1433,
    database: 'sporotomasyon',
    options: { encrypt: false, trustServerCertificate: true, enableArithAbort: true },
    connectionTimeout: 30000,
    requestTimeout: 30000
};

let pool;
async function connectDB() {
    try {
        pool = await sql.connect(dbConfig);
        console.log('✅ MSSQL veritabanına bağlanıldı!');
    } catch (err) {
        console.error('❌ Veritabanı bağlantı hatası:', err.message);
        process.exit(1);
    }
}

// =============================================
// DASHBOARD
// =============================================
app.get('/api/dashboard', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT
                (SELECT COUNT(*) FROM UYELER) AS toplam_uye,
                (SELECT COUNT(*) FROM UYELIKLER WHERE durum = N'Aktif') AS aktif_uyelik,
                (SELECT COUNT(*) FROM EGITIMENLER WHERE durum = N'Aktif') AS toplam_egitmen,
                (SELECT ISNULL(SUM(tutar),0) FROM ODEMELER WHERE durum=N'Tamamlandı') AS aylik_gelir,
                (SELECT COUNT(*) FROM GIRIS_CIKIS WHERE cikis_zamani IS NULL) AS icerideki_uye,
                (SELECT ISNULL(SUM(kapasite), 300) FROM SALONLAR) AS toplam_kapasite
        `);
        res.json(result.recordset[0]);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/dashboard/son-girisler', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT TOP 5 u.ad, u.soyad, gc.giris_zamani, gc.giris_yontemi
            FROM GIRIS_CIKIS gc INNER JOIN UYELER u ON gc.uye_id = u.uye_id
            ORDER BY gc.giris_zamani DESC
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/dashboard/bitis-yaklasan', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT u.ad, u.soyad, p.paket_adi, ul.bitis_tarihi,
                   DATEDIFF(DAY, CAST(GETDATE() AS DATE), ul.bitis_tarihi) AS kalan_gun
            FROM UYELER u
            INNER JOIN UYELIKLER ul ON u.uye_id = ul.uye_id
            INNER JOIN UYELIK_PAKETLERI p ON ul.paket_id = p.paket_id
            WHERE ul.durum = N'Aktif'
              AND DATEDIFF(DAY, CAST(GETDATE() AS DATE), ul.bitis_tarihi) BETWEEN 0 AND 30
            ORDER BY ul.bitis_tarihi
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// =============================================
// ÜYELER
// =============================================
app.get('/api/uyeler', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT u.uye_id, u.tc_kimlik, u.ad, u.soyad, u.cinsiyet,
                   u.telefon, u.email, u.durum AS uye_durum,
                   p.paket_adi, ul.bitis_tarihi, ul.durum AS uyelik_durum
            FROM UYELER u
            LEFT JOIN UYELIKLER ul ON u.uye_id = ul.uye_id
                AND ul.uyelik_id = (SELECT MAX(uyelik_id) FROM UYELIKLER WHERE uye_id = u.uye_id)
            LEFT JOIN UYELIK_PAKETLERI p ON ul.paket_id = p.paket_id
            ORDER BY u.uye_id
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/paketler', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT paket_id, paket_adi, sure_gun, fiyat
            FROM UYELIK_PAKETLERI WHERE durum = N'Aktif' ORDER BY fiyat
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/uyeler/liste', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT uye_id, ad, soyad FROM UYELER WHERE durum = N'Aktif' ORDER BY ad
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/uyeler', async (req, res) => {
    try {
        const { tc_kimlik, ad, soyad, cinsiyet, dogum_tarihi, telefon, email, adres, paket_id, odeme_yontemi, kayit_tarihi } = req.body;
        const result = await pool.request()
            .input('p_tc', sql.Char(11), tc_kimlik)
            .input('p_ad', sql.NVarChar(50), ad)
            .input('p_soyad', sql.NVarChar(50), soyad)
            .input('p_cinsiyet', sql.NVarChar(10), cinsiyet)
            .input('p_dogum', sql.Date, dogum_tarihi || null)
            .input('p_telefon', sql.NVarChar(15), telefon)
            .input('p_email', sql.NVarChar(100), email || null)
            .input('p_adres', sql.NVarChar(sql.MAX), adres || null)
            .input('p_paket_id', sql.Int, paket_id)
            .input('p_odeme_yontemi', sql.NVarChar(15), odeme_yontemi || 'Nakit')
            .input('p_kayit_tarihi', sql.DateTime, kayit_tarihi ? new Date(kayit_tarihi) : null)
            .execute('SP_YENI_UYE_KAYIT');
        res.json({ success: true, data: result.recordset[0] });
    } catch (err) { res.status(400).json({ error: err.message }); }
});

app.delete('/api/uyeler/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        await pool.request().input('id', sql.Int, id).query('DELETE FROM VUCUT_OLCUMLERI WHERE uye_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM DERS_KATILIM WHERE uye_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM RANDEVULAR WHERE uye_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM GIRIS_CIKIS WHERE uye_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM ODEMELER WHERE uye_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM UYELIKLER WHERE uye_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM UYELER WHERE uye_id = @id');
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// =============================================
// EĞİTMENLER
// =============================================
app.get('/api/egitimenler', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT e.egitmen_id, e.ad, e.soyad, e.telefon, e.email,
                   e.deneyim_yili, e.sertifikalar, e.maas, e.ise_baslama_tarihi,
                   STRING_AGG(ua.uzmanlik_adi, ', ') AS uzmanliklar
            FROM EGITIMENLER e
            LEFT JOIN EGITMEN_UZMANLIKLAR eu ON e.egitmen_id = eu.egitmen_id
            LEFT JOIN UZMANLIK_ALANLARI ua ON eu.uzmanlik_id = ua.uzmanlik_id
            WHERE e.durum = N'Aktif'
            GROUP BY e.egitmen_id, e.ad, e.soyad, e.telefon, e.email,
                     e.deneyim_yili, e.sertifikalar, e.maas, e.ise_baslama_tarihi
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/uzmanliklar', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT uzmanlik_id, uzmanlik_adi FROM UZMANLIK_ALANLARI ORDER BY uzmanlik_adi
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/egitimenler', async (req, res) => {
    try {
        const { tc_kimlik, ad, soyad, telefon, email, deneyim_yili, sertifikalar, maas, ise_baslama_tarihi, uzmanlik_ids } = req.body;
        const r = await pool.request()
            .input('tc', sql.Char(11), tc_kimlik)
            .input('ad', sql.NVarChar(50), ad)
            .input('soyad', sql.NVarChar(50), soyad)
            .input('telefon', sql.NVarChar(15), telefon)
            .input('email', sql.NVarChar(100), email || null)
            .input('deneyim', sql.Int, parseInt(deneyim_yili) || 0)
            .input('sertifika', sql.NVarChar(sql.MAX), sertifikalar || null)
            .input('maas', sql.Decimal(10, 2), parseFloat(maas) || null)
            .input('baslama', sql.Date, ise_baslama_tarihi || null)
            .query(`
                INSERT INTO EGITIMENLER (tc_kimlik, ad, soyad, telefon, email, deneyim_yili, sertifikalar, maas, ise_baslama_tarihi)
                VALUES (@tc, @ad, @soyad, @telefon, @email, @deneyim, @sertifika, @maas, @baslama);
                SELECT SCOPE_IDENTITY() AS egitmen_id;
            `);
        const egitmen_id = r.recordset[0].egitmen_id;
        if (uzmanlik_ids && uzmanlik_ids.length > 0) {
            for (const uid of uzmanlik_ids) {
                await pool.request()
                    .input('eid', sql.Int, egitmen_id)
                    .input('uid', sql.Int, uid)
                    .query('INSERT INTO EGITMEN_UZMANLIKLAR (egitmen_id, uzmanlik_id) VALUES (@eid, @uid)');
            }
        }
        res.json({ success: true, egitmen_id });
    } catch (err) { res.status(400).json({ error: err.message }); }
});

app.delete('/api/egitimenler/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        await pool.request().input('id', sql.Int, id).query('DELETE FROM EGITMEN_UZMANLIKLAR WHERE egitmen_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM DERS_PROGRAMI WHERE egitmen_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM RANDEVULAR WHERE egitmen_id = @id');
        await pool.request().input('id', sql.Int, id).query(`UPDATE EGITIMENLER SET durum = N'Pasif' WHERE egitmen_id = @id`);
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// =============================================
// DERS PROGRAMI
// =============================================
app.get('/api/ders-programi', async (req, res) => {
    try {
        const day = req.query.gun || 'Pazartesi';
        const result = await pool.request()
            .input('gun', sql.NVarChar(15), day)
            .query(`
                SELECT dp.program_id, dp.baslangic_saati, dp.bitis_saati,
                       d.ders_adi, d.max_katilimci, d.seviye,
                       (e.ad + ' ' + e.soyad) AS egitmen, s.salon_adi, dp.gun
                FROM DERS_PROGRAMI dp
                INNER JOIN DERSLER d ON dp.ders_id = d.ders_id
                INNER JOIN EGITIMENLER e ON dp.egitmen_id = e.egitmen_id
                INNER JOIN SALONLAR s ON dp.salon_id = s.salon_id
                WHERE dp.gun = @gun AND dp.durum = N'Aktif'
                ORDER BY dp.baslangic_saati
            `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/dersler', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT ders_id, ders_adi, sure_dakika, max_katilimci, seviye
            FROM DERSLER WHERE durum = N'Aktif' ORDER BY ders_adi
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/salonlar', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT salon_id, salon_adi, kapasite FROM SALONLAR WHERE durum = N'Aktif' ORDER BY salon_adi
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/ders-programi', async (req, res) => {
    try {
        const { ders_id, egitmen_id, salon_id, gun, baslangic_saati, bitis_saati } = req.body;
        await pool.request()
            .input('ders_id', sql.Int, ders_id)
            .input('egitmen_id', sql.Int, egitmen_id)
            .input('salon_id', sql.Int, salon_id)
            .input('gun', sql.NVarChar(15), gun)
            .input('bas', sql.NVarChar(10), baslangic_saati)
            .input('bit', sql.NVarChar(10), bitis_saati)
            .query(`
                INSERT INTO DERS_PROGRAMI (ders_id, egitmen_id, salon_id, gun, baslangic_saati, bitis_saati, durum)
                VALUES (@ders_id, @egitmen_id, @salon_id, @gun, @bas, @bit, N'Aktif')
            `);
        res.json({ success: true });
    } catch (err) { res.status(400).json({ error: err.message }); }
});

app.delete('/api/ders-programi/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        await pool.request().input('id', sql.Int, id).query('DELETE FROM DERS_KATILIM WHERE program_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM DERS_PROGRAMI WHERE program_id = @id');
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// =============================================
// ÖDEMELER
// =============================================
app.get('/api/odemeler', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT o.odeme_id, o.uye_id, (u.ad + ' ' + u.soyad) AS uye,
                   o.tutar, o.odeme_yontemi, o.odeme_turu, o.odeme_tarihi, o.durum
            FROM ODEMELER o INNER JOIN UYELER u ON o.uye_id = u.uye_id
            ORDER BY o.odeme_tarihi DESC
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/odemeler', async (req, res) => {
    try {
        const { uye_id, tutar, odeme_yontemi, odeme_turu, aciklama } = req.body;
        await pool.request()
            .input('uye_id', sql.Int, uye_id)
            .input('tutar', sql.Decimal(10, 2), parseFloat(tutar))
            .input('yontem', sql.NVarChar(15), odeme_yontemi)
            .input('tur', sql.NVarChar(10), odeme_turu)
            .input('aciklama', sql.NVarChar(sql.MAX), aciklama || null)
            .query(`
                INSERT INTO ODEMELER (uye_id, tutar, odeme_yontemi, odeme_turu, aciklama, durum)
                VALUES (@uye_id, @tutar, @yontem, @tur, @aciklama, N'Tamamlandı')
            `);
        res.json({ success: true });
    } catch (err) { res.status(400).json({ error: err.message }); }
});

app.delete('/api/odemeler/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        await pool.request().input('id', sql.Int, id).query('DELETE FROM ODEMELER WHERE odeme_id = @id');
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// =============================================
// EKİPMANLAR
// =============================================
app.get('/api/ekipmanlar', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT ek.ekipman_id, ek.ekipman_adi, ek.marka, ek.model,
                   (ISNULL(ek.marka,'') + ' ' + ISNULL(ek.model,'')) AS marka_model,
                   s.salon_id, s.salon_adi, ek.durum,
                   (SELECT MAX(eb.bakim_tarihi) FROM EKIPMAN_BAKIM eb WHERE eb.ekipman_id = ek.ekipman_id) AS son_bakim
            FROM EKIPMANLAR ek INNER JOIN SALONLAR s ON ek.salon_id = s.salon_id
            ORDER BY s.salon_adi, ek.ekipman_adi
        `);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/ekipmanlar', async (req, res) => {
    try {
        const { salon_id, ekipman_adi, marka, model, satin_alma_tarihi } = req.body;
        await pool.request()
            .input('salon_id', sql.Int, salon_id)
            .input('ad', sql.NVarChar(100), ekipman_adi)
            .input('marka', sql.NVarChar(100), marka || null)
            .input('model', sql.NVarChar(100), model || null)
            .input('tarih', sql.Date, satin_alma_tarihi || null)
            .query(`
                INSERT INTO EKIPMANLAR (salon_id, ekipman_adi, marka, model, satin_alma_tarihi, durum)
                VALUES (@salon_id, @ad, @marka, @model, @tarih, N'Aktif')
            `);
        res.json({ success: true });
    } catch (err) { res.status(400).json({ error: err.message }); }
});

app.delete('/api/ekipmanlar/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        await pool.request().input('id', sql.Int, id).query('DELETE FROM EKIPMAN_BAKIM WHERE ekipman_id = @id');
        await pool.request().input('id', sql.Int, id).query('DELETE FROM EKIPMANLAR WHERE ekipman_id = @id');
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// =============================================
// SUNUCUYU BAŞLAT
// =============================================
const PORT = 3000;
connectDB().then(() => {
    app.listen(PORT, () => {
        console.log(`🏋️  Spor Salonu API → http://localhost:${PORT}`);
        console.log(`📊  Dashboard    → http://localhost:${PORT}/index.html`);
    });
});
