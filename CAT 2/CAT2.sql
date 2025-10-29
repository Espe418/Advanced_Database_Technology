---Task1:Split your database into two logical nodes (e.g.BranchDB_A, BranchDB_B) using Vertical fragmentation. 
-- Create logical nodes as schemas
CREATE SCHEMA IF NOT EXISTS Branch_A;
CREATE SCHEMA IF NOT EXISTS Branch_B;
-- --------- Branch_A tables ----------
CREATE TABLE Department(
    DeptID SERIAL PRIMARY KEY,
    DeptName VARCHAR(100),
    Location VARCHAR(100),
    Head VARCHAR(100)
);

CREATE TABLE Staff(
    StaffID SERIAL PRIMARY KEY,
    FullName VARCHAR(100),
    DeptID INT REFERENCES Department(DeptID),
    Role VARCHAR(50),
    Email VARCHAR(100),
    HireDate DATE
);


-- Departments
INSERT INTO Department (DeptName, Location, Head) VALUES
('Human Resources', 'Building A', 'John Doe'),
('Finance', 'Building B', 'Jane Smith'),
('IT', 'Building C', 'Alice Johnson'),
('Marketing', 'Building D', 'Bob Brown');


-- Staff
INSERT INTO Staff (FullName, DeptID, Role, Email, HireDate) VALUES
('Michael Scott', 1, 'HR Manager', 'michael.scott@company.com', '2020-01-15'),
('Pam Beesly', 1, 'HR Assistant', 'pam.beesly@company.com', '2021-03-10'),
('Jim Halpert', 2, 'Financial Analyst', 'jim.halpert@company.com', '2019-06-20'),
('Dwight Schrute', 2, 'Accountant', 'dwight.schrute@company.com', '2018-11-05'),
('Angela Martin', 3, 'IT Specialist', 'angela.martin@company.com', '2022-02-12'),
('Kevin Malone', 3, 'System Admin', 'kevin.malone@company.com', '2017-08-25'),
('Oscar Martinez', 4, 'Marketing Manager', 'oscar.martinez@company.com', '2016-05-30'),
('Kelly Kapoor', 4, 'Marketing Assistant', 'kelly.kapoor@company.com', '2021-09-14');

------- Task2. Create a database link between your two schemas Demonstrate a successful remote SELECT and a 
---distributed join between local and remote tables. Include scripts and query results. 

 
-- On BranchDB_A to access BranchDB_B
CREATE EXTENSION IF NOT EXISTS postgres_fdw; ----enabling fdw extension
-- Create server pointing to the same DB or a remote DB. Replace connection options.
CREATE SERVER branchb_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'Branch_B', port '5432');
-- Create user mapping for current_user (replace username/password)
CREATE USER MAPPING FOR CURRENT_USER
SERVER branchb_server
OPTIONS (user 'postgres', password '1234');

-- Import remote table
IMPORT FOREIGN SCHEMA public
LIMIT TO (Salary, Payroll,Leaverecord, Attendance)
FROM SERVER branchb_server
INTO public;

SELECT * FROM staff;
SELECT * FROM Salary;
SELECT * FROM attendance ;
-- Join local Staff with remote Salary table
EXPLAIN ANALYZE
SELECT s.FullName, s.Role, sal.BasePay, sal.Allowances
FROM Staff s
JOIN Salary sal ON s.StaffID = sal.StaffID;



SELECT *FROM salary;


-- Select all rows from remote Salary table
SELECT * FROM Payroll;

-- Select specific columns from remote salary table 
SELECT StaffID, BasePay, Allowances FROM Salary
WHERE BasePay > 4000;


SELECT datname FROM pg_database;

----TASK3:  Enable parallel query execution on a large table (e.g., Transactions, Orders). Use /*+ PARALLEL(table, 8) */ hint and compare serial vs parallel performance. Show 
--EXPLAIN PLAN output and execution time.

SELECT * FROM payroll LIMIT 5;

CREATE FOREIGN TABLE payroll_fdw (
    salaryid INT,
    periodstart DATE,
    periodend DATE,
    netpay NUMERIC(12,2)
) SERVER branchb_server
OPTIONS (table_name 'payroll');  -- remote table
----
-- Serial run: force no parallel workers
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO payroll_fdw (salaryid, periodstart, periodend, netpay)
SELECT
    (6 + (random()*1000)::int) AS salaryid,
    current_date - ((random()*365)::int) AS periodstart,
    current_date AS periodend,
    (random()*1000000)::numeric(12,2) AS netpay
FROM generate_series(1, 2000000);

--- Parallel  run
SET max_parallel_workers_per_gather = 2;
SET max_parallel_workers = 8;
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO payroll_fdw (salaryid, periodstart, periodend, netpay)
SELECT
    (6 + (random()*1000)::int) AS salaryid,
    current_date - ((random()*365)::int) AS periodstart,
    current_date AS periodend,
    (random()*1000000)::numeric(12,2) AS netpay
