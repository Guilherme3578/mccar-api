// Recria o banco do zero: apaga o .db, roda schema.sql e seed.sql.
// Uso: npm run db:reset   (feche SQLTools/DB Browser antes, senão dá "database is locked")
const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');
require('dotenv').config({ quiet: true });

const dbPath = path.resolve(process.cwd(), process.env.DB_PATH || './mccar.db');
for (const sufixo of ['', '-wal', '-shm']) {
  if (fs.existsSync(dbPath + sufixo)) fs.unlinkSync(dbPath + sufixo);
}

const db = new Database(dbPath);
db.pragma('foreign_keys = ON');
db.exec(fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8'));
db.exec(fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8'));

const tabelas = db.prepare("SELECT COUNT(*) AS n FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").get().n;
const produtos = db.prepare('SELECT COUNT(*) AS n FROM produto').get().n;
console.log(`Banco recriado em ${dbPath}: ${tabelas} tabelas, ${produtos} produtos.`);
db.close();
