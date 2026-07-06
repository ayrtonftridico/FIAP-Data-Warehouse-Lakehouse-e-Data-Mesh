-- Compacta os arquivos da pedidos_iceberg (BIN_PACK) e limpa snapshots orfaos (VACUUM).
-- ATENCAO: o Athena nao roda VACUUM junto com outros comandos. Rode OPTIMIZE e
-- VACUUM em queries separadas no console.

-- foto antes
SELECT COUNT(*) AS num_arquivos_antes
FROM "trabalho_final_aluno"."pedidos_iceberg$files";

OPTIMIZE trabalho_final_aluno.pedidos_iceberg REWRITE DATA USING BIN_PACK;

-- rode em query separada da de cima:
VACUUM trabalho_final_aluno.pedidos_iceberg;

-- foto depois (num_arquivos cai; COUNT continua 100003)
SELECT COUNT(*) AS num_arquivos_depois
FROM "trabalho_final_aluno"."pedidos_iceberg$files";

SELECT snapshot_id, operation, summary
FROM "trabalho_final_aluno"."pedidos_iceberg$snapshots"
ORDER BY committed_at DESC
LIMIT 5;

SELECT COUNT(*) FROM trabalho_final_aluno.pedidos_iceberg;
