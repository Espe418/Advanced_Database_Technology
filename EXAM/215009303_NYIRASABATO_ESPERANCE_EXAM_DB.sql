----NYIRASABATO ESPERANCE
--REG_NO:215009303
----ADVANCED DATABASE TECHNOLOGY
---- EXAM
---- DATE: 28/10/2025


--node A 
CREATE TABLE payroll_a (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    department VARCHAR(20),
    total_pay NUMERIC CHECK(total_pay > 0)
);
---NODE B
CREATE TABLE payroll_b (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    department VARCHAR(20),
    total_pay NUMERIC CHECK(total_pay > 0)
);
----INSERT DATA INTO NODE A
INSERT INTO payroll_a VALUES
(1,'Alice','HR',2500),
(2,'Ben','IT',2100),
(3,'Clare','Finance',2800),
(4,'Dan','HR',2000),
(5,'Eva','IT',2200);
----INSERT DATA INTO NODE B
INSERT INTO payroll_b VALUES
(6,'Frank','Finance',2600),
(7,'Grace','IT',2400),
(8,'Henry','HR',2300),
(9,'Ivy','Finance',2700),
(10,'Jack','IT',2900);

-----3 CREATING DABASE LINK FROM NODE A TO NODE B
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

----
CREATE SERVER branchb_server FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'node_b', port '5432');

CREATE USER MAPPING FOR CURRENT_USER SERVER nodeb_server
OPTIONS (user 'postgres', password '1234');

IMPORT FOREIGN SCHEMA public
FROM SERVER branchb_server INTO public;

---4 CREATE OR REPLACE VIEW payroll_all AS

CREATE OR REPLACE VIEW payroll_all AS
SELECT * FROM payroll_a
UNION ALL
SELECT * FROM payroll_b;
---5Validate count and checksum
SELECT COUNT(*) AS total_rows, SUM(MOD(emp_id,97)) AS checksum FROM payroll_a;
SELECT COUNT(*) AS total_rows, SUM(MOD(emp_id,97)) AS checksum FROM payroll_b;
SELECT COUNT(*) AS total_rows, SUM(MOD(emp_id,97)) AS checksum FROM payroll_all;

---A2
--A2: Database Link & Cross-Node Join (3–10 rows result)
--NODE B
CREATE TABLE department (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(20)
);

INSERT INTO department(dept_name) VALUES
('HR'),('IT'),('Finance');

CREATE TABLE staff (
    staff_id INT PRIMARY KEY,
    staff_name VARCHAR(50),
    department VARCHAR(20)
);

INSERT INTO staff VALUES
(1,'Alice','HR'),(2,'Ben','IT'),(3,'Clare','Finance'),
(4,'Dan','HR'),(5,'Eva','IT');
---On Node_A:
SELECT p.emp_id, p.emp_name, s.staff_name, s.department
FROM payroll_a p
JOIN staff s ON p.department = s.department
LIMIT 5;
 ---A3: Parallel vs Serial Aggregation (≤10 rows)
 ---Serial aggregation:
 SELECT department, SUM(total_pay) AS dept_total
FROM payroll_all
GROUP BY department;
---Parallel aggregation:
SET max_parallel_workers_per_gather = 4;    
SELECT department, SUM(total_pay) AS dept_total
FROM payroll_all    
GROUP BY department;

---A4: Parallel vs Serial Sort (≤10 rows)
---Serial sort: 
SET max_parallel_workers_per_gather = 0;
SET max_parallel_workers_per_gather = 8;

EXPLAIN ANALYZE
SELECT department, SUM(total_pay) AS dept_total
FROM payroll_all
GROUP BY department;
---Parallel sort:
SET max_parallel_workers_per_gather = 4;   
EXPLAIN ANALYZE
SELECT department, SUM(total_pay) AS dept_total
FROM payroll_all
GROUP BY department;

