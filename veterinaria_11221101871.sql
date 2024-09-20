-- Adriano Teruo Shibuya  RGM: 11221101871
create schema veterinaria;
 
use veterinaria;
 
 -- tabela paciente
create table pacientes(
id_paciente integer primary key  auto_increment,
nome varchar (100),
especie varchar (100),
idade integer
);
  
-- tabela veterinarios
create table veterinarios(
id_veterinario integer primary key auto_increment,
nome varchar (100),
especialidade varchar (50)
);
 
 
 -- tabela consultas
CREATE TABLE Consultas (
    id_consulta integer primary key auto_increment,
    id_paciente integer,
    id_veterinario integer,
    data_consulta date,
    custo decimal(10, 2),
    FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    FOREIGN KEY (id_veterinario) REFERENCES Veterinarios(id_veterinario)
    );
 
 -- tabela de log das consultas
 CREATE TABLE Log_Consultas (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    custo_antigo DECIMAL(10, 2),
    custo_novo DECIMAL(10, 2)
);

 
 
DELIMITER $$
-- criar a procedure agendar_consulta
CREATE PROCEDURE agendar_consulta (
-- parametros
    IN p_id_paciente INTEGER,
    IN p_id_veterinario INTEGER,
    IN p_data_consulta DATE,
    IN p_custo DECIMAL(10, 2)
)
BEGIN
-- inserir dados nas tabelas 
    INSERT INTO Consultas (id_paciente, id_veterinario, data_consulta, custo)
    VALUES (p_id_paciente, p_id_veterinario, p_data_consulta, p_custo);
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE atualizar_paciente (
-- parametros 
    IN p_id_paciente INTEGER,
    IN p_novo_nome VARCHAR(100),
    IN p_nova_especie VARCHAR(50),
    IN p_nova_idade INTEGER
)
BEGIN
-- ações que serao executadas
    UPDATE Pacientes
    SET nome = p_novo_nome,
        especie = p_nova_especie,
        idade = p_nova_idade
    WHERE id_paciente = p_id_paciente;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE remover_consulta (
-- parametro
    IN p_id_consulta INTEGER
)
BEGIN
-- deletar consulta
    DELETE FROM Consultas
    WHERE id_consulta = p_id_consulta;
END $$

DELIMITER ;

-- inserts para testar as tabelas e procedures
INSERT INTO Pacientes (nome, especie, idade) VALUES ('jujuba', 'Cachorro', 8);
INSERT INTO Veterinarios (nome, especialidade) VALUES ('DrAndre', 'cirurgia');

-- chamando as procedures para testar
CALL agendar_consulta(1, 1, '2024-09-20', 55.00);
CALL atualizar_paciente(1, 'bilu', 'gato', 5);
CALL remover_consulta(1);
CALL agendar_consulta(2, 1, '2024-09-26', 125.00);

DELIMITER $$

-- function para mostrar o valor total gasto pelo paciente em consultas.
CREATE FUNCTION total_gasto_paciente (
    p_id_paciente INT
)
RETURNS DECIMAL(10, 2)
BEGIN
    DECLARE total DECIMAL(10, 2);
    
SELECT 
    SUM(custo)
INTO total FROM
    Consultas
WHERE
    id_paciente = p_id_paciente;
    
    RETURN total;
END$$

DELIMITER ;

-- select para testar a function
SELECT total_gasto_paciente(1) AS total_gasto;


DELIMITER $$
-- trigger para verificar idade do paciente
CREATE TRIGGER verificar_idade_paciente
BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    IF NEW.idade <= 0 THEN
        SIGNAL SQLSTATE '45000'
        -- menssagem que vai ser exibida se a idade não for positiva
        SET MESSAGE_TEXT = 'A idade do paciente deve ser um número positivo.';
    END IF;
END$$

DELIMITER ;

-- insert para testar a trigger da idade
INSERT INTO Pacientes (nome, especie, idade) VALUES ('birulei', 'Cachorro', -2);


DELIMITER $$
-- trigger para salvar alterações do custo das consultas
CREATE TRIGGER atualizar_custo_consulta
AFTER UPDATE ON Consultas
FOR EACH ROW
BEGIN
    IF NEW.custo <> OLD.custo THEN
        INSERT INTO Log_Consultas (id_consulta, custo_antigo, custo_novo)
        VALUES (OLD.id_consulta, OLD.custo, NEW.custo);
    END IF;
END$$

DELIMITER ;

-- update para testar a trigger
UPDATE Consultas
SET custo = 200.00
WHERE id_consulta = 4;

-- select para mostrar o log da consulta alterada
SELECT * FROM Log_Consultas;


-- parte 2

CREATE TABLE Medicamentos (
    id_medicamento INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100),
    descricao TEXT,
    preco DECIMAL(10, 2)
);

CREATE TABLE Prescricoes (
    id_prescricao INTEGER PRIMARY KEY AUTO_INCREMENT,
    id_paciente INTEGER,
    id_veterinario INTEGER,
    id_medicamento INTEGER,
    data_prescricao DATE,
    dosagem VARCHAR(50),
    FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    FOREIGN KEY (id_veterinario) REFERENCES Veterinarios(id_veterinario),
    FOREIGN KEY (id_medicamento) REFERENCES Medicamentos(id_medicamento)
);


CREATE TABLE Exames (
    id_exame INTEGER PRIMARY KEY AUTO_INCREMENT,
    id_paciente INTEGER,
    tipo_exame VARCHAR(100),
    data_exame DATE,
    resultado TEXT,
    FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente)
);

-- trigger para verificar se o tipo de exame não seja nulo
DELIMITER $$

