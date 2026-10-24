const path = require('path');
const Database = require('better-sqlite3');
require('dotenv').config({ quiet: true });

// caminho do arquivo .db (relativo à raiz do projeto)
const dbPath = path.resolve(process.cwd(), process.env.DB_PATH || './mccar.db');

const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON'); // o SQLite NÃO respeita FK por padrão

module.exports = db;
