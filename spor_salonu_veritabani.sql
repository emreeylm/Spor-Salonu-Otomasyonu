-- =============================================
-- SPOR SALONU OTOMASYON SİSTEMİ
-- Microsoft SQL Server (MSSQL) Veritabanı Betikleri
-- =============================================

-- Veritabanı oluşturma
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'sporotomasyon')
    CREATE DATABASE sporotomasyon;
GO

USE sporotomasyon;
GO

-- =============================================
-- 1. TABLOLAR
-- =============================================

-- 1.1 UYELER Tablosu
CREATE TABLE UYELER (
    uye_id INT IDENTITY(1,1) PRIMARY KEY,
    tc_kimlik CHAR(11) NOT NULL,
    ad NVARCHAR(50) NOT NULL,
    soyad NVARCHAR(50) NOT NULL,
    cinsiyet NVARCHAR(10) NOT NULL,
    dogum_tarihi DATE NOT NULL,
    telefon NVARCHAR(15) NOT NULL,
    email NVARCHAR(100),
    adres NVARCHAR(MAX),
    kayit_tarihi DATETIME DEFAULT GETDATE(),
    durum NVARCHAR(20) DEFAULT N'Aktif',
    CONSTRAINT UQ_UYELER_TC UNIQUE (tc_kimlik),
    CONSTRAINT UQ_UYELER_EMAIL UNIQUE (email),
    CONSTRAINT CHK_TC_UZUNLUK CHECK (LEN(tc_kimlik) = 11),
    CONSTRAINT CHK_CINSIYET CHECK (cinsiyet IN (N'Erkek', N'Kadın')),
    CONSTRAINT CHK_UYE_DURUM CHECK (durum IN (N'Aktif', N'Pasif', N'Dondurulmuş'))
);

-- Mevcut veritabanında gereksiz kolonları kaldır (zaten oluşturulmuşsa çalıştır)
-- ALTER TABLE UYELER DROP COLUMN acil_kisi_ad;
-- ALTER TABLE UYELER DROP COLUMN acil_kisi_telefon;
-- ALTER TABLE UYELER DROP COLUMN saglik_durumu;
-- ALTER TABLE UYELER DROP COLUMN profil_foto;

-- 1.2 UYELIK_PAKETLERI Tablosu
CREATE TABLE UYELIK_PAKETLERI (
    paket_id INT IDENTITY(1,1) PRIMARY KEY,
    paket_adi NVARCHAR(100) NOT NULL,
    sure_gun INT NOT NULL,
    fiyat DECIMAL(10, 2) NOT NULL,
    aciklama NVARCHAR(MAX),
    max_giris_sayisi INT DEFAULT NULL,
    durum NVARCHAR(10) DEFAULT N'Aktif',
    olusturma_tarihi DATETIME DEFAULT GETDATE(),
    CONSTRAINT CHK_SURE CHECK (sure_gun > 0),
    CONSTRAINT CHK_FIYAT CHECK (fiyat > 0),
    CONSTRAINT CHK_PAKET_DURUM CHECK (durum IN (N'Aktif', N'Pasif'))
);

-- 1.3 HIZMETLER Tablosu
CREATE TABLE HIZMETLER (
    hizmet_id INT IDENTITY(1,1) PRIMARY KEY,
    hizmet_adi NVARCHAR(100) NOT NULL,
    aciklama NVARCHAR(MAX),
    durum NVARCHAR(10) DEFAULT N'Aktif',
    CONSTRAINT CHK_HIZMET_DURUM CHECK (durum IN (N'Aktif', N'Pasif'))
);

-- 1.4 PAKET_HIZMETLER Tablosu (M:N ilişki)
CREATE TABLE PAKET_HIZMETLER (
    paket_hizmet_id INT IDENTITY(1,1) PRIMARY KEY,
    paket_id INT NOT NULL,
    hizmet_id INT NOT NULL,
    CONSTRAINT FK_PH_PAKET FOREIGN KEY (paket_id) REFERENCES UYELIK_PAKETLERI(paket_id),
    CONSTRAINT FK_PH_HIZMET FOREIGN KEY (hizmet_id) REFERENCES HIZMETLER(hizmet_id),
    CONSTRAINT UQ_PAKET_HIZMET UNIQUE (paket_id, hizmet_id)
);

-- 1.5 KAMPANYALAR Tablosu
CREATE TABLE KAMPANYALAR (
    kampanya_id INT IDENTITY(1,1) PRIMARY KEY,
    kampanya_adi NVARCHAR(150) NOT NULL,
    indirim_orani DECIMAL(5, 2) NOT NULL,
    baslangic_tarihi DATE NOT NULL,
    bitis_tarihi DATE NOT NULL,
    aciklama NVARCHAR(MAX),
    durum NVARCHAR(10) DEFAULT N'Aktif',
    CONSTRAINT CHK_INDIRIM CHECK (indirim_orani > 0 AND indirim_orani <= 100),
    CONSTRAINT CHK_KAMPANYA_TARIH CHECK (bitis_tarihi > baslangic_tarihi),
    CONSTRAINT CHK_KAMPANYA_DURUM CHECK (durum IN (N'Aktif', N'Pasif'))
);

-- 1.6 UYELIKLER Tablosu
CREATE TABLE UYELIKLER (
    uyelik_id INT IDENTITY(1,1) PRIMARY KEY,
    uye_id INT NOT NULL,
    paket_id INT NOT NULL,
    kampanya_id INT DEFAULT NULL,
    baslangic_tarihi DATE NOT NULL,
    bitis_tarihi DATE NOT NULL,
    kalan_giris INT DEFAULT NULL,
    durum NVARCHAR(20) DEFAULT N'Aktif',
    olusturma_tarihi DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_UYELIK_UYE FOREIGN KEY (uye_id) REFERENCES UYELER(uye_id),
    CONSTRAINT FK_UYELIK_PAKET FOREIGN KEY (paket_id) REFERENCES UYELIK_PAKETLERI(paket_id),
    CONSTRAINT FK_UYELIK_KAMPANYA FOREIGN KEY (kampanya_id) REFERENCES KAMPANYALAR(kampanya_id),
    CONSTRAINT CHK_UYELIK_TARIH CHECK (bitis_tarihi > baslangic_tarihi),
    CONSTRAINT CHK_UYELIK_DURUM CHECK (durum IN (N'Aktif', N'Pasif', N'Süresi Dolmuş', N'İptal'))
);

-- 1.7 PERSONEL Tablosu
CREATE TABLE PERSONEL (
    personel_id INT IDENTITY(1,1) PRIMARY KEY,
    tc_kimlik CHAR(11) NOT NULL,
    ad NVARCHAR(50) NOT NULL,
    soyad NVARCHAR(50) NOT NULL,
    pozisyon NVARCHAR(100) NOT NULL,
    telefon NVARCHAR(15) NOT NULL,
    email NVARCHAR(100),
    maas DECIMAL(10, 2),
    ise_baslama_tarihi DATE NOT NULL,
    durum NVARCHAR(10) DEFAULT N'Aktif',
    CONSTRAINT UQ_PERSONEL_TC UNIQUE (tc_kimlik),
    CONSTRAINT CHK_PERSONEL_DURUM CHECK (durum IN (N'Aktif', N'Pasif'))
);

-- 1.8 EGITIMENLER Tablosu
CREATE TABLE EGITIMENLER (
    egitmen_id INT IDENTITY(1,1) PRIMARY KEY,
    tc_kimlik CHAR(11) NOT NULL,
    ad NVARCHAR(50) NOT NULL,
    soyad NVARCHAR(50) NOT NULL,
    telefon NVARCHAR(15) NOT NULL,
    email NVARCHAR(100),
    deneyim_yili INT DEFAULT 0,
    sertifikalar NVARCHAR(MAX),
    maas DECIMAL(10, 2),
    ise_baslama_tarihi DATE NOT NULL,
    durum NVARCHAR(10) DEFAULT N'Aktif',
    CONSTRAINT UQ_EGITMEN_TC UNIQUE (tc_kimlik),
    CONSTRAINT CHK_EGITMEN_DURUM CHECK (durum IN (N'Aktif', N'Pasif'))
);

-- 1.9 UZMANLIK_ALANLARI Tablosu
CREATE TABLE UZMANLIK_ALANLARI (
    uzmanlik_id INT IDENTITY(1,1) PRIMARY KEY,
    uzmanlik_adi NVARCHAR(100) NOT NULL,
    aciklama NVARCHAR(MAX)
);

