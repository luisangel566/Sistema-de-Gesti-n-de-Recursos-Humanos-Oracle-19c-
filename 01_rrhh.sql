-- ============================================================
-- PROYECTO 7: SISTEMA DE RECURSOS HUMANOS
-- Nivel: AVANZADO
-- Motor: Oracle Database 19c+
-- Conceptos: Packages completos, BULK COLLECT, FORALL,
--            Cursores REF CURSOR (dinámicos), Collections,
--            Funciones analíticas avanzadas
-- Autor: Luis Angel Tapias Madronero
-- ============================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE historial_cargos CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE evaluaciones CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE vacaciones CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE empleados CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE cargos CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE departamentos CASCADE CONSTRAINTS';
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ_RH%') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE SEQUENCE seq_rh_depto   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_rh_cargo   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_rh_emp     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_rh_hist    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_rh_eval    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_rh_vac     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE departamentos (
    id_depto   NUMBER        DEFAULT seq_rh_depto.NEXTVAL PRIMARY KEY,
    nombre     VARCHAR2(100) NOT NULL UNIQUE,
    id_gerente NUMBER,
    presupuesto_anual NUMBER(16,2) DEFAULT 0
);

CREATE TABLE cargos (
    id_cargo      NUMBER        DEFAULT seq_rh_cargo.NEXTVAL PRIMARY KEY,
    titulo        VARCHAR2(100) NOT NULL,
    nivel         NUMBER(2)     NOT NULL,  -- 1=junior, 2=semi-senior, 3=senior, 4=lider, 5=gerente
    salario_min   NUMBER(12,2)  NOT NULL,
    salario_max   NUMBER(12,2)  NOT NULL,
    id_depto      NUMBER        NOT NULL,
    CONSTRAINT fk_cargo_depto FOREIGN KEY (id_depto) REFERENCES departamentos(id_depto),
    CONSTRAINT chk_rango_sal  CHECK (salario_max >= salario_min),
    CONSTRAINT chk_nivel      CHECK (nivel BETWEEN 1 AND 5)
);

CREATE TABLE empleados (
    id_empleado  NUMBER        DEFAULT seq_rh_emp.NEXTVAL PRIMARY KEY,
    cedula       VARCHAR2(20)  NOT NULL UNIQUE,
    nombre       VARCHAR2(100) NOT NULL,
    apellido     VARCHAR2(100) NOT NULL,
    email        VARCHAR2(150) NOT NULL UNIQUE,
    id_cargo     NUMBER        NOT NULL,
    id_jefe      NUMBER,
    salario      NUMBER(12,2)  NOT NULL,
    fecha_ingreso DATE         DEFAULT SYSDATE NOT NULL,
    activo       NUMBER(1)     DEFAULT 1,
    CONSTRAINT fk_emp_cargo  FOREIGN KEY (id_cargo) REFERENCES cargos(id_cargo),
    CONSTRAINT fk_emp_jefe   FOREIGN KEY (id_jefe)  REFERENCES empleados(id_empleado)
);

CREATE TABLE historial_cargos (
    id_hist      NUMBER        DEFAULT seq_rh_hist.NEXTVAL PRIMARY KEY,
    id_empleado  NUMBER        NOT NULL,
    id_cargo_ant NUMBER,
    id_cargo_nvo NUMBER        NOT NULL,
    salario_ant  NUMBER(12,2),
    salario_nvo  NUMBER(12,2)  NOT NULL,
    motivo       VARCHAR2(200),
    fecha_cambio DATE          DEFAULT SYSDATE,
    CONSTRAINT fk_hist_emp FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado)
);

