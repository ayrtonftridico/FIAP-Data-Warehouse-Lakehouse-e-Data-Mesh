# DECISION — Como evoluir `pedidos_iceberg` se a TPCH crescer 100×

## Contexto

Hoje a `pedidos_iceberg` cobre **100 mil pedidos** distribuídos em 2023–2024, sem particionamento, armazenada como Parquet + ZSTD em um único diretório no S3. A Marina consome dois acessos: a **query executiva** (top 5 clientes por receita líquida) e o **ciclo diário de CDC** (`MERGE INTO` com poucos deltas). Se a TPCH crescer **100×**, passamos a ~**10 milhões de pedidos** (~2 anos de dados) e o delta diário sobe proporcionalmente. O formato Iceberg já nos dá transacionalidade e snapshots, mas **a forma como a tabela está fisicamente organizada** (sem partitioning, sem ordem nos arquivos) passa a ser o gargalo: leituras analíticas varrem arquivos demais e o `MERGE` diário gera muitos arquivos pequenos.

## O que eu mudaria primeiro

**Particionamento por `mes_pedido` (derivado de `data_pedido`), com `OPTIMIZE` BIN_PACK agendado.**

Razões objetivas:

1. **Poda de leitura (partition pruning) na query executiva.** A Marina quase sempre filtra por período ("fechar o trimestre", "últimos 12 meses"). Com a tabela particionada por mês, o Athena lê só os arquivos dos meses relevantes em vez de varrer os 10M de pedidos. Em consultas do tipo `WHERE data_pedido >= DATE '2024-01-01'`, isso tipicamente reduz o volume de dados lidos em 10–50×, dependendo da janela.

2. **Contenção do `MERGE` diário.** O CDC do dia afeta quase exclusivamente pedidos do mês corrente (e raramente do mês anterior). Com a tabela particionada por mês, o Iceberg reescreve apenas os arquivos das partições atingidas pelo `MERGE`, em vez de varrer a tabela inteira para casar `id_pedido`. Isso reduz custo (bytes varridos no Athena) e tempo da ingestão diária.

3. **Sinergia direta com o que já existe.** Já temos `OPTIMIZE ... REWRITE DATA USING BIN_PACK` (Tarefa 7) rodando para compactar arquivos pequenos. Com particionamento mensal, o `OPTIMIZE` passa a atuar por partição — o que é exatamente o padrão de manutenção recomendado pelo Iceberg. Ou seja, **não é uma tecnologia nova**: é configurar a tabela atual para tirar proveito do que já rodamos.

## Alternativas que descartei (nesta primeira iteração)

| Alternativa | Por que não agora |
|---|---|
| **Z-ordering / multi-dimensional sorting** (`OPTIMIZE ... REWRITE DATA USING ZORDER`) | Excelente para acelerar filtros em colunas de cardinalidade alta (ex: `id_cliente`, `categoria_produto`), mas o Athena cobra por bytes varridos e o Z-order ainda varre a partição inteira. Sem particionar antes, o ganho relativo é menor e o custo do rewrite inicial em 10M de linhas é alto. Fica como **segunda iteração**, sobre a tabela já particionada por mês. |
| **Materialized View** (`CREATE MATERIALIZED VIEW`) pré-agregando receita por cliente | Reduziria a query executiva a um `SELECT` simples, mas troca latência por **custo de manutenção**: cada `MERGE` no CDC invalidaria a MV e exigiria refresh. Para um relatório que roda esporadicamente para o conselho, o custo/benefício é pior que particionar a fato. |
| **Migrar a ingestão para streaming (Kinesis + Athena Iceberg streaming upserts)** | Resolve a latência do CDC (de batch para near-real-time), mas a Marina pediu número consolidado **no dia seguinte** — não há requisito de minuto. Streaming traz complexidade operacional (checkpoint, ordering, exatamente-uma-vez) que não se paga neste volume. |
| **Particionamento por `categoria_produto`** | Cardinalidade baixa (~5–10 categorias) e distribuição desigual → partições muito heterogêneas e pequenas. `mes_pedido` tem cardinalidade controlada (~24 partições para 2 anos) e alinhamento natural com o padrão de filtro da Marina. |

## Como eu validaria a decisão

Após reparticionar (via `ALTER TABLE` + rewrite histórico em um job controlado), rodaria:

1. **Redução de bytes varridos na query executiva com filtro de período:**
   ```sql
   SELECT query_execution_status, data_scanned_bytes
   FROM "trabalho_final_aluno"."pedidos_iceberg$history"
   -- comparar execucoes antes/depois do particionamento
   -- alvo: queda de >=10x nos bytes varridos para janelas de 1-3 meses
   ```

2. **Custo do `MERGE` diário confinado à partição corrente:**
   ```sql
   SELECT snapshot_id, operation, summary
   FROM "trabalho_final_aluno"."pedidos_iceberg$snapshots"
   ORDER BY committed_at DESC LIMIT 5;
   -- validar no summary o campo changed_partitions/added-data-files
   -- restrito a 1-2 partições (mes atual + anterior), nao a tabela inteira
   ```

3. **Saúde física da tabela após o ciclo delta + OPTIMIZE mensal:**
   ```sql
   SELECT COUNT(*) AS num_arquivos,
          ROUND(AVG(file_size_in_bytes)/1024/1024, 2) AS tam_medio_mb
   FROM "trabalho_final_aluno"."pedidos_iceberg$files";
   -- alvo: poucos arquivos por particao, cada um >= 128 MB (longe do small-file problem)
   ```

## Pergunta para validar com o stakeholder

> Marina, o relatório do conselho é sempre sobre um **período fechado** (mês/trimestre) ou você também precisa de **ad-hoc por cliente/categoria** sem filtro de data? Se for o primeiro caso, o particionamento por mês resolve a maior parte do custo; se for o segundo, eu combino mês + Z-ordering em `id_cliente` numa segunda iteração.
