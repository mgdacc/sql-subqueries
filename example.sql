-- =============================================================================
-- ||                 EJEMPLOS DETALLADOS DE SQL SUBQUERIES                   ||
-- =============================================================================
-- 
-- Este script demuestra el uso de consultas anidadas (Subqueries) en diferentes
-- cláusulas (WHERE, SELECT, FROM) y tipos (Escalares, Listas, Correlacionadas).
-- 

-- =============================================================================
-- PASO 1: CONFIGURACIÓN - CREACIÓN DE TABLAS Y DATOS
-- =============================================================================

-- Configuración para SQLite (ignorado por otros motores)
PRAGMA foreign_keys = ON;

-- Limpieza
DROP TABLE IF EXISTS DetalleOrdenes;
DROP TABLE IF EXISTS Ordenes;
DROP TABLE IF EXISTS Productos;
DROP TABLE IF EXISTS Empleados;

-- 1. Tabla de Empleados (Vendedores)
CREATE TABLE Empleados (
    EmpleadoID INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Salario DECIMAL(10, 2),
    Departamento VARCHAR(50)
);

-- 2. Tabla de Productos
CREATE TABLE Productos (
    ProductoID INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Categoria VARCHAR(50),
    Precio DECIMAL(10, 2)
);

-- 3. Tabla de Ordenes (Ventas)
CREATE TABLE Ordenes (
    OrdenID INT PRIMARY KEY,
    EmpleadoID INT, -- Quién vendió
    MontoTotal DECIMAL(10, 2),
    Fecha DATE,
    FOREIGN KEY (EmpleadoID) REFERENCES Empleados(EmpleadoID)
);

-- --- Insertar Datos ---

INSERT INTO Empleados VALUES
(1, 'Ana Gerente', 8000.00, 'Ventas'),
(2, 'Carlos Vendedor', 3000.00, 'Ventas'),
(3, 'Diana Vendedora', 3200.00, 'Ventas'),
(4, 'Eduardo Soporte', 2500.00, 'IT'), -- Salario bajo
(5, 'Fernando Nuevo', 1200.00, 'Ventas'); -- Salario muy bajo, sin ventas aún

INSERT INTO Productos VALUES
(101, 'Laptop Pro', 'Electrónica', 1500.00),
(102, 'Smartphone', 'Electrónica', 800.00),
(103, 'Monitor', 'Electrónica', 300.00),
(104, 'Silla Ergonómica', 'Muebles', 200.00),
(105, 'Escritorio', 'Muebles', 150.00);

INSERT INTO Ordenes VALUES
(1, 2, 1500.00, '2023-10-01'), -- Venta de Carlos
(2, 2, 300.00,  '2023-10-02'), -- Venta de Carlos
(3, 3, 2000.00, '2023-10-05'), -- Venta de Diana
(4, 1, 5000.00, '2023-10-10'); -- Venta de Ana


-- =============================================================================
-- PASO 2: EJEMPLOS DE SUBQUERIES
-- =============================================================================

-- ===== EJEMPLO 1: Subquery Escalar en WHERE =====
-- Escenario: Queremos saber qué empleados ganan MÁS que el salario promedio de la empresa.
-- Lógica:
-- 1. La subquery calcula el promedio (un solo número).
-- 2. La query principal filtra comparando con ese número.

SELECT Nombre, Salario
FROM Empleados
WHERE Salario > (SELECT AVG(Salario) FROM Empleados);

-- Resultado esperado: Ana (8000) gana más que el promedio (aprox 3580).


-- ===== EJEMPLO 2: Subquery de Lista con IN =====
-- Escenario: Queremos ver los detalles de los productos que son de la misma categoría
-- que la 'Silla Ergonómica', pero sin incluir la silla misma.
-- Lógica:
-- 1. La subquery obtiene la categoría de la silla ('Muebles').
-- 2. La query principal busca productos en esa categoría.

SELECT Nombre, Precio
FROM Productos
WHERE Categoria IN (
    SELECT Categoria 
    FROM Productos 
    WHERE Nombre = 'Silla Ergonómica'
)
AND Nombre != 'Silla Ergonómica';

-- Resultado esperado: Escritorio.


-- ===== EJEMPLO 3: Subquery en SELECT (Columna Calculada) =====
-- Escenario: Queremos una lista de todos los empleados y cuántas órdenes ha procesado cada uno.
-- Lógica: Para cada fila de empleado, la subquery cuenta sus órdenes en la otra tabla.

SELECT 
    Nombre,
    (SELECT COUNT(*) 
     FROM Ordenes 
     WHERE Ordenes.EmpleadoID = Empleados.EmpleadoID) AS TotalOrdenes
FROM Empleados;

-- Resultado esperado: 
-- Carlos: 2, Diana: 1, Ana: 1, Eduardo: 0, Fernando: 0.


-- ===== EJEMPLO 4: Subquery con NOT EXISTS (Correlacionada) =====
-- Escenario: Encontrar empleados del departamento de 'Ventas' que AÚN NO han hecho ninguna venta.
-- Lógica: "Dame los empleados donde NO EXISTE una orden con su ID".

SELECT Nombre
FROM Empleados E
WHERE Departamento = 'Ventas'
AND NOT EXISTS (
    SELECT 1 
    FROM Ordenes O 
    WHERE O.EmpleadoID = E.EmpleadoID
);

-- Resultado esperado: Fernando Nuevo (es de ventas pero no tiene órdenes).
-- Eduardo tampoco tiene órdenes, pero es de IT, así que el filtro de Dpto lo excluye.


-- ===== EJEMPLO 5: Subquery en FROM (Tabla Derivada) =====
-- Escenario: Queremos saber el salario promedio por departamento, pero solo de los 
-- departamentos donde ese promedio sea mayor a 3000.
-- Lógica: Primero agrupamos y calculamos promedios (tabla virtual), luego filtramos esa tabla.

SELECT Departamento, SalarioPromedio
FROM (
    SELECT Departamento, AVG(Salario) AS SalarioPromedio
    FROM Empleados
    GROUP BY Departamento
) AS TablaPromedios -- El alias es obligatorio en muchos SQL
WHERE SalarioPromedio > 3000;

-- Resultado esperado: Solo el departamento 'Ventas' (promedio alto). 'IT' tiene promedio 2500.


-- ===== BONUS: Common Table Expression (CTE) =====
-- Escenario: El mismo que el anterior (Ejemplo 5), pero escrito de forma moderna y legible.
-- Esto hace lo mismo que una subquery en FROM, pero se define arriba.

WITH MetricasDepartamentos AS (
    SELECT Departamento, AVG(Salario) AS SalarioPromedio
    FROM Empleados
    GROUP BY Departamento
)
SELECT Departamento, SalarioPromedio
FROM MetricasDepartamentos
WHERE SalarioPromedio > 3000;

-- Resultado esperado: El mismo que el anterior, pero el código es más limpio.