CREATE TABLE evaluaciones (
    id_eval      NUMBER        DEFAULT seq_rh_eval.NEXTVAL PRIMARY KEY,
    id_empleado  NUMBER        NOT NULL,
    periodo      VARCHAR2(7)   NOT NULL,
    nota_desempenio NUMBER(4,2) NOT NULL,  -- 1 a 5
    nota_actitud    NUMBER(4,2) NOT NULL,
    nota_resultados NUMBER(4,2) NOT NULL,
    nota_final      NUMBER(4,2),
    comentario   VARCHAR2(500),
    evaluador    VARCHAR2(100),
    CONSTRAINT fk_eval_emp    FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado),
    CONSTRAINT uq_eval        UNIQUE (id_empleado, periodo),
    CONSTRAINT chk_notas_rh   CHECK (nota_desempenio BETWEEN 1 AND 5
                                 AND nota_actitud     BETWEEN 1 AND 5
                                 AND nota_resultados  BETWEEN 1 AND 5)
);

CREATE TABLE vacaciones (
    id_vacacion  NUMBER        DEFAULT seq_rh_vac.NEXTVAL PRIMARY KEY,
    id_empleado  NUMBER        NOT NULL,
    fecha_inicio DATE          NOT NULL,
    fecha_fin    DATE          NOT NULL,
    dias_habiles NUMBER(3)     NOT NULL,
    estado       VARCHAR2(15)  DEFAULT 'SOLICITADA',
    aprobado_por VARCHAR2(100),
    CONSTRAINT fk_vac_emp   FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado),
    CONSTRAINT chk_vac_est  CHECK (estado IN ('SOLICITADA','APROBADA','RECHAZADA','DISFRUTADA')),
    CONSTRAINT chk_vac_fec  CHECK (fecha_fin > fecha_inicio)
);

-- ============================================================
-- DATOS BASE
-- ============================================================
INSERT INTO departamentos (nombre, presupuesto_anual) VALUES ('Tecnología',       600000000);
INSERT INTO departamentos (nombre, presupuesto_anual) VALUES ('Recursos Humanos',  120000000);
INSERT INTO departamentos (nombre, presupuesto_anual) VALUES ('Finanzas',          200000000);
INSERT INTO departamentos (nombre, presupuesto_anual) VALUES ('Operaciones',       300000000);

INSERT INTO cargos (titulo, nivel, salario_min, salario_max, id_depto) VALUES
('Desarrollador Junior',   1, 2000000,  3500000, 1);
INSERT INTO cargos (titulo, nivel, salario_min, salario_max, id_depto) VALUES
('Desarrollador Semi-Senior',2,3500000, 5500000, 1);
INSERT INTO cargos (titulo, nivel, salario_min, salario_max, id_depto) VALUES
('Desarrollador Senior',   3, 5500000,  8000000, 1);
INSERT INTO cargos (titulo, nivel, salario_min, salario_max, id_depto) VALUES
('Líder Técnico',          4, 8000000, 12000000, 1);
INSERT INTO cargos (titulo, nivel, salario_min, salario_max, id_depto) VALUES
('Gerente de TI',          5,12000000, 20000000, 1);
INSERT INTO cargos (titulo, nivel, salario_min, salario_max, id_depto) VALUES
('Analista RRHH',          2, 2800000,  4500000, 2);
INSERT INTO cargos (titulo, nivel, salario_min, salario_max, id_depto) VALUES
('Contador Senior',        3, 4500000,  7000000, 3);

-- Empleados
INSERT INTO empleados (cedula, nombre, apellido, email, id_cargo, id_jefe, salario, fecha_ingreso) VALUES
('10000001','Miguel',   'Santos',   'miguel.s@co.com',    5, NULL, 15000000, DATE '2018-03-01');
INSERT INTO empleados (cedula, nombre, apellido, email, id_cargo, id_jefe, salario, fecha_ingreso) VALUES
('10000002','Laura',    'Garzón',   'laura.g@co.com',     4, 1,   9500000,  DATE '2019-07-15');
INSERT INTO empleados (cedula, nombre, apellido, email, id_cargo, id_jefe, salario, fecha_ingreso) VALUES
('10000003','Felipe',   'Ríos',     'felipe.r@co.com',    3, 2,   6500000,  DATE '2020-01-20');
INSERT INTO empleados (cedula, nombre, apellido, email, id_cargo, id_jefe, salario, fecha_ingreso) VALUES
('10000004','Catalina', 'Mora',     'catalina.m@co.com',  2, 2,   4200000,  DATE '2021-06-10');
INSERT INTO empleados (cedula, nombre, apellido, email, id_cargo, id_jefe, salario, fecha_ingreso) VALUES
('10000005','Andrés',   'Vargas',   'andres.v@co.com',    1, 2,   2800000,  DATE '2023-09-01');
INSERT INTO empleados (cedula, nombre, apellido, email, id_cargo, id_jefe, salario, fecha_ingreso) VALUES
('10000006','Patricia', 'Jiménez',  'patricia.j@co.com',  6, NULL, 3800000, DATE '2020-04-01');
INSERT INTO empleados (cedula, nombre, apellido, email, id_cargo, id_jefe, salario, fecha_ingreso) VALUES
('10000007','Ricardo',  'Castillo', 'ricardo.c@co.com',   7, NULL, 6000000, DATE '2019-11-15');

