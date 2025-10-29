--NYIRASABATO ESPERANCE
REG_NO:215009303
--ADVANCED DATABASE TECHNOLOGY
-- ASSIGNMENT 1
-- SCHEMA CREATION AND DATA MANIPULATION
-- DATE: 20/10/2025





--Create all  6 tables with appropriate constraints and data types.
CREATE TABLE departments(
DeptID INT PRIMARY KEY,
DeptName varchar(50) NOT NULL,
Place varchar(50) NOT NULL,
Head varchar(50)
);

CREATE TABLE staffs(
StaffID INT PRIMARY KEY,
Firstname varchar(50) NOT NULL,
Lastname varchar(50) NOT NULL,
Roles varchar(50) NOT NULL,
Email Varchar(50)  UNIQUE ,
HireDate date,
DeptID INT REFERENCES departments(DeptID) 
);


CREATE TABLE salaries (
SalaryID int PRIMARY KEY,
BasePay decimal(10,2) NOT NULL ,
Allowances decimal(10,2) NOT NULL ,
Deductions decimal (10,2) NOT NULL
);
CREATE TABLE  payrolls(
PayrollID varchar(30)  PRIMARY KEY ,
PeriodStart date NOT NULL ,
PeriodEnd date NOT NULL ,
NetPay decimal(10 ,2),
SalaryID  INT REFERENCES salaries(SalaryID)
);

ALTER TABLE payrolls
DROP COLUMN PayrollID;

ALTER TABLE payrolls
ADD COLUMN PayrollID SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY;




DROP TABLE leaveRecords;
CREATE TABLE leaveRecords(
LeaveID INT PRIMARY KEY ,
StartDate  date  NOT NULL,
EndDate  date NOT NULL ,
Reason TEXT NOT NULL ,
Status varchar(40) NOT NULL,
staffID INT REFERENCES staffs(StaffID)   ON DELETE CASCADE  ---applying  the  delete cascade function
);

CREATE TABLE attendances(
AttendanceID  INT PRIMARY KEY ,
AttendanceDate date NOT NULL ,
Status varchar(40) NOT NULL ,
HoursWorked INT NOT NULL ,
StaffID INT REFERENCES staffs(StaffID) ON DELETE CASCADE ---applying  the  delete cascade function
);

-- Insert data for 5 departments   
INSERT INTO departments(DeptID, DeptName, Place, Head)
VALUES
(1, 'Finance', 'Head Office _Kigali', 'Alice Nshuti'),
(2, 'Information Technology', 'ICT Building _ Kigali', 'Eric Uwizeye'),
(3, 'Engineering', 'Tech Block _Huye', 'Marie Mukamana'),
(4, 'Economics', 'Business Center_Musanze', 'David Nkurunziza'),
(5, 'Health and Medicine', 'Medical Wing _Rwamagana', 'Dr. Sarah Uwimana');

-- Insert data for 5 salary structures.
INSERT INTO salaries(SalaryID, BasePay, Allowances, Deductions)
VALUES
    (1, 3000, 500, 200),
    (2, 4500, 700, 300),
    (3, 5000, 800, 400),
    (4, 6000, 1000, 500),
    (5, 5500, 900, 450);

-- insert 10 staff members.
	INSERT INTO staffs (StaffID, DeptID, FirstName, LastName, Roles, Email, HireDate)
