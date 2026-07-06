# Trabalho Final — Lakehouse Iceberg (TPCH Trading)

Entrega do trabalho final da disciplina **Data Warehouse, Lakehouse e Data Mesh (FIAP)**.
Pipeline lakehouse ponta a ponta no Amazon Athena: CSV → Glue Catalog → Iceberg →
`MERGE INTO` (CDC) → `OPTIMIZE` → query executiva.

- **Account ID usado nos SQLs:** `163234203185`
- **Bucket:** `s3://tf-aluno-163234203185`
- **Database Glue:** `trabalho_final_aluno`

## Estrutura

```
trabalho-final/
├── sql/
│   ├── 01_create_iceberg_tables.sql   # Tarefa 3  - DDL Iceberg (clientes_iceberg, pedidos_iceberg)
│   ├── 02_insert_data.sql             # Tarefa 4  - INSERT INTO ... SELECT + CAST(data_pedido AS DATE)
│   ├── 03_add_calculated_column.sql   # Tarefa 5  - ALTER TABLE ADD COLUMNS + UPDATE valor_final
│   ├── 04_merge_delta.sql             # Tarefa 6  - CTAS pedidos_delta_iceberg + MERGE INTO
│   ├── 05_optimize.sql                # Tarefa 7  - OPTIMIZE BIN_PACK + VACUUM
│   └── 06_query_executiva.sql         # Tarefa 8  - Top 5 clientes por receita liquida
├── prints/
│   ├── 01_show_create_iceberg.png     # Tarefa 3  - SHOW CREATE TABLE pedidos_iceberg (Iceberg)
│   ├── 02_count_apos_merge.png        # Tarefa 6  - SELECT COUNT(*) = 100003
│   └── 03_top5_clientes.png           # Tarefa 8  - resultado das 5 linhas
└── DECISION.md                        # Tarefa 9  - ADR de evolução para 100×
```

## Ordem de execução no Athena

> Pré-requisito (não incluído aqui — roda no Codespaces): Tarefas 1 e 2 do enunciado
> (`scripts/setup_aluno.sh` e `scripts/setup_glue_crawler.sh`), que criam o bucket,
> os 3 CSVs e catalogam as 3 tabelas raw no Glue.

1. Configurar **Resultado da consulta** do Athena para
   `s3://tf-aluno-163234203185/athena-results/`.
2. Selecionar o database `trabalho_final_aluno` no painel esquerdo.
3. Rodar os SQLs **na ordem dos nomes** (01 → 06). Cada arquivo contém,
   além dos comandos principais, blocos de validação comentados (`-- ...`).
4. Atenção especial:
   - **05_optimize.sql**: `OPTIMIZE` e `VACUUM` **devem rodar em queries separadas**
     no console (o Athena recusa `VACUUM` em statement múltiplo).
   - **04_merge_delta.sql**: a CTAS intermediária (`pedidos_delta_iceberg`)
     exige `is_external = false` no bloco `WITH (...)` — já está assim no arquivo.
5. Capturar os 3 prints listados acima (janela inteira, legível) e colocar em
   `prints/`.

## Resultados esperados (checkpoints)

| Tarefa | Checkpoint |
|--------|------------|
| 3 | `SHOW TABLES` lista 5 tabelas; `DESCRIBE pedidos_iceberg` mostra `data_pedido date`; `COUNT(*) = 0` |
| 4 | `clientes_iceberg = 10000`; `pedidos_iceberg = 100000`; `data_min = 2023-01-01`, `data_max = 2024-12-31` |
| 5 | `com_valor = total = 100000` (zero NULLs); `min_valor > 0` |
| 6 | `COUNT(*) = 100003`; 2 updates com `desconto = 0.50 / 0.45`; snapshot novo `operation = overwrite` |
| 7 | `num_arquivos_depois < num_arquivos_antes` (geralmente 1–3); snapshot `operation = replace`; `COUNT(*) = 100003` |
| 8 | 5 linhas em ordem decrescente de `receita_total`, com `qtd_pedidos > 0` e `ticket_medio > 0` |

## Entrega (Tarefa 10)

1. Na máquina local, montar a pasta `trabalho-final/` exatamente como acima
   (com os 6 SQLs, 3 prints e o `DECISION.md`).
2. Compactar a pasta em `trabalho-final.zip` (no Windows: botão direito →
   *Enviar para → Pasta compactada (zip)*).
3. Subir o `.zip` no **portal FIAP**, no espaço do trabalho da turma.
   > O upload no portal é a **única** forma de submissão válida.

## Limpeza (Tarefa 11) — obrigatória após entrega

```bash
aws s3 rm "s3://tf-aluno-163234203185" --recursive
aws s3 rb "s3://tf-aluno-163234203185"
```

No console Glue: deletar o database `trabalho_final_aluno` e o crawler
`crawler-trabalho-final-aluno`. Confirmar com `aws s3 ls | grep tf-aluno`.
