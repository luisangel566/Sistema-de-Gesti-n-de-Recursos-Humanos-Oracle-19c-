Sistema de Gestión de Recursos Humanos – Oracle 19c+

Autor: Luis Angel Tapias Madronero
Nivel: Avanzado
Motor: Oracle Database 19c+
Conceptos clave: Packages PL/SQL, BULK COLLECT, FORALL, REF CURSOR dinámicos, Collections, Funciones analíticas avanzadas, Pipelined Functions.

📌 Descripción del Proyecto

Este proyecto implementa un sistema completo de Recursos Humanos que permite gestionar:

Departamentos y cargos.

Empleados y sus jerarquías.

Evaluaciones de desempeño.

Historial de cargos y promociones.

Solicitudes y control de vacaciones.

Ajustes salariales masivos.

Reportes avanzados y análisis de salarios mediante funciones analíticas.

El proyecto hace uso intensivo de PL/SQL avanzado, colecciones, operaciones BULK y funciones pipelined para reportes, asegurando eficiencia en el procesamiento de grandes volúmenes de datos.

🗂 Estructura de la Base de Datos
Tablas principales
Tabla	Descripción
departamentos	Información de los departamentos y presupuesto anual.
cargos	Información de cargos, niveles y rangos salariales.
empleados	Datos de los empleados, cargos, jefe y salario.
historial_cargos	Registro de cambios de cargos y salarios de los empleados.
evaluaciones	Evaluaciones de desempeño por período y notas finales.
vacaciones	Control de solicitudes y aprobación de vacaciones.
Secuencias
Secuencia	Uso
seq_rh_depto	Generar IDs de departamentos.
seq_rh_cargo	Generar IDs de cargos.
seq_rh_emp	Generar IDs de empleados.
seq_rh_hist	Generar IDs de historial de cargos.
seq_rh_eval	Generar IDs de evaluaciones.
seq_rh_vac	Generar IDs de vacaciones.
📦 Package pkg_rrhh

Este package centraliza la lógica de negocio y automatiza tareas comunes:

Procedimientos

calcular_notas_finales(p_periodo IN VARCHAR2)

Calcula la nota final de todos los empleados para un período dado utilizando la fórmula:

nota_final = 0.4*nota_desempenio + 0.3*nota_actitud + 0.3*nota_resultados

promover_empleado(p_id_empleado, p_id_cargo_nvo, p_nuevo_salario, p_motivo, p_mensaje OUT)

Aplica promociones de cargo y salario, validando rangos y registrando cambios en historial_cargos.

ajuste_masivo_salarios(p_id_depto, p_porcentaje, p_mensaje OUT)

Ajusta los salarios de todos los empleados activos de un departamento en un porcentaje dado. Implementado con BULK COLLECT y FORALL para eficiencia.

Funciones

reporte_departamento(p_id_depto) RETURN t_emp_tabla PIPELINED

Genera un reporte detallado de los empleados de un departamento, incluyendo:

Nombre completo

Cargo

Departamento

Salario

Antigüedad

Última nota de evaluación

🔍 Funciones Analíticas Avanzadas

Comparación de salarios por departamento usando AVG() OVER (PARTITION BY ...)

Ranking y cuartiles salariales con RANK() y NTILE()

Salario acumulado con SUM() OVER (...)

Jerarquía de empleados usando consultas recursivas CONNECT BY PRIOR

💾 Datos de prueba

Se incluyen datos de ejemplo para:

4 departamentos: Tecnología, Recursos Humanos, Finanzas y Operaciones.

7 cargos distintos.

7 empleados con jerarquías y diferentes salarios.

Evaluaciones del período 2024-2.
