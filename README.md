# Projeto Banco de Dados - Gestão Hospitalar

---
## Integrantes

- ### Arthur Gaudêncio Odebrecht Stern
- ### Edeildo Alves de Assis Junior
---
## Descrição do Projeto

Esquema de banco de dados para um sistema de gestão hospitalar, com tabelas para
pacientes, profissionais (residentes e preceptores), atendimentos, procedimentos e
escalas de plantão.

---
## Requisitos

- MySQL 8.0+ ou MariaDB 10.5+ (o esquema usa `ENUM`, `REGEXP` e triggers)

---
## Como executar

Os scripts devem ser rodados nesta ordem:

1. **`inicializacao.sql`** => cria o banco `gestao_hospitalar`, as tabelas e os
   triggers de validação (data de nascimento, data de admissão, data/hora de
   atendimento, faturamento automático, etc.).

2. **`dados_teste.sql`** => popula o banco com dados de teste: 26 pessoas
   (pacientes, residentes e preceptores), 220 atendimentos distribuídos entre
   julho/2025 e junho/2026, procedimentos realizados, escalas e alergias.

3. **`crud.sql`** => exemplos de operações CRUD (inserir atendimento, listar,
   atualizar, remover procedimento não faturado, calcular média de duração).

4. **`consultas_analiticas.sql`** => queries analíticas (ranking de residentes,
   preceptores com mais de 5 atendimentos no mês, plantões por unidade,
   pacientes sem procedimento de risco alto).

---
## Notas

- O campo `faturamento_total` em `PROCEDIMENTO_REALIZADO` é preenchido
  automaticamente por um trigger quando omitido (`NULL`), calculando
  `faturamento_unitario × quantidade`. Se o procedimento não tiver preço
  unitário cadastrado, o total permanece `NULL`.
- Pacientes com `data_hora_saida = NULL` ainda estão internados.