-- 1.10 EGITMEN_UZMANLIKLAR Tablosu (M:N ilişki)
CREATE TABLE EGITMEN_UZMANLIKLAR (
    egitmen_uzmanlik_id INT IDENTITY(1,1) PRIMARY KEY,
    egitmen_id INT NOT NULL,
    uzmanlik_id INT NOT NULL,
    CONSTRAINT FK_EU_EGITMEN FOREIGN KEY (egitmen_id) REFERENCES EGITIMENLER(egitmen_id),
    CONSTRAINT FK_EU_UZMANLIK FOREIGN KEY (uzmanlik_id) REFERENCES UZMANLIK_ALANLARI(uzmanlik_id),
    CONSTRAINT UQ_EGITMEN_UZMANLIK UNIQUE (egitmen_id, uzmanlik_id)
);

-- 1.11 SALONLAR Tablosu
CREATE TABLE SALONLAR (
    salon_id INT IDENTITY(1,1) PRIMARY KEY,
    salon_adi NVARCHAR(100) NOT NULL,
    kapasite INT NOT NULL,
    alan_metrekare DECIMAL(8, 2),
    aciklama NVARCHAR(MAX),
    durum NVARCHAR(10) DEFAULT N'Aktif',
    CONSTRAINT CHK_KAPASITE CHECK (kapasite > 0),
    CONSTRAINT CHK_SALON_DURUM CHECK (durum IN (N'Aktif', N'Bakımda', N'Kapalı'))
);

-- 1.12 EKIPMANLAR Tablosu
CREATE TABLE EKIPMANLAR (
    ekipman_id INT IDENTITY(1,1) PRIMARY KEY,
    salon_id INT NOT NULL,
    ekipman_adi NVARCHAR(100) NOT NULL,
    marka NVARCHAR(100),
    model NVARCHAR(100),
    satin_alma_tarihi DATE,
    garanti_bitis DATE,
    durum NVARCHAR(20) DEFAULT N'Aktif',
    CONSTRAINT FK_EKIPMAN_SALON FOREIGN KEY (salon_id) REFERENCES SALONLAR(salon_id),
    CONSTRAINT CHK_EKIPMAN_DURUM CHECK (durum IN (N'Aktif', N'Arızalı', N'Bakımda', N'Hurdaya Ayrılmış'))
);

-- 1.13 EKIPMAN_BAKIM Tablosu
CREATE TABLE EKIPMAN_BAKIM (
    bakim_id INT IDENTITY(1,1) PRIMARY KEY,
    ekipman_id INT NOT NULL,
    personel_id INT NOT NULL,
    bakim_tarihi DATE NOT NULL,
    bakim_turu NVARCHAR(20) NOT NULL,
    aciklama NVARCHAR(MAX),
    maliyet DECIMAL(10, 2) DEFAULT 0,
    sonraki_bakim_tarihi DATE,
    CONSTRAINT FK_BAKIM_EKIPMAN FOREIGN KEY (ekipman_id) REFERENCES EKIPMANLAR(ekipman_id),
    CONSTRAINT FK_BAKIM_PERSONEL FOREIGN KEY (personel_id) REFERENCES PERSONEL(personel_id),
    CONSTRAINT CHK_BAKIM_TURU CHECK (bakim_turu IN (N'Periyodik', N'Arıza', N'Genel Kontrol'))
);

-- 1.14 DERSLER Tablosu
CREATE TABLE DERSLER (
    ders_id INT IDENTITY(1,1) PRIMARY KEY,
    ders_adi NVARCHAR(100) NOT NULL,
    aciklama NVARCHAR(MAX),
    sure_dakika INT NOT NULL DEFAULT 60,
    max_katilimci INT NOT NULL,
    seviye NVARCHAR(15) DEFAULT N'Başlangıç',
    durum NVARCHAR(10) DEFAULT N'Aktif',
    CONSTRAINT CHK_DERS_SURE CHECK (sure_dakika > 0),
    CONSTRAINT CHK_MAX_KATILIMCI CHECK (max_katilimci > 0),
    CONSTRAINT CHK_SEVIYE CHECK (seviye IN (N'Başlangıç', N'Orta', N'İleri')),
    CONSTRAINT CHK_DERS_DURUM CHECK (durum IN (N'Aktif', N'Pasif'))
);

-- 1.15 DERS_PROGRAMI Tablosu
CREATE TABLE DERS_PROGRAMI (
    program_id INT IDENTITY(1,1) PRIMARY KEY,
    ders_id INT NOT NULL,
    egitmen_id INT NOT NULL,
    salon_id INT NOT NULL,
    gun NVARCHAR(15) NOT NULL,
    baslangic_saati TIME NOT NULL,
    bitis_saati TIME NOT NULL,
    durum NVARCHAR(10) DEFAULT N'Aktif',
    CONSTRAINT FK_DP_DERS FOREIGN KEY (ders_id) REFERENCES DERSLER(ders_id),
    CONSTRAINT FK_DP_EGITMEN FOREIGN KEY (egitmen_id) REFERENCES EGITIMENLER(egitmen_id),
    CONSTRAINT FK_DP_SALON FOREIGN KEY (salon_id) REFERENCES SALONLAR(salon_id),
    CONSTRAINT CHK_SAAT CHECK (bitis_saati > baslangic_saati),
    CONSTRAINT CHK_GUN CHECK (gun IN (N'Pazartesi',N'Salı',N'Çarşamba',N'Perşembe',N'Cuma',N'Cumartesi',N'Pazar')),
    CONSTRAINT CHK_DP_DURUM CHECK (durum IN (N'Aktif', N'İptal'))
);

-- 1.16 DERS_KATILIM Tablosu
CREATE TABLE DERS_KATILIM (
    katilim_id INT IDENTITY(1,1) PRIMARY KEY,
    program_id INT NOT NULL,
    uye_id INT NOT NULL,
    katilim_tarihi DATE NOT NULL,
    durum NVARCHAR(15) DEFAULT N'Katıldı',
    CONSTRAINT FK_DK_PROGRAM FOREIGN KEY (program_id) REFERENCES DERS_PROGRAMI(program_id),
    CONSTRAINT FK_DK_UYE FOREIGN KEY (uye_id) REFERENCES UYELER(uye_id),
    CONSTRAINT CHK_KATILIM_DURUM CHECK (durum IN (N'Katıldı', N'Katılmadı', N'İptal'))
);

-- 1.17 RANDEVULAR Tablosu
CREATE TABLE RANDEVULAR (
    randevu_id INT IDENTITY(1,1) PRIMARY KEY,
    uye_id INT NOT NULL,
    egitmen_id INT NOT NULL,
    randevu_tarihi DATE NOT NULL,
    baslangic_saati TIME NOT NULL,
    bitis_saati TIME NOT NULL,
    tur NVARCHAR(20) NOT NULL DEFAULT N'PT',
    notlar NVARCHAR(MAX),
    durum NVARCHAR(15) DEFAULT N'Planlandı',
    olusturma_tarihi DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_RANDEVU_UYE FOREIGN KEY (uye_id) REFERENCES UYELER(uye_id),
    CONSTRAINT FK_RANDEVU_EGITMEN FOREIGN KEY (egitmen_id) REFERENCES EGITIMENLER(egitmen_id),
    CONSTRAINT CHK_RANDEVU_SAAT CHECK (bitis_saati > baslangic_saati),
    CONSTRAINT CHK_RANDEVU_TUR CHECK (tur IN (N'PT', N'Değerlendirme', N'Diyet Danışma')),
    CONSTRAINT CHK_RANDEVU_DURUM CHECK (durum IN (N'Planlandı', N'Tamamlandı', N'İptal', N'Gelmedi'))
);

-- 1.18 ODEMELER Tablosu
CREATE TABLE ODEMELER (
    odeme_id INT IDENTITY(1,1) PRIMARY KEY,
    uye_id INT NOT NULL,
    uyelik_id INT DEFAULT NULL,
    tutar DECIMAL(10, 2) NOT NULL,
    odeme_tarihi DATETIME DEFAULT GETDATE(),
    odeme_yontemi NVARCHAR(15) NOT NULL,
    odeme_turu NVARCHAR(10) NOT NULL DEFAULT N'Üyelik',
    aciklama NVARCHAR(MAX),
    durum NVARCHAR(15) DEFAULT N'Tamamlandı',
    CONSTRAINT FK_ODEME_UYE FOREIGN KEY (uye_id) REFERENCES UYELER(uye_id),
    CONSTRAINT FK_ODEME_UYELIK FOREIGN KEY (uyelik_id) REFERENCES UYELIKLER(uyelik_id),
    CONSTRAINT CHK_TUTAR CHECK (tutar > 0),
    CONSTRAINT CHK_ODEME_YONTEM CHECK (odeme_yontemi IN (N'Nakit', N'Kredi Kartı', N'Havale/EFT', N'Online')),
    CONSTRAINT CHK_ODEME_TUR CHECK (odeme_turu IN (N'Üyelik', N'PT', N'Ürün', N'Diğer')),
    CONSTRAINT CHK_ODEME_DURUM CHECK (durum IN (N'Tamamlandı', N'Beklemede', N'İade'))
);

