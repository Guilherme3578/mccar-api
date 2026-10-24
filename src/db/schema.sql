-- MCCAR · schema SQLite (gerado a partir do DER "Pé de Galinha")
-- String -> TEXT | Integer -> INTEGER | Float -> REAL
-- Datas em TEXT (ISO 8601, UTC) · dinheiro SEMPRE em centavos (INTEGER)
PRAGMA foreign_keys = ON;

-- ============ USUÁRIO ============
CREATE TABLE usuario (
  id_usuario  INTEGER PRIMARY KEY AUTOINCREMENT,
  nome        TEXT NOT NULL,
  email       TEXT NOT NULL UNIQUE,
  senha_hash  TEXT NOT NULL,
  criado_em   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE endereco (
  id_endereco INTEGER PRIMARY KEY AUTOINCREMENT,
  id_usuario  INTEGER NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  logradouro  TEXT NOT NULL,
  numero      TEXT NOT NULL,
  complemento TEXT,
  bairro      TEXT NOT NULL,
  cidade      TEXT NOT NULL,
  uf          TEXT NOT NULL CHECK (length(uf) = 2),
  cep         TEXT NOT NULL,
  principal   INTEGER NOT NULL DEFAULT 0 CHECK (principal IN (0,1))
);
-- no máximo 1 endereço principal por usuário
CREATE UNIQUE INDEX ux_endereco_principal ON endereco(id_usuario) WHERE principal = 1;

CREATE TABLE cartao_salvo (
  id_cartao     INTEGER PRIMARY KEY AUTOINCREMENT,
  id_usuario    INTEGER NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  apelido       TEXT,
  bandeira      TEXT NOT NULL,
  ultimos_quatro TEXT NOT NULL CHECK (length(ultimos_quatro) = 4),
  nome_titular  TEXT NOT NULL,
  principal     INTEGER NOT NULL DEFAULT 0 CHECK (principal IN (0,1))
);
CREATE UNIQUE INDEX ux_cartao_principal ON cartao_salvo(id_usuario) WHERE principal = 1;

-- ============ VEÍCULOS ============
CREATE TABLE modelo_veiculo (
  id_modelo_veiculo INTEGER PRIMARY KEY AUTOINCREMENT,
  marca  TEXT NOT NULL,
  modelo TEXT NOT NULL,
  ano    INTEGER NOT NULL CHECK (ano BETWEEN 1950 AND 2100),
  UNIQUE (marca, modelo, ano)
);

CREATE TABLE veiculo (  -- veículo do usuário
  id_veiculo        INTEGER PRIMARY KEY AUTOINCREMENT,
  id_usuario        INTEGER NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_modelo_veiculo INTEGER NOT NULL REFERENCES modelo_veiculo(id_modelo_veiculo),
  principal         INTEGER NOT NULL DEFAULT 0 CHECK (principal IN (0,1))
);
CREATE UNIQUE INDEX ux_veiculo_principal ON veiculo(id_usuario) WHERE principal = 1;

-- ============ CATÁLOGO ============
CREATE TABLE categoria (
  id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
  nome  TEXT NOT NULL UNIQUE,
  icone TEXT
);

CREATE TABLE produto (
  id_produto     INTEGER PRIMARY KEY AUTOINCREMENT,
  id_categoria   INTEGER NOT NULL REFERENCES categoria(id_categoria),
  codigo         TEXT NOT NULL UNIQUE,
  nome           TEXT NOT NULL,
  marca          TEXT NOT NULL,
  descricao      TEXT NOT NULL,
  preco_centavos INTEGER NOT NULL CHECK (preco_centavos >= 0),
  imagem_uri     TEXT,
  garantia_meses INTEGER NOT NULL DEFAULT 0 CHECK (garantia_meses >= 0),
  destaque       INTEGER NOT NULL DEFAULT 0 CHECK (destaque IN (0,1)),
  ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
  avaliacao_media      REAL CHECK (avaliacao_media IS NULL OR avaliacao_media BETWEEN 0 AND 5),
  avaliacao_quantidade INTEGER NOT NULL DEFAULT 0 CHECK (avaliacao_quantidade >= 0),
  prazo_envio_horas    INTEGER NOT NULL DEFAULT 24 CHECK (prazo_envio_horas >= 0),
  frete_gratis_acima_centavos INTEGER NOT NULL DEFAULT 0 CHECK (frete_gratis_acima_centavos >= 0)
);
CREATE INDEX ix_produto_categoria ON produto(id_categoria);
CREATE INDEX ix_produto_nome ON produto(nome);

CREATE TABLE produto_veiculo (  -- compatibilidade N:N
  id_produto        INTEGER NOT NULL REFERENCES produto(id_produto) ON DELETE CASCADE,
  id_modelo_veiculo INTEGER NOT NULL REFERENCES modelo_veiculo(id_modelo_veiculo) ON DELETE CASCADE,
  PRIMARY KEY (id_produto, id_modelo_veiculo)
);
CREATE INDEX ix_pv_modelo ON produto_veiculo(id_modelo_veiculo);

CREATE TABLE especificacao_produto (
  id_produto INTEGER NOT NULL REFERENCES produto(id_produto) ON DELETE CASCADE,
  nome       TEXT NOT NULL,
  valor      TEXT NOT NULL,
  PRIMARY KEY (id_produto, nome)
);

CREATE TABLE favorito (
  id_usuario INTEGER NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  id_produto INTEGER NOT NULL REFERENCES produto(id_produto) ON DELETE CASCADE,
  criado_em  TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (id_usuario, id_produto)
);

-- ============ CARRINHO ============
CREATE TABLE carrinho (
  id_carrinho    INTEGER PRIMARY KEY AUTOINCREMENT,
  id_usuario     INTEGER NOT NULL UNIQUE REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  atualizado_em  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE item_carrinho (
  id_carrinho INTEGER NOT NULL REFERENCES carrinho(id_carrinho) ON DELETE CASCADE,
  id_produto  INTEGER NOT NULL REFERENCES produto(id_produto) ON DELETE CASCADE,
  quantidade  INTEGER NOT NULL CHECK (quantidade > 0),
  PRIMARY KEY (id_carrinho, id_produto)
);

-- ============ CUPOM / PEDIDO / PAGAMENTO ============
CREATE TABLE cupom (
  id_cupom               INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo                 TEXT NOT NULL UNIQUE,
  tipo                   TEXT NOT NULL CHECK (tipo IN ('percentual','valor_fixo')),
  valor                  INTEGER NOT NULL CHECK (valor > 0), -- % ou centavos, conforme o tipo
  minimo_compra_centavos INTEGER NOT NULL DEFAULT 0 CHECK (minimo_compra_centavos >= 0),
  valido_ate             TEXT,
  ativo                  INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1))
);

