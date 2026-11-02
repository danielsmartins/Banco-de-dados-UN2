-- ==============================================================================
-- POVOAMENTO DA BASE DE DADOS (executar após DDL_esquema.sql)
-- ==============================================================================

INSERT INTO Genero (nome) VALUES
('Literatura Brasileira'), ('Distopia'), ('Filosofia'), ('Fantasia');

INSERT INTO Editora (nome, pais, telefone) VALUES
('Companhia das Letras', 'Brasil', '(11) 3707-3500'),
('Editora Record', 'Brasil', '(21) 2585-2000'),
('Nova Fronteira', 'Brasil', '(21) 3882-8200'),
('Martin Claret', 'Brasil', '(11) 3672-8144');

INSERT INTO Autor (nome, nacionalidade, data_nascimento) VALUES
('Machado de Assis', 'Brasileira', '1839-06-21'),
('George Orwell', 'Britânica', '1903-06-25'),
('Clarice Lispector', 'Brasileira', '1920-12-10'),
('J.R.R. Tolkien', 'Britânica', '1892-01-03');

INSERT INTO Obra (titulo, ano_publicacao, idioma, id_genero, id_editora) VALUES
('Memórias Póstumas de Brás Cubas', 1881, 'Português', 1, 1),
('1984', 1949, 'Português', 2, 1),
('A Hora da Estrela', 1977, 'Português', 1, 2),
('O Hobbit', 1937, 'Português', 4, 3);

INSERT INTO Obra_Autor (id_obra, id_autor) VALUES (1, 1), (2, 2), (3, 3), (4, 4);

INSERT INTO Exemplar (id_obra, codigo_tombo, estado_conservacao, preco_venda, disponivel, data_aquisicao) VALUES
(1, 'TB-0001', 'bom',       28.50, FALSE, '2026-08-10'),  -- vendido no pedido 1
(1, 'TB-0002', 'excelente', 55.00, TRUE,  '2026-09-02'),
(2, 'TB-0003', 'regular',   19.90, FALSE, '2026-08-15'),  -- vendido no pedido 2
(2, 'TB-0004', 'excelente', 34.00, TRUE,  '2026-09-20'),
(3, 'TB-0005', 'bom',       22.00, TRUE,  '2026-09-25'),
(4, 'TB-0006', 'excelente', 48.00, TRUE,  '2026-10-01');  -- pedido 3 cancelado: segue disponível

-- Os hashes abaixo são apenas ilustrativos (a aplicação gera o hash com bcrypt)
INSERT INTO Cliente (nome, email, senha_hash, perfil, rua, numero, complemento, bairro, cidade, estado, cep) VALUES
('Carlos Eduardo Menezes', 'carlos.menezes@email.com', '$2b$12$exemploHashCarlos0000000000000000000000000000000000', 'cliente', 'Avenida Senador Salgado Filho', '3000', 'Apto 204', 'Candelária', 'Natal', 'RN', '59064-741'),
('Mariana Ferreira Costa', 'mariana.costa@email.com', '$2b$12$exemploHashMariana000000000000000000000000000000000', 'cliente', 'Rua Jaguarari', '1450', NULL, 'Lagoa Nova', 'Natal', 'RN', '59054-500'),
('Rodrigo Antunes Lins', 'rodrigo.lins@email.com', '$2b$12$exemploHashRodrigo000000000000000000000000000000000', 'cliente', 'Avenida Engenheiro Roberto Freire', '2920', 'Bloco B', 'Capim Macio', 'Natal', 'RN', '59082-000'),
('Administrador do Sebo', 'admin@sebo.com', '$2b$12$exemploHashAdmin0000000000000000000000000000000000', 'admin', NULL, NULL, NULL, NULL, 'Natal', 'RN', NULL);

INSERT INTO Telefone (id_cliente, numero) VALUES
(1, '(84) 99876-1234'), (1, '(84) 3211-0099'), (2, '(84) 98765-4321'), (3, '(84) 99123-4567');

-- Pedido 1 (entregue): Carlos comprou o exemplar 1
INSERT INTO Pedido (id_cliente, data, status, total) VALUES (1, CURRENT_DATE - 6, 'entregue', 28.50);
INSERT INTO Item_Pedido (id_pedido, id_exemplar, preco_unitario) VALUES (1, 1, 28.50);
INSERT INTO Entrega (id_pedido, status, logradouro, numero, cidade, estado, cep, data_prevista, data_entrega) VALUES
(1, 'entregue', 'Avenida Senador Salgado Filho', '3000', 'Natal', 'RN', '59064-741', CURRENT_DATE - 2, CURRENT_DATE - 3);

-- Pedido 2 (pago): Mariana comprou o exemplar 3
INSERT INTO Pedido (id_cliente, data, status, total) VALUES (2, CURRENT_DATE - 1, 'pago', 19.90);
INSERT INTO Item_Pedido (id_pedido, id_exemplar, preco_unitario) VALUES (2, 3, 19.90);
INSERT INTO Entrega (id_pedido, status, logradouro, numero, cidade, estado, cep, data_prevista) VALUES
(2, 'preparando', 'Rua Jaguarari', '1450', 'Natal', 'RN', '59054-500', CURRENT_DATE + 4);

-- Pedido 3 (cancelado): Rodrigo desistiu do exemplar 6, que voltou a ficar disponível
INSERT INTO Pedido (id_cliente, data, status, total) VALUES (3, CURRENT_DATE - 4, 'cancelado', 48.00);
INSERT INTO Item_Pedido (id_pedido, id_exemplar, preco_unitario) VALUES (3, 6, 48.00);
INSERT INTO Entrega (id_pedido, status, logradouro, numero, cidade, estado, cep) VALUES
(3, 'preparando', 'Avenida Engenheiro Roberto Freire', '2920', 'Natal', 'RN', '59082-000');

-- Doações e trocas
INSERT INTO Doacao_Troca (id_cliente, tipo, status, data_solicitacao, data_conclusao, credito_gerado) VALUES
(1, 'troca',   'concluida',    CURRENT_DATE - 10, CURRENT_DATE - 7, 50.00),
(3, 'troca',   'pendente',     CURRENT_DATE - 2,  NULL,             0),
(2, 'doacao',  'em_avaliacao', CURRENT_DATE - 1,  NULL,             0);

INSERT INTO Item_Doacao (id_doacao_troca, id_exemplar, titulo_informado, autor_informado, estado_informado, status_avaliacao, valor_avaliado) VALUES
(1, 2,    'Memórias Póstumas de Brás Cubas - Capa Dura', 'Machado de Assis', 'excelente', 'aceito',   50.00),
(1, NULL, 'Dom Casmurro - exemplar com páginas soltas',  'Machado de Assis', 'danificado', 'recusado', NULL),
(2, NULL, '1984',                                        'George Orwell',    'bom',        'pendente', NULL),
(3, NULL, 'Cálculo com Geometria Analítica',             'Louis Leithold',   'regular',    'pendente', NULL);

-- Contato (um cliente e um visitante sem cadastro)
INSERT INTO Mensagem_Contato (id_cliente, nome, email, assunto, texto, respondida) VALUES
(2,    'Mariana Ferreira Costa', 'mariana.costa@email.com', 'Dúvida sobre envio', 'A entrega é feita em horário comercial pelos Correios?', TRUE),
(NULL, 'Lucas Silveira', 'lucas.visitante@gmail.com', 'Sugestão de livros', 'Vocês aceitam coleções completas de quadrinhos na modalidade troca?', FALSE);
