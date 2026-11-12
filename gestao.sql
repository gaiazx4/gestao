CREATE TABLE colaboradores (
    id_colaborador SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE projetos (
    id_projeto SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    gerente_id INT REFERENCES colaboradores(id_colaborador),
    CHECK (data_fim >= data_inicio)
);

CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(50) UNIQUE NOT NULL,
    descricao TEXT
);

CREATE TABLE tarefas (
    id_tarefa SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descricao TEXT,
    data_agendamento DATE NOT NULL,
    prazo_entrega DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Pendente',
    data_criacao TIMESTAMP,
    colaborador_id INT NOT NULL REFERENCES colaboradores(id_colaborador),
    projeto_id INT NOT NULL REFERENCES projetos(id_projeto),
    categoria_id INT NOT NULL REFERENCES categorias(id_categoria),

    CHECK (prazo_entrega >= data_agendamento),
    CHECK (status IN ('Pendente', 'Em andamento', 'Concluída', 'Atrasada'))
);

CREATE TABLE historico_tarefas (
    id_historico SERIAL PRIMARY KEY,
    tarefa_id INT NOT NULL REFERENCES tarefas(id_tarefa),
    acao VARCHAR(50) NOT NULL,
    detalhes TEXT,
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE OR REPLACE FUNCTION fn_validar_tarefa()
RETURNS TRIGGER AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM colaboradores
        WHERE id_colaborador = NEW.colaborador_id
        AND ativo = TRUE
    ) THEN
        RAISE EXCEPTION 'Colaborador inexistente ou inativo';
    END IF;

    NEW.data_criacao := CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_validar_tarefa
BEFORE INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_tarefa();



CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO historico_tarefas
    (tarefa_id, acao, detalhes)
    VALUES (
        NEW.id_tarefa,
        'Criação',
        'Tarefa cadastrada'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();



INSERT INTO colaboradores (nome, email, senha, cargo, ativo)
VALUES
('João Silva', 'joao@email.com', '123456', 'Gerente', TRUE),
('Maria Oliveira', 'maria@email.com', '123456', 'Analista', TRUE),
('Pedro Santos', 'pedro@email.com', '123456', 'Desenvolvedor', TRUE);



INSERT INTO projetos
(nome, descricao, data_inicio, data_fim, gerente_id)
VALUES
('Sistema Interno', 'Desenvolvimento do sistema',
 CURRENT_DATE, CURRENT_DATE + 90, 1),

('Marketing', 'Campanhas da empresa',
 CURRENT_DATE, CURRENT_DATE + 60, 2),

('Financeiro', 'Organização financeira',
 CURRENT_DATE, CURRENT_DATE + 120, 1);



INSERT INTO categorias (nome, descricao)
VALUES
('Desenvolvimento', 'Programação'),
('Planejamento', 'Organização de projetos'),
('Design', 'Criação visual');



INSERT INTO tarefas
(titulo, descricao, data_agendamento, prazo_entrega,
 status, colaborador_id, projeto_id, categoria_id)
VALUES
('Criar página inicial', 'Desenvolver tela principal',
 CURRENT_DATE, CURRENT_DATE + 5, 'Em andamento', 3, 1, 1),

('Planejar campanha', 'Organizar campanha',
 CURRENT_DATE, CURRENT_DATE + 10, 'Pendente', 2, 2, 2),

('Criar identidade visual', 'Desenvolver identidade',
 CURRENT_DATE, CURRENT_DATE + 15, 'Pendente', 1, 3, 3);



CREATE OR REPLACE FUNCTION fn_buscar_colaboradores(p_termo TEXT)
RETURNS TABLE (
    id_colaborador INT,
    nome VARCHAR(100),
    email VARCHAR(100),
    cargo VARCHAR(50),
    ativo BOOLEAN
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id_colaborador,
        c.nome,
        c.email,
        c.cargo,
        c.ativo
    FROM colaboradores c
    WHERE c.nome ILIKE '%' || p_termo || '%'
       OR c.email ILIKE '%' || p_termo || '%';
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE VIEW vw_painel_principal AS
SELECT
    c.nome AS colaborador,
    t.titulo AS tarefa,
    cat.nome AS categoria,
    t.prazo_entrega,
    t.status
FROM tarefas t
INNER JOIN colaboradores c
    ON t.colaborador_id = c.id_colaborador
INNER JOIN categorias cat
    ON t.categoria_id = cat.id_categoria;



CREATE OR REPLACE VIEW vw_cronograma_prazos AS
SELECT
    t.id_tarefa,
    t.titulo AS tarefa,
    c.nome AS responsavel,
    t.data_agendamento,
    t.prazo_entrega,
    t.status,
    t.prazo_entrega - CURRENT_DATE AS dias_restantes
FROM tarefas t
INNER JOIN colaboradores c
    ON t.colaborador_id = c.id_colaborador
ORDER BY t.prazo_entrega ASC, t.id_tarefa ASC;



SELECT * FROM colaboradores;
SELECT * FROM projetos;
SELECT * FROM categorias;
SELECT * FROM tarefas;
SELECT * FROM historico_tarefas;

SELECT * FROM fn_buscar_colaboradores('Maria');

SELECT * FROM vw_painel_principal;

SELECT * FROM vw_cronograma_prazos;