-- =====================================================================
-- Tarefa 7 - Otimizar a tabela (OPTIMIZE BIN_PACK + VACUUM)
-- ---------------------------------------------------------------------
-- Compacta arquivos pequenos da pedidos_iceberg em arquivos maiores
-- (~512 MB) sem alterar dados de negocio, e limpa snapshots/ arquivos
-- orfaos com VACUUM.
--
-- IMPORTANT: OPTIMIZE e VACUUM devem rodar em queries SEPARADAS no
-- console Athena (VACUUM nao roda em statement multiplo composto).
--
-- Account ID: 163234203185
-- =====================================================================

-- ---------------------------------------------------------------------
-- 7.1 - Foto ANTES do OPTIMIZE (rodar separadamente)
-- ---------------------------------------------------------------------
-- SELECT COUNT(*) AS num_arquivos_antes
-- FROM "trabalho_final_aluno"."pedidos_iceberg$files";

-- ---------------------------------------------------------------------
-- 7.2 - OPTIMIZE BIN_PACK (rodar em query isolada)
-- ---------------------------------------------------------------------
OPTIMIZE trabalho_final_aluno.pedidos_iceberg REWRITE DATA USING BIN_PACK;

-- ---------------------------------------------------------------------
-- 7.3 - VACUUM (rodar em query isolada, separada do OPTIMIZE)
-- Limpa snapshots orfaos alem do retention default (5 dias).
-- ---------------------------------------------------------------------
VACUUM trabalho_final_aluno.pedidos_iceberg;

-- ---------------------------------------------------------------------
-- 7.4 - Foto DEPOIS do OPTIMIZE (rodar separadamente)
-- Esperado: num_arquivos_depois < num_arquivos_antes (geralmente 1-3)
-- ---------------------------------------------------------------------
-- SELECT COUNT(*) AS num_arquivos_depois
-- FROM "trabalho_final_aluno"."pedidos_iceberg$files";
--
-- -- Snapshot novo com operation = replace
-- SELECT snapshot_id, operation, summary
-- FROM "trabalho_final_aluno"."pedidos_iceberg$snapshots"
-- ORDER BY committed_at DESC
-- LIMIT 5;
--
-- -- Sanity check dos dados (continua 100003)
-- SELECT COUNT(*) FROM trabalho_final_aluno.pedidos_iceberg;