VALUES
(1, 01, 'John', 'Mukiza', 'Manager', 'john.mukiza@company.com', '2021-01-10'),
(2, 02, 'Mary', 'Uwase', 'Accountant', 'mary.uwase@company.com', '2021-03-15'),
(3, 01, 'David', 'Habimana', 'Assistant Manager', 'david.habimana@company.com', '2022-02-25'),
(4, 03, 'Alice', 'Iradukunda', 'HR Officer', 'alice.iradukunda@company.com', '2022-05-10'),
(5, 04, 'James', 'Niyonzima', 'IT Specialist', 'james.niyonzima@company.com', '2023-01-05'),
(6, 02, 'Grace', 'Mukamana', 'Cashier', 'grace.mukamana@company.com', '2023-03-20'),
(7, 03, 'Eric', 'Nzabakira', 'Recruiter', 'eric.nzabakira@company.com', '2023-06-12'),
(8, 05, 'Linda', 'Uwera', 'Marketing Officer', 'linda.uwera@company.com', '2023-08-09'),
(9, 04, 'Patrick', 'Mutabazi', 'System Analyst', 'patrick.mutabazi@company.com', '2024-01-12'),
(10, 01, 'Sylvia', 'Uwitonze', 'Supervisor', 'sylvia.uwitonze@company.com', '2024-06-18');
-- Insert data for 5 payroll records.
INSERT INTO payrolls (PayrollID, PeriodStart, PeriodEnd, Netpay,  SalaryID)
VALUES
(1, '2025-10-01', '2025-10-15', 7500000.00,  1),
(2, '2025-10-01', '2025-10-15', 5500000.00,  2),
(3, '2025-10-01', '2025-10-15', 680000.00,  3),
(4, '2025-10-01', '2025-10-15', 700000.00,  4),
(5, '2025-10-01', '2025-10-15', 800000.00, 5);



select* from payrolls;            ---- 3. Write a query to retrieve the total number of employees in each department along with the
--- total gross salary (BasePay + Allowances) and total net pay for each department.
----Normalize 
ALTER TABLE payrolls
DROP COLUMN StaffID;
---Retrieve payroll reports per department. 
--- 3. Write a query to retrieve the total number of employees in each department along with the
--- total gross salary (BasePay + Allowances) and total net pay for each department.
SELECT 
  p.PayrollID,
  sal.StaffID,
  st.FullName,
  p.PeriodStart,
  p.PeriodEnd,
  p.NetPay
FROM payrolls p
JOIN salaries sal ON p.SalaryID = sal.SalaryID
JOIN staffs st ON sal.StaffID = st.StaffID;

select *from salaries ;
ALTER TABLE salaries
ADD COLUMN StaffID INT;
--- verify the changes
SELECT * FROM salaries;

-- Add the foreign key relationship (optional but recommended)
ALTER TABLE salaries;
ADD CONSTRAINT fk_salary_staff
FOREIGN KEY (StaffID) REFERENCES staffs(StaffID) ON DELETE CASCADE;
-- Example only: update with correct staff assignments
UPDATE salaries SET StaffID = 4 WHERE SalaryID = 4;
UPDATE salaries SET StaffID = 2 WHERE SalaryID = 3;
UPDATE salaries SET StaffID = 1 WHERE SalaryID = 2;
UPDATE salaries SET StaffID = 3 WHERE SalaryID = 5;
UPDATE salaries SET StaffID = 5 WHERE SalaryID = 7;

SELECT * FROM salaries ;





---- retrieving payroll per department 
SELECT 
  d.DeptName,
  st.StaffID,
  st.FirstName,
  st.LastName,
  p.PeriodStart,
  p.PeriodEnd,
  p.NetPay
FROM payrolls p
JOIN Salaries s ON p.SalaryID = s.SalaryID
JOIN staffs st ON s.StaffID = st.StaffID
JOIN departments d ON st.DeptID = d.DeptID
ORDER BY d.DeptName, st.StaffID;


----  insert a staff member for leave record testing 
INSERT INTO staffs (staffid, firstname, lastname, roles, email, hiredate, deptid)
VALUES 
(1, 'John', 'Doe', 'Teller', 'john.doe@bank.com', '2022-01-10', '1'); --- Insert a staff member for leave record testing
INSERT INTO leaverecords (leaveid, startdate, enddate, reason, status, staffid)
VALUES 
(1, '2025-10-01', '2025-10-05', 'Annual Leave', 'Approved', 4); --- Insert a leave record for the staff member

INSERT INTO leaveRecords (LeaveID, StartDate, EndDate, Reason, Status, StaffID)
VALUES
(2, '2025-10-15', '2025-10-17', 'Sick Leave', 'Pending', 2),
(3, '2025-10-18', '2025-10-20', 'Vacation', 'Pending', 5),
(5, '2025-10-21', '2025-10-22', 'Personal', 'Pending', 3),
(4, '2025-10-23', '2025-10-24', 'Medical', 'Pending', 4),
(7, '2025-10-25', '2025-10-26', 'Family Event', 'Pending', 6); --- Insert multiple leave records for testing
--- View all leave records
SELECT *FROM leaveRecords;