UPDATE departamentos SET id_gerente = 1 WHERE id_depto = 1;
UPDATE departamentos SET id_gerente = 6 WHERE id_depto = 2;
UPDATE departamentos SET id_gerente = 7 WHERE id_depto = 3;

-- Evaluaciones
INSERT INTO evaluaciones (id_empleado, periodo, nota_desempenio, nota_actitud, nota_resultados, evaluador)
VALUES (1, '2024-2', 5.0, 4.8, 5.0, 'Junta Directiva');
INSERT INTO evaluaciones (id_empleado, periodo, nota_desempenio, nota_actitud, nota_resultados, evaluador)
VALUES (2, '2024-2', 4.5, 4.7, 4.3, 'Miguel Santos');
INSERT INTO evaluaciones (id_empleado, periodo, nota_desempenio, nota_actitud, nota_resultados, evaluador)
VALUES (3, '2024-2', 4.0, 4.2, 3.8, 'Laura Garzón');
INSERT INTO evaluaciones (id_empleado, periodo, nota_desempenio, nota_actitud, nota_resultados, evaluador)
VALUES (4, '2024-2', 3.5, 4.0, 3.5, 'Laura Garzón');
INSERT INTO evaluaciones (id_empleado, periodo, nota_desempenio, nota_actitud, nota_resultados, evaluador)
VALUES (5, '2024-2', 3.0, 3.8, 2.9, 'Laura Garzón');

COMMIT;

-- ============================================================
-- PACKAGE RRHH COMPLETO
-- ============================================================
CREATE OR REPLACE PACKAGE pkg_rrhh AS

    -- Tipo para reportes en colección
    TYPE t_emp_rec IS RECORD (
        nombre_completo VARCHAR2(200),
        cargo           VARCHAR2(100),
        departamento    VARCHAR2(100),
        salario         NUMBER(12,2),
        antiguedad      NUMBER,
        nota_eval       NUMBER(4,2)
    );
    TYPE t_emp_tabla IS TABLE OF t_emp_rec;

    PROCEDURE calcular_notas_finales(p_periodo IN VARCHAR2);

    PROCEDURE promover_empleado(
        p_id_empleado IN  NUMBER,
        p_id_cargo_nvo IN NUMBER,
        p_nuevo_salario IN NUMBER,
        p_motivo        IN VARCHAR2,
        p_mensaje       OUT VARCHAR2
    );

    FUNCTION reporte_departamento(p_id_depto IN NUMBER)
        RETURN t_emp_tabla PIPELINED;

    PROCEDURE ajuste_masivo_salarios(
        p_id_depto    IN  NUMBER,
        p_porcentaje  IN  NUMBER,
        p_mensaje     OUT VARCHAR2
    );

END pkg_rrhh;
/

