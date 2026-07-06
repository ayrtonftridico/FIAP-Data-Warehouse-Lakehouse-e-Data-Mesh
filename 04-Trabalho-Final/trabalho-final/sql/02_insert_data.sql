-- =====================================================================
-- Tarefa 4 - Carregar dados iniciais
-- ---------------------------------------------------------------------
-- Popula as duas Iceberg principais a partir das tabelas raw (Hive externa)
-- catalogadas pelo Glue Crawler na Tarefa 2.
--
-- Pontos chave:
--  * Colunas listadas explicitamente (contrato visivel).
--  * CAST(data_pedido AS DATE): na raw vem STRING (YYYY-MM-DD),
--    na Iceberg a coluna é DATE. Conversao canonica schema-on-write.
--
-- Account ID: 163234203185
-- =====================================================================

-- ---------------------------------------------------------------------
-- 4.1 - Carga de clientes_iceberg (esperado: 10.000 linhas)
-- ---------------------------------------------------------------------
INSERT INTO trabalho_final_aluno.clientes_iceberg (
    id_cliente,
    nome,
    sobrenome,
    ano_nascimento,
    cidade,
    estado,
    segmento
)
SELECT
    id_cliente,
    nome,
    sobrenome,
    ano_nascimento,
    cidade,
    estado,
    segmento
FROM trabalho_final_aluno.clientes;

-- Validacao:
-- SELECT COUNT(*) FROM trabalho_final_aluno.clientes_iceberg;  -- esperado: 10000

-- ---------------------------------------------------------------------
-- 4.2 - Carga de pedidos_iceberg (esperado: 100.000 linhas)
-- Conversao critica de tipo: data_pedido STRING -> DATE
-- ---------------------------------------------------------------------
INSERT INTO trabalho_final_aluno.pedidos_iceberg (
    id_pedido,
    id_cliente,
    data_pedido,
    categoria_produto,
    quantidade,
    preco_unitario,
    desconto,
    frete
)
SELECT
    id_pedido,
    id_cliente,
    CAST(data_pedido AS DATE) AS data_pedido,
    categoria_produto,
    quantidade,
    preco_unitario,
    desconto,
    frete
FROM trabalho_final_aluno.pedidos;

-- ---------------------------------------------------------------------
-- Validacao consolidada da carga de pedidos
-- Esperado: total=100000, data_min=2023-01-01, data_max=2024-12-31
-- ---------------------------------------------------------------------
-- SELECT
--     COUNT(*)                   AS total,
--     MIN(data_pedido)           AS data_min,
--     MAX(data_pedido)           AS data_max,
--     COUNT(DISTINCT id_cliente) AS clientes_distintos
-- FROM trabalho_final_aluno.pedidos_iceberg;

-- Snapshots apos a carga:
-- SELECT * FROM "trabalho_final_aluno"."pedidos_iceberg$snapshots";
