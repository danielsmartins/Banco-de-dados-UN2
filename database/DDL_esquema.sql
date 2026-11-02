-- ==============================================================================
-- PROJETO SEBO LITERÁRIO - DDL (ITERAÇÃO 2)
-- SGBD: PostgreSQL 15+
-- ==============================================================================

DROP TABLE IF EXISTS Mensagem_Contato CASCADE;
DROP TABLE IF EXISTS Item_Doacao CASCADE;
DROP TABLE IF EXISTS Doacao_Troca CASCADE;
DROP TABLE IF EXISTS Entrega CASCADE;
DROP TABLE IF EXISTS Item_Pedido CASCADE;
DROP TABLE IF EXISTS Pedido CASCADE;
DROP TABLE IF EXISTS Telefone CASCADE;
DROP TABLE IF EXISTS Cliente CASCADE;
DROP TABLE IF EXISTS Exemplar CASCADE;
DROP TABLE IF EXISTS Obra_Autor CASCADE;
DROP TABLE IF EXISTS Obra CASCADE;
DROP TABLE IF EXISTS Autor CASCADE;
DROP TABLE IF EXISTS Genero CASCADE;
DROP TABLE IF EXISTS Editora CASCADE;

-- ----------------------------------------------------------------------------
-- 1. CATÁLOGO
-- ----------------------------------------------------------------------------
CREATE TABLE Autor (
    id_autor        SERIAL PRIMARY KEY,
    nome            VARCHAR(150) NOT NULL,
    nacionalidade   VARCHAR(50),
    data_nascimento DATE
);

CREATE TABLE Genero (
    id_genero SERIAL PRIMARY KEY,
    nome      VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Editora (
    id_editora SERIAL PRIMARY KEY,
    nome       VARCHAR(100) NOT NULL,
    pais       VARCHAR(50),
    telefone   VARCHAR(20)
);

CREATE TABLE Obra (
    id_obra        SERIAL PRIMARY KEY,
    titulo         VARCHAR(200) NOT NULL,
    isbn           VARCHAR(20) UNIQUE,
    ano_publicacao INT CHECK (ano_publicacao > 1400),
    idioma         VARCHAR(30),
    id_genero      INT NOT NULL REFERENCES Genero(id_genero) ON DELETE RESTRICT,
    id_editora     INT NOT NULL REFERENCES Editora(id_editora) ON DELETE RESTRICT
);

CREATE TABLE Obra_Autor (
    id_obra  INT NOT NULL REFERENCES Obra(id_obra) ON DELETE CASCADE,
    id_autor INT NOT NULL REFERENCES Autor(id_autor) ON DELETE RESTRICT,
    PRIMARY KEY (id_obra, id_autor)
);

CREATE TABLE Exemplar (
    id_exemplar        SERIAL PRIMARY KEY,
    id_obra            INT NOT NULL REFERENCES Obra(id_obra) ON DELETE RESTRICT,
    codigo_tombo       VARCHAR(20) UNIQUE,
    estado_conservacao VARCHAR(20) CHECK (estado_conservacao IN ('excelente', 'bom', 'regular', 'danificado')),
    preco_venda        DECIMAL(10,2) NOT NULL CHECK (preco_venda >= 0),
    disponivel         BOOLEAN NOT NULL DEFAULT TRUE,
    data_aquisicao     DATE
);

-- ----------------------------------------------------------------------------
-- 2. CLIENTES, PEDIDOS E ENTREGA
-- ----------------------------------------------------------------------------
CREATE TABLE Cliente (
    id_cliente  SERIAL PRIMARY KEY,
    nome        VARCHAR(150) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    senha_hash  VARCHAR(255) NOT NULL,
    perfil      VARCHAR(10) NOT NULL DEFAULT 'cliente' CHECK (perfil IN ('cliente', 'admin')),
    rua         VARCHAR(150),
    numero      VARCHAR(20),
    complemento VARCHAR(100),
    bairro      VARCHAR(80),
    cidade      VARCHAR(100),
    estado      CHAR(2),
    cep         VARCHAR(9)
);

CREATE TABLE Telefone (
    id_telefone SERIAL PRIMARY KEY,
    id_cliente  INT NOT NULL REFERENCES Cliente(id_cliente) ON DELETE CASCADE,
    numero      VARCHAR(20) NOT NULL
);

CREATE TABLE Pedido (
    id_pedido  SERIAL PRIMARY KEY,
    id_cliente INT NOT NULL REFERENCES Cliente(id_cliente) ON DELETE RESTRICT,
    data       DATE NOT NULL DEFAULT CURRENT_DATE,
    status     VARCHAR(15) NOT NULL DEFAULT 'pendente'
               CHECK (status IN ('pendente', 'pago', 'enviado', 'entregue', 'cancelado')),
    total      DECIMAL(10,2) CHECK (total >= 0)   -- atributo derivado (soma dos itens)
);

-- Um mesmo exemplar pode aparecer em mais de um item ao longo do tempo
-- (ex.: pedido cancelado e exemplar vendido depois).
CREATE TABLE Item_Pedido (
    id_item_pedido SERIAL PRIMARY KEY,
    id_pedido      INT NOT NULL REFERENCES Pedido(id_pedido) ON DELETE CASCADE,
    id_exemplar    INT NOT NULL REFERENCES Exemplar(id_exemplar) ON DELETE RESTRICT,
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0)
);

