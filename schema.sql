CREATE TABLE Department(
DeptID INT PRIMARY KEY,
DeptName varchar(50) NOT NULL,
Place varchar(50) NOT NULL,
Head varchar(50)
);

CREATE TABLE Staff(
StaffID INT PRIMARY KEY,
Firstname varchar(50) NOT NULL,
Lastname varchar(50) NOT NULL,
Roles varchar(50) NOT NULL,
Email Varchar(50)  UNIQUE ,
HireDate date,
DeptID INT REFERENCES Department(DeptID)
);


CREATE TABLE Salary (
SalaryID int PRIMARY KEY,
BasePay decimal(10,2) NOT NULL ,
Allowances decimal(10,2) NOT NULL ,
Deductions decimal (10,2) NOT NULL
);
CREATE TABLE  Payroll(
PayrollID varchar(30) PRIMARY KEY ,
PeriodStart date NOT NULL ,
PeriodEnd date NOT NULL ,
NetPay decimal(10 ,2),
SalaryID  INT REFERENCES Salary(SalaryID)
);


CREATE TABLE LeaveRecord(
LeaveID INT PRIMARY KEY ,
StartDate  date  NOT NULL,
EndDate  date NOT NULL ,
Reason TEXT NOT NULL ,
Status varchar(40) NOT NULL,
staffID INT REFERENCES Staff(StaffID) ON DELETE CASCADE  ---applying  the  delete cascade function
);

CREATE TABLE Attendance(
AttendanceID  INT PRIMARY KEY ,
AttendanceDate date NOT NULL ,
Status varchar(40) NOT NULL ,
HoursWorked INT NOT NULL ,
StaffID INT REFERENCES Staff(StaffID) ON DELETE CASCADE 
);
INSERT INTO Department(DeptID, DeptName, Place, Head)
VALUES
(1, 'Finance', 'Head Office _Kigali', 'Alice Nshuti'),
(2, 'Information Technology', 'ICT Building _ Kigali', 'Eric Uwizeye'),
(3, 'Engineering', 'Tech Block _Huye', 'Marie Mukamana'),
(4, 'Economics', 'Business Center_Musanze', 'David Nkurunziza'),
(5, 'Health and Medicine', 'Medical Wing _Rwamagana', 'Dr. Sarah Uwimana');


INSERT INTO salary (SalaryID, BasePay, Allowances, Deductions)
VALUES
    (1, 3000, 500, 200),
    (2, 4500, 700, 300),
    (3, 5000, 800, 400),
    (4, 6000, 1000, 500),
    (5, 5500, 900, 450);


	INSERT INTO Staff (StaffID, DeptID, FirstName, LastName, Roles, Email, HireDate)
VALUES
(11, 01, 'John', 'Mukiza', 'Manager', 'john.mukiza@company.com', '2021-01-10'),
(2, 02, 'Mary', 'Uwase', 'Accountant', 'mary.uwase@company.com', '2021-03-15'),
(3, 01, 'David', 'Habimana', 'Assistant Manager', 'david.habimana@company.com', '2022-02-25'),
(4, 03, 'Alice', 'Iradukunda', 'HR Officer', 'alice.iradukunda@company.com', '2022-05-10'),
(5, 04, 'James', 'Niyonzima', 'IT Specialist', 'james.niyonzima@company.com', '2023-01-05'),
(6, 02, 'Grace', 'Mukamana', 'Cashier', 'grace.mukamana@company.com', '2023-03-20'),
(7, 03, 'Eric', 'Nzabakira', 'Recruiter', 'eric.nzabakira@company.com', '2023-06-12'),
(8, 05, 'Linda', 'Uwera', 'Marketing Officer', 'linda.uwera@company.com', '2023-08-09'),
(9, 04, 'Patrick', 'Mutabazi', 'System Analyst', 'patrick.mutabazi@company.com', '2024-01-12'),
(10, 01, 'Sylvia', 'Uwitonze', 'Supervisor', 'sylvia.uwitonze@company.com', '2024-06-18');

