-- ==============================================================================
-- CONSULTAS ANALÍTICAS - Sebo Literário (Iteração 2)
-- Cada consulta imprime um texto explicativo antes do resultado.
-- ==============================================================================
\set QUIET on
\echo
\echo '################################################################################'
\echo '#  CONSULTAS ANALÍTICAS DO SEBO LITERÁRIO'
\echo '################################################################################'

-- 6.1 Catálogo com exemplares disponíveis e faixas de preço
\echo
\echo '================================================================================'
\echo 'CONSULTA 1 - CATÁLOGO DE LIVROS DISPONÍVEIS'
\echo '================================================================================'
\echo 'Tabelas usadas : Obra, Genero, Editora, Autor, Obra_Autor, Exemplar'
\echo 'O que mostra    : as obras que têm pelo menos 1 exemplar à venda (disponivel = TRUE),'
\echo '                  com autor, gênero, editora e a faixa de preço dos exemplares.'
\echo 'Como ler        : cada linha é uma OBRA. A coluna exemplares_disponiveis diz quantas'
\echo '                  cópias físicas dela ainda podem ser compradas.'
\echo 'No sebo         : é a vitrine do catálogo público do site.'
\pset title 'Consulta 1 - Catálogo: obras com exemplares disponíveis'
SELECT
    o.id_obra,
    o.titulo,
    STRING_AGG(DISTINCT a.nome, ', ') AS autores,
    g.nome AS genero,
    ed.nome AS editora,
    COUNT(DISTINCT e.id_exemplar) AS exemplares_disponiveis,
    MIN(e.preco_venda) AS menor_preco,
    MAX(e.preco_venda) AS maior_preco
FROM Obra o
JOIN Genero g ON o.id_genero = g.id_genero
JOIN Editora ed ON o.id_editora = ed.id_editora
JOIN Obra_Autor oa ON o.id_obra = oa.id_obra
JOIN Autor a ON oa.id_autor = a.id_autor
JOIN Exemplar e ON o.id_obra = e.id_obra
WHERE e.disponivel = TRUE
GROUP BY o.id_obra, o.titulo, g.nome, ed.nome
ORDER BY o.titulo;

-- 6.2 Histórico de pedidos de um cliente (id_cliente = 1)
\echo
\echo '================================================================================'
\echo 'CONSULTA 2 - HISTÓRICO DE PEDIDOS DE UM CLIENTE'
\echo '================================================================================'
\echo 'Tabelas usadas : Pedido, Item_Pedido, Exemplar, Obra, Entrega'
\echo 'O que mostra    : tudo o que o cliente 1 (Carlos Eduardo Menezes) comprou: pedido,'
\echo '                  livro, estado do exemplar, preço pago, total e situação da entrega.'
\echo 'Como ler        : cada linha é um ITEM de pedido. preco_unitario é o valor cobrado'
\echo '                  no dia da compra (fica gravado, mesmo se o sebo remarcar o livro).'
\echo 'No sebo         : é a tela "Meus pedidos" do cliente.'
\pset title 'Consulta 2 - Pedidos do cliente 1 (Carlos Eduardo Menezes)'
SELECT
    p.id_pedido, p.data, p.status,
    o.titulo AS obra, e.estado_conservacao,
    ip.preco_unitario, p.total,
    en.status AS status_entrega, en.data_prevista, en.data_entrega
FROM Pedido p
JOIN Item_Pedido ip ON p.id_pedido = ip.id_pedido
JOIN Exemplar e ON ip.id_exemplar = e.id_exemplar
JOIN Obra o ON e.id_obra = o.id_obra
LEFT JOIN Entrega en ON p.id_pedido = en.id_pedido
WHERE p.id_cliente = 1
ORDER BY p.data DESC;