CREATE TABLE Entrega (
    id_entrega    SERIAL PRIMARY KEY,
    id_pedido     INT NOT NULL UNIQUE REFERENCES Pedido(id_pedido) ON DELETE CASCADE,
    status        VARCHAR(15) NOT NULL DEFAULT 'preparando'
                  CHECK (status IN ('preparando', 'em_transito', 'entregue')),
    logradouro    VARCHAR(150),
    numero        VARCHAR(20),
    cidade        VARCHAR(100),
    estado        CHAR(2),
    cep           VARCHAR(9),
    data_prevista DATE,
    data_entrega  DATE
);

-- ----------------------------------------------------------------------------
-- 3. DOAÇÃO/TROCA E CONTATO
-- ----------------------------------------------------------------------------
CREATE TABLE Doacao_Troca (
    id_doacao_troca  SERIAL PRIMARY KEY,
    id_cliente       INT NOT NULL REFERENCES Cliente(id_cliente) ON DELETE RESTRICT,
    tipo             VARCHAR(10) NOT NULL CHECK (tipo IN ('doacao', 'troca')),
    status           VARCHAR(15) NOT NULL DEFAULT 'pendente'
                     CHECK (status IN ('pendente', 'em_avaliacao', 'concluida', 'cancelada')),
    data_solicitacao DATE NOT NULL DEFAULT CURRENT_DATE,
    data_conclusao   DATE,
    credito_gerado   DECIMAL(10,2) DEFAULT 0 CHECK (credito_gerado >= 0)  -- derivado; sempre 0 em doações
);

CREATE TABLE Item_Doacao (
    id_item_doacao   SERIAL PRIMARY KEY,
    id_doacao_troca  INT NOT NULL REFERENCES Doacao_Troca(id_doacao_troca) ON DELETE CASCADE,
    id_exemplar      INT UNIQUE REFERENCES Exemplar(id_exemplar) ON DELETE SET NULL,
    titulo_informado VARCHAR(200) NOT NULL,
    autor_informado  VARCHAR(150),
    estado_informado VARCHAR(20) CHECK (estado_informado IN ('excelente', 'bom', 'regular', 'danificado')),
    status_avaliacao VARCHAR(10) NOT NULL DEFAULT 'pendente'
                     CHECK (status_avaliacao IN ('pendente', 'aceito', 'recusado')),
    valor_avaliado   DECIMAL(10,2) CHECK (valor_avaliado >= 0)
);

CREATE TABLE Mensagem_Contato (
    id_mensagem SERIAL PRIMARY KEY,
    id_cliente  INT REFERENCES Cliente(id_cliente) ON DELETE SET NULL,
    nome        VARCHAR(150) NOT NULL,
    email       VARCHAR(120) NOT NULL,
    assunto     VARCHAR(100) NOT NULL,
    texto       TEXT NOT NULL,
    data_envio  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    respondida  BOOLEAN NOT NULL DEFAULT FALSE
);
