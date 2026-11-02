-- 6.1 Catálogo com exemplares disponíveis e faixas de preço
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