---A4: Two-Phase Commit & Recovery (2 rows)
--On Node A:
BEGIN;
UPDATE payroll_a SET total_pay = total_pay + 500 WHERE emp_id = 1;
UPDATE payroll_b SET total_pay = total_pay + 500 WHERE emp_id = 6;
PREPARE TRANSACTION 'payroll_update_1';
--On Node B:
BEGIN;
UPDATE payroll_b SET total_pay = total_pay + 500 WHERE emp_id = 6;
UPDATE payroll_a SET total_pay = total_pay + 500 WHERE emp_id = 1;
PREPARE TRANSACTION 'payroll_update_1';
--To commit the transaction on both nodes:
--On Node A:
COMMIT PREPARED 'payroll_update_1';
--On Node B:
COMMIT PREPARED 'payroll_update_1';
--To rollback the transaction on both nodes:
SELECT * FROM pg_prepared_xacts;
---
COMMIT PREPARED 'txn_demo';
-- or
ROLLBACK PREPARED 'txn_demo';

---A5: Distributed Lock Conflict & Diagnosis (no extra rows)

--Session 1 (Node_A):
BEGIN;
UPDATE payroll_a SET total_pay = 9999 WHERE emp_id = 1;
-- keep session open, do not commit yet
--Session 2 (Node_B):
BEGIN;
UPDATE payroll_b SET total_pay = 8888 WHERE emp_id = 6;
-- keep session open, do not commit yet
--Session 1 (Node_A):
BEGIN;
UPDATE payroll_b SET total_pay = 7777 WHERE emp_id = 6;
-- This will block due to lock held by Session 2
--Session 2 (Node_B):
--- This will block due to lock held by Session 1
SELECT pid, locktype, relation::regclass, mode, granted
FROM pg_locks
WHERE relation::regclass::text LIKE 'payroll_a%';
SELECT pid, locktype, relation::regclass, mode, granted
FROM pg_locks
WHERE relation::regclass::text LIKE 'payroll_b%';       
--To resolve the deadlock, you can choose to rollback one of the transactions:
--Session 1 (Node_A):
ROLLBACK;
--Session 2 (Node_B):
ROLLBACK;
--Or, if you want to proceed with Session 1:
COMMIT;  -- on Session 1

---SECTION B
-----B6 : Complex Constraints & Exception Handling
-- 1. Create tables with constraints

--- -- Payroll table
CREATE TABLE Payroll(
    emp_id INT PRIMARY KEY,
    department VARCHAR(30) NOT NULL,
    total_pay NUMERIC,
    period_start DATE,
    period_end DATE
);

-- Attendance table
CREATE TABLE Attendance(
    emp_id INT NOT NULL,
    status VARCHAR(20),
    work_date DATE
);

-- Payroll_AUDIT table (for B7)
CREATE TABLE Payroll_AUDIT(
    bef_total NUMERIC,
    aft_total NUMERIC,
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    key_col TEXT
);

-- HIER table (for B8)
CREATE TABLE HIER(
    parent_id INT,
    child_id INT
);

-- TRIPLE table (for B9)
CREATE TABLE TRIPLE(
    s TEXT,
    p TEXT,
    o TEXT
);

-- BUSINESS_LIMITS table (for B10)
CREATE TABLE BUSINESS_LIMITS(
    rule_key TEXT PRIMARY KEY,
    threshold INT,
    active CHAR(1) CHECK(active IN ('Y','N'))
);
--2 Add constraints to Payroll

ALTER TABLE Payroll
  ADD CONSTRAINT chk_total_pay_positive CHECK (total_pay > 0);

ALTER TABLE Payroll
  ADD CONSTRAINT chk_period_order CHECK (period_end >= period_start);

ALTER TABLE Payroll
  ALTER COLUMN department SET NOT NULL;

-- Add constraints to Attendance
ALTER TABLE Attendance
  ADD CONSTRAINT chk_status_valid CHECK (status IN ('PRESENT','ABSENT','LEAVE'));

ALTER TABLE Attendance
  ALTER COLUMN emp_id SET NOT NULL;

