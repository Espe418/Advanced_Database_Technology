CREATE TABLE Salary(
    SalaryID SERIAL PRIMARY KEY,
    StaffID INT,
    BasePay NUMERIC(10,2),
    Allowances NUMERIC(10,2),
    Deductions NUMERIC(10,2)
);

select * from salary;
select * from payroll ;
CREATE TABLE Payroll(
    PayrollID SERIAL PRIMARY KEY,
    SalaryID INT REFERENCES Salary(SalaryID),
    PeriodStart DATE,
    PeriodEnd DATE,
    NetPay NUMERIC(10,2)
);

CREATE TABLE LeaveRecord(
    LeaveID SERIAL PRIMARY KEY,
    StaffID INT,
    StartDate DATE,
    EndDate DATE,
    Type VARCHAR(50),
    Status VARCHAR(50)
);

CREATE TABLE Attendance(
    AttendanceID SERIAL PRIMARY KEY,
    StaffID INT,
    Date DATE,
    Status VARCHAR(50),
    HoursWorked NUMERIC(5,2)
);
----
INSERT INTO Salary (StaffID, BasePay, Allowances, Deductions) VALUES
(1, 5000, 500, 200),
(2, 3000, 300, 100),
(3, 4500, 450, 150),
(4, 4000, 400, 150),
(5, 3500, 350, 120),
(6, 4200, 420, 180),
(7, 4800, 480, 200),
(8, 3200, 320, 100);

ALTER TABLE salary
ADD COLUMN new_salaryid INT GENERATED ALWAYS AS IDENTITY;


INSERT INTO Payroll (SalaryID, PeriodStart, PeriodEnd, NetPay) VALUES
(1, '2025-10-01', '2025-10-15', 5300),
(2, '2025-10-01', '2025-10-15', 3200),
(3, '2025-10-01', '2025-10-15', 4800),
(4, '2025-10-01', '2025-10-15', 4250),
(5, '2025-10-01', '2025-10-15', 3730),
(6, '2025-10-01', '2025-10-15', 4440),
(7, '2025-10-01', '2025-10-15', 5080),
(8, '2025-10-01', '2025-10-15', 3420);


INSERT INTO LeaveRecord (StaffID, StartDate, EndDate, Type, Status) VALUES
(1, '2025-09-01', '2025-09-05', 'Annual', 'Approved'),
(2, '2025-09-10', '2025-09-12', 'Sick', 'Approved'),
(3, '2025-10-05', '2025-10-07', 'Annual', 'Pending'),
(4, '2025-10-01', '2025-10-02', 'Sick', 'Approved'),
(5, '2025-09-15', '2025-09-20', 'Annual', 'Approved'),
(6, '2025-10-08', '2025-10-10', 'Sick', 'Pending'),
(7, '2025-09-25', '2025-09-27', 'Annual', 'Approved'),
(8, '2025-10-03', '2025-10-04', 'Sick', 'Approved');

INSERT INTO Attendance (StaffID, Date, Status, HoursWorked) VALUES
(1, '2025-10-20', 'Present', 8),
(2, '2025-10-20', 'Present', 7.5),
(3, '2025-10-20', 'Absent', 0),
(4, '2025-10-20', 'Present', 8),
(5, '2025-10-20', 'Present', 8),
(6, '2025-10-20', 'Present', 8),
(7, '2025-10-20', 'Absent', 0),
(8, '2025-10-20', 'Present', 6);

ALTER TABLE salary ADD COLUMN new_salaryid INTEGER GENERATED ALWAYS AS IDENTITY;
ALTER TABLE payroll DROP CONSTRAINT payroll_salaryid_fkey;

ALTER TABLE salary ADD PRIMARY KEY (new_salaryid);

select * from salary;

SELECT * FROM Branch_B.salary ;


---TASK 6
SET lock_timeout = '5s';
UPDATE payroll
SET netpay = netpay + 500
WHERE salaryid = 2;

---- TASK 8

BEGIN;
INSERT INTO salary (staffid, basepay, allowances, deductions) VALUES
(999,1000,100,10);
PREPARE TRANSACTION 'tx_b';



-- to commit both
COMMIT PREPARED 'tx_a';   -- run on branch_a
COMMIT PREPARED 'tx_b';   -- run on branch_b

-- or to rollback both
ROLLBACK PREPARED 'tx_a';
ROLLBACK PREPARED 'tx_b';


ALTER TABLE salary ADD COLUMN net_pay numeric(10,2);

UPDATE salary
SET net_pay = basepay + allowances - deductions;


ALTER TABLE salary ADD COLUMN net_pay numeric(10,2);

UPDATE salary
SET net_pay = basepay + allowances - deductions;




