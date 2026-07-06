-- =====================================================================
-- Tarefa 6 - Aplicar delta de CDC com MERGE INTO
-- ---------------------------------------------------------------------
-- Estrategia (tarefa-ancora do trabalho):
--   1. CTAS Iceberg intermediaria `pedidos_delta_iceberg` com valor_final
--      ja calculado e data_pedido como DATE (mesmo schema do alvo).
--   2. MERGE INTO pedidos_iceberg USING pedidos_delta_iceberg ON id_pedido:
--        WHEN MATCHED    -> UPDATE  (2 pedidos: O000001, O000002)
--        WHEN NOT MATCHED-> INSERT  (3 pedidos: O100001, O100002, O100003)
--
-- Resultado esperado: pedidos_iceberg com 100.003 linhas.
--
-- Account ID: 163234203185
-- =====================================================================

-- ---------------------------------------------------------------------
-- 6.1 - CTAS Iceberg intermediaria do delta (5 linhas, COM valor_final)
-- Atencao: em CTAS Iceberg o parametro `is_external = false` e obrigatorio.
-- ---------------------------------------------------------------------
CREATE TABLE trabalho_final_aluno.pedidos_delta_iceberg
WITH (
    table_type        = 'ICEBERG',
    format            = 'PARQUET',
    write_compression = 'ZSTD',
    is_external       = false,
    location          = 's3://tf-aluno-163234203185/iceberg/pedidos_delta/'
) AS
SELECT
    id_pedido,
    id_cliente,
    CAST(data_pedido AS DATE) AS data_pedido,
    categoria_produto,
    quantidade,
    preco_unitario,
    desconto,
    frete,
    quantidade * preco_unitario * (1 - desconto) + frete AS valor_final
FROM trabalho_final_aluno.pedidos_delta;

-- Validacao da intermediaria:
-- SELECT * FROM trabalho_final_aluno.pedidos_delta_iceberg ORDER BY id_pedido;
-- Esperado: 5 linhas
--   O000001/O000002 (updates, desconto 0.50 / 0.45)
--   O100001/O100002/O100003 (inserts novos)

-- ---------------------------------------------------------------------
-- 6.2 - MERGE INTO: aplica os 5 deltas em uma unica transacao
-- Chave: id_pedido
-- Tempo esperado: 10-30s
-- ---------------------------------------------------------------------
MERGE INTO trabalho_final_aluno.pedidos_iceberg AS t
USING trabalho_final_aluno.pedidos_delta_iceberg AS s
   ON t.id_pedido = s.id_pedido
WHEN MATCHED THEN
    UPDATE SET
        id_cliente        = s.id_cliente,
        data_pedido       = s.data_pedido,
        categoria_produto = s.categoria_produto,
        quantidade        = s.quantidade,
        preco_unitario    = s.preco_unitario,
        desconto          = s.desconto,
        frete             = s.frete,
        valor_final       = s.valor_final
WHEN NOT MATCHED THEN
    INSERT (
        id_pedido,
        id_cliente,
        data_pedido,
        categoria_produto,
        quantidade,
        preco_unitario,
        desconto,
        frete,
        valor_final
    )
    VALUES (
        s.id_pedido,
        s.id_cliente,
        s.data_pedido,
        s.categoria_produto,
        s.quantidade,
        s.preco_unitario,
        s.desconto,
        s.frete,
        s.valor_final
    );

-- ---------------------------------------------------------------------
-- Validacao do MERGE
-- ---------------------------------------------------------------------
-- 1) Total apos merge: esperado 100003
-- SELECT COUNT(*) FROM trabalho_final_aluno.pedidos_iceberg;
--
-- 2) Os 2 updates com desconto atualizado e valor_final recalculado
-- SELECT t.id_pedido, t.desconto, t.valor_final
-- FROM trabalho_final_aluno.pedidos_iceberg t
-- JOIN trabalho_final_aluno.pedidos_delta_iceberg s
--   ON t.id_pedido = s.id_pedido
-- ORDER BY t.id_pedido;
--
-- 3) Snapshot do MERGE com operation = overwrite
-- SELECT snapshot_id, operation, summary
-- FROM "trabalho_final_aluno"."pedidos_iceberg$snapshots"
-- ORDER BY committed_at DESC
-- LIMIT 5;
--
-- -- Print para entrega: 02_count_apos_merge.png (COUNT(*) = 100003)