CREATE TABLE pedido (
  id_pedido   INTEGER PRIMARY KEY AUTOINCREMENT,
  id_usuario  INTEGER NOT NULL REFERENCES usuario(id_usuario),
  id_endereco INTEGER REFERENCES endereco(id_endereco) ON DELETE SET NULL, -- o endereço oficial é o snapshot entrega_*
  id_cupom    INTEGER REFERENCES cupom(id_cupom) ON DELETE SET NULL,
  numero      TEXT NOT NULL UNIQUE,            -- ex.: MC-95497578
  criado_em   TEXT NOT NULL DEFAULT (datetime('now')),
  status      TEXT NOT NULL DEFAULT 'em_processamento'
              CHECK (status IN ('aguardando_pagamento','em_processamento','enviado','entregue','cancelado')),
  subtotal_centavos INTEGER NOT NULL CHECK (subtotal_centavos >= 0),
  frete_centavos    INTEGER NOT NULL CHECK (frete_centavos >= 0),
  desconto_centavos INTEGER NOT NULL DEFAULT 0 CHECK (desconto_centavos >= 0),
  total_centavos    INTEGER NOT NULL CHECK (total_centavos >= 0),
  prazo_min_dias    INTEGER NOT NULL CHECK (prazo_min_dias >= 0),
  prazo_max_dias    INTEGER NOT NULL,
  entrega_logradouro  TEXT NOT NULL,
  entrega_numero      TEXT NOT NULL,
  entrega_complemento TEXT,
  entrega_bairro      TEXT NOT NULL,
  entrega_cidade      TEXT NOT NULL,
  entrega_uf          TEXT NOT NULL,
  entrega_cep         TEXT NOT NULL,
  CHECK (total_centavos = subtotal_centavos + frete_centavos - desconto_centavos),
  CHECK (prazo_max_dias >= prazo_min_dias)
);
CREATE INDEX ix_pedido_usuario ON pedido(id_usuario, criado_em DESC);

CREATE TABLE item_pedido (
  id_pedido  INTEGER NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
  id_produto INTEGER NOT NULL REFERENCES produto(id_produto),
  nome_produto   TEXT NOT NULL,   -- snapshot: o pedido não muda se o produto mudar
  codigo_produto TEXT NOT NULL,
  quantidade     INTEGER NOT NULL CHECK (quantidade > 0),
  preco_unitario_centavos INTEGER NOT NULL CHECK (preco_unitario_centavos >= 0),
  PRIMARY KEY (id_pedido, id_produto)
);

CREATE TABLE pagamento (
  id_pagamento  INTEGER PRIMARY KEY AUTOINCREMENT,
  id_pedido     INTEGER NOT NULL UNIQUE REFERENCES pedido(id_pedido) ON DELETE CASCADE,
  id_usuario    INTEGER NOT NULL REFERENCES usuario(id_usuario),
  id_cartao     INTEGER REFERENCES cartao_salvo(id_cartao) ON DELETE SET NULL,
  metodo        TEXT NOT NULL CHECK (metodo IN ('cartao','pix','boleto')),
  status        TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','aprovado','recusado')),
  valor_centavos INTEGER NOT NULL CHECK (valor_centavos >= 0),
  cartao_bandeira TEXT,
  cartao_final    TEXT,
  criado_em     TEXT NOT NULL DEFAULT (datetime('now')),
  aprovado_em   TEXT
);