-- 3 Test INSERTs using DO blocks for exception handling
DO $$
BEGIN
    -- Passing Payroll rows
    INSERT INTO Payroll(emp_id, department, total_pay, period_start, period_end)
    VALUES(1,'HR',1000,'2025-01-01','2025-01-31');
    
    INSERT INTO Payroll(emp_id, department, total_pay, period_start, period_end)
    VALUES(2,'FIN',1500,'2025-01-01','2025-01-31');

    -- Failing Payroll rows
    BEGIN
        INSERT INTO Payroll(emp_id, department, total_pay, period_start, period_end)
        VALUES(3,'IT',-500,'2025-01-01','2025-01-31');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Payroll error: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO Payroll(emp_id, department, total_pay, period_start, period_end)
        VALUES(4,'SALES',1000,'2025-02-01','2025-01-31');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Payroll error: %', SQLERRM;
    END;

    -- Passing Attendance rows
    INSERT INTO Attendance(emp_id, status, work_date)
    VALUES(1,'PRESENT','2025-01-15');
    
    INSERT INTO Attendance(emp_id, status, work_date)
    VALUES(2,'LEAVE','2025-01-16');

    -- Failing Attendance rows
    BEGIN
        INSERT INTO Attendance(emp_id, status, work_date)
        VALUES(3,'WORKING','2025-01-17');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Attendance error: %', SQLERRM;
    END;

    BEGIN
        INSERT INTO Attendance(emp_id, status, work_date)
        VALUES(NULL,'PRESENT','2025-01-18');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Attendance error: %', SQLERRM;
    END;
END $$;

-- 4 Check committed rows
SELECT * FROM Payroll;
SELECT * FROM Attendance;

---B7:Statement-Level Trigger for Denormalized Totals
-- 1. Audit table


-- 2. Trigger function
CREATE OR REPLACE FUNCTION update_payroll_totals() RETURNS trigger AS $$
DECLARE
    v_before NUMERIC;
    v_after NUMERIC;
BEGIN
    SELECT SUM(total_pay) INTO v_before FROM Payroll;

    -- Simple recompute: e.g., total_pay = 1000 for PRESENT attendance
    UPDATE Payroll p
    SET total_pay = COALESCE(
        (SELECT COUNT(*) * 1000 FROM Attendance a WHERE a.emp_id = p.emp_id AND a.status='PRESENT'), 
        total_pay
    );

    SELECT SUM(total_pay) INTO v_after FROM Payroll;

    INSERT INTO Payroll_AUDIT(bef_total, aft_total, key_col)
    VALUES(v_before, v_after, 'ALL');

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Attach trigger (statement-level)
CREATE OR REPLACE FUNCTION update_payroll_totals() RETURNS trigger AS $$
DECLARE
    v_before NUMERIC;
    v_after NUMERIC;
BEGIN
    SELECT SUM(total_pay) INTO v_before FROM Payroll;

    -- recompute totals, enforce positive
    UPDATE Payroll p
    SET total_pay = GREATEST(
        1,
        COALESCE(
            (SELECT COUNT(*) * 1000
             FROM Attendance a
             WHERE a.emp_id = p.emp_id AND a.status='PRESENT'),
            p.total_pay
        )
    );

    SELECT SUM(total_pay) INTO v_after FROM Payroll;

    INSERT INTO Payroll_AUDIT(bef_total, aft_total, key_col)
    VALUES (v_before, v_after, 'ALL');

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

----create trigger
CREATE TRIGGER trg_update_payroll_totals
AFTER INSERT OR UPDATE OR DELETE ON Attendance
FOR EACH STATEMENT
EXECUTE FUNCTION update_payroll_totals();


-- Check results
SELECT * FROM Payroll;
SELECT * FROM Payroll_AUDIT;


---B7_3-- Insert some Attendance rows
INSERT INTO Attendance(emp_id, status, work_date) VALUES (1, 'PRESENT', '2025-01-20');
INSERT INTO Attendance(emp_id, status, work_date) VALUES (2, 'ABSENT', '2025-01-21');

-- Update one row
UPDATE Attendance SET status='LEAVE' WHERE emp_id=1;

-- Delete one row
DELETE FROM Attendance WHERE emp_id=2;

