-- MCCAR · dados iniciais de teste (catálogo). Usuários são criados pela API (senha com hash).
INSERT INTO categoria (nome, icone) VALUES
  ('Motor','engine'), ('Freios','disc'), ('Suspensão','help-circle'), ('Elétrica','flash'), ('Acessórios','car-wrench');

WITH RECURSIVE a(ano) AS (SELECT 2013 UNION ALL SELECT ano+1 FROM a WHERE ano < 2019)
  INSERT INTO modelo_veiculo (marca, modelo, ano) SELECT 'Volkswagen','Gol',ano FROM a;
WITH RECURSIVE a(ano) AS (SELECT 2016 UNION ALL SELECT ano+1 FROM a WHERE ano < 2022)
  INSERT INTO modelo_veiculo (marca, modelo, ano) SELECT 'Chevrolet','Onix',ano FROM a;
WITH RECURSIVE a(ano) AS (SELECT 2018 UNION ALL SELECT ano+1 FROM a WHERE ano < 2024)
  INSERT INTO modelo_veiculo (marca, modelo, ano) SELECT 'Fiat','Argo',ano FROM a;

INSERT INTO produto (id_categoria, codigo, nome, marca, descricao, preco_centavos, garantia_meses, destaque, avaliacao_media, avaliacao_quantidade, prazo_envio_horas, frete_gratis_acima_centavos) VALUES
  ((SELECT id_categoria FROM categoria WHERE nome='Freios'),     'FL-2034',  'Pastilha de Freio Dianteira', 'Fras-le', 'Pastilha cerâmica de baixo ruído, com sensor de desgaste.', 18990, 12, 1, 4.8, 32, 24, 30000),
  ((SELECT id_categoria FROM categoria WHERE nome='Elétrica'),   'MO-60AH',  'Bateria 60Ah',                'Moura',   'Bateria selada 60Ah, livre de manutenção.',               45990, 18, 1, 4.7, 51, 24, 30000),
  ((SELECT id_categoria FROM categoria WHERE nome='Suspensão'),  'BL-7731',  'Amortecedor Traseiro',        'Bilstein','Amortecedor a gás de alta durabilidade (par).',           24990, 12, 1, 4.6, 18, 48, 30000),
  ((SELECT id_categoria FROM categoria WHERE nome='Motor'),      'NGK-IR4',  'Jogo de Velas de Ignição',    'NGK',     'Jogo com 4 velas de ignição de irídio.',                  15990, 12, 1, 4.9, 77, 24, 30000),
  ((SELECT id_categoria FROM categoria WHERE nome='Motor'),      'MN-OF21',  'Filtro de Óleo',              'Mann',    'Filtro de óleo de alta eficiência de filtragem.',          3490,  6, 0, 4.5, 40, 24, 30000),
  ((SELECT id_categoria FROM categoria WHERE nome='Acessórios'), 'WB-PAL',   'Palheta Limpador (par)',      'Bosch',   'Par de palhetas de limpador de para-brisa.',               5990,  6, 0, 4.4, 22, 24, 30000);

INSERT INTO especificacao_produto (id_produto, nome, valor) VALUES
  ((SELECT id_produto FROM produto WHERE codigo='FL-2034'), 'Material', 'Cerâmico'),
  ((SELECT id_produto FROM produto WHERE codigo='FL-2034'), 'Posição',  'Dianteira'),
  ((SELECT id_produto FROM produto WHERE codigo='MO-60AH'), 'Capacidade', '60Ah'),
  ((SELECT id_produto FROM produto WHERE codigo='MO-60AH'), 'Tensão', '12V');

-- compatibilidade: pastilha só Gol e Onix; os demais servem em todos os modelos do seed
INSERT INTO produto_veiculo (id_produto, id_modelo_veiculo)
  SELECT p.id_produto, m.id_modelo_veiculo FROM produto p, modelo_veiculo m
  WHERE p.codigo = 'FL-2034' AND m.modelo IN ('Gol','Onix');
INSERT INTO produto_veiculo (id_produto, id_modelo_veiculo)
  SELECT p.id_produto, m.id_modelo_veiculo FROM produto p, modelo_veiculo m
  WHERE p.codigo <> 'FL-2034';

INSERT INTO cupom (codigo, tipo, valor, minimo_compra_centavos) VALUES ('MCCAR10','percentual',10,10000);
