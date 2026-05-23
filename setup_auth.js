const sql = require('mssql');
const bcrypt = require('bcryptjs');

const config = {
    user: 'sa',
    password: 'Eowkai57',
    server: 'localhost',
    database: 'sporotomasyon',
    options: { encrypt: true, trustServerCertificate: true }
};

async function setup() {
    try {
        const pool = await sql.connect(config);
        
        // Tabloyu oluştur
        await pool.request().query(`
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='YONETICILER' and xtype='U')
            CREATE TABLE YONETICILER (
                yonetici_id INT IDENTITY(1,1) PRIMARY KEY,
                kullanici_adi NVARCHAR(50) NOT NULL UNIQUE,
                sifre_hash NVARCHAR(255) NOT NULL,
                rol NVARCHAR(20) DEFAULT N'Admin',
                olusturma_tarihi DATETIME DEFAULT GETDATE()
            )
        `);
        console.log("Tablo oluşturuldu veya zaten var.");

        // Admin var mı kontrol et
        const check = await pool.request()
            .input('username', sql.NVarChar, 'admin')
            .query("SELECT * FROM YONETICILER WHERE kullanici_adi = @username");

        if (check.recordset.length === 0) {
            // Hash password and insert
            const hash = await bcrypt.hash('admin123', 10);
            await pool.request()
                .input('username', sql.NVarChar, 'admin')
                .input('hash', sql.NVarChar, hash)
                .query("INSERT INTO YONETICILER (kullanici_adi, sifre_hash, rol) VALUES (@username, @hash, N'Admin')");
            console.log("Varsayılan admin (admin / admin123) oluşturuldu.");
        } else {
            console.log("Admin kullanıcısı zaten mevcut.");
        }
        
        process.exit(0);
    } catch (err) {
        console.error("Hata:", err);
        process.exit(1);
    }
}

setup();