FROM generate_series(1, 2000000);
 
-------TASK 4:Two-Phase Commit Simulation
----Session 1 :LOCAL
--Begin + Prepare Remote (Salary) Transaction
-- Start local transaction to insert into remote Salary table via FDW
-- Local transaction (BranchDB_A)
--  Remote Salary insert via FDW
BEGIN;

INSERT INTO salary_fdw(staffid, basepay, allowances, deductions)
VALUES (1, 50000, 600, 100);

-- Prepare remote transaction
PREPARE TRANSACTION 'gid_staff_salary_tx';
ROLLBACK;

----
INSERT INTO staff(fullname, deptid, role, email, hiredate)
VALUES ('Mugisha', 1, 'Accountant', 'mugisha@example.com', '2025-9-24');

-- Remote Salary (FDW)
BEGIN;
INSERT INTO salary_fdw(staffid, basepay, allowances, deductions)
VALUES (1, 50000, 600, 100);
PREPARE TRANSACTION 'gid_staff_salary_tx';

-- Local Staff
BEGIN;
INSERT INTO staff(fullname, deptid, role, email, hiredate)
VALUES ('Alice', 1, 'Manager', 'alice@example.com', '2025-10-24');
PREPARE TRANSACTION 'gid_staff_salary_tx';
COMMIT PREPARED 'gid_staff_salary_tx';
COMMIT PREPARED 'gid_staff_salary_tx';

SELECT * FROM pg_prepared_xacts;

ROLLBACK PREPARED 'fail_test';



----- TASK 5: Simulate a network failure during a distributed transaction. Check unresolved transactions and resolve them using ROLLBACK FORCE. Submit screenshots and 
--brief explanation of recovery steps.

CREATE FOREIGN TABLE salary_fdw (
    salaryid INT,
    staffid INT,
    basepay NUMERIC,
    allowances NUMERIC,
    deductions NUMERIC
)
SERVER branchb_server
OPTIONS (schema_name 'public', table_name 'salary');

BEGIN;

INSERT INTO Staff(FullName, DeptID, Role, Email, HireDate)
VALUES ('Alice', 1, 'Manager', 'alice@example.com', '2025-10-24');


INSERT INTO public.salary(staffid, basepay, allowances, deductions)
VALUES (1, 5000.00, 500.00, 100.00);

---- for failing the transaction
BEGIN;

-- This insert must succeed, otherwise PREPARE won't work
INSERT INTO Staff(FullName, DeptID, Role, Email, HireDate)
VALUES ('Alice', 1, 'Manager', 'alice@example.com', '2025-10-24');

-- Prepare the transaction
PREPARE TRANSACTION 'fail_test';

-- You can now see it
SELECT * FROM pg_prepared_xacts;

-- Later, rollback to simulate failure
ROLLBACK PREPARED 'fail_test';
BEGIN;

-- This insert must succeed, otherwise PREPARE won't work
INSERT INTO Staff(FullName, DeptID, Role, Email, HireDate)
VALUES ('Alice', 1, 'Manager', 'alice@example.com', '2025-10-24');

-- Prepare the transaction
PREPARE TRANSACTION 'fail_test';

-- You can now see it
SELECT * FROM pg_prepared_xacts;

-- Later, rollback to simulate failure
ROLLBACK PREPARED 'fail_test';



new_salaryid INT GENERATED ALWAYS AS IDENTITY;
SELECT * FROM pg_prepared_xacts;

PREPARE TRANSACTION 'tx1';

-- Commit after verification
COMMIT PREPARED 'tx1';


----- TASK 5: Simulate a network failure during a distributed transaction. Check unresolved transactions and resolve them using ROLLBACK FORCE. Submit screenshots and 
--brief explanation of recovery steps.

SELECT * FROM pg_prepared_xacts;


ROLLBACK PREPARED 'tx1';

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT s.fullname, sal.basepay, p.netpay
FROM staff s
JOIN salary sal ON s.staffid = sal.staffid
JOIN payroll p ON sal.salaryid = p.salaryid;


----
SELECT * FROM pg_prepared_xacts;
``- --This will list all currently prepared transactions. If `"tx1"` isn’t listed, it doesn’t exist.
-- Make sure you **prepare the transaction** before trying to commit it:sql
  BEGIN;
  -- your SQL operations
  PREPARE TRANSACTION 'tx1';

SHOW max_prepared_transactions;



----- TASK6:Distributed Concurrency Control

---- lock Demonstrate a lock conflict by running two sessions that update the same record from different nodes

BEGIN;_---- local node (Branch_A): start explicit transaction (autocommit disabled)
 