CREATE TRIGGER verificar_tipo_exame
BEFORE INSERT ON Exames
FOR EACH ROW
BEGIN
    IF NEW.tipo_exame IS NULL OR NEW.tipo_exame = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O tipo de exame não pode ser nulo.';
    END IF;
END$$

DELIMITER ;

-- insert para testar trigger
INSERT INTO Exames (id_paciente, tipo_exame, data_exame, resultado) 
VALUES (1, '', '2024-09-21', 'Sem anormalidades');


-- trigger para verificar se o id do veterinario consta na tabela veterinarios
DELIMITER $$

CREATE TRIGGER verificar_id_veterinario_prescricao
BEFORE INSERT ON Prescricoes
FOR EACH ROW
BEGIN
    DECLARE v_count INTEGER;
    
    -- Verifica se o id_veterinario existe na tabela Veterinarios
    SELECT COUNT(*) INTO v_count
    FROM Veterinarios
    WHERE id_veterinario = NEW.id_veterinario;
    
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O id_veterinario fornecido não existe na tabela Veterinarios.';
    END IF;
END$$

DELIMITER ;

-- insert para testar a trigger
INSERT INTO Prescricoes (id_paciente, id_veterinario, id_medicamento, data_prescricao, dosagem) 
VALUES (1, 999, 1, '2024-09-20', '2x ao dia');



-- trigger para ver se a especialidae do veterinario não seja nula
DELIMITER $$

CREATE TRIGGER verificar_especialidade_veterinario
BEFORE INSERT ON Veterinarios
FOR EACH ROW
BEGIN
    IF NEW.especialidade IS NULL OR NEW.especialidade = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A especialidade do veterinário não pode ser nula.';
    END IF;
END$$

DELIMITER ;

-- insert para testar a trigger 
INSERT INTO Veterinarios (nome, especialidade) VALUES ('DrLima', '');


-- trigger para verificar o nome do paciente

DELIMITER $$

CREATE TRIGGER verificar_nome_paciente
BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    IF NEW.nome IS NULL OR NEW.nome = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O nome do paciente não pode ser nulo.';
    END IF;
END $$

DELIMITER ;

-- insert para testar a trigger
INSERT INTO pacientes (nome, especie) VALUES ('', 'vira lata');


-- trigger para verificar se a data do exame não seja nulo
DELIMITER $$

CREATE TRIGGER verificar_data_exame
BEFORE INSERT ON Exames
FOR EACH ROW
BEGIN
    IF NEW.data_exame IS NULL OR NEW.data_exame = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = ' A data do exame não pode ser nulo.';
    END IF;
END$$

DELIMITER ;

-- insert para testar trigger
INSERT INTO Exames (id_paciente, tipo_exame, data_exame, resultado) 
VALUES (1, 'tumografia', '', 'Sem anormalidades');


-- procedure para adicionar paciente
DELIMITER $$

CREATE PROCEDURE adicionar_paciente (
    IN p_nome VARCHAR(100),
    IN p_especie VARCHAR(50),
    IN p_idade INTEGER
)
BEGIN
    INSERT INTO Pacientes (nome, especie, idade)
    VALUES (p_nome, p_especie, p_idade);
END$$

DELIMITER ;

-- call para testar 
CALL adicionar_paciente('Bella', 'Gato', 2);


-- procedure para adicionar novo veterinario
DELIMITER $$

CREATE PROCEDURE adicionar_veterinario (
    IN p_nome VARCHAR(100),
    IN p_especialidade VARCHAR(50)
)
BEGIN
    INSERT INTO Veterinarios (nome, especialidade)
    VALUES (p_nome, p_especialidade);
END$$

DELIMITER ;

-- call para testar 
CALL adicionar_veterinario('DrSouza', 'Cardiologia');


-- procedure para adicionar novo medicamento
DELIMITER $$

CREATE PROCEDURE adicionar_medicamento (
    IN p_nome VARCHAR(100),
    IN p_descricao TEXT,
    IN p_preco DECIMAL(10, 2)
)
BEGIN
    INSERT INTO Medicamentos (nome, descricao, preco)
    VALUES (p_nome, p_descricao, p_preco);
END$$

DELIMITER ;

-- call para testar procedure
CALL adicionar_medicamento('Antibiótico', 'Medicamento para infecções', 50.00);


-- procedure para adicionar uma nova prescrição
DELIMITER $$

CREATE PROCEDURE registrar_prescricao (
    IN p_id_paciente INTEGER,
    IN p_id_veterinario INTEGER,
    IN p_id_medicamento INTEGER,
    IN p_data_prescricao DATE,
    IN p_dosagem VARCHAR(50)
)
BEGIN
    INSERT INTO Prescricoes (id_paciente, id_veterinario, id_medicamento, data_prescricao, dosagem)
    VALUES (p_id_paciente, p_id_veterinario, p_id_medicamento, p_data_prescricao, p_dosagem);
END$$

DELIMITER ;


-- call para testar procedure
CALL registrar_prescricao(1, 1, 1, '2024-09-20', '2x ao dia');



-- procedure para adicionar um novo exame
DELIMITER $$

CREATE PROCEDURE registrar_exame (
    IN p_id_paciente INTEGER,
    IN p_tipo_exame VARCHAR(100),
    IN p_data_exame DATE,
    IN p_resultado TEXT
)
BEGIN
    INSERT INTO Exames (id_paciente, tipo_exame, data_exame, resultado)
    VALUES (p_id_paciente, p_tipo_exame, p_data_exame, p_resultado);
END$$

DELIMITER ;

-- call para testar procesure
CALL registrar_exame(1, 'Raio-X', '2024-09-21', 'Sem anormalidades');
