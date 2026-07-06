-- Delta de CDC: 3 inserts (O100001/O100002/O100003) + 2 updates (O000001/O000002).
-- A raw pedidos_delta nao tem valor_final e tem data_pedido como STRING,
-- entao montei uma Iceberg intermediaria com o schema igual ao do alvo
-- e faco o MERGE a partir dela.

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

-- 5 linhas: 2 updates (desconto 0.50 / 0.45) + 3 inserts novos
SELECT * FROM trabalho_final_aluno.pedidos_delta_iceberg ORDER BY id_pedido;

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
        id_pedido, id_cliente, data_pedido, categoria_produto,
        quantidade, preco_unitario, desconto, frete, valor_final
    )
    VALUES (
        s.id_pedido, s.id_cliente, s.data_pedido, s.categoria_produto,
        s.quantidade, s.preco_unitario, s.desconto, s.frete, s.valor_final
    );

-- validacoes do merge
SELECT COUNT(*) FROM trabalho_final_aluno.pedidos_iceberg;  -- 100003 (print 02_count_apos_merge.png)

SELECT t.id_pedido, t.desconto, t.valor_final
FROM trabalho_final_aluno.pedidos_iceberg t
JOIN trabalho_final_aluno.pedidos_delta_iceberg s
  ON t.id_pedido = s.id_pedido
ORDER BY t.id_pedido;

SELECT snapshot_id, operation, summary
FROM "trabalho_final_aluno"."pedidos_iceberg$snapshots"
ORDER BY committed_at DESC
LIMIT 5;
