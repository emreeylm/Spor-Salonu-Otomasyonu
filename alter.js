const sql = require('mssql');
const config = {
    user: 'sa',
    password: 'Eowkai57',
    server: 'localhost',
    database: 'sporotomasyon',
    options: { encrypt: true, trustServerCertificate: true }
};

const query = `
ALTER PROCEDURE SP_YENI_UYE_KAYIT
    @p_tc CHAR(11), @p_ad NVARCHAR(50), @p_soyad NVARCHAR(50),
    @p_cinsiyet NVARCHAR(10), @p_dogum DATE,
    @p_telefon NVARCHAR(15), @p_email NVARCHAR(100), @p_adres NVARCHAR(MAX),
    @p_paket_id INT, @p_odeme_yontemi NVARCHAR(15),
    @p_kayit_tarihi DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_uye_id INT, @v_uyelik_id INT;
    DECLARE @v_fiyat DECIMAL(10,2), @v_sure INT;

    SELECT @v_fiyat = fiyat, @v_sure = sure_gun
    FROM UYELIK_PAKETLERI WHERE paket_id = @p_paket_id;

    IF @p_kayit_tarihi IS NULL SET @p_kayit_tarihi = GETDATE();

    INSERT INTO UYELER (tc_kimlik, ad, soyad, cinsiyet, dogum_tarihi, telefon, email, adres, kayit_tarihi)
    VALUES (@p_tc, @p_ad, @p_soyad, @p_cinsiyet, @p_dogum, @p_telefon, @p_email, @p_adres, @p_kayit_tarihi);
    SET @v_uye_id = SCOPE_IDENTITY();

    INSERT INTO UYELIKLER (uye_id, paket_id, baslangic_tarihi, bitis_tarihi, durum)
    VALUES (@v_uye_id, @p_paket_id, CAST(@p_kayit_tarihi AS DATE), DATEADD(DAY, @v_sure, CAST(@p_kayit_tarihi AS DATE)), N'Aktif');
    SET @v_uyelik_id = SCOPE_IDENTITY();

    INSERT INTO ODEMELER (uye_id, uyelik_id, tutar, odeme_tarihi, odeme_yontemi, odeme_turu, durum, aciklama)
    VALUES (@v_uye_id, @v_uyelik_id, @v_fiyat, @p_kayit_tarihi, @p_odeme_yontemi, N'Üyelik', N'Tamamlandı', N'Yeni üyelik ödemesi');

    SELECT @v_uye_id AS uye_id, @v_uyelik_id AS uyelik_id;
END;
`;

sql.connect(config).then(pool => {
    return pool.request().batch(query);
}).then(result => {
    console.log("Procedure altered successfully.");
    process.exit(0);
}).catch(err => {
    console.error("Error altering procedure:", err);
    process.exit(1);
});
