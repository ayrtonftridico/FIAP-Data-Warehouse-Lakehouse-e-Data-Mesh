-- Query executiva para a Marina: top 5 clientes por receita liquida (SUM(valor_final)).
-- valor_final ja vem do UPDATE da Tarefa 5 e ja inclui o delta de CDC do MERGE.

SELECT
    c.id_cliente,
    c.nome || ' ' || c.sobrenome AS nome_completo,
    c.cidade,
    c.estado,
    c.segmento,
    ROUND(SUM(p.valor_final), 2) AS receita_total,
    COUNT(p.id_pedido)           AS qtd_pedidos,
    ROUND(AVG(p.valor_final), 2) AS ticket_medio,
    (2024 - c.ano_nascimento)    AS idade
FROM trabalho_final_aluno.pedidos_iceberg  AS p
JOIN trabalho_final_aluno.clientes_iceberg AS c
  ON p.id_cliente = c.id_cliente
GROUP BY
    c.id_cliente, c.nome, c.sobrenome,
    c.cidade, c.estado, c.segmento, c.ano_nascimento
ORDER BY receita_total DESC
LIMIT 5;
-- print 03_top5_clientes.png
