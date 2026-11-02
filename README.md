# Sebo Literário — Banco de Dados (Iteração 2)

Banco de dados relacional de um sebo online de livros usados (catálogo de obras e exemplares, clientes, pedidos, entrega, doações/trocas e contato).
Projeto da disciplina de Banco de Dados — IMD/UFRN.

**Equipe:** Bianca Bezerra Pires, Daniel Silva Martins e Thyago Pereira da Silva.

## Conteúdo do repositório

```
database/
  DDL_esquema.sql           Cria as 14 tabelas, chaves e restrições (executar 1º)
  DML_povoamento.sql        Insere os dados de demonstração (executar 2º)
  Verificacao.sql           Confere se o banco foi criado e povoado (executar 3º)
  Consultas_analiticas.sql  5 consultas analíticas
  Transacoes_exemplo.sql    Regras de negócio como transações SQL (terminam em ROLLBACK)
docs/
  DER_modelo_relacional.png                          Diagrama entidade-relacionamento
  Projeto_Sebo_Literario_Iteracao_2.pdf              Documento da Iteração 2
  Sebo_Literario_Iteracao_2_Repositorio_e_Apresentacao.pdf   Repositório, integração opcional e roteiro
```

Diagrama interativo: https://dbdiagram.io/d/trabalho-sebo-iteracao2-6ae63fbf8bf38111a8f7499d

## Requisitos

- PostgreSQL 15 ou superior (testado no 16)
- Cliente `psql` (vem com o PostgreSQL) ou o pgAdmin

## Como executar (terminal)

Rode os comandos a partir da pasta raiz do repositório. Em todos eles, troque `postgres` pelo seu usuário do PostgreSQL, se for outro.

1. Crie o banco:

   ```bash
   psql -U postgres -c "CREATE DATABASE sebo_literario;"
   ```

2. Crie as tabelas e insira os dados:

   ```bash
   psql -U postgres -d sebo_literario -f database/DDL_esquema.sql
   psql -U postgres -d sebo_literario -f database/DML_povoamento.sql
   ```

3. Verifique se está funcionando:

   ```bash
   psql -U postgres -d sebo_literario -f database/Verificacao.sql
   ```

   **Resultado esperado:** 14 linhas com `ok = t` (true) e `tabelas_criadas = 14`.
   Se alguma linha mostrar `f`, o povoamento não foi concluído: rode o passo 2 de novo (o `DDL_esquema.sql` apaga e recria as tabelas, então pode ser repetido).

4. Execute as consultas e as transações de exemplo:

   ```bash
   psql -U postgres -d sebo_literario -f database/Consultas_analiticas.sql
   psql -U postgres -d sebo_literario -f database/Transacoes_exemplo.sql
   ```

   As transações terminam em `ROLLBACK`, então não alteram os dados e podem ser repetidas à vontade.

## Como executar (pgAdmin)

1. Crie um banco chamado `sebo_literario` (botão direito em *Databases* > *Create* > *Database*).
2. Abra o *Query Tool* nesse banco e use *Open File* para carregar, nesta ordem, `DDL_esquema.sql`, `DML_povoamento.sql` e `Verificacao.sql`. Execute cada um com F5.
3. A verificação deve mostrar todas as linhas com `ok = true` e 14 tabelas criadas.

## Regras de negócio

As regras (por exemplo, "exemplar vendido fica indisponível" e a geração de crédito nas trocas) são implementadas pela aplicação, como transações SQL, sem triggers nem funções no banco. Os exemplos estão em `database/Transacoes_exemplo.sql` e são explicados na seção 5 do PDF da Iteração 2.
