# University Staff Information and Payroll Portal

## Case Study Overview

This project implements a relational database system for managing university staff profiles, departmental assignments, salary structures, leave applications, attendance, and payroll processing. It ensures administrative visibility and compliance with institutional HR policies.

---

## Database Schema

### 1. Department
- `DeptID` (Primary Key)
- `DeptName`
- `Location`
- `Head`

### 2. Staff
- `StaffID` (Primary Key)
- `FullName`
- `DeptID` (Foreign Key → Department)
- `Role`
- `Email`
- `HireDate`

### 3. Salary
- `SalaryID` (Primary Key)
- `StaffID` (Foreign Key → Staff)
- `BasePay`
- `Allowances`
- `Deductions`

### 4. Payroll
- `PayrollID` (Primary Key)
- `SalaryID` (Foreign Key → Salary)
- `PeriodStart`
- `PeriodEnd`
- `NetPay`

### 5. LeaveRecord
- `LeaveID` (Primary Key)
- `StaffID` (Foreign Key → Staff, ON DELETE CASCADE)
- `StartDate`
- `EndDate`
- `Type`
- `Status`

### 6. Attendance
- `AttendanceID` (Primary Key)
- `StaffID` (Foreign Key → Staff, ON DELETE CASCADE)
- `Date`
- `Status`
- `HoursWorked`


##  Relationships

- **Department → Staff** (1:N)
- **Staff → Salary** (1:N)
- **Salary → Payroll** (1:N)
- **Staff → LeaveRecord** (1:N)
- **Staff → Attendance** (1:N)


## Tasks Implemented

1. **Table Creation**  
   All tables created with appropriate constraints and data types.

2. **Cascade Delete**  
   Applied `ON DELETE CASCADE` from `Staff` to `LeaveRecord` and `Attendance`.

3. **Data Insertion**  
   Inserted sample data for:
   - 5 Departments
   - 10 Staff Members

4. **Payroll Reports per Department**  
   SQL query retrieves payroll details grouped by department.

5. **Leave Status Update**  
   SQL `UPDATE` statement to change leave status when approved by HR.

6. **Repeated Absence Detection**  
   SQL query identifies staff with frequent absences.

7. **Payroll Summary View**  
   Created a view summarizing total payroll cost per department.

8. **Trigger for Payroll Recalculation**  
   Implemented a trigger to recalculate `NetPay` when salary details change.

---

## Logical ER Diagram

The system follows a normalized structure with clear 1:N relationships. Each staff member is linked to a department, salary records, leave records, and attendance logs. Payroll is derived from salary data.

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/university-payroll-system.git
   cd university-payroll-system
