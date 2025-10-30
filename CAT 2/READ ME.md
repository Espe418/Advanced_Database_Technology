#NYIRASABATO ESPERANCE
## REG:215009303
## ADVANCED DATABASE TECHNOGY


#  Parallel and Distributed Database System (PostgreSQL / pgAdmin)

##  Purpose
This lab assessment help me to **design, implement, and analyze a parallel and distributed database system** using **PostgreSQL/pgAdmin**.  
**University Staff Information and Payroll System.**


## Implementation Details
## 1.Distributed Schema Design and Fragmentation /Split your database into two logical nodes (e.g., BranchDB_A, BranchDB_B) using **horizontal or vertical fragmentation**. Submit an ER diagram and SQL scripts that create both schemas. 
## 2. Create and Use Database Links / Create a **database link** between schemas. Demonstrate **remote SELECT** and **distributed join** between local and remote tables. Include scripts and query results

## 3. Parallel Query Execution : Enable parallel query execution on a large table. Compare **serial vs parallel performance** using `EXPLAIN PLAN`. 
## 4 .Two-Phase Commit Simulation : Write a PL/pgSQL block performing inserts on both nodes and committing once. Verify atomicity using `pg_prepared_xacts`. 
## 5. Distributed Rollback and Recovery :Simulate network failure during distributed transaction. Resolve unresolved transactions using `ROLLBACK PREPARED`. 
## 6. Distributed Concurrency Control / Demonstrate a **lock conflict** from two sessions updating the same record. Use `pg_locks` to analyze. 
## 7 Parallel Data Loading :ETL Simulation / Perform parallel aggregation/loading using `PARALLEL DML`. Compare runtime and query cost. 
## 8 . Three-Tier Client-Server Architecture Design : Draw and explain three-tier architecture (Presentation, Application, Database). Show **data flow and DB link interactions**. 
## 9. Distributed Query Optimization : Use `EXPLAIN PLAN` and discuss optimizer strategy and **data movement minimization**. 
## 10  Performance Benchmark and Report : Run complex query three ways – centralized, parallel, distributed. Measure **time and I/O** using `AUTOTRACE`. Write analysis. 

##  TASK 1: Distributed Schema Design and Fragmentation (Vertical)

 ---- sql code
CREATE SCHEMA IF NOT EXISTS Branch_A;
CREATE SCHEMA IF NOT EXISTS Branch_B;

-- Branch_A tables
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

-- Insert data
INSERT INTO Department (DeptName, Location, Head) VALUES
('Human Resources', 'Building A', 'John Doe'),
('Finance', 'Building B', 'Jane Smith'),
('IT', 'Building C', 'Alice Johnson'),
('Marketing', 'Building D', 'Bob Brown');

INSERT INTO Staff (FullName, DeptID, Role, Email, HireDate) VALUES
('Michael Scott', 1, 'HR Manager', 'michael.scott@company.com', '2020-01-15'),
('Pam Beesly', 1, 'HR Assistant', 'pam.beesly@company.com', '2021-03-10'),
('Jim Halpert', 2, 'Financial Analyst', 'jim.halpert@company.com', '2019-06-20'),
('Dwight Schrute', 2, 'Accountant', 'dwight.schrute@company.com', '2018-11-05'),
('Angela Martin', 3, 'IT Specialist', 'angela.martin@company.com', '2022-02-12'),
('Kevin Malone', 3, 'System Admin', 'kevin.malone@company.com', '2017-08-25'),
('Oscar Martinez', 4, 'Marketing Manager', 'oscar.martinez@company.com', '2016-05-30'),
('Kelly Kapoor', 4, 'Marketing Assistant', 'kelly.kapoor@company.com', '2021-09-14');
```



##  TASK 2: Create and Use Database Links (FDW)

---sql code
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER branchb_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'Branch_B', port '5432');

CREATE USER MAPPING FOR CURRENT_USER
SERVER branchb_server
OPTIONS (user 'postgres', password '1234');

IMPORT FOREIGN SCHEMA public
LIMIT TO (Salary, Payroll, Leaverecord, Attendance)
FROM SERVER branchb_server
INTO public;

-- Remote queries and joins
SELECT s.FullName, s.Role, sal.BasePay, sal.Allowances
FROM Staff s
JOIN Salary sal ON s.StaffID = sal.StaffID;
```

