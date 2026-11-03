-- ==============================================================================
-- REGRAS DE NEGÓCIO IMPLEMENTADAS PELA APLICAÇÃO (SQL puro, sem triggers)
-- Cada demonstração explica a situação, executa a transação e mostra o antes e o
-- depois. Todas terminam em ROLLBACK para preservar os dados; na aplicação real,
-- o ROLLBACK seria COMMIT.
-- ==============================================================================
\set QUIET on
\echo
\echo '################################################################################'
\echo '#  REGRAS DE NEGÓCIO DO SEBO COMO TRANSAÇÕES SQL'
\echo '#  (o banco não usa triggers: quem executa estes passos é a aplicação)'
\echo '################################################################################'

-- 5.1 Compra de um exemplar (Carlos compra o exemplar 4)
\echo
\echo '================================================================================'
\echo 'TRANSAÇÃO 1 - UM CLIENTE COMPRA UM LIVRO'
\echo '================================================================================'
\echo 'Situação : Carlos Eduardo Menezes (cliente 1) quer comprar o exemplar 4 do livro'
\echo '           "1984" (estado excelente, preço de tabela R$ 34,00).'
\echo 'Passos   : (1) reserva o exemplar, marcando-o como indisponível;'
\echo '           (2) cria o pedido com status "pendente";'
\echo '           (3) cria o item do pedido COPIANDO o preço atual do exemplar;'
\echo '           (4) calcula o total do pedido;'
\echo '           (5) cria a entrega usando o endereço do cliente.'
\echo 'Em termos do sebo: o livro sai da vitrine para ninguém mais comprá-lo e o preço'
\echo '           pago fica gravado no pedido, mesmo que o sebo remarque o livro depois.'
\pset title 'ANTES - exemplar 4 na vitrine'
SELECT e.id_exemplar, o.titulo, e.estado_conservacao, e.preco_venda, e.disponivel
FROM Exemplar e JOIN Obra o USING (id_obra) WHERE e.id_exemplar = 4;
\echo '>> Executando a transação (BEGIN)...'
BEGIN;
UPDATE Exemplar SET disponivel = FALSE WHERE id_exemplar = 4 AND disponivel = TRUE;
INSERT INTO Pedido (id_cliente, status) VALUES (1, 'pendente');
INSERT INTO Item_Pedido (id_pedido, id_exemplar, preco_unitario)
SELECT currval('pedido_id_pedido_seq'), id_exemplar, preco_venda FROM Exemplar WHERE id_exemplar = 4;
UPDATE Pedido SET total = (SELECT SUM(preco_unitario) FROM Item_Pedido WHERE id_pedido = currval('pedido_id_pedido_seq'))
WHERE id_pedido = currval('pedido_id_pedido_seq');
INSERT INTO Entrega (id_pedido, logradouro, numero, cidade, estado, cep)
SELECT currval('pedido_id_pedido_seq'), rua, numero, cidade, estado, cep FROM Cliente WHERE id_cliente = 1;
\pset title 'DEPOIS - pedido criado (visível só dentro da transação)'
SELECT p.id_pedido, c.nome AS cliente, p.status AS status_pedido, o.titulo,
       ip.preco_unitario AS preco_cobrado, p.total, en.status AS status_entrega, en.cidade AS cidade_entrega
FROM Pedido p
JOIN Cliente c ON c.id_cliente = p.id_cliente
JOIN Item_Pedido ip ON ip.id_pedido = p.id_pedido
JOIN Exemplar e ON e.id_exemplar = ip.id_exemplar
JOIN Obra o ON o.id_obra = e.id_obra
JOIN Entrega en ON en.id_pedido = p.id_pedido
WHERE p.id_pedido = currval('pedido_id_pedido_seq');
\pset title 'DEPOIS - exemplar 4 saiu da vitrine'
SELECT id_exemplar, disponivel FROM Exemplar WHERE id_exemplar = 4;
ROLLBACK;
\echo '>> ROLLBACK: transação desfeita só para a demonstração (na aplicação seria COMMIT).'
\echo

-- 5.2 Tentativa de comprar um exemplar que já foi vendido
\echo '================================================================================'
\echo 'TRANSAÇÃO 2 - TENTATIVA DE COMPRAR UM LIVRO QUE JÁ FOI VENDIDO'
\echo '================================================================================'
\echo 'Situação : alguém tenta comprar o exemplar 1 ("Memórias Póstumas de Brás Cubas"),'
\echo '           que o Carlos já comprou no pedido 1.'
\echo 'Passo    : o mesmo UPDATE condicional da transação 1 (só reserva se disponivel = TRUE).'
\echo 'Resultado esperado: nenhuma linha é reservada. A aplicação percebe que 0 linhas foram'
\echo '           afetadas, dá ROLLBACK e avisa o cliente que o livro não está mais disponível.'
\echo 'Em termos do sebo: cada exemplar é uma cópia física individual, então a mesma cópia'
\echo '           nunca é vendida duas vezes, nem se duas pessoas clicarem em "comprar" ao mesmo tempo.'
\pset title 'ANTES - exemplar 1 (já vendido)'
SELECT id_exemplar, disponivel FROM Exemplar WHERE id_exemplar = 1;
\echo '>> Executando a tentativa de reserva...'
BEGIN;
\pset title 'RESULTADO - linhas reservadas (deve ser 0 linhas)'
UPDATE Exemplar SET disponivel = FALSE WHERE id_exemplar = 1 AND disponivel = TRUE RETURNING id_exemplar;
ROLLBACK;
\echo '>> 0 linhas reservadas: compra recusada, nada foi alterado.'
\echo

