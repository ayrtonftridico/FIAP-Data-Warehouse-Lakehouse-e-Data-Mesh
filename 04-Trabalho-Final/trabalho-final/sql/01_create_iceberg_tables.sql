-- =====================================================================
-- Tarefa 3 - Criar tabelas Iceberg vazias
-- ---------------------------------------------------------------------
-- Cria as duas tabelas Iceberg principais (entregaveis) no database
-- `trabalho_final_aluno`, vazias. A carga vem na Tarefa 4 (02_insert_data.sql).
--
-- Account ID usado: 163234203185
-- Bucket:            s3://tf-aluno-163234203185
-- Engine:            Amazon Athena (Iceberg)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 3.1 - clientes_iceberg
-- Espelha o schema final dos clientes (ja com tipos corretos).
-- ---------------------------------------------------------------------
CREATE TABLE trabalho_final_aluno.clientes_iceberg (
    id_cliente      STRING,
    nome            STRING,
    sobrenome       STRING,
    ano_nascimento  INT,
    cidade          STRING,
    estado          STRING,
    segmento        STRING
)
LOCATION 's3://tf-aluno-163234203185/iceberg/clientes/'
TBLPROPERTIES (
    'table_type'        = 'iceberg',
    'format'            = 'PARQUET',
    'write_compression' = 'zstd'
);

-- ---------------------------------------------------------------------
-- 3.2 - pedidos_iceberg
-- Atencao: data_pedido ja nasce como DATE (na raw vem como STRING).
-- A conversao acontece na carga (Tarefa 4) via CAST.
-- valor_final sera adicionado depois (Tarefa 5) via ALTER TABLE.
-- ---------------------------------------------------------------------
CREATE TABLE trabalho_final_aluno.pedidos_iceberg (
    id_pedido         STRING,
    id_cliente        STRING,
    data_pedido       DATE,
    categoria_produto STRING,
    quantidade        INT,
    preco_unitario    DOUBLE,
    desconto          DOUBLE,
    frete             DOUBLE
)
LOCATION 's3://tf-aluno-163234203185/iceberg/pedidos/'
TBLPROPERTIES (
    'table_type'        = 'iceberg',
    'format'            = 'PARQUET',
    'write_compression' = 'zstd'
);

-- ---------------------------------------------------------------------
-- Validacao (rodar separadamente no console Athena)
-- ---------------------------------------------------------------------
-- SHOW TABLES IN trabalho_final_aluno;            -- espera 5 tabelas (3 raw + 2 iceberg)
-- DESCRIBE trabalho_final_aluno.pedidos_iceberg;  -- data_pedido deve aparecer como date
-- SELECT COUNT(*) FROM trabalho_final_aluno.pedidos_iceberg;  -- espera 0
-- SHOW CREATE TABLE trabalho_final_aluno.pedidos_iceberg;     -- para o print 01_show_create_iceberg.png
