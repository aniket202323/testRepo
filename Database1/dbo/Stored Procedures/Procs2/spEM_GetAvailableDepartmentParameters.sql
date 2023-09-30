Create Procedure dbo.spEM_GetAvailableDepartmentParameters
@DepartmentId int
AS
    select [Key] = p.Parm_ID,[Parameter] = p.Parm_Name,[Description] = Parm_long_desc
    from Parameters p 
    Where Parm_Id in (14,15,16,17)
 	 and Parm_Id Not In (SELECT Parm_Id From Dept_Parameters where Dept_Id = @DepartmentId) 
    order by p.Parm_Name
