const sql = require('mssql');
const config = {
    user: 'sa',
    password: 'Eowkai57',
    server: 'localhost',
    database: 'sporotomasyon',
    options: { encrypt: true, trustServerCertificate: true }
};

const query = `
    UPDATE UYELIKLER
    SET bitis_tarihi = DATEADD(DAY, (uyelik_id % 10), '2026-06-08')
    WHERE bitis_tarihi < '2026-06-08';
`;

sql.connect(config).then(pool => {
    return pool.request().query(query);
}).then(result => {
    console.log("Dates updated successfully. Rows affected:", result.rowsAffected);
    process.exit(0);
}).catch(err => {
    console.error("Error updating dates:", err);
    process.exit(1);
});