INSERT INTO Payroll (PayrollID, PeriodStart, PeriodEnd, Netpay,  SalaryID)
VALUES
(1, '2025-10-01', '2025-10-15', 7500000.00,  5),
(2, '2025-10-01', '2025-10-15', 5500000.00,  2),
(3, '2025-10-01', '2025-10-15', 680000.00,  3),
(4, '2025-10-01', '2025-10-15', 700000.00,  4),
(5, '2025-10-01', '2025-10-15', 800000.00, 1);



select* from Payroll ;
ALTER TABLE Payroll
ADD COLUMN staffid INT REFERENCES Staff(staffid);







SELECT 
    d.deptname,
    COUNT(s.staffid) AS NumEmployees,
    SUM(sa.basepay + sa.allowances) AS TotalGrossSalary,
    SUM(p.netpay) AS TotalNetPay
FROM payroll p
JOIN staff s ON p.staffid = s.staffid
JOIN department d ON s.deptid = d.deptid
JOIN salary sa ON p.salaryid = sa.salaryid
GROUP BY d.deptname
ORDER BY d.deptname;
----
INSERT INTO staff (staffid, firstname, lastname, roles, email, hiredate, deptid)
VALUES 
(1, 'John', 'Doe', 'Teller', 'john.doe@bank.com', '2022-01-10', '1');
INSERT INTO leaverecord (leaveid, startdate, enddate, reason, status, staffid)
VALUES 
(1, '2025-10-01', '2025-10-05', 'Annual Leave', 'Approved', 1);

INSERT INTO LeaveRecord (LeaveID, StartDate, EndDate, Reason, Status, StaffID)
VALUES
(2, '2025-10-15', '2025-10-17', 'Sick Leave', 'Pending', 2),
(3, '2025-10-18', '2025-10-20', 'Vacation', 'Pending', 2),
(5, '2025-10-21', '2025-10-22', 'Personal', 'Pending', 3),
(4, '2025-10-23', '2025-10-24', 'Medical', 'Pending', 4),
(7, '2025-10-25', '2025-10-26', 'Family Event', 'Pending', 5);
SELECT *FROM LeaveRecord;
---5
UPDATE LeaveRecord
SET Status = 'Approved'
WHERE StaffID = 2 AND Status = 'Pending';

----- 5
INSERT INTO Attendance (AttendanceID, StaffID, AttendanceDate, Status, HoursWorked)
VALUES
(1, 1, '2025-10-01', 'Present', 8),
(2, 1, '2025-10-02', 'Absent', 0),
(3, 1, '2025-10-03', 'Absent', 0),
(4, 2, '2025-10-01', 'Present', 8),
(5, 2, '2025-10-02', 'Present', 8),
(6, 2, '2025-10-03', 'Absent', 0),
(7, 3, '2025-10-01', 'Present', 8);

---- 6
SELECT 
    s.StaffID,
    s.FirstName || ' ' || s.LastName AS StaffName,
    COUNT(a.AttendanceID) AS AbsenceCount
FROM Attendance a
JOIN Staff s ON a.StaffID = s.StaffID
WHERE a.Status = 'Absent'
GROUP BY s.StaffID, s.FirstName, s.LastName
HAVING COUNT(a.AttendanceID) >= 2
ORDER BY AbsenceCount DESC;

-----7
CREATE OR REPLACE VIEW DepartmentPayrollSummary AS
SELECT
    d.DeptID,
    d.DeptName,
    COUNT(s.StaffID) AS NumEmployees,
    SUM(p.Netpay) AS TotalNetPay
FROM Department d
JOIN Staff s ON d.DeptID = s.DeptID
JOIN Payroll p ON s.StaffID = p.SalaryID  -- assuming SalaryID in Payroll links to StaffID
GROUP BY d.DeptID, d.DeptName
ORDER BY d.DeptName;

----8
ALTER TABLE Staff
ADD COLUMN Salary NUMERIC(12,2);

CREATE OR REPLACE FUNCTION recalc_payroll()
RETURNS TRIGGER AS $$
BEGIN
    -- Update Payroll NetPay to match the new salary
    UPDATE Payroll
    SET NetPay = NEW.Salary
    WHERE SalaryID = NEW.StaffID;
    
    RETURN NEW;
END;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';
  



