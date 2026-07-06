-- Cria as duas tabelas Iceberg vazias no database trabalho_final_aluno.
-- data_pedido ja nasce como DATE (na raw vem como STRING, converto na carga).
-- valor_final entra depois, via ALTER TABLE.

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

-- validacoes (rodei cada uma no console)
SHOW TABLES IN trabalho_final_aluno;                       -- 5 tabelas: 3 raw + 2 iceberg
DESCRIBE trabalho_final_aluno.pedidos_iceberg;             -- data_pedido aparece como date
SELECT COUNT(*) FROM trabalho_final_aluno.pedidos_iceberg; -- 0
SHOW CREATE TABLE trabalho_final_aluno.pedidos_iceberg;    -- print 01_show_create_iceberg.png
