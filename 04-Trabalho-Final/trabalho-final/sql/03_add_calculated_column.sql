-- =====================================================================
-- Tarefa 5 - Adicionar coluna calculada `valor_final`
-- ---------------------------------------------------------------------
-- Materializa a regra de negocio:
--     valor_final = quantidade * preco_unitario * (1 - desconto) + frete
--
-- Passo 1: ALTER TABLE ADD COLUMNS  -> so altera metadado (~5s)
-- Passo 2: UPDATE                   -> regrava arquivos populando a coluna
--
-- Account ID: 163234203185
-- =====================================================================

-- ---------------------------------------------------------------------
-- 5.1 - Evolucao de schema: adiciona coluna valor_final (DOUBLE)
-- Operacao barata em Iceberg: apenas metadado, sem reescrever dados.
-- ---------------------------------------------------------------------
ALTER TABLE trabalho_final_aluno.pedidos_iceberg
ADD COLUMNS (valor_final DOUBLE);

-- ---------------------------------------------------------------------
-- 5.2 - Materializa valor_final em todas as 100.000 linhas
-- Tempo esperado no Athena: 30-60s
-- ---------------------------------------------------------------------
UPDATE trabalho_final_aluno.pedidos_iceberg
SET valor_final = quantidade * preco_unitario * (1 - desconto) + frete;

-- ---------------------------------------------------------------------
-- Validacao
-- Esperado: total=100000, com_valor=100000 (zero NULLs), min_valor>0
-- ---------------------------------------------------------------------
-- DESCRIBE trabalho_final_aluno.pedidos_iceberg;
--
-- SELECT
--     COUNT(*)                   AS total,
--     COUNT(valor_final)         AS com_valor,
--     ROUND(MIN(valor_final), 2) AS min_valor,
--     ROUND(MAX(valor_final), 2) AS max_valor,
--     ROUND(AVG(valor_final), 2) AS media_valor
-- FROM trabalho_final_aluno.pedidos_iceberg;