CREATE OR REPLACE PACKAGE BODY pkg_rrhh AS

    -- Calcular nota final de evaluaciones (40%-30%-30%)
    PROCEDURE calcular_notas_finales(p_periodo IN VARCHAR2) IS
        TYPE t_ids IS TABLE OF NUMBER;
        v_ids t_ids;
    BEGIN
        -- BULK COLLECT: cargar todos los IDs en colección
        SELECT id_eval BULK COLLECT INTO v_ids
        FROM evaluaciones WHERE periodo = p_periodo AND nota_final IS NULL;

        -- FORALL: actualizar en lote (1 operación en lugar de N)
        FORALL i IN 1..v_ids.COUNT
            UPDATE evaluaciones
            SET nota_final = ROUND(
                nota_desempenio * 0.40 + nota_actitud * 0.30 + nota_resultados * 0.30, 2)
            WHERE id_eval = v_ids(i);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Notas calculadas para ' || v_ids.COUNT || ' evaluaciones. Período: ' || p_periodo);
    END;

    -- Promover empleado con registro de historial
    PROCEDURE promover_empleado(
        p_id_empleado   IN  NUMBER,
        p_id_cargo_nvo  IN  NUMBER,
        p_nuevo_salario IN  NUMBER,
        p_motivo        IN  VARCHAR2,
        p_mensaje       OUT VARCHAR2
    ) IS
        v_cargo_ant  NUMBER;
        v_salario_ant NUMBER(12,2);
        v_sal_min    NUMBER(12,2);
        v_sal_max    NUMBER(12,2);
    BEGIN
        SELECT id_cargo, salario INTO v_cargo_ant, v_salario_ant
        FROM empleados WHERE id_empleado = p_id_empleado;

        SELECT salario_min, salario_max INTO v_sal_min, v_sal_max
        FROM cargos WHERE id_cargo = p_id_cargo_nvo;

        IF p_nuevo_salario NOT BETWEEN v_sal_min AND v_sal_max THEN
            p_mensaje := 'ERROR: El salario $' || p_nuevo_salario ||
                         ' está fuera del rango para el cargo ($' ||
                         v_sal_min || ' - $' || v_sal_max || ')';
            RETURN;
        END IF;

        -- Registrar historial antes de cambiar
        INSERT INTO historial_cargos (id_empleado, id_cargo_ant, id_cargo_nvo,
                                      salario_ant, salario_nvo, motivo)
        VALUES (p_id_empleado, v_cargo_ant, p_id_cargo_nvo,
                v_salario_ant, p_nuevo_salario, p_motivo);

        -- Actualizar empleado
        UPDATE empleados
        SET id_cargo = p_id_cargo_nvo, salario = p_nuevo_salario
        WHERE id_empleado = p_id_empleado;

        COMMIT;
        p_mensaje := 'Promoción aplicada. Nuevo salario: $' ||
                     TO_CHAR(p_nuevo_salario,'999,999,999');
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    -- Función pipelined: Reporte de departamento
    FUNCTION reporte_departamento(p_id_depto IN NUMBER)
        RETURN t_emp_tabla PIPELINED IS
        v_rec t_emp_rec;
    BEGIN
        FOR r IN (
            SELECT
                e.nombre || ' ' || e.apellido   AS nombre_completo,
                c.titulo                         AS cargo,
                d.nombre                         AS departamento,
                e.salario,
                TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecha_ingreso)/12) AS antiguedad,
                ev.nota_final
            FROM empleados  e
            INNER JOIN cargos        c  ON e.id_cargo  = c.id_cargo
            INNER JOIN departamentos d  ON c.id_depto  = d.id_depto
            LEFT  JOIN evaluaciones  ev ON e.id_empleado = ev.id_empleado
                                       AND ev.periodo = '2024-2'
            WHERE d.id_depto = p_id_depto AND e.activo = 1
            ORDER BY e.salario DESC
        ) LOOP
            v_rec.nombre_completo := r.nombre_completo;
            v_rec.cargo           := r.cargo;
            v_rec.departamento    := r.departamento;
            v_rec.salario         := r.salario;
            v_rec.antiguedad      := r.antiguedad;
            v_rec.nota_eval       := r.nota_final;
            PIPE ROW(v_rec);
        END LOOP;
    END;

    -- Ajuste masivo de salarios con BULK COLLECT + FORALL
    PROCEDURE ajuste_masivo_salarios(
        p_id_depto   IN  NUMBER,
        p_porcentaje IN  NUMBER,
        p_mensaje    OUT VARCHAR2
    ) IS
        TYPE t_emp_ids IS TABLE OF NUMBER;
        TYPE t_salarios IS TABLE OF NUMBER;
        v_ids      t_emp_ids;
        v_salarios t_salarios;
        v_ajuste   NUMBER;
    BEGIN
        IF p_porcentaje <= 0 OR p_porcentaje > 30 THEN
            p_mensaje := 'ERROR: El porcentaje debe ser entre 0.1% y 30%.';
            RETURN;
        END IF;

        v_ajuste := 1 + (p_porcentaje / 100);

        -- BULK COLLECT: obtener empleados del departamento
        SELECT e.id_empleado, ROUND(e.salario * v_ajuste, 0)
        BULK COLLECT INTO v_ids, v_salarios
        FROM empleados e
        INNER JOIN cargos c ON e.id_cargo = c.id_cargo
        WHERE c.id_depto = p_id_depto AND e.activo = 1;

        -- FORALL: actualizar todos en un solo viaje a la BD
        FORALL i IN 1..v_ids.COUNT
            UPDATE empleados
            SET salario = v_salarios(i)
            WHERE id_empleado = v_ids(i);

        COMMIT;
        p_mensaje := 'Ajuste del ' || p_porcentaje || '% aplicado a ' ||
                     v_ids.COUNT || ' empleados del departamento.';
    END;

