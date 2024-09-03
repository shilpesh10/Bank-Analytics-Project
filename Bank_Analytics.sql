create database bank_analytics;
use bank_analytics;
desc finance_1;
select * from finance_1;
desc finance_2;
select * from finance_2;

-- Data Cleaning
update finance_1
set annual_inc = replace(annual_inc, ',','');
update finance_1
set issue_d = str_to_date(issue_d, '%d-%m-%Y');

alter table finance_1
modify annual_inc int, modify issue_d date;

alter table finance_2
modify earliest_cr_line date;

update finance_2
set last_pymnt_d = null where last_pymnt_d = '';
alter table finance_2
modify last_pymnt_d date;

update finance_2
set last_credit_pull_d = null where last_credit_pull_d = '';
alter table finance_2
modify last_credit_pull_d date;

select * from finance_2 where last_credit_pull_d = '';

delete from finance_2 where last_credit_pull_d is null;

-- KPI's
-- 1) Total Loan Applications
select concat(round(count(id)/1000,2)," K") Total_Loan_Applications from finance_1;

-- 2) Total Loan Amount
select concat(round(sum(loan_amnt)/1000000,2)," M") Total_loan_amount
from finance_1;

-- 3) Total Revol Balance
select concat(round(sum(revol_bal)/1000000,2)," M") Total_Revol_Balance
from finance_2;

-- 4) Total Fund
select concat(round(sum(funded_amnt)/1000000,2)," M") Total_Fund
from finance_1;

-- 5) Average Interest Rate
select concat(round(avg(int_rate),2)," %") Average_Interest_Rate
from finance_1;

-- Visuals
-- 1) Year wise Loan Amount Status
select year(issue_d) loan_year, loan_status,
concat(round(sum(loan_amnt)/1000000,2),' M') total_loan_amount
from finance_1 
group by year(issue_d), loan_status
order by loan_year, loan_status;

-- 2) Total Payment for Verified vs Non-Verified Status
select f1.verification_status,
concat(round(sum(f2.total_pymnt)/1000000), ' M') total_payment,
concat(round((sum(f2.total_pymnt)/(select sum(fy2.total_pymnt)
from finance_2 fy2 join finance_1 fy1 on fy2.id = fy1.id
where fy1.verification_status = 'Verified' or fy1.verification_status = 'Not Verified'))*100),' %') total_payment_percent
from finance_1 f1 join finance_2 f2
on f1.id = f2.id
group by f1.verification_status
having f1.verification_status = 'Verified' or f1.verification_status = 'Not Verified';

-- 3) State and last_credit_pull_d wise Loan Status
select f1.addr_state state, year(f2.last_credit_pull_d)  year, f1.loan_status loan_status
from finance_1 f1 join finance_2 f2
on f1.id = f2.id
group by f1.addr_state, year(f2.last_credit_pull_d), f1.loan_status
order by f1.addr_state, year(f2.last_credit_pull_d), f1.loan_status;

select year(f2.last_credit_pull_d) year, count(f1.loan_status) loan_count
from finance_1 f1 join finance_2 f2
on f1.id = f2.id and year(f2.last_credit_pull_d) is not null
group by  year(f2.last_credit_pull_d)
order by  year(f2.last_credit_pull_d);

-- 4) Grade and Sub-grade wise Revol balance
select grade, sub_grade,
concat(round(sum(revol_bal)/1000000,2),' M') Total_revol_bal
from finance_1 f1 join finance_2 f2
on f1.id = f2.id
group by grade, sub_grade 
order by grade, sub_grade;

-- 5) Home Ownership vs Last Payment Date Status
SELECT home_ownership, count(last_pymnt_d) Last_Payment_Date_count
from finance_1 f1 join finance_2 f2
on f1.id = f2.id
GROUP BY home_ownership
ORDER BY count(last_pymnt_d) desc;