-- 1.19 GIRIS_CIKIS Tablosu
CREATE TABLE GIRIS_CIKIS (
    kayit_id INT IDENTITY(1,1) PRIMARY KEY,
    uye_id INT NOT NULL,
    personel_id INT DEFAULT NULL,
    giris_zamani DATETIME NOT NULL DEFAULT GETDATE(),
    cikis_zamani DATETIME DEFAULT NULL,
    giris_yontemi NVARCHAR(15) DEFAULT N'Kart',
    CONSTRAINT FK_GC_UYE FOREIGN KEY (uye_id) REFERENCES UYELER(uye_id),
    CONSTRAINT FK_GC_PERSONEL FOREIGN KEY (personel_id) REFERENCES PERSONEL(personel_id),
    CONSTRAINT CHK_GIRIS_YONTEM CHECK (giris_yontemi IN (N'Kart', N'QR Kod', N'Parmak İzi', N'Manuel'))
);

-- 1.20 VUCUT_OLCUMLERI Tablosu
CREATE TABLE VUCUT_OLCUMLERI (
    olcum_id INT IDENTITY(1,1) PRIMARY KEY,
    uye_id INT NOT NULL,
    olcum_tarihi DATE NOT NULL,
    kilo DECIMAL(5, 2),
    boy DECIMAL(5, 2),
    bel DECIMAL(5, 2),
    gogus DECIMAL(5, 2),
    kalca DECIMAL(5, 2),
    kol DECIMAL(5, 2),
    bacak DECIMAL(5, 2),
    vucut_yag_orani DECIMAL(5, 2),
    kas_kutlesi DECIMAL(5, 2),
    notlar NVARCHAR(MAX),
    CONSTRAINT FK_OLCUM_UYE FOREIGN KEY (uye_id) REFERENCES UYELER(uye_id)
);

-- Log Tabloları
CREATE TABLE GIRIS_LOG (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    uye_id INT,
    giris_zamani DATETIME,
    sonuc NVARCHAR(50),
    mesaj NVARCHAR(MAX)
);

CREATE TABLE UYELIK_LOG (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    uyelik_id INT,
    eski_durum NVARCHAR(50),
    yeni_durum NVARCHAR(50),
    degisiklik_tarihi DATETIME DEFAULT GETDATE()
);

-- =============================================
-- 2. INDEX'LER
-- =============================================

CREATE INDEX IX_UYELER_AD_SOYAD ON UYELER(ad, soyad);
CREATE INDEX IX_UYELIKLER_TARIH ON UYELIKLER(baslangic_tarihi, bitis_tarihi);
CREATE INDEX IX_UYELIKLER_DURUM ON UYELIKLER(durum);
CREATE INDEX IX_ODEMELER_TARIH ON ODEMELER(odeme_tarihi);
CREATE INDEX IX_GIRIS_CIKIS_TARIH ON GIRIS_CIKIS(giris_zamani);
CREATE INDEX IX_RANDEVULAR_TARIH ON RANDEVULAR(randevu_tarihi);
CREATE INDEX IX_DERS_PROGRAMI_GUN ON DERS_PROGRAMI(gun, baslangic_saati);
GO

-- =============================================
-- 3. VIEW'LAR
-- =============================================

CREATE VIEW VW_AKTIF_UYELER AS
SELECT 
    u.uye_id, u.ad, u.soyad, u.telefon, u.email,
    ul.uyelik_id, p.paket_adi, ul.baslangic_tarihi, ul.bitis_tarihi,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), ul.bitis_tarihi) AS kalan_gun
FROM UYELER u
INNER JOIN UYELIKLER ul ON u.uye_id = ul.uye_id
INNER JOIN UYELIK_PAKETLERI p ON ul.paket_id = p.paket_id
WHERE ul.durum = N'Aktif' AND u.durum = N'Aktif';
GO

CREATE VIEW VW_UYELIK_DETAY AS
SELECT 
    u.ad, u.soyad, p.paket_adi, p.fiyat,
    ul.baslangic_tarihi, ul.bitis_tarihi, ul.durum AS uyelik_durum,
    STRING_AGG(h.hizmet_adi, ', ') AS dahil_hizmetler
FROM UYELIKLER ul
INNER JOIN UYELER u ON ul.uye_id = u.uye_id
INNER JOIN UYELIK_PAKETLERI p ON ul.paket_id = p.paket_id
LEFT JOIN PAKET_HIZMETLER ph ON p.paket_id = ph.paket_id
LEFT JOIN HIZMETLER h ON ph.hizmet_id = h.hizmet_id
GROUP BY ul.uyelik_id, u.ad, u.soyad, p.paket_adi, p.fiyat,
         ul.baslangic_tarihi, ul.bitis_tarihi, ul.durum;
GO

CREATE VIEW VW_GUNLUK_GIRIS_RAPORU AS
SELECT 
    CAST(gc.giris_zamani AS DATE) AS tarih,
    COUNT(*) AS toplam_giris,
    COUNT(gc.cikis_zamani) AS toplam_cikis,
    AVG(DATEDIFF(MINUTE, gc.giris_zamani, gc.cikis_zamani)) AS ort_sure_dakika
FROM GIRIS_CIKIS gc
GROUP BY CAST(gc.giris_zamani AS DATE);
GO

CREATE VIEW VW_EGITMEN_DERS_PROGRAMI AS
SELECT 
    e.ad AS egitmen_ad, e.soyad AS egitmen_soyad,
    d.ders_adi, dp.gun, dp.baslangic_saati, dp.bitis_saati,
    s.salon_adi, d.max_katilimci
FROM DERS_PROGRAMI dp
INNER JOIN EGITIMENLER e ON dp.egitmen_id = e.egitmen_id
INNER JOIN DERSLER d ON dp.ders_id = d.ders_id
INNER JOIN SALONLAR s ON dp.salon_id = s.salon_id
WHERE dp.durum = N'Aktif';
GO

CREATE VIEW VW_ODEME_OZETI AS
SELECT 
    YEAR(odeme_tarihi) AS yil,
    MONTH(odeme_tarihi) AS ay,
    odeme_yontemi,
    COUNT(*) AS islem_sayisi,
    SUM(tutar) AS toplam_tutar,
    AVG(tutar) AS ortalama_tutar
FROM ODEMELER
WHERE durum = N'Tamamlandı'
GROUP BY YEAR(odeme_tarihi), MONTH(odeme_tarihi), odeme_yontemi;
GO

CREATE VIEW VW_EKIPMAN_DURUM AS
SELECT 
    ek.ekipman_id, ek.ekipman_adi, ek.marka, ek.model,
    s.salon_adi, ek.durum,
    MAX(eb.bakim_tarihi) AS son_bakim_tarihi,
    MIN(eb.sonraki_bakim_tarihi) AS sonraki_bakim
FROM EKIPMANLAR ek
INNER JOIN SALONLAR s ON ek.salon_id = s.salon_id
LEFT JOIN EKIPMAN_BAKIM eb ON ek.ekipman_id = eb.ekipman_id
GROUP BY ek.ekipman_id, ek.ekipman_adi, ek.marka, ek.model, s.salon_adi, ek.durum;
GO

CREATE VIEW VW_UYELIK_BITIS_YAKLASAN AS
SELECT 
    u.uye_id, u.ad, u.soyad, u.telefon, u.email,
    p.paket_adi, ul.bitis_tarihi,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), ul.bitis_tarihi) AS kalan_gun
FROM UYELER u
INNER JOIN UYELIKLER ul ON u.uye_id = ul.uye_id
INNER JOIN UYELIK_PAKETLERI p ON ul.paket_id = p.paket_id
WHERE ul.durum = N'Aktif'
  AND DATEDIFF(DAY, CAST(GETDATE() AS DATE), ul.bitis_tarihi) BETWEEN 0 AND 7;
GO

-- =============================================
-- 4. STORED PROCEDURE'LER
-- =============================================