-- Payroll totals should have been recomputed
SELECT * FROM Payroll;

-- Audit log
SELECT * FROM Payroll_AUDIT;

---B8-- Recursive Hierarchy Rollup
-- 1. Hierarchy table


-- 2. Insert 6–10 rows (3-level)
INSERT INTO HIER VALUES(1,2);
INSERT INTO HIER VALUES(1,3);
INSERT INTO HIER VALUES(2,4);
INSERT INTO HIER VALUES(2,5);
INSERT INTO HIER VALUES(3,6);
INSERT INTO HIER VALUES(3,7);

-- 3. Recursive query
WITH RECURSIVE rollup(child_id, root_id, depth) AS (
    SELECT child_id, parent_id, 1 FROM HIER
    UNION ALL
    SELECT r.child_id, h.parent_id, r.depth+1
    FROM rollup r
    JOIN HIER h ON r.root_id = h.child_id
)
SELECT * FROM rollup;


---B9 --- Recursive Inference over Triples
-- 1. Triple table
CREATE TABLE TRIPLE(s TEXT, p TEXT, o TEXT);

-- 2. Insert 8–10 facts
INSERT INTO TRIPLE VALUES('Payroll','isA','FinancialRecord');
INSERT INTO TRIPLE VALUES('Attendance','isA','Record');
INSERT INTO TRIPLE VALUES('FinancialRecord','isA','Record');
INSERT INTO TRIPLE VALUES('LeaveRecord','isA','Attendance');
INSERT INTO TRIPLE VALUES('Salary','isA','Payroll');
INSERT INTO TRIPLE VALUES('HR','manages','Payroll');
INSERT INTO TRIPLE VALUES('HR','manages','Attendance');
INSERT INTO TRIPLE VALUES('Manager','supervises','HR');

-- 3. Recursive inference
WITH RECURSIVE isa_chain(s,o) AS (
    SELECT s,o FROM TRIPLE WHERE p='isA'
    UNION ALL
    SELECT t.s, c.o
    FROM TRIPLE t
    JOIN isa_chain c ON t.o = c.s
    WHERE t.p='isA'
)
SELECT * FROM isa_chain;


------ B10: Business Limit Alert (Function + Trigger)
INSERT INTO BUSINESS_LIMITS VALUES('MAX_ABSENCE', 2, 'Y');

-- 2. Function
CREATE OR REPLACE FUNCTION fn_should_alert(emp INT) RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Attendance a
    JOIN BUSINESS_LIMITS b ON b.active='Y'
    WHERE a.emp_id = emp AND a.status='ABSENT';
    
    RETURN v_count >= (SELECT threshold FROM BUSINESS_LIMITS WHERE rule_key='MAX_ABSENCE');
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger function
CREATE OR REPLACE FUNCTION trg_fn_check_limit() RETURNS trigger AS $$
BEGIN
    IF fn_should_alert(NEW.emp_id) THEN
        RAISE EXCEPTION 'Business limit exceeded for emp_id %', NEW.emp_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger
CREATE TRIGGER trg_check_business_limit
BEFORE INSERT OR UPDATE ON Attendance
FOR EACH ROW
EXECUTE FUNCTION trg_fn_check_limit();

-- 5. Demo DML
-- Failing cases
DO $$
BEGIN
    INSERT INTO Attendance(emp_id,status,work_date) VALUES(1,'ABSENT','2025-01-22');
    INSERT INTO Attendance(emp_id,status,work_date) VALUES(1,'ABSENT','2025-01-23');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
END $$;


----FAILING
INSERT INTO Attendance(emp_id, status, work_date)
VALUES (2, 'ON DUTY', '2025-01-24');


INSERT INTO Attendance(emp_id, status, work_date)
VALUES (2, 'ON DUTY', '2025-01-24');

-- Passing cases
INSERT INTO Attendance(emp_id,status,work_date) VALUES(2,'PRESENT','2025-01-22');
INSERT INTO Attendance(emp_id,status,work_date) VALUES(2,'PRESENT','2025-01-23');

-- Check final table
SELECT * FROM Attendance;