---- Update leave status when approved by HR.
UPDATE leaveRecords
SET Status = 'Approved'
WHERE StaffID = 4 AND Status = 'Pending';
SELECT*FROM leaveRecords;

----- 5. Insert attendance records for staff members.
INSERT INTO attendances (AttendanceID, StaffID, AttendanceDate, Status, HoursWorked)
VALUES
(1, 11, '2025-10-01', 'Present', 8),
(2, 11, '2025-10-02', 'Absent', 0),
(3, 11, '2025-10-03', 'Absent', 0),
(4, 2, '2025-10-01', 'Present', 8),
(5, 2, '2025-10-02', 'Present', 8),
(6, 2, '2025-10-03', 'Absent', 0),
(7, 3, '2025-10-01', 'Present', 8),
(8 , 4,'2025-10-01', 'Absent',0),
(9,4,'2025-10-02','Present',8),
(10,4,'2025-10-03','Absent',0);

---- 6. Write a query to find staff members with more than 2 absences in the past month or Identify staff with repeated absence in attendance records. 

SELECT StaffID, COUNT(*) AS AbsenceCount
FROM attendances
WHERE Status = 'Absent'
GROUP BY StaffID
HAVING COUNT(*) > 1;

SELECT 
    s.StaffID,
    s.FirstName || ' ' || s.LastName AS StaffName,
    COUNT(a.AttendanceID) AS AbsenceCount
FROM attendances a
JOIN Staff s ON a.StaffID = s.StaffID
WHERE a.Status = 'Absent'
GROUP BY s.StaffID, s.FirstName, s.LastName
HAVING COUNT(a.AttendanceID) >= 2
ORDER BY AbsenceCount DESC;

-----7. Create a view to summarize payroll information per department.

CREATE OR REPLACE VIEW payrollSummaryPerDepartment AS
SELECT 
  d.DeptName,
  COUNT(DISTINCT st.StaffID) AS StaffCount,
  SUM(p.NetPay) AS TotalPayroll,
  ROUND(AVG(p.NetPay), 2) AS AveragePayroll
FROM Payroll p
JOIN Salary s ON p.SalaryID = s.SalaryID
JOIN Staff st ON s.StaffID = st.StaffID
JOIN Department d ON st.DeptID = d.DeptID
GROUP BY d.DeptName
ORDER BY d.DeptName;

SELECT * FROM payrollSummaryPerDepartment;



----8. Implement a trigger to automatically update the Payroll table whenever a staff member's salary is updated.
ALTER TABLE staffs
ADD COLUMN Salary NUMERIC(12,2);
-- Create the trigger to call the function after an update on Staff table

CREATE OR REPLACE FUNCTION recalc_netpay()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE Payroll
  SET NetPay = NEW.BasePay + NEW.Allowances - NEW.Deductions
  WHERE SalaryID = NEW.SalaryID;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM payrolls ;
SELECT  * FROM attendances ;
SELECT *  FROM Staffs ;
-- create  the trigger to call the function after an update on Salary table
CREATE TRIGGER trg_recalc_netpay
AFTER UPDATE ON Salary
FOR EACH ROW
EXECUTE FUNCTION recalc_netpay();

--- Test the trigger by updating a salary record
--UPDATE salary

SELECT * FROM Salary ;
INSERT INTO Salary (SalaryID, StaffID, BasePay, Allowances, Deductions)
VALUES (3, 2, 750000, 5000, 2000);
-- Ensure PayrollID is auto-generated
ALTER TABLE payroll
ALTER COLUMN PayrollID
ADD GENERATED ALWAYS AS IDENTITY; -- Ensure PayrollID is auto-generated


-- Now insert into Payroll
 SELECT * FROM payroll ;
INSERT INTO Payroll (SalaryID, PeriodStart, PeriodEnd)
VALUES (3, '2025-10-01', '2025-10-31');
select *from salaries;



-- Check if NetPay is updated
SELECT * FROM payrolls WHERE SalaryID = 5;















