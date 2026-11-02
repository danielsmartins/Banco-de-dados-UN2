-- ==============================================================================
-- VERIFICAÇÃO: confere se o banco foi criado e povoado corretamente.
-- Todas as linhas devem mostrar ok = true.
-- ==============================================================================
\set QUIET on
\echo
\echo 'VERIFICAÇÃO DO BANCO: cada linha compara o número de linhas da tabela com o esperado.'
\echo 'Tudo certo quando a coluna ok mostra t (true) em todas as linhas.'
\pset title 'Verificação do povoamento'
SELECT t.tabela, t.linhas, t.esperado, (t.linhas = t.esperado) AS ok
FROM (
    SELECT 'Genero' AS tabela, COUNT(*) AS linhas, 4 AS esperado FROM Genero
    UNION ALL SELECT 'Editora', COUNT(*), 4 FROM Editora
    UNION ALL SELECT 'Autor', COUNT(*), 4 FROM Autor
    UNION ALL SELECT 'Obra', COUNT(*), 4 FROM Obra
    UNION ALL SELECT 'Obra_Autor', COUNT(*), 4 FROM Obra_Autor
    UNION ALL SELECT 'Exemplar', COUNT(*), 6 FROM Exemplar
    UNION ALL SELECT 'Cliente', COUNT(*), 4 FROM Cliente
    UNION ALL SELECT 'Telefone', COUNT(*), 4 FROM Telefone
    UNION ALL SELECT 'Pedido', COUNT(*), 3 FROM Pedido
    UNION ALL SELECT 'Item_Pedido', COUNT(*), 3 FROM Item_Pedido
    UNION ALL SELECT 'Entrega', COUNT(*), 3 FROM Entrega
    UNION ALL SELECT 'Doacao_Troca', COUNT(*), 3 FROM Doacao_Troca
    UNION ALL SELECT 'Item_Doacao', COUNT(*), 4 FROM Item_Doacao
    UNION ALL SELECT 'Mensagem_Contato', COUNT(*), 2 FROM Mensagem_Contato
) t;

\echo
\echo 'Número de tabelas criadas (esperado: 14):'
\pset title
SELECT COUNT(*) AS tabelas_criadas
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
\set QUIET off
