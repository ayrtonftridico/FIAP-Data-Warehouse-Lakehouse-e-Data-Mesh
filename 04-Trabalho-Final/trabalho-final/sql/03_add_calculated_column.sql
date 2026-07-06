-- Coluna calculada valor_final = quantidade * preco_unitario * (1 - desconto) + frete
-- Primeiro adiciono a coluna (so metadado, rapido), depois populo com UPDATE.

ALTER TABLE trabalho_final_aluno.pedidos_iceberg
ADD COLUMNS (valor_final DOUBLE);

UPDATE trabalho_final_aluno.pedidos_iceberg
SET valor_final = quantidade * preco_unitario * (1 - desconto) + frete;

-- validacao: com_valor tem que bater com total (100000), nenhum NULL
DESCRIBE trabalho_final_aluno.pedidos_iceberg;

SELECT
    COUNT(*)                   AS total,
    COUNT(valor_final)         AS com_valor,
    ROUND(MIN(valor_final), 2) AS min_valor,
    ROUND(MAX(valor_final), 2) AS max_valor,
    ROUND(AVG(valor_final), 2) AS media_valor
FROM trabalho_final_aluno.pedidos_iceberg;