---

##  TASK 3: Parallel Query Execution

---sql code
-- Serial execution
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO payroll_fdw (...)
SELECT ... FROM generate_series(1, 2000000);

-- Parallel execution
SET max_parallel_workers_per_gather = 2;
SET max_parallel_workers = 8;
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO payroll_fdw (...)
SELECT ... FROM generate_series(1, 2000000);




##  TASK 4: Two-Phase Commit Simulation

---sql code
BEGIN;
INSERT INTO salary_fdw(staffid, basepay, allowances, deductions)
VALUES (1, 50000, 600, 100);
PREPARE TRANSACTION 'gid_staff_salary_tx';
COMMIT PREPARED 'gid_staff_salary_tx';
SELECT * FROM pg_prepared_xacts;



## TASK 5: Distributed Rollback and Recovery

---sql code
BEGIN;
INSERT INTO Staff(...) VALUES (...);
PREPARE TRANSACTION 'fail_test';
SELECT * FROM pg_prepared_xacts;
ROLLBACK PREPARED 'fail_test';
`

To check unresolved transactions:
--- sql code
SELECT * FROM pg_prepared_xacts;



## TASK 6: Distributed Concurrency Control

---sql
BEGIN;
UPDATE staff SET role = 'Manager' WHERE staffid = 2;
-- On another session:
UPDATE staff SET role = 'Supervisor' WHERE staffid = 2;

-- Detect lock conflict
SELECT pid, relation::regclass AS table_name, mode, granted
FROM pg_locks WHERE relation::regclass = 'staff'::regclass;



##  TASK 7: Parallel Data Loading / ETL Simulation

---sql code
SET max_parallel_workers_per_gather = 8;

CREATE TABLE Payroll_Archive AS TABLE Payroll WITH NO DATA;

-- Serial insert
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO Payroll_Archive SELECT * FROM Payroll;

-- Parallel insert
SET max_parallel_workers_per_gather = 8;
EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO Payroll_Archive SELECT * FROM Payroll;


##  TASK 8: Three-Tier Client–Server Architecture

**Layers:**
1. **Presentation Layer:** Web interface or pgAdmin client  
2. **Application Layer:** Python, PHP, or middleware logic handling SQL operations  
3. **Database Layer:** PostgreSQL nodes (`BranchDB_A`, `BranchDB_B`) connected via FDW  

**Data Flow:**

User Interface → Application Logic → BranchDB_A ↔ BranchDB_B


## TASK 9: Distributed Query Optimization

---sql code
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT s.fullname, (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM staff s
JOIN public.salary_remote sal
ON s.staffid = sal.staffid;

The optimizer minimizes **data movement** by **pushing filters to remote nodes** before join execution.


## TASK 10: Performance Benchmark and Report

**Centralized Query:**
---sql
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT s.fullname, (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM staff s JOIN salary sal ON s.staffid = sal.staffid;

**Parallel Query:**
---sql code
SET max_parallel_workers_per_gather = 4;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT s.fullname, (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM staff s JOIN salary sal ON s.staffid = sal.staffid;


**Distributed Query:**
--sql code
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT s.fullname, (sal.basepay + sal.allowances - sal.deductions) AS net_pay
FROM staff s JOIN public.salary_remote sal ON s.staffid = sal.staffid;

**Analysis:**  
Compare execution time and I/O statistics (shared reads, hits).  
Parallel and distributed queries should show **lower execution time and improved scalability** compared to the centralized version.

