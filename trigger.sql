=

DROP TABLE IF EXISTS historico_tarefas CASCADE;
DROP TABLE IF EXISTS tarefas CASCADE;
DROP TABLE IF EXISTS colaboradores CASCADE;



CREATE TABLE colaboradores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    senha VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);




CREATE TABLE tarefas (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    categoria VARCHAR(80) NOT NULL,
    descricao TEXT,
    prazo DATE NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'Pendente',
    colaborador_id INTEGER NOT NULL,

    CONSTRAINT fk_responsavel
        FOREIGN KEY (colaborador_id)
        REFERENCES colaboradores(id),

    CONSTRAINT verificar_status
        CHECK (status IN (
            'Pendente',
            'Em andamento',
            'Concluida',
            'Cancelada'
        ))
);




CREATE TABLE historico_tarefas (
    id SERIAL PRIMARY KEY,
    tarefa_id INTEGER NOT NULL,
    descricao_evento TEXT NOT NULL,
    registrado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_historico_tarefa
        FOREIGN KEY (tarefa_id)
        REFERENCES tarefas(id)
);




INSERT INTO colaboradores (nome, email, senha, ativo)
VALUES
('Lucas', 'lucas@gmail.com', 'lucas123', TRUE),
('Fernanda', 'fernanda@gmail.com', 'fer123', TRUE),
('Pedro', 'pedro@gmail.com', 'pedro456', FALSE),
('Juliana', 'juliana@gmail.com', 'juli789', TRUE);




CREATE OR REPLACE FUNCTION validar_colaborador()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM colaboradores
        WHERE id = NEW.colaborador_id
        AND ativo = TRUE
    ) THEN
        RAISE EXCEPTION
        'Não é possível criar tarefa para colaborador inativo ou inexistente!';
    END IF;

    NEW.criado_em = NOW();

    RETURN NEW;

END;
$$;


CREATE TRIGGER verificar_colaborador
BEFORE INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION validar_colaborador();



CREATE OR REPLACE FUNCTION adicionar_historico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO historico_tarefas (
        tarefa_id,
        descricao_evento
    )
    VALUES (
        NEW.id,
        'Nova tarefa cadastrada: ' || NEW.titulo
    );

    RETURN NEW;

END;
$$;


CREATE TRIGGER registrar_criacao
AFTER INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION adicionar_historico();



INSERT INTO tarefas
(titulo, categoria, descricao, prazo, status, colaborador_id)
VALUES
(
    'Atualizar sistema interno',
    'Tecnologia',
    'Realizar melhorias no sistema da empresa',
    '2026-12-03',
    'Em andamento',
    1
),
(
    'Revisar contratos',
    'Jurídico',
    'Verificar documentos e contratos pendentes',
    '2026-12-08',
    'Pendente',
    2
),
(
    'Planejar campanha publicitária',
    'Marketing',
    'Organizar ideias para a próxima campanha',
    '2026-12-15',
    'Pendente',
    4
),
(
    'Organizar estoque',
    'Administrativo',
    'Conferir os produtos armazenados',
    '2026-12-01',
    'Concluida',
    1
);



CREATE OR REPLACE VIEW vw_tarefas AS
SELECT
    t.id,
    t.titulo,
    t.categoria,
    c.nome AS responsavel,
    t.prazo,
    t.status
FROM tarefas t
JOIN colaboradores c
ON c.id = t.colaborador_id;



CREATE OR REPLACE FUNCTION pesquisar_colaborador(
    pesquisa TEXT
)
RETURNS TABLE (
    codigo INTEGER,
    nome VARCHAR(120),
    email VARCHAR(150),
    situacao BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
        c.id,
        c.nome,
        c.email,
        c.ativo
    FROM colaboradores c
    WHERE c.nome ILIKE '%' || pesquisa || '%'
       OR c.email ILIKE '%' || pesquisa || '%';

END;
$$;



CREATE OR REPLACE VIEW vw_prazos AS
SELECT
    t.id AS codigo_tarefa,
    t.titulo,
    t.prazo,
    t.status,
    c.nome AS responsavel,
    (t.prazo - CURRENT_DATE) AS dias_ate_entrega
FROM tarefas t
INNER JOIN colaboradores c
ON c.id = t.colaborador_id;



SELECT * FROM colaboradores;



SELECT * FROM tarefas;



SELECT * FROM historico_tarefas;



SELECT * FROM vw_tarefas;



SELECT * FROM pesquisar_colaborador('Lucas');

SELECT *
FROM vw_prazos
ORDER BY prazo ASC;