END pkg_rrhh;
/

-- ============================================================
-- FUNCIONES ANALÍTICAS AVANZADAS
-- ============================================================

-- Análisis salarial completo con ventanas
SELECT
    e.nombre || ' ' || e.apellido            AS empleado,
    c.titulo                                  AS cargo,
    d.nombre                                  AS departamento,
    e.salario,
    -- Comparación con compañeros del departamento
    ROUND(AVG(e.salario) OVER (PARTITION BY d.id_depto), 0)    AS promedio_depto,
    e.salario - AVG(e.salario) OVER (PARTITION BY d.id_depto)  AS diferencia_promedio,
    RANK()  OVER (PARTITION BY d.id_depto ORDER BY e.salario DESC) AS rank_en_depto,
    NTILE(4) OVER (ORDER BY e.salario DESC)                    AS cuartil_salarial,
    -- Salario acumulado
    SUM(e.salario) OVER (ORDER BY e.salario DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS acumulado
FROM empleados  e
INNER JOIN cargos        c ON e.id_cargo  = c.id_cargo
INNER JOIN departamentos d ON c.id_depto  = d.id_depto
WHERE e.activo = 1
ORDER BY d.nombre, e.salario DESC;

-- Jerarquía de empleados (consulta recursiva)
SELECT LEVEL,
    LPAD('  ', (LEVEL-1)*3) || e.nombre || ' ' || e.apellido AS organigrama,
    c.titulo AS cargo
FROM empleados e
INNER JOIN cargos c ON e.id_cargo = c.id_cargo
START WITH e.id_jefe IS NULL
CONNECT BY PRIOR e.id_empleado = e.id_jefe
ORDER SIBLINGS BY e.apellido;

-- ============================================================
-- EJECUCIÓN
-- ============================================================
SET SERVEROUTPUT ON;

-- Calcular notas finales del período
EXEC pkg_rrhh.calcular_notas_finales('2024-2');

-- Promover empleado
DECLARE v_msg VARCHAR2(500); BEGIN
    pkg_rrhh.promover_empleado(5, 2, 4000000, 'Excelente desempeño y antigüedad', v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
END;
/

-- Ajuste salarial masivo departamento TI (5%)
DECLARE v_msg VARCHAR2(500); BEGIN
    pkg_rrhh.ajuste_masivo_salarios(1, 5, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
END;
/

-- Reporte del departamento (función pipelined)
SELECT * FROM TABLE(pkg_rrhh.reporte_departamento(1));
