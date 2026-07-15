-- Ranking dos residentes por número de atendimentos realizados
SELECT DENSE_RANK() over (ORDER BY COUNT(*) DESC) AS Ranking, P.nome AS Residente, COUNT(*) AS Total_Atendimentos
FROM ATENDIMENTO A
         JOIN PESSOA P ON A.id_residente = P.id_pessoa
GROUP BY A.id_residente
ORDER BY Total_Atendimentos DESC;

-- Listar os preceptores que supervisionaram mais de 5 atendimentos em um determinado mês
SELECT P.nome   AS Preceptor,
       COUNT(*) AS Atendimentos
FROM ATENDIMENTO A
         JOIN PESSOA P ON A.id_preceptor = P.id_pessoa
WHERE MONTH(A.data_hora) = 3
  AND YEAR(A.data_hora) = 2026
GROUP BY A.id_preceptor
HAVING COUNT(*) > 5;

-- Para cada unidade, mostrar a quantidade de plantões escalados por residente no mês corrente
SELECT U.nome AS Unidade, P.nome AS Residente, COUNT(E.id_residente) AS Plantoes
FROM ESCALA E
         JOIN UNIDADE U on E.id_unidade = U.id_unidade
         JOIN PESSOA P ON P.id_pessoa = E.id_residente
GROUP BY E.id_unidade, E.id_residente;

-- Listar pacientes que nunca realizaram nenhum procedimento de nível de risco 'ALTO'
SELECT DISTINCT P.nome
FROM ATENDIMENTO A
         JOIN PESSOA P ON id_pessoa = A.id_paciente
WHERE A.id_paciente NOT IN (SELECT A2.id_paciente
                            FROM ATENDIMENTO A2
                                     JOIN PROCEDIMENTO_REALIZADO PR ON A2.id_atendimento = PR.id_atendimento
                                     JOIN PROCEDIMENTO P2 ON PR.id_procedimento = P2.id_procedimento
                            WHERE P2.risco = 'ALTO');
