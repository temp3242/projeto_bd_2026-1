-- Inserir um novo atendimento (verificando se paciente, residente, preceptor existem)
INSERT INTO ATENDIMENTO (id_atendimento, data_hora, duracao_minutos, id_paciente, id_residente, id_preceptor)
VALUES (221, NOW(), 75, 20, 23, 25);

-- Procedimentos realizados no atendimento acima atendimento
INSERT INTO PROCEDIMENTO_REALIZADO (id_atendimento, id_procedimento, quantidade, tempo_real_minutos, observacao, faturamento_total) VALUES
(221, 1, 1, 35, 'Avaliacao clinica de rotina',                    NULL),
(221, 3, 1, 22, 'ECG de controle',                                NULL),
(221, 2, 2, 18, 'Coleta para hemograma e bioquimica',             NULL);

-- Listar todos os atendimentos de um paciente específico (ordernados por data)
SELECT *
FROM ATENDIMENTO A
WHERE A.id_paciente = 1
ORDER BY A.data_hora DESC;

-- Listar os procedimentos realizados em um atendimento
SELECT P.nome as 'Procedimento', PR.quantidade, PR.tempo_real_minutos
FROM ATENDIMENTO A
         JOIN PROCEDIMENTO_REALIZADO PR ON A.id_atendimento = PR.id_atendimento
         JOIN PROCEDIMENTO P ON PR.id_procedimento = P.id_procedimento
WHERE A.id_atendimento = 1;

-- Atualizar os dados de um paciente (endereço ou convênio)
UPDATE PACIENTE
SET num_convenio = 10023
WHERE id_pessoa = 3;

-- Remover um procedimento realizado (apenas se ainda não houver faturamento associado – usar uma flag)
WITH procs_faturamentos AS (SELECT PROC_R_2.id_procedimento,
                                   PROC_R_2.id_atendimento,
                                   ISNULL(PROC_R_2.faturamento_total) AS NaoTemFaturamento
                            FROM PROCEDIMENTO_REALIZADO PROC_R_2)
DELETE PROC_R
FROM PROCEDIMENTO_REALIZADO PROC_R
         INNER JOIN procs_faturamentos PF
                    ON PROC_R.id_procedimento = PF.id_procedimento
                        AND PROC_R.id_atendimento = PF.id_atendimento
WHERE PF.NaoTemFaturamento = 1;

-- Calcular o tempo médio de duração dos atendimentos por residente
SELECT P.nome AS Residente, AVG(A.duracao_minutos) AS 'Duracao media do atendimento (minutos)'
FROM ATENDIMENTO A
         JOIN PESSOA P ON A.id_residente = P.id_pessoa
GROUP BY P.nome