CREATE PROCEDURE SP_YENI_UYE_KAYIT
    @p_tc CHAR(11), @p_ad NVARCHAR(50), @p_soyad NVARCHAR(50),
    @p_cinsiyet NVARCHAR(10), @p_dogum DATE,
    @p_telefon NVARCHAR(15), @p_email NVARCHAR(100), @p_adres NVARCHAR(MAX),
    @p_paket_id INT, @p_odeme_yontemi NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_uye_id INT, @v_uyelik_id INT;
    DECLARE @v_fiyat DECIMAL(10,2), @v_sure INT;

    SELECT @v_fiyat = fiyat, @v_sure = sure_gun
    FROM UYELIK_PAKETLERI WHERE paket_id = @p_paket_id;

    INSERT INTO UYELER (tc_kimlik, ad, soyad, cinsiyet, dogum_tarihi, telefon, email, adres)
    VALUES (@p_tc, @p_ad, @p_soyad, @p_cinsiyet, @p_dogum, @p_telefon, @p_email, @p_adres);
    SET @v_uye_id = SCOPE_IDENTITY();

    INSERT INTO UYELIKLER (uye_id, paket_id, baslangic_tarihi, bitis_tarihi, durum)
    VALUES (@v_uye_id, @p_paket_id, CAST(GETDATE() AS DATE), DATEADD(DAY, @v_sure, CAST(GETDATE() AS DATE)), N'Aktif');
    SET @v_uyelik_id = SCOPE_IDENTITY();

    INSERT INTO ODEMELER (uye_id, uyelik_id, tutar, odeme_yontemi, odeme_turu)
    VALUES (@v_uye_id, @v_uyelik_id, @v_fiyat, @p_odeme_yontemi, N'Üyelik');

    SELECT @v_uye_id AS uye_id, @v_uyelik_id AS uyelik_id, N'Kayıt başarılı' AS mesaj;
END;
GO

CREATE PROCEDURE SP_UYELIK_YENILE
    @p_uye_id INT, @p_paket_id INT, @p_odeme_yontemi NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_fiyat DECIMAL(10,2), @v_sure INT, @v_uyelik_id INT;

    UPDATE UYELIKLER SET durum = N'Süresi Dolmuş'
    WHERE uye_id = @p_uye_id AND durum = N'Aktif';

    SELECT @v_fiyat = fiyat, @v_sure = sure_gun
    FROM UYELIK_PAKETLERI WHERE paket_id = @p_paket_id;

    INSERT INTO UYELIKLER (uye_id, paket_id, baslangic_tarihi, bitis_tarihi, durum)
    VALUES (@p_uye_id, @p_paket_id, CAST(GETDATE() AS DATE), DATEADD(DAY, @v_sure, CAST(GETDATE() AS DATE)), N'Aktif');
    SET @v_uyelik_id = SCOPE_IDENTITY();

    INSERT INTO ODEMELER (uye_id, uyelik_id, tutar, odeme_yontemi, odeme_turu)
    VALUES (@p_uye_id, @v_uyelik_id, @v_fiyat, @p_odeme_yontemi, N'Üyelik');

    SELECT N'Üyelik yenilendi' AS mesaj, @v_uyelik_id AS yeni_uyelik_id;
END;
GO

CREATE PROCEDURE SP_RANDEVU_OLUSTUR
    @p_uye_id INT, @p_egitmen_id INT,
    @p_tarih DATE, @p_bas TIME, @p_bit TIME,
    @p_tur NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_cakisma INT;

    SELECT @v_cakisma = COUNT(*) FROM RANDEVULAR
    WHERE egitmen_id = @p_egitmen_id AND randevu_tarihi = @p_tarih
      AND durum = N'Planlandı'
      AND ((baslangic_saati < @p_bit) AND (bitis_saati > @p_bas));

    IF @v_cakisma > 0
        THROW 50001, N'Bu saat aralığında eğitmenin başka randevusu var!', 1;
    ELSE
    BEGIN
        INSERT INTO RANDEVULAR (uye_id, egitmen_id, randevu_tarihi, baslangic_saati, bitis_saati, tur)
        VALUES (@p_uye_id, @p_egitmen_id, @p_tarih, @p_bas, @p_bit, @p_tur);
        SELECT SCOPE_IDENTITY() AS randevu_id, N'Randevu oluşturuldu' AS mesaj;
    END;
END;
GO

CREATE PROCEDURE SP_ODEME_AL
    @p_uye_id INT, @p_uyelik_id INT, @p_tutar DECIMAL(10,2),
    @p_yontem NVARCHAR(15), @p_tur NVARCHAR(10), @p_aciklama NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ODEMELER (uye_id, uyelik_id, tutar, odeme_yontemi, odeme_turu, aciklama)
    VALUES (@p_uye_id, @p_uyelik_id, @p_tutar, @p_yontem, @p_tur, @p_aciklama);
    SELECT SCOPE_IDENTITY() AS odeme_id, N'Ödeme kaydedildi' AS mesaj;
END;
GO

CREATE PROCEDURE SP_GIRIS_YAP
    @p_uye_id INT, @p_yontem NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_aktif INT;

    SELECT @v_aktif = COUNT(*) FROM UYELIKLER
    WHERE uye_id = @p_uye_id AND durum = N'Aktif' AND bitis_tarihi >= CAST(GETDATE() AS DATE);

    IF @v_aktif = 0
        THROW 50002, N'Aktif üyelik bulunamadı! Giriş reddedildi.', 1;
    ELSE
    BEGIN
        INSERT INTO GIRIS_CIKIS (uye_id, giris_zamani, giris_yontemi)
        VALUES (@p_uye_id, GETDATE(), @p_yontem);
        SELECT SCOPE_IDENTITY() AS kayit_id, N'Giriş başarılı' AS mesaj;
    END;
END;
GO

CREATE PROCEDURE SP_CIKIS_YAP @p_uye_id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE TOP (1) GIRIS_CIKIS
    SET cikis_zamani = GETDATE()
    WHERE uye_id = @p_uye_id AND cikis_zamani IS NULL;
    SELECT N'Çıkış kaydedildi' AS mesaj;
END;
GO

CREATE PROCEDURE SP_VUCUT_OLCUMU_KAYDET
    @p_uye_id INT, @p_kilo DECIMAL(5,2), @p_boy DECIMAL(5,2),
    @p_bel DECIMAL(5,2), @p_gogus DECIMAL(5,2), @p_kalca DECIMAL(5,2),
    @p_kol DECIMAL(5,2), @p_bacak DECIMAL(5,2),
    @p_yag DECIMAL(5,2), @p_kas DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO VUCUT_OLCUMLERI (uye_id, olcum_tarihi, kilo, boy, bel, gogus, kalca, kol, bacak, vucut_yag_orani, kas_kutlesi)
    VALUES (@p_uye_id, CAST(GETDATE() AS DATE), @p_kilo, @p_boy, @p_bel, @p_gogus, @p_kalca, @p_kol, @p_bacak, @p_yag, @p_kas);
    SELECT SCOPE_IDENTITY() AS olcum_id, N'Ölçüm kaydedildi' AS mesaj;
END;
GO

CREATE PROCEDURE SP_AYLIK_RAPOR @p_yil INT, @p_ay INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT N'Yeni Üye Sayısı' AS metrik, COUNT(*) AS deger
    FROM UYELER WHERE YEAR(kayit_tarihi) = @p_yil AND MONTH(kayit_tarihi) = @p_ay;

    SELECT N'Toplam Gelir (TL)' AS metrik, ISNULL(SUM(tutar), 0) AS deger
    FROM ODEMELER WHERE YEAR(odeme_tarihi) = @p_yil AND MONTH(odeme_tarihi) = @p_ay AND durum = N'Tamamlandı';

    SELECT N'Toplam Giriş Sayısı' AS metrik, COUNT(*) AS deger
    FROM GIRIS_CIKIS WHERE YEAR(giris_zamani) = @p_yil AND MONTH(giris_zamani) = @p_ay;

    SELECT N'Aktif Üyelik Sayısı' AS metrik, COUNT(*) AS deger
    FROM UYELIKLER WHERE durum = N'Aktif';
END;
GO

-- =============================================
-- 5. TRIGGER'LAR
-- =============================================

CREATE TRIGGER TRG_UYELIK_DURUM_GUNCELLE
ON UYELIKLER
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE u SET
        u.uye_id = i.uye_id, u.paket_id = i.paket_id,
        u.kampanya_id = i.kampanya_id, u.baslangic_tarihi = i.baslangic_tarihi,
        u.bitis_tarihi = i.bitis_tarihi, u.kalan_giris = i.kalan_giris,
        u.durum = CASE
            WHEN i.bitis_tarihi < CAST(GETDATE() AS DATE) AND i.durum = N'Aktif'
            THEN N'Süresi Dolmuş' ELSE i.durum END
    FROM UYELIKLER u INNER JOIN inserted i ON u.uyelik_id = i.uyelik_id;
END;
GO

CREATE TRIGGER TRG_ODEME_SONRASI_UYELIK
ON ODEMELER
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE UYELIKLER SET durum = N'Aktif'
    WHERE uyelik_id IN (
        SELECT uyelik_id FROM inserted
        WHERE odeme_turu = N'Üyelik' AND durum = N'Tamamlandı' AND uyelik_id IS NOT NULL
    );
