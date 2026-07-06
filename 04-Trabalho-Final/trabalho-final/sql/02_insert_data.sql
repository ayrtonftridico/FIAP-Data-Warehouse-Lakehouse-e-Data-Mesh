-- Carga inicial das duas Iceberg a partir das raw (catalogadas pelo Glue Crawler).
-- No pedidos, o CAST(data_pedido AS DATE) resolve a diferenca de tipo STRING -> DATE.

INSERT INTO trabalho_final_aluno.clientes_iceberg (
    id_cliente, nome, sobrenome, ano_nascimento, cidade, estado, segmento
)
SELECT
    id_cliente, nome, sobrenome, ano_nascimento, cidade, estado, segmento
FROM trabalho_final_aluno.clientes;

-- count esperado: 10000
SELECT COUNT(*) FROM trabalho_final_aluno.clientes_iceberg;

INSERT INTO trabalho_final_aluno.pedidos_iceberg (
    id_pedido, id_cliente, data_pedido, categoria_produto,
    quantidade, preco_unitario, desconto, frete
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

-- count=100000, data_min=2023-01-01, data_max=2024-12-31
SELECT
    COUNT(*)                   AS total,
    MIN(data_pedido)           AS data_min,
    MAX(data_pedido)           AS data_max,
    COUNT(DISTINCT id_cliente) AS clientes_distintos
FROM trabalho_final_aluno.pedidos_iceberg;

SELECT * FROM "trabalho_final_aluno"."pedidos_iceberg$snapshots";
