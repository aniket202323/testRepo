CREATE PROCEDURE dbo.spRS_GetDepartments
AS
select Dept_Id, Dept_Desc from departments order by Dept_Desc