-- 6.3 Faturamento e vendas por gênero (pedidos pagos, enviados ou entregues)
\echo
\echo '================================================================================'
\echo 'CONSULTA 3 - FATURAMENTO POR GÊNERO LITERÁRIO'
\echo '================================================================================'
\echo 'Tabelas usadas : Item_Pedido, Pedido, Exemplar, Obra, Genero'
\echo 'O que mostra    : quantos livros foram vendidos e quanto cada gênero faturou.'
\echo 'Como ler        : só entram pedidos pagos, enviados ou entregues. Pedidos pendentes'
\echo '                  ou cancelados não contam como venda. ticket_medio = preço médio'
\echo '                  por livro vendido naquele gênero.'
\echo 'No sebo         : relatório do administrador para decidir quais gêneros buscar.'
\pset title 'Consulta 3 - Vendas e faturamento por gênero'
SELECT
    g.nome AS genero,
    COUNT(ip.id_item_pedido) AS livros_vendidos,
    SUM(ip.preco_unitario) AS faturamento,
    ROUND(AVG(ip.preco_unitario), 2) AS ticket_medio
FROM Item_Pedido ip
JOIN Pedido p ON ip.id_pedido = p.id_pedido
JOIN Exemplar e ON ip.id_exemplar = e.id_exemplar
JOIN Obra o ON e.id_obra = o.id_obra
JOIN Genero g ON o.id_genero = g.id_genero
WHERE p.status IN ('pago', 'enviado', 'entregue')
GROUP BY g.nome
ORDER BY faturamento DESC;

-- 6.4 Doações e trocas: itens enviados, aceitos e crédito gerado
\echo
\echo '================================================================================'
\echo 'CONSULTA 4 - DOAÇÕES E TROCAS E CRÉDITO GERADO'
\echo '================================================================================'
\echo 'Tabelas usadas : Doacao_Troca, Cliente, Item_Doacao'
\echo 'O que mostra    : cada solicitação de doação ou troca, quantos livros o cliente'
\echo '                  enviou, quantos o sebo aceitou e quanto crédito foi gerado.'
\echo 'Como ler        : tipo = troca gera crédito para compras futuras; tipo = doacao'
\echo '                  nunca gera (credito_gerado fica 0). itens_aceitos conta só os'
\echo '                  livros que passaram na avaliação do sebo.'
\echo 'No sebo         : fila de trabalho do administrador (pendentes) e controle de crédito.'
\pset title 'Consulta 4 - Solicitações de doação/troca e crédito gerado'
SELECT
    dt.id_doacao_troca,
    c.nome AS cliente,
    dt.tipo,
    dt.status,
    COUNT(it.id_item_doacao) AS itens_enviados,
    COUNT(*) FILTER (WHERE it.status_avaliacao = 'aceito') AS itens_aceitos,
    dt.credito_gerado
FROM Doacao_Troca dt
JOIN Cliente c ON dt.id_cliente = c.id_cliente
LEFT JOIN Item_Doacao it ON dt.id_doacao_troca = it.id_doacao_troca
GROUP BY dt.id_doacao_troca, c.nome, dt.tipo, dt.status, dt.credito_gerado
ORDER BY dt.data_solicitacao;

-- 6.5 Estoque disponível por estado de conservação
\echo
\echo '================================================================================'
\echo 'CONSULTA 5 - ESTOQUE DISPONÍVEL POR ESTADO DE CONSERVAÇÃO'
\echo '================================================================================'
\echo 'Tabelas usadas : Exemplar'
\echo 'O que mostra    : quantos exemplares estão à venda em cada estado de conservação,'
\echo '                  que fração do estoque isso representa e a faixa de preços.'
\echo 'Como ler        : percentual = parte do estoque disponível naquele estado.'
\echo '                  Exemplares já vendidos não entram.'
\echo 'No sebo         : ajuda a precificar e a decidir que tipo de livro aceitar em trocas.'
\pset title 'Consulta 5 - Estoque disponível por estado de conservação'
SELECT
    e.estado_conservacao,
    COUNT(*) AS quantidade,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Exemplar WHERE disponivel = TRUE), 2) AS percentual,
    MIN(e.preco_venda) AS menor_preco,
    ROUND(AVG(e.preco_venda), 2) AS preco_medio,
    MAX(e.preco_venda) AS maior_preco
FROM Exemplar e
WHERE e.disponivel = TRUE
GROUP BY e.estado_conservacao
ORDER BY quantidade DESC;

\pset title
\set QUIET off
