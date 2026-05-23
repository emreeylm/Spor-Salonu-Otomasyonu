const sql = require('mssql');
const config = {
    user: 'sa',
    password: 'Eowkai57',
    server: 'localhost',
    database: 'sporotomasyon',
    options: { encrypt: true, trustServerCertificate: true }
};

const query = `
    -- Fix status for all members whose end date is in the future
    UPDATE UYELIKLER
    SET durum = N'Aktif'
    WHERE bitis_tarihi >= CAST(GETDATE() AS DATE);
    
    UPDATE UYELER
    SET durum = N'Aktif'
    WHERE uye_id IN (
        SELECT uye_id FROM UYELIKLER WHERE bitis_tarihi >= CAST(GETDATE() AS DATE)
    );

    -- Expire two specific members
    UPDATE UYELIKLER
    SET baslangic_tarihi = '2025-01-01', bitis_tarihi = '2025-05-01', durum = N'Süresi Dolmuş'
    WHERE uyelik_id IN (1, 2);

    UPDATE UYELER
    SET durum = N'Pasif'
    WHERE uye_id IN (SELECT uye_id FROM UYELIKLER WHERE uyelik_id IN (1, 2));
`;

sql.connect(config).then(pool => {
    return pool.request().query(query);
}).then(result => {
    console.log("Fixed statuses successfully.");
    process.exit(0);
}).catch(err => {
    console.error("Error updating DB:", err);
    process.exit(1);
});
