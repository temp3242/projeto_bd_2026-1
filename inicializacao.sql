DROP DATABASE IF EXISTS gestao_hospitalar;
CREATE DATABASE IF NOT EXISTS gestao_hospitalar;
USE gestao_hospitalar;

CREATE TABLE IF NOT EXISTS PESSOA
(
    id_pessoa            INT PRIMARY KEY,
    nome                 VARCHAR(100) NOT NULL,
    CPF                  CHAR(15) UNIQUE NOT NULL CHECK ( LENGTH(CPF) = 14 ),
    data_nascimento      DATE NOT NULL,
    is_flamengo          BOOLEAN,

    -- Endereço pode ser NULL (pessoa desabrigada, por exemplo)
    endereco_cep         INT CHECK ( endereco_cep IS NULL OR endereco_cep > 0),
    endereco_bairro      VARCHAR(100),
    endereco_rua         VARCHAR(100),
    endereco_numero      INT CHECK ( endereco_numero IS NULL OR endereco_numero > 0 ),
    endereco_complemento VARCHAR(100),
    telefone             CHAR(11) CHECK ( telefone IS NULL OR telefone REGEXP '^[0-9]{11}$') -- Checando se o telefone esta no formato DDNNNNNNNNN

);

CREATE TABLE IF NOT EXISTS PACIENTE
(
    id_pessoa         INT PRIMARY KEY REFERENCES PESSOA (id_pessoa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    num_convenio      INT CHECK ( num_convenio IS NULL OR num_convenio > 0),
    grupo_sanguineo   VARCHAR(3) NOT NULL CHECK ( grupo_sanguineo IN ('A-', 'A+', 'B-', 'B+', 'AB-', 'AB+', 'O-', 'O+') ), -- Checando se o tipo sanguineo é valido
    data_hora_entrada DATETIME   NOT NULL,
    data_hora_saida   DATETIME,
    leito             INT CHECK ( (data_hora_saida IS NOT NULL AND leito IS NULL) OR leito > 0)                                                             -- Leito pode ser NULL se o paciente não estiver mais internado
);

CREATE TABLE IF NOT EXISTS PROFISSIONAL
(
    id_pessoa     INT PRIMARY KEY REFERENCES PESSOA (id_pessoa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CRM           INT UNIQUE  NOT NULL CHECK ( CRM > 0 ),
    data_admissao DATE        NOT NULL,
    especialidade VARCHAR(64) NOT NULL
);

CREATE TABLE IF NOT EXISTS PRECEPTOR
(
    id_profissional INT PRIMARY KEY REFERENCES PROFISSIONAL (id_pessoa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    titulacao       VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS RESIDENTE
(
    id_profissional INT PRIMARY KEY REFERENCES PROFISSIONAL (id_pessoa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ano_residencia  ENUM ('R1', 'R2', 'R3') NOT NULL
);

CREATE TABLE IF NOT EXISTS UNIDADE
(
    id_unidade        INT PRIMARY KEY,
    nome              VARCHAR(100)                                                NOT NULL,
    tipo              ENUM ('Enfermaria', 'UTI', 'Pronto Socorro', 'Ambulatorio') NOT NULL,
    capacidade_leitos INT CHECK ( capacidade_leitos IS NULL OR capacidade_leitos >= 0 ) -- Capacidade pode ser NULL se desconhecida
);

CREATE TABLE IF NOT EXISTS ATENDIMENTO
(
    id_atendimento  INT PRIMARY KEY,
    data_hora       DATETIME NOT NULL,
    duracao_minutos INT      NOT NULL CHECK ( duracao_minutos > 0 ),
    id_paciente     INT      NOT NULL REFERENCES PACIENTE (id_pessoa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_residente    INT      NOT NULL REFERENCES RESIDENTE (id_profissional)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    id_preceptor    INT      NOT NULL REFERENCES PRECEPTOR (id_profissional)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS PROCEDIMENTO
(
    id_procedimento      INT PRIMARY KEY,
    codigo               INT UNIQUE                      NOT NULL CHECK ( codigo > 0 ),
    nome                 VARCHAR(100)                    NOT NULL,
    tempo_medio_minutos  INT                             NOT NULL CHECK ( tempo_medio_minutos > 0 ),
    faturamento_unitario DECIMAL(9, 2) CHECK ( faturamento_unitario IS NULL OR faturamento_unitario >= 0 ),
    risco                ENUM ('BAIXO', 'MEDIO', 'ALTO') NOT NULL
);

CREATE TABLE IF NOT EXISTS PROCEDIMENTO_REALIZADO
(
    id_atendimento     INT NOT NULL REFERENCES ATENDIMENTO (id_atendimento)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    id_procedimento    INT NOT NULL REFERENCES PROCEDIMENTO (id_procedimento)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    quantidade         INT NOT NULL CHECK ( quantidade > 0 ),
    tempo_real_minutos INT NOT NULL CHECK ( tempo_real_minutos > 0 ),
    observacao         VARCHAR(255),
    -- faturamento_total pode ser diferente de faturamento_unitario * quantidade, por exemplo, se for dado um desconto no procedimento.
    faturamento_total  DECIMAL(9, 2),
    PRIMARY KEY (id_atendimento, id_procedimento)
);

CREATE TABLE IF NOT EXISTS ESCALA
(
    id_escala    INT PRIMARY KEY,
    id_unidade   INT NOT NULL REFERENCES UNIDADE (id_unidade),
    dia_semana   ENUM ('Domingo', 'Segunda', 'Terca', 'Quarta', 'Quinta', 'Sexta', 'Sabado') NOT NULL ,
    turno        ENUM ('Manha', 'Tarde', 'Noite') NOT NULL ,
    id_residente INT NOT NULL REFERENCES RESIDENTE (id_profissional)
        ON UPDATE CASCADE,
    id_preceptor INT NOT NULL REFERENCES PRECEPTOR (id_profissional)
        ON UPDATE CASCADE,
    UNIQUE (id_unidade, dia_semana, turno, id_residente)
);

CREATE TABLE IF NOT EXISTS ALERGIAS
(
    id_paciente INT REFERENCES PACIENTE (id_pessoa)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    alergia     VARCHAR(100) NOT NULL CHECK ( alergia != '' ),
    PRIMARY KEY (id_paciente, alergia)
);

DELIMITER //
CREATE TRIGGER check_nascimento_pessoa_insert
    BEFORE INSERT
    ON PESSOA
    FOR EACH ROW
BEGIN
    IF NEW.data_nascimento > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de nascimento invalida!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_nascimento_pessoa_update
    BEFORE UPDATE
    ON PESSOA
    FOR EACH ROW
BEGIN
    IF NEW.data_nascimento > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de nascimento invalida!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_admissao_profissional_insert
    BEFORE INSERT
    ON PROFISSIONAL
    FOR EACH ROW
BEGIN
    IF NEW.data_admissao > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de admissao invalida!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_admissao_profissional_update
    BEFORE UPDATE
    ON PROFISSIONAL
    FOR EACH ROW
BEGIN
    IF NEW.data_admissao > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de admissao invalida!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_datahora_atendimento_insert
    BEFORE INSERT
    ON ATENDIMENTO
    FOR EACH ROW
BEGIN
    IF NEW.data_hora > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data/hora do atendimento invalida!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_datahora_atendimento_update
    BEFORE UPDATE
    ON ATENDIMENTO
    FOR EACH ROW
BEGIN
    IF NEW.data_hora > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data/hora do atendimento invalida!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_datahora_entrada_paciente_insert
    BEFORE INSERT
    ON PACIENTE
    FOR EACH ROW
BEGIN
    -- Paciente não pode ser internado no futuro
    IF NEW.data_hora_entrada > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data/hora de entrada do paciente invalida!';
    END IF;
END;
DELIMITER ;
DELIMITER //

CREATE TRIGGER check_datahora_entrada_paciente_update
    BEFORE UPDATE
    ON PACIENTE
    FOR EACH ROW
BEGIN
    -- Paciente não pode ser internado no futuro
    IF NEW.data_hora_entrada > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data/hora de entrada do paciente invalida!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_datahora_saida_paciente_insert
    BEFORE INSERT
    ON PACIENTE
    FOR EACH ROW
BEGIN
    -- Paciente não pode ter alta no futuro
    IF NEW.data_hora_saida IS NOT NULL AND NEW.data_hora_saida > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data/hora de saida do paciente invalida!';
    END IF;

    IF NEW.data_hora_saida IS NOT NULL AND NEW.leito IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paciente com data de saída não pode ter leito atribuído.';
    END IF;
END;
DELIMITER ;
DELIMITER //

CREATE TRIGGER check_datahora_saida_paciente_update
    BEFORE UPDATE
    ON PACIENTE
    FOR EACH ROW
BEGIN
    -- Paciente não pode ter alta no futuro
    IF NEW.data_hora_saida IS NOT NULL AND NEW.data_hora_saida > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data/hora de saida do paciente invalida!';
    END IF;

    IF NEW.data_hora_saida IS NOT NULL AND NEW.leito IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paciente com data de saída não pode ter leito atribuído.';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER default_faturamento_total_insert
    BEFORE INSERT
    ON PROCEDIMENTO_REALIZADO
    FOR EACH ROW
BEGIN
    -- Autocalcula se um valor de faturamento total não for dado
    IF NEW.faturamento_total IS NULL THEN
        SELECT faturamento_unitario
        INTO @unitario
        FROM PROCEDIMENTO
        WHERE id_procedimento = NEW.id_procedimento;

        -- Guarda: NULL unitário × qualquer coisa = NULL (não 0)
        IF @unitario IS NOT NULL THEN
            SET NEW.faturamento_total = @unitario * NEW.quantidade;
        END IF;
        -- caso contrário permanece NULL — "ainda não precificado"
    END IF;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER default_faturamento_total_update
    BEFORE UPDATE
    ON PROCEDIMENTO_REALIZADO
    FOR EACH ROW
BEGIN
    -- Autocalcula se um valor de faturamento total não for dado
    IF NEW.faturamento_total IS NULL THEN
        SELECT faturamento_unitario
        INTO @unitario
        FROM PROCEDIMENTO
        WHERE id_procedimento = NEW.id_procedimento;

        -- Guarda: NULL unitário × qualquer coisa = NULL (não 0)
        IF @unitario IS NOT NULL THEN
            SET NEW.faturamento_total = @unitario * NEW.quantidade;
        END IF;
        -- caso contrário permanece NULL — "ainda não precificado"
    END IF;
END;
//
DELIMITER ;
/*
DELIMITER //
CREATE TRIGGER check_ids_atendimento_existem_create
    BEFORE INSERT ON ATENDIMENTO
    FOR EACH ROW
BEGIN
    IF NOT EXISTS(SELECT 1 FROM PACIENTE P WHERE P.id_pessoa = NEW.id_paciente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paciente do atendimento nao existe na base de dados!';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM RESIDENTE R WHERE R.id_profissional = NEW.id_residente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Residente do atendimento nao existe na base de dados!';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM PRECEPTOR P WHERE P.id_profissional = NEW.id_preceptor) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Preceptor do atendimento nao existe na base de dados!';
    END IF;
END;
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_ids_atendimento_existem_update
    BEFORE UPDATE ON ATENDIMENTO
    FOR EACH ROW
BEGIN
    IF NOT EXISTS(SELECT 1 FROM PACIENTE P WHERE P.id_pessoa = NEW.id_paciente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paciente do atendimento nao existe na base de dados!';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM RESIDENTE R WHERE R.id_profissional = NEW.id_residente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Residente do atendimento nao existe na base de dados!';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM PRECEPTOR P WHERE P.id_profissional = NEW.id_preceptor) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Preceptor do atendimento nao existe na base de dados!';
    END IF;
END;
DELIMITER ;
*/