-- 5.3 Cancelamento de pedido (pedido 2)
\echo '================================================================================'
\echo 'TRANSAÇÃO 3 - CANCELAMENTO DE UM PEDIDO'
\echo '================================================================================'
\echo 'Situação : Mariana Ferreira Costa (cliente 2) desiste do pedido 2 ("1984", exemplar 3),'
\echo '           que estava pago e aguardando envio.'
\echo 'Passos   : (1) muda o status do pedido para "cancelado";'
\echo '           (2) devolve os exemplares do pedido para a vitrine (disponivel = TRUE).'
\echo 'Em termos do sebo: o livro volta a poder ser vendido para outro cliente. O pedido'
\echo '           continua no histórico, apenas marcado como cancelado.'
\pset title 'ANTES - pedido 2 e exemplar 3'
SELECT p.id_pedido, p.status AS status_pedido, e.id_exemplar, e.disponivel
FROM Pedido p JOIN Item_Pedido ip USING (id_pedido) JOIN Exemplar e USING (id_exemplar) WHERE p.id_pedido = 2;
\echo '>> Executando o cancelamento...'
BEGIN;
UPDATE Pedido SET status = 'cancelado' WHERE id_pedido = 2;
UPDATE Exemplar SET disponivel = TRUE
WHERE id_exemplar IN (SELECT id_exemplar FROM Item_Pedido WHERE id_pedido = 2);
\pset title 'DEPOIS - pedido 2 cancelado e exemplar 3 de volta à vitrine'
SELECT p.id_pedido, p.status AS status_pedido, e.id_exemplar, e.disponivel
FROM Pedido p JOIN Item_Pedido ip USING (id_pedido) JOIN Exemplar e USING (id_exemplar) WHERE p.id_pedido = 2;
ROLLBACK;
\echo '>> ROLLBACK: transação desfeita só para a demonstração.'
\echo

-- 5.4 Aceite de item de troca (item 3, de Rodrigo): cria o exemplar e gera crédito
\echo '================================================================================'
\echo 'TRANSAÇÃO 4 - O SEBO ACEITA UM LIVRO OFERECIDO EM TROCA'
\echo '================================================================================'
\echo 'Situação : Rodrigo Antunes Lins (cliente 3) ofereceu o livro "1984" em troca'
\echo '           (solicitação 2, item 3). O administrador avaliou e aceitou, atribuindo'
\echo '           R$ 15,00 de crédito.'
\echo 'Passos   : (1) cadastra o livro como novo exemplar do acervo (à venda por R$ 25,00);'
\echo '           (2) marca o item como "aceito", registra o valor avaliado e liga o item'
\echo '               ao novo exemplar;'
\echo '           (3) atualiza a solicitação: credito_gerado = soma dos itens aceitos e'
\echo '               status "concluida".'
\echo 'Em termos do sebo: o livro doado passa a fazer parte do acervo e o cliente fica com'
\echo '           R$ 15,00 de crédito registrado. Se fosse uma DOAÇÃO, o livro entraria no'
\echo '           acervo do mesmo jeito, mas o crédito continuaria 0.'
\pset title 'ANTES - solicitação 2 e item 3'
SELECT dt.id_doacao_troca, dt.tipo, dt.status AS status_solicitacao, dt.credito_gerado,
       it.id_item_doacao, it.titulo_informado, it.status_avaliacao, it.valor_avaliado, it.id_exemplar
FROM Doacao_Troca dt JOIN Item_Doacao it USING (id_doacao_troca) WHERE it.id_item_doacao = 3;
\echo '>> Executando o aceite...'
BEGIN;
INSERT INTO Exemplar (id_obra, codigo_tombo, estado_conservacao, preco_venda, data_aquisicao)
VALUES (2, 'TB-0007', 'bom', 25.00, CURRENT_DATE);
UPDATE Item_Doacao
   SET status_avaliacao = 'aceito', valor_avaliado = 15.00,
       id_exemplar = currval('exemplar_id_exemplar_seq')
 WHERE id_item_doacao = 3;
UPDATE Doacao_Troca
   SET credito_gerado = (SELECT COALESCE(SUM(valor_avaliado), 0) FROM Item_Doacao
                          WHERE id_doacao_troca = 2 AND status_avaliacao = 'aceito'),
       status = 'concluida', data_conclusao = CURRENT_DATE
 WHERE id_doacao_troca = 2 AND tipo = 'troca';
\pset title 'DEPOIS - item aceito, ligado ao novo exemplar, crédito gerado'
SELECT dt.id_doacao_troca, dt.tipo, dt.status AS status_solicitacao, dt.credito_gerado,
       it.id_item_doacao, it.titulo_informado, it.status_avaliacao, it.valor_avaliado, it.id_exemplar
FROM Doacao_Troca dt JOIN Item_Doacao it USING (id_doacao_troca) WHERE it.id_item_doacao = 3;
\pset title 'DEPOIS - novo exemplar no acervo'
SELECT e.id_exemplar, e.codigo_tombo, o.titulo, e.estado_conservacao, e.preco_venda, e.disponivel
FROM Exemplar e JOIN Obra o USING (id_obra) WHERE e.codigo_tombo = 'TB-0007';
ROLLBACK;
\echo '>> ROLLBACK: transação desfeita só para a demonstração.'

\pset title
\set QUIET off