END;
GO

CREATE TRIGGER TRG_EKIPMAN_BAKIM_UYARI
ON EKIPMAN_BAKIM
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE EKIPMANLAR SET durum = N'Bakımda'
    WHERE ekipman_id IN (SELECT ekipman_id FROM inserted WHERE bakim_turu = N'Arıza');
END;
GO

CREATE TRIGGER TRG_GIRIS_LOG
ON GIRIS_CIKIS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO GIRIS_LOG (uye_id, giris_zamani, sonuc, mesaj)
    SELECT i.uye_id, i.giris_zamani,
        CASE WHEN EXISTS (
            SELECT 1 FROM UYELIKLER WHERE uye_id = i.uye_id AND durum = N'Aktif' AND bitis_tarihi >= CAST(GETDATE() AS DATE)
        ) THEN N'Başarılı' ELSE N'Uyarı' END,
        CASE WHEN EXISTS (
            SELECT 1 FROM UYELIKLER WHERE uye_id = i.uye_id AND durum = N'Aktif' AND bitis_tarihi >= CAST(GETDATE() AS DATE)
        ) THEN N'Üye girişi kaydedildi.' ELSE N'Aktif üyelik bulunamadı!' END
    FROM inserted i;
END;
GO

CREATE TRIGGER TRG_UYELIK_LOG
ON UYELIKLER
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO UYELIK_LOG (uyelik_id, eski_durum, yeni_durum)
    SELECT d.uyelik_id, d.durum, i.durum
    FROM deleted d INNER JOIN inserted i ON d.uyelik_id = i.uyelik_id
    WHERE d.durum != i.durum;
END;
GO

-- =============================================
-- 6. ÖRNEK VERİLER
-- =============================================

-- 6.1 Üyeler
INSERT INTO UYELER (tc_kimlik, ad, soyad, cinsiyet, dogum_tarihi, telefon, email, adres) VALUES
('11111111111', N'Ahmet', N'Yılmaz', N'Erkek', '1990-05-15', '05301234567', 'ahmet@email.com', N'Kadıköy, İstanbul'),
('22222222222', N'Ayşe', N'Demir', N'Kadın', '1995-08-20', '05351234567', 'ayse@email.com', N'Beşiktaş, İstanbul'),
('33333333333', N'Mehmet', N'Kaya', N'Erkek', '1988-03-10', '05401234567', 'mehmet@email.com', N'Üsküdar, İstanbul'),
('44444444444', N'Fatma', N'Çelik', N'Kadın', '1992-11-25', '05451234567', 'fatma@email.com', N'Bakırköy, İstanbul'),
('55555555555', N'Ali', N'Öztürk', N'Erkek', '1985-07-08', '05501234567', 'ali@email.com', N'Şişli, İstanbul'),
('66666666666', N'Zeynep', N'Arslan', N'Kadın', '1997-01-14', '05321234567', 'zeynep@email.com', N'Ataşehir, İstanbul'),
('77777777777', N'Burak', N'Şahin', N'Erkek', '1993-09-30', '05331234567', 'burak@email.com', N'Maltepe, İstanbul'),
('88888888888', N'Elif', N'Aydın', N'Kadın', '1991-04-18', '05341234567', 'elif@email.com', N'Kartal, İstanbul'),
('99999999999', N'Emre', N'Koç', N'Erkek', '1994-12-05', '05361234567', 'emre@email.com', N'Pendik, İstanbul'),
('10101010101', N'Selin', N'Yıldız', N'Kadın', '1996-06-22', '05371234567', 'selin@email.com', N'Tuzla, İstanbul'),
('12121212121', N'Can', N'Erdoğan', N'Erkek', '1989-02-28', '05381234567', 'can@email.com', N'Beyoğlu, İstanbul'),
('13131313131', N'Deniz', N'Korkmaz', N'Kadın', '1998-10-11', '05391234567', 'deniz@email.com', N'Sarıyer, İstanbul');

-- 6.2 Üyelik Paketleri
INSERT INTO UYELIK_PAKETLERI (paket_adi, sure_gun, fiyat, aciklama, max_giris_sayisi) VALUES
(N'Aylık Standart', 30, 1500.00, N'Fitness salonu erişimi, 30 gün', NULL),
(N'Aylık Premium', 30, 2500.00, N'Fitness + Havuz + Sauna, 30 gün', NULL),
(N'3 Aylık Standart', 90, 4000.00, N'Fitness salonu, 3 ay', NULL),
(N'3 Aylık Premium', 90, 6500.00, N'Tüm alanlar, 3 ay', NULL),
(N'6 Aylık Standart', 180, 7000.00, N'Fitness salonu, 6 ay', NULL),
(N'Yıllık VIP', 365, 15000.00, N'Tüm hizmetler sınırsız, 1 yıl', NULL),
(N'10 Giriş Paketi', 90, 1200.00, N'10 girişlik paket', 10),
(N'Öğrenci Aylık', 30, 1000.00, N'Öğrencilere özel indirimli aylık paket', NULL),
(N'Haftalık Deneme', 7, 500.00, N'1 haftalık deneme paketi, tüm alanlar', NULL),
(N'Aile Paketi', 30, 4000.00, N'Aile üyeleri için grup aylık paket', NULL);

-- 6.3 Hizmetler
INSERT INTO HIZMETLER (hizmet_adi, aciklama) VALUES
(N'Fitness Salonu', N'Ağırlık ve kardiyo ekipmanları'),
(N'Havuz', N'Yarı olimpik yüzme havuzu'),
(N'Sauna', N'Kuru ve buhar sauna'),
(N'Grup Dersleri', N'Yoga, Pilates, Spinning vb.'),
(N'Kişisel Antrenman', N'Birebir eğitmen eşliğinde antrenman'),
(N'Duş ve Soyunma Odası', N'Kilitli dolap, duş imkanı'),
(N'Otopark', N'Üyelere özel otopark'),
(N'Diyet Danışmanlığı', N'Beslenme uzmanı desteği'),
(N'Masaj & Spa', N'Spor sonrası profesyonel masaj ve spa hizmeti'),
(N'Çocuk Aktivite Alanı', N'Çocuklara özel oyun ve spor alanı hizmeti');

