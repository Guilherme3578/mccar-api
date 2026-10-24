require('dotenv').config({ quiet: true });
const express = require('express');
const cors = require('cors');
const db = require('./db/connection');

const app = express();
app.use(cors());
app.use(express.json());

// teste de fumaça: confirma que a API e o banco estão de pé
app.get('/health', (req, res) => {
  const { produtos } = db.prepare('SELECT COUNT(*) AS produtos FROM produto').get();
  res.json({ ok: true, produtos });
});

// (próximos passos) app.use('/auth', require('./routes/auth.routes'));
// (próximos passos) app.use('/produtos', require('./routes/produtos.routes'));

app.use((req, res) => res.status(404).json({ erro: 'Rota não encontrada' }));
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ erro: 'Erro interno do servidor' });
});

const PORT = process.env.PORT || 3000;
// 0.0.0.0 = aceita conexões do celular na mesma rede (Expo Go)
app.listen(PORT, '0.0.0.0', () => console.log(`API MCCAR rodando na porta ${PORT}`));
