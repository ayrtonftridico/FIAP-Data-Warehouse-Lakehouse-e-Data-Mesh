-- =====================================================================
-- Tarefa 8 - Query executiva: Top 5 clientes por receita liquida
-- ---------------------------------------------------------------------
-- Entregavel simbolico para a Marina (CFO).
-- JOIN pedidos_iceberg x clientes_iceberg, agregando SUM(valor_final).
--
-- Observacoes:
--  * valor_final ja esta materializado (Tarefa 5) e consolidado com o
--    delta de CDC (Tarefa 6) -> o numero reflete os ajustes de ultima
--    hora pedidos pela Marina.
--  * idade e opcional (enriquecimento analitico), mantida no SELECT.
--
-- Account ID: 163234203185
-- =====================================================================

SELECT
    c.id_cliente,
    c.nome || ' ' || c.sobrenome             AS nome_completo,
    c.cidade,
    c.estado,
    c.segmento,
    ROUND(SUM(p.valor_final), 2)             AS receita_total,
    COUNT(p.id_pedido)                       AS qtd_pedidos,
    ROUND(AVG(p.valor_final), 2)             AS ticket_medio,
    (2024 - c.ano_nascimento)                AS idade
FROM trabalho_final_aluno.pedidos_iceberg   AS p
JOIN trabalho_final_aluno.clientes_iceberg  AS c
  ON p.id_cliente = c.id_cliente
GROUP BY
    c.id_cliente,
    c.nome,
    c.sobrenome,
    c.cidade,
    c.estado,
    c.segmento,
    c.ano_nascimento
ORDER BY receita_total DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- Anotar para o relatorio: id_cliente e receita_total do #1 da lista.
-- Print para entrega: 03_top5_clientes.png (resultado das 5 linhas)
-- ---------------------------------------------------------------------