-- 6.4 Paket-Hizmet İlişkileri
INSERT INTO PAKET_HIZMETLER (paket_id, hizmet_id) VALUES
(1, 1), (1, 6),
(2, 1), (2, 2), (2, 3), (2, 4), (2, 6),
(3, 1), (3, 6),
(4, 1), (4, 2), (4, 3), (4, 4), (4, 6), (4, 7),
(5, 1), (5, 6),
(6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (6, 7), (6, 8),
(7, 1), (7, 6),
(8, 1), (8, 6),
(9, 1), (9, 6),
(10, 1), (10, 2), (10, 4), (10, 6);

-- 6.5 Kampanyalar
INSERT INTO KAMPANYALAR (kampanya_adi, indirim_orani, baslangic_tarihi, bitis_tarihi, aciklama) VALUES
(N'Yeni Yıl Kampanyası', 20.00, '2026-01-01', '2026-01-31', N'Yeni yıl, yeni sen!'),
(N'Yaz Fırsatı', 15.00, '2026-06-01', '2026-08-31', N'Yaza formda girin'),
(N'Arkadaşını Getir', 10.00, '2026-01-01', '2026-12-31', N'Arkadaşınızla birlikte kayıtta %10 indirim'),
(N'Öğrenci İndirimi', 25.00, '2026-01-01', '2026-12-31', N'Geçerli öğrenci belgesine sahip üyeler için'),
(N'Sonbahar Kampanyası', 18.00, '2026-09-01', '2026-10-31', N'Sonbahar sezonuna özel indirim'),
(N'Kış Fırsatı', 12.00, '2026-11-01', '2026-12-31', N'Kış aylarında aktif kal'),
(N'Çiftlere Özel', 30.00, '2026-02-01', '2026-02-28', N'Sevgililer günü çift üyelik kampanyası'),
(N'Doğum Günü İndirimi', 20.00, '2026-01-01', '2026-12-31', N'Doğum ayında kayıt yaptıranlara özel indirim'),
(N'Kurumsal Paket', 22.00, '2026-03-01', '2026-12-31', N'Şirket çalışanlarına toplu indirim'),
(N'İlk Kayıt Fırsatı', 35.00, '2026-01-01', '2026-12-31', N'İlk kez kayıt yaptıranlara hoş geldin indirimi');

-- 6.6 Üyelikler
INSERT INTO UYELIKLER (uye_id, paket_id, kampanya_id, baslangic_tarihi, bitis_tarihi, durum) VALUES
(1, 2, NULL, '2026-02-01', '2026-03-03', N'Aktif'),
(2, 6, 1, '2026-01-15', '2027-01-15', N'Aktif'),
(3, 1, NULL, '2026-02-10', '2026-03-12', N'Aktif'),
(4, 4, NULL, '2026-01-01', '2026-04-01', N'Aktif'),
(5, 3, NULL, '2026-02-15', '2026-05-16', N'Aktif'),
(6, 8, 4, '2026-02-20', '2026-03-22', N'Aktif'),
(7, 5, NULL, '2025-09-01', '2026-02-28', N'Aktif'),
(8, 2, NULL, '2026-02-01', '2026-03-03', N'Aktif'),
(9, 1, NULL, '2025-12-01', '2025-12-31', N'Süresi Dolmuş'),
(10, 7, NULL, '2026-02-01', '2026-05-01', N'Aktif'),
(11, 4, 3, '2026-02-05', '2026-05-06', N'Aktif'),
(12, 2, NULL, '2026-02-25', '2026-03-27', N'Aktif');

-- 6.7 Personel
INSERT INTO PERSONEL (tc_kimlik, ad, soyad, pozisyon, telefon, email, maas, ise_baslama_tarihi) VALUES
('20202020202', N'Hakan', N'Tekin', N'Resepsiyon', '05551112233', 'hakan@spor.com', 18000.00, '2023-06-01'),
('21212121212', N'Merve', N'Aktaş', N'Resepsiyon', '05551112244', 'merve@spor.com', 18000.00, '2024-01-15'),
('23232323232', N'Serkan', N'Güneş', N'Temizlik', '05551112255', 'serkan@spor.com', 15000.00, '2023-03-01'),
('24242424242', N'Nurcan', N'Doğan', N'Müdür', '05551112266', 'nurcan@spor.com', 35000.00, '2022-01-01'),
('25252525252', N'Tolga', N'Özdemir', N'Teknik Bakım', '05551112277', 'tolga@spor.com', 22000.00, '2023-09-01'),
('26262626262', N'Berk', N'Kılıç', N'Resepsiyon', '05551112288', 'berk@spor.com', 18500.00, '2024-06-01'),
('27272727272', N'Pınar', N'Yaman', N'Muhasebe', '05551112299', 'pinar@spor.com', 26000.00, '2022-08-15'),
('28282828282', N'Cem', N'Bozkurt', N'Güvenlik', '05551112300', 'cem@spor.com', 16500.00, '2023-11-01'),
('29292929292', N'Leyla', N'Şimşek', N'Temizlik', '05551112311', 'leyla@spor.com', 15000.00, '2024-03-01'),
('30303030330', N'Kadir', N'Polat', N'IT Destek', '05551112322', 'kadir@spor.com', 24000.00, '2023-07-15');

-- 6.8 Eğitmenler
INSERT INTO EGITIMENLER (tc_kimlik, ad, soyad, telefon, email, deneyim_yili, sertifikalar, maas, ise_baslama_tarihi) VALUES
('30303030303', N'Oğuz', N'Kılıç', '05551113311', 'oguz@spor.com', 8, N'ACE CPT, NASM', 28000.00, '2022-06-01'),
('31313131313', N'Seda', N'Balcı', '05551113322', 'seda@spor.com', 5, N'Pilates Mat, Reformer', 25000.00, '2023-01-15'),
('32323232323', N'Volkan', N'Eren', '05551113333', 'volkan@spor.com', 10, N'CrossFit L2, Weightlifting', 30000.00, '2021-03-01'),
('34343434343', N'İrem', N'Başar', '05551113344', 'irem@spor.com', 3, N'Yoga RYT-200', 22000.00, '2024-02-01'),
('35353535353', N'Onur', N'Çetin', '05551113355', 'onur@spor.com', 6, N'Kickboks, Muay Thai', 26000.00, '2023-05-01'),
('36363636363', N'Gökhan', N'Acar', '05551113366', 'gokhan@spor.com', 4, N'ACE Group Fitness, TRX', 23000.00, '2024-01-01'),
('37373737373', N'Melis', N'Tunç', '05551113377', 'melis@spor.com', 7, N'Zumba, Step Aerobik', 24000.00, '2023-03-15'),
('38383838383', N'Barış', N'Kurt', '05551113388', 'baris@spor.com', 9, N'Yüzme Eğitmenliği, Aqua Fitness', 27000.00, '2022-09-01'),
('39393939393', N'Neslihan', N'Öz', '05551113399', 'neslihan@spor.com', 2, N'Pilates Reformer', 21000.00, '2024-06-01'),
('40404040404', N'Arda', N'Çakır', '05551113400', 'arda@spor.com', 5, N'Fonksiyonel Antrenman, HIIT', 25000.00, '2023-08-01');

-- 6.9 Uzmanlık Alanları
INSERT INTO UZMANLIK_ALANLARI (uzmanlik_adi, aciklama) VALUES
(N'Vücut Geliştirme', N'Kas kütlesi artırma ve şekillendirme'),
(N'Fonksiyonel Antrenman', N'Günlük yaşam hareketlerini destekleyen antrenman'),
(N'Pilates', N'Mat ve reformer pilates eğitimi'),
(N'Yoga', N'Hatha, Vinyasa, Yin yoga'),
(N'Kardiyo & HIIT', N'Yüksek yoğunluklu interval antrenman'),
(N'Kickboks', N'Kickboks ve dövüş sanatları'),
(N'Yüzme', N'Yüzme eğitimi ve su sporları'),
(N'Beslenme Danışmanlığı', N'Sporcu beslenmesi ve diyet'),
(N'Zumba & Dans Fitness', N'Dans temelli kardiyovasküler antrenman'),
(N'Streching & Mobilite', N'Esneklik ve eklem hareketliliği geliştirme');

-- 6.10 Eğitmen-Uzmanlık İlişkileri
INSERT INTO EGITMEN_UZMANLIKLAR (egitmen_id, uzmanlik_id) VALUES
(1, 1), (1, 2), (1, 5),
(2, 3), (2, 4),
(3, 1), (3, 2), (3, 5),
(4, 4), (4, 3),
(5, 6), (5, 5),
(6, 2), (6, 5),
(7, 9), (7, 5),
(8, 7), (8, 10),
(9, 3), (9, 4),
(10, 2), (10, 5);

-- 6.11 Salonlar
INSERT INTO SALONLAR (salon_adi, kapasite, alan_metrekare, aciklama) VALUES
(N'Ana Fitness Salonu', 80, 500.00, N'Ağırlık ve kardiyo bölümü'),
(N'Grup Dersleri Salonu', 30, 200.00, N'Yoga, pilates, step'),
(N'Spinning Salonu', 25, 100.00, N'Spinning bisikletleri'),
(N'Havuz', 20, 600.00, N'Yarı olimpik yüzme havuzu'),
(N'Dövüş Sanatları Salonu', 20, 150.00, N'Kickboks, muay thai'),
(N'CrossFit Alanı', 15, 250.00, N'Outdoor CrossFit ekipmanları'),
(N'Sauna & Hamam Bölümü', 10, 80.00, N'Kuru ve buhar sauna'),
(N'Çocuk Aktivite Alanı', 20, 120.00, N'Çocuklara özel oyun ve spor alanı'),
(N'Rehabilitasyon Odası', 8, 60.00, N'Fizyo terapi ve iyileşme odası'),
(N'Outdoor Spor Terası', 30, 300.00, N'Açık hava spor ve yoga terası');

-- 6.12 Ekipmanlar
INSERT INTO EKIPMANLAR (salon_id, ekipman_adi, marka, model, satin_alma_tarihi, garanti_bitis) VALUES
(1, N'Koşu Bandı', N'Technogym', N'Excite Run 1000', '2023-01-15', '2026-01-15'),
(1, N'Koşu Bandı', N'Technogym', N'Excite Run 1000', '2023-01-15', '2026-01-15'),
(1, N'Eliptik Bisiklet', N'Life Fitness', N'E5', '2023-03-20', '2026-03-20'),
(1, N'Bench Press', N'Hammer Strength', N'Olympic Flat', '2022-06-10', '2025-06-10'),
(1, N'Lat Pulldown', N'Cybex', N'VR3', '2022-06-10', '2025-06-10'),
(1, N'Leg Press', N'Hammer Strength', N'Linear LP', '2023-01-15', '2026-01-15'),
(1, N'Dumbbell Seti', N'Eleiko', N'2-50 kg', '2022-01-01', '2027-01-01'),
(1, N'Cable Crossover', N'Life Fitness', N'Signature', '2023-06-01', '2026-06-01'),
(3, N'Spinning Bisiklet', N'Keiser', N'M3i', '2023-09-01', '2026-09-01'),
(3, N'Spinning Bisiklet', N'Keiser', N'M3i', '2023-09-01', '2026-09-01'),
(5, N'Boks Torbası', N'Everlast', N'Powercore', '2024-01-15', '2027-01-15'),
(6, N'Rowing Machine', N'Concept 2', N'Model D', '2023-06-15', '2026-06-15');

-- 6.13 Ekipman Bakım
INSERT INTO EKIPMAN_BAKIM (ekipman_id, personel_id, bakim_tarihi, bakim_turu, aciklama, maliyet, sonraki_bakim_tarihi) VALUES
(1, 5, '2026-01-15', N'Periyodik', N'Kayış ve yağlama kontrolü', 500.00, '2026-04-15'),
(3, 5, '2026-02-01', N'Periyodik', N'Genel kontrol yapıldı', 200.00, '2026-05-01'),
(4, 5, '2026-01-20', N'Genel Kontrol', N'Cıvata sıkma ve temizlik', 100.00, '2026-04-20'),
(9, 5, '2026-02-10', N'Arıza', N'Pedal arızası giderildi', 800.00, '2026-05-10'),
(2, 5, '2026-01-15', N'Periyodik', N'Kayış ve motor kontrolü', 500.00, '2026-04-15'),
(5, 5, '2026-02-05', N'Periyodik', N'Kaynak ve vida kontrolü', 150.00, '2026-05-05'),
(6, 5, '2026-01-28', N'Genel Kontrol', N'Yağlama ve temizlik', 120.00, '2026-04-28'),
(7, 5, '2026-02-15', N'Periyodik', N'Halter seti genel kontrol', 80.00, '2026-05-15'),
(8, 5, '2026-01-10', N'Arıza', N'Kablo değişimi yapıldı', 950.00, '2026-04-10'),
(10, 5, '2026-02-10', N'Periyodik', N'Pedal ve direnç sistemi kontrolü', 450.00, '2026-05-10'),
(11, 5, '2025-12-20', N'Genel Kontrol', N'Zincir ve askı kontrolü', 200.00, '2026-03-20'),
(12, 5, '2026-01-05', N'Periyodik', N'Kızak ve kollar yağlandı', 180.00, '2026-04-05');

-- 6.14 Dersler
INSERT INTO DERSLER (ders_adi, aciklama, sure_dakika, max_katilimci, seviye) VALUES
(N'Yoga', N'Rahatlatıcı yoga dersi', 60, 25, N'Başlangıç'),
(N'Pilates Mat', N'Mat üzerinde pilates egzersizleri', 50, 20, N'Orta'),
(N'Spinning', N'Yüksek tempolu bisiklet antrenmanı', 45, 25, N'İleri'),
(N'HIIT', N'Yüksek yoğunluklu interval antrenman', 40, 20, N'İleri'),
(N'Kickboks', N'Dövüş sanatları temelli kardiyo', 60, 15, N'Orta'),
(N'Zumba', N'Dans ile fitness', 50, 30, N'Başlangıç'),
(N'Fonksiyonel Antrenman', N'TRX ve kettlebell ile antrenman', 45, 15, N'Orta'),
(N'Aqua Fitness', N'Havuzda yapılan egzersiz dersi', 45, 15, N'Başlangıç'),
(N'TRX Antrenmanı', N'Askı sistemi ile vücut ağırlığı egzersizleri', 45, 12, N'Orta'),
(N'Stretching & Mobilite', N'Esneklik ve eklem hareketliliği geliştirme dersi', 40, 20, N'Başlangıç');

-- 6.15 Ders Programı
INSERT INTO DERS_PROGRAMI (ders_id, egitmen_id, salon_id, gun, baslangic_saati, bitis_saati) VALUES
(1, 4, 2, N'Pazartesi', '09:00', '10:00'),
(2, 2, 2, N'Pazartesi', '10:30', '11:20'),
(3, 3, 3, N'Pazartesi', '18:00', '18:45'),
(4, 1, 6, N'Salı', '07:00', '07:40'),
(5, 5, 5, N'Salı', '19:00', '20:00'),
(6, 2, 2, N'Çarşamba', '17:00', '17:50'),
(1, 4, 2, N'Çarşamba', '09:00', '10:00'),
(7, 3, 6, N'Perşembe', '18:00', '18:45'),
(3, 3, 3, N'Cuma', '18:00', '18:45'),
(8, 2, 4, N'Cumartesi', '10:00', '10:45'),
(4, 1, 6, N'Cumartesi', '11:00', '11:40');

-- 6.16 Ders Katılım
INSERT INTO DERS_KATILIM (program_id, uye_id, katilim_tarihi, durum) VALUES
(1, 2, '2026-02-24', N'Katıldı'),
(1, 4, '2026-02-24', N'Katıldı'),
(1, 6, '2026-02-24', N'Katılmadı'),
(2, 8, '2026-02-24', N'Katıldı'),
(3, 1, '2026-02-24', N'Katıldı'),
(3, 5, '2026-02-24', N'Katıldı'),
(4, 3, '2026-02-25', N'Katıldı'),
(5, 7, '2026-02-25', N'Katıldı'),
(5, 11, '2026-02-25', N'Katıldı'),
(6, 10, '2026-02-26', N'Katıldı'),
(7, 12, '2026-02-26', N'Katıldı');

-- 6.17 Randevular
INSERT INTO RANDEVULAR (uye_id, egitmen_id, randevu_tarihi, baslangic_saati, bitis_saati, tur, durum) VALUES
(1, 1, '2026-02-27', '10:00', '11:00', N'PT', N'Planlandı'),
(2, 1, '2026-02-27', '14:00', '15:00', N'PT', N'Planlandı'),
(3, 3, '2026-02-28', '09:00', '10:00', N'Değerlendirme', N'Planlandı'),
(4, 2, '2026-02-28', '11:00', '12:00', N'PT', N'Planlandı'),
(5, 1, '2026-02-25', '10:00', '11:00', N'PT', N'Tamamlandı'),
(7, 5, '2026-02-26', '16:00', '17:00', N'PT', N'Tamamlandı'),
(8, 4, '2026-02-27', '15:00', '16:00', N'Diyet Danışma', N'Planlandı'),
(11, 3, '2026-02-24', '10:00', '11:00', N'PT', N'Gelmedi'),
(6, 4, '2026-03-01', '14:00', '15:00', N'Diyet Danışma', N'Planlandı'),
(10, 5, '2026-03-02', '09:00', '10:00', N'PT', N'Planlandı');

-- 6.18 Ödemeler
INSERT INTO ODEMELER (uye_id, uyelik_id, tutar, odeme_tarihi, odeme_yontemi, odeme_turu, durum) VALUES
(1, 1, 2500.00, '2026-02-01', N'Kredi Kartı', N'Üyelik', N'Tamamlandı'),
(2, 2, 12000.00, '2026-01-15', N'Havale/EFT', N'Üyelik', N'Tamamlandı'),
(3, 3, 1500.00, '2026-02-10', N'Nakit', N'Üyelik', N'Tamamlandı'),
(4, 4, 6500.00, '2026-01-01', N'Kredi Kartı', N'Üyelik', N'Tamamlandı'),
(5, 5, 4000.00, '2026-02-15', N'Online', N'Üyelik', N'Tamamlandı'),
(6, 6, 750.00, '2026-02-20', N'Nakit', N'Üyelik', N'Tamamlandı'),
(7, 7, 7000.00, '2025-09-01', N'Kredi Kartı', N'Üyelik', N'Tamamlandı'),
(8, 8, 2500.00, '2026-02-01', N'Havale/EFT', N'Üyelik', N'Tamamlandı'),
(1, NULL, 500.00, '2026-02-20', N'Nakit', N'PT', N'Tamamlandı'),
(5, NULL, 500.00, '2026-02-25', N'Kredi Kartı', N'PT', N'Tamamlandı'),
(10, 10, 1200.00, '2026-02-01', N'Online', N'Üyelik', N'Tamamlandı'),
(11, 11, 5850.00, '2026-02-05', N'Kredi Kartı', N'Üyelik', N'Tamamlandı'),
(12, 12, 2500.00, '2026-02-25', N'Nakit', N'Üyelik', N'Tamamlandı');

-- 6.19 Giriş/Çıkış Kayıtları
INSERT INTO GIRIS_CIKIS (uye_id, personel_id, giris_zamani, cikis_zamani, giris_yontemi) VALUES
(1, 1, '2026-02-26 08:30:00', '2026-02-26 10:15:00', N'Kart'),
(2, 1, '2026-02-26 09:00:00', '2026-02-26 11:00:00', N'QR Kod'),
(3, 1, '2026-02-26 10:00:00', '2026-02-26 11:30:00', N'Parmak İzi'),
(5, 2, '2026-02-26 17:00:00', '2026-02-26 19:00:00', N'Kart'),
(7, 2, '2026-02-26 18:00:00', '2026-02-26 20:00:00', N'Kart'),
(1, 1, '2026-02-27 08:00:00', NULL, N'Kart'),
(4, 1, '2026-02-27 09:00:00', NULL, N'QR Kod'),
(8, 2, '2026-02-27 07:30:00', '2026-02-27 09:00:00', N'Parmak İzi'),
(11, 1, '2026-02-27 10:00:00', NULL, N'Kart'),
(12, 2, '2026-02-27 08:45:00', NULL, N'Manuel');

-- 6.20 Vücut Ölçümleri
INSERT INTO VUCUT_OLCUMLERI (uye_id, olcum_tarihi, kilo, boy, bel, gogus, kalca, kol, bacak, vucut_yag_orani, kas_kutlesi) VALUES
(1, '2026-02-01', 82.50, 178.00, 88.00, 102.00, 98.00, 36.00, 58.00, 18.50, 35.00),
(1, '2026-02-27', 80.00, 178.00, 85.00, 103.00, 97.00, 37.00, 59.00, 16.80, 36.50),
(2, '2026-01-15', 58.00, 165.00, 68.00, 85.00, 92.00, 27.00, 52.00, 22.00, 24.00),
(3, '2026-02-10', 95.00, 182.00, 98.00, 110.00, 105.00, 40.00, 64.00, 25.00, 38.00),
(4, '2026-01-01', 62.00, 170.00, 72.00, 88.00, 95.00, 28.00, 54.00, 24.00, 25.00),
(5, '2026-02-15', 78.00, 175.00, 82.00, 100.00, 96.00, 35.00, 57.00, 17.00, 34.00),
(7, '2025-09-01', 88.00, 180.00, 92.00, 105.00, 100.00, 38.00, 60.00, 20.00, 36.00),
(7, '2026-02-27', 83.00, 180.00, 86.00, 106.00, 98.00, 39.00, 61.00, 17.50, 38.00),
(8, '2026-02-01', 55.00, 162.00, 65.00, 82.00, 90.00, 25.00, 50.00, 23.50, 22.00),
(11, '2026-02-05', 75.00, 176.00, 80.00, 98.00, 95.00, 33.00, 56.00, 19.00, 32.00);

-- =============================================
-- 7. ÖRNEK KULLANIM (VIEW, SP, TRIGGER TEST)
-- =============================================

PRINT N'=== VIEW SORGULARI ==='
GO

-- Tüm aktif üyeleri ve kalan günlerini göster
SELECT * FROM VW_AKTIF_UYELER;
GO

-- Üyeliği 7 gün içinde bitecek olanları göster (bildirim amaçlı)
SELECT * FROM VW_UYELIK_BITIS_YAKLASAN;
GO

-- Tüm eğitmenlerin aktif ders programlarını göster
SELECT * FROM VW_EGITMEN_DERS_PROGRAMI;
GO

-- Günlük giriş/çıkış raporu (ortalama salon kullanım süresi ile)
SELECT * FROM VW_GUNLUK_GIRIS_RAPORU ORDER BY tarih DESC;
GO

-- Ödeme yöntemine göre aylık gelir özeti
SELECT * FROM VW_ODEME_OZETI ORDER BY yil DESC, ay DESC;
GO

-- Ekipmanların son bakım ve sonraki bakım tarihlerini listele
SELECT * FROM VW_EKIPMAN_DURUM;
GO

-- Üyeliklerin dahil ettiği hizmetleri göster
SELECT * FROM VW_UYELIK_DETAY;
GO

PRINT N'=== STORED PROCEDURE KULLANIMLARI ==='
GO

-- SP: Yeni üye kaydı (TC, ad, soyad, cinsiyet, doğum, tel, email, adres, paket, ödeme)
EXEC SP_YENI_UYE_KAYIT
    '14141414141', N'Yeni', N'Üye', N'Erkek', '2000-01-01',
    '05551119999', 'yeni@email.com', N'Ankara', 1, N'Nakit';
GO

-- SP: Süresi dolmuş üyenin üyeliğini yenile
EXEC SP_UYELIK_YENILE 9, 2, N'Kredi Kartı';
GO

-- SP: Eğitmen randevusu oluştur (çakışma kontrolü yapılır)
EXEC SP_RANDEVU_OLUSTUR 1, 2, '2026-03-05', '13:00', '14:00', N'PT';
EXEC SP_RANDEVU_OLUSTUR 6, 3, '2026-03-06', '11:00', '12:00', N'Değerlendirme';
GO

-- SP: Üye girişi yap (aktif üyelik kontrolü tetiklenir)
EXEC SP_GIRIS_YAP 1, N'Kart';
EXEC SP_GIRIS_YAP 4, N'QR Kod';
GO

-- SP: Üye çıkışı kaydet
EXEC SP_CIKIS_YAP 1;
GO

-- SP: Ödeme kaydet
EXEC SP_ODEME_AL 3, NULL, 500.00, N'Nakit', N'PT', N'Kişisel antrenman seansı ödemesi';
GO

-- SP: Vücut ölçümü kaydet
EXEC SP_VUCUT_OLCUMU_KAYDET 6, 65.0, 168.0, 70.0, 87.0, 94.0, 28.0, 53.0, 21.5, 25.5;
GO

-- SP: Aylık rapor (yıl, ay)
EXEC SP_AYLIK_RAPOR 2026, 2;
EXEC SP_AYLIK_RAPOR 2026, 1;
GO

PRINT N'=== TRIGGER TEST SONUÇLARI ==='
GO

-- TRG_UYELIK_LOG testi: Üyelik durumu güncelle → log tablosunu kontrol et
UPDATE UYELIKLER SET durum = N'Pasif' WHERE uyelik_id = 3;
SELECT * FROM UYELIK_LOG;
GO

-- TRG_GIRIS_LOG testi: Yeni giriş ekle → log tablosunu kontrol et
INSERT INTO GIRIS_CIKIS (uye_id, giris_zamani, giris_yontemi) VALUES (5, GETDATE(), N'Kart');
SELECT * FROM GIRIS_LOG;
GO

-- TRG_EKIPMAN_BAKIM_UYARI testi: Arıza bakımı ekle → ekipman durumunu kontrol et
INSERT INTO EKIPMAN_BAKIM (ekipman_id, personel_id, bakim_tarihi, bakim_turu, aciklama, maliyet)
VALUES (5, 5, CAST(GETDATE() AS DATE), N'Arıza', N'Motor arızası', 1200.00);
SELECT ekipman_id, ekipman_adi, durum FROM EKIPMANLAR WHERE ekipman_id = 5;
GO

-- TRG_ODEME_SONRASI_UYELIK testi: Ödeme ekle → üyelik aktifleşiyor mu?
SELECT uyelik_id, durum FROM UYELIKLER WHERE uyelik_id = 3;
UPDATE UYELIKLER SET durum = N'Pasif' WHERE uyelik_id = 3;
INSERT INTO ODEMELER (uye_id, uyelik_id, tutar, odeme_yontemi, odeme_turu)
VALUES (3, 3, 1500.00, N'Nakit', N'Üyelik');
SELECT uyelik_id, durum FROM UYELIKLER WHERE uyelik_id = 3;
GO

PRINT N'=== INDEX KULLANIM TEST SORGULARI ==='
GO

-- IX_UYELER_AD_SOYAD index'ini kullanan sorgu
SELECT uye_id, ad, soyad, telefon FROM UYELER WHERE ad = N'Ahmet' AND soyad = N'Yılmaz';

-- IX_UYELIKLER_DURUM index'ini kullanan sorgu
SELECT * FROM UYELIKLER WHERE durum = N'Aktif';

-- IX_ODEMELER_TARIH index'ini kullanan sorgu
SELECT * FROM ODEMELER WHERE odeme_tarihi >= '2026-02-01' AND odeme_tarihi < '2026-03-01';

-- IX_GIRIS_CIKIS_TARIH index'ini kullanan sorgu
SELECT * FROM GIRIS_CIKIS WHERE giris_zamani >= '2026-02-26' AND giris_zamani < '2026-02-28';

-- IX_RANDEVULAR_TARIH index'ini kullanan sorgu
SELECT * FROM RANDEVULAR WHERE randevu_tarihi = '2026-02-27';

-- IX_DERS_PROGRAMI_GUN index'ini kullanan sorgu
SELECT * FROM DERS_PROGRAMI WHERE gun = N'Pazartesi' ORDER BY baslangic_saati;
GO
