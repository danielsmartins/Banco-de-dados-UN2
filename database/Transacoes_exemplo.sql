-- ==============================================================================
-- REGRAS DE NEGÓCIO IMPLEMENTADAS PELA APLICAÇÃO (SQL puro, sem triggers)
-- Cada bloco é uma transação; os exemplos terminam em ROLLBACK para preservar o
-- povoamento. Na aplicação, troque ROLLBACK por COMMIT.
-- ==============================================================================

-- 5.1 Compra de um exemplar (Carlos compra o exemplar 4)
BEGIN;
-- Reserva o exemplar. Se afetar 0 linhas, ele já foi vendido: a aplicação dá ROLLBACK.
UPDATE Exemplar SET disponivel = FALSE WHERE id_exemplar = 4 AND disponivel = TRUE;
INSERT INTO Pedido (id_cliente, status) VALUES (1, 'pendente');
-- O preço cobrado é copiado do exemplar e fica gravado no item
INSERT INTO Item_Pedido (id_pedido, id_exemplar, preco_unitario)
SELECT currval('pedido_id_pedido_seq'), id_exemplar, preco_venda FROM Exemplar WHERE id_exemplar = 4;
-- Total derivado do pedido
UPDATE Pedido SET total = (SELECT SUM(preco_unitario) FROM Item_Pedido WHERE id_pedido = currval('pedido_id_pedido_seq'))
WHERE id_pedido = currval('pedido_id_pedido_seq');
-- Entrega com o endereço do cliente
INSERT INTO Entrega (id_pedido, logradouro, numero, cidade, estado, cep)
SELECT currval('pedido_id_pedido_seq'), rua, numero, cidade, estado, cep FROM Cliente WHERE id_cliente = 1;
SELECT p.id_pedido, p.status, p.total, ip.preco_unitario, e.disponivel
FROM Pedido p JOIN Item_Pedido ip USING (id_pedido) JOIN Exemplar e USING (id_exemplar)
WHERE p.id_pedido = currval('pedido_id_pedido_seq');
ROLLBACK;

-- 5.2 Cancelamento de pedido (pedido 2): os exemplares voltam ao catálogo
BEGIN;
UPDATE Pedido SET status = 'cancelado' WHERE id_pedido = 2;
UPDATE Exemplar SET disponivel = TRUE
WHERE id_exemplar IN (SELECT id_exemplar FROM Item_Pedido WHERE id_pedido = 2);
SELECT id_exemplar, disponivel FROM Exemplar WHERE id_exemplar = 3;
ROLLBACK;

-- 5.3 Aceite de item de troca (item 3, de Rodrigo): cria o exemplar e gera crédito
BEGIN;
INSERT INTO Exemplar (id_obra, codigo_tombo, estado_conservacao, preco_venda, data_aquisicao)
VALUES (2, 'TB-0007', 'bom', 25.00, CURRENT_DATE);
UPDATE Item_Doacao
   SET status_avaliacao = 'aceito', valor_avaliado = 15.00,
       id_exemplar = currval('exemplar_id_exemplar_seq')
 WHERE id_item_doacao = 3;
-- credito_gerado = soma dos itens aceitos (só em troca)
UPDATE Doacao_Troca
   SET credito_gerado = (SELECT COALESCE(SUM(valor_avaliado), 0) FROM Item_Doacao
                          WHERE id_doacao_troca = 2 AND status_avaliacao = 'aceito'),
       status = 'concluida', data_conclusao = CURRENT_DATE
 WHERE id_doacao_troca = 2 AND tipo = 'troca';
SELECT id_doacao_troca, status, credito_gerado FROM Doacao_Troca WHERE id_doacao_troca = 2;
ROLLBACK;