UPDATE staff SET role = 'Manager' WHERE staffid = 2;
-----Step 2: remode node(FleetSupport): Simulates lock conflict by updating same record remotely
-- The follwing statement hangs (waits) indefinitely until transaction on node A is committed/rolled back
-- Keep it open
UPDATE staff SET role = 'Supervisor' WHERE staffid = 2;


----
SELECT
    pid,
    relation::regclass AS table_name,
    mode,
    granted
FROM pg_locks
WHERE relation::regclass = 'staff'::regclass;

----
BEGIN;  -- start a transaction

UPDATE staff
SET role = 'Manager'
WHERE staffid = 2;

-- now staffid = 2 is locked until you COMMIT or ROLLBACK
UPDATE staff
SET role = 'Supervisor'
WHERE staffid = 2;
----
SELECT
    pid,
    locktype,
    relation::regclass AS table_name,
    mode,
    granted
FROM pg_locks
WHERE relation::regclass IN ('staff'::regclass, 'payroll'::regclass);


COMMIT;

---- Unlocking the transaction
SELECT
    l.pid,
    c.relname AS table_name,
    l.mode,
    l.granted
FROM pg_locks l
JOIN pg_class c ON l.relation = c.oid
WHERE c.relname = 'staff';







-----TASK7:Perform parallel data aggregation or loading using PARALLEL DML. Compare runtime and document improvement in query cost and execution time.
--1. Enable parallel workers
SET max_parallel_workers_per_gather = 8;
SET max_parallel_workers = 8;
SET max_parallel_maintenance_workers = 4;


-- Serial insert
INSERT INTO Payroll_Archive
SELECT * FROM Payroll;

-- 2. Create archive table
CREATE TABLE Payroll_Archive AS
TABLE Payroll WITH NO DATA;

-- 4. Serial insert with EXPLAIN
SET max_parallel_workers_per_gather = 0;  -- disable parallelism
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO Payroll_Archive
SELECT * FROM Payroll;


--5. Parallel insert with EXPLAIN
SET max_parallel_workers_per_gather = 8;
SET max_parallel_workers = 8;
SET max_parallel_maintenance_workers = 4;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO Payroll_Archive
SELECT * FROM Payroll;


----- TASK 8:Draw and explain a three-tier architecture for your project 
--(Presentation, Application, Database). Show data flow and interaction with database links.
 --Distributed Query Optimization Use EXPLAIN PLAN and DBMS_X
BEGIN;
INSERT INTO staff (fullname, deptid, role, email, hiredate) VALUES
('Tx User A',1,'Temp','txa@example.com',current_date);
-- prepare the local transaction
PREPARE TRANSACTION 'tx_a';
-- do NOT COMMIT PREPARED yet

SELECT * FROM pg_prepared_xacts;

---TASK9:Use EXPLAIN PLAN and DBMS_XPLAN.DISPLAY to analyze a distributed join. Discuss optimizer strategy and
 --how data movement is minimized.

--  Ensure correct search_path (optional, adjust if needed)
SET search_path = public, BranchDB_A;

--  Distributed join query with EXPLAIN in JSON format
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT 
    s.fullname,
    (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM 
    staff s
JOIN 
    public.salary_remote sal
ON 
    s.staffid = sal.staffid
WHERE s.active = true;  -- optional filter to minimize rows

-----



CREATE FOREIGN TABLE public.salary_remote (
    staffid INT,
    basepay NUMERIC,
    allowances NUMERIC,
    deductions NUMERIC
)
SERVER branchb_server
OPTIONS (
    table_name 'salary'
);
SELECT * FROM public.salary_remote LIMIT 5;
----

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT 
    s.fullname,
    (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM 
    staff s
JOIN 
    public.salary_remote sal
ON 
    s.staffid = sal.staffid;



   
---TASK 10 :Run one complex query three ways – centralized, parallel, distributed. Measure time and I/O using AUTOTRACE. Write a half-page analysis on scalability and efficiency.


-- TASK: Centralized, Parallel, Distributed Query

-- Centralized Query  no parallelism)
SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    s.fullname,
    (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM 
    staff s
JOIN 
    salary sal
ON 
    s.staffid = sal.staffid;

--  Parallel Query (use multiple workers for local tables)
SET max_parallel_workers_per_gather = 4;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    s.fullname,
    (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM 
    staff s
JOIN 
    salary sal
ON 
    s.staffid = sal.staffid;

--  Distributed Query (salary_remote via FDW)
-- Ensure salary_remote already exists and FDW server is configured

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    s.fullname,
    (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM 
    staff s
JOIN 
    public.salary_remote sal
ON 
    s.staffid = sal.staffid;

-- ============================
-- Notes on Measuring Time and I/O
-- ============================
-- Execution time: shown in EXPLAIN ANALYZE under "Execution Time"
-- Buffer usage: "shared read", "shared hit", "temp read/write" shows I/O
-- Compare the three runs to see efficiency and scalability


----SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'active' AND query LIKE '%your_query_identifier%';



