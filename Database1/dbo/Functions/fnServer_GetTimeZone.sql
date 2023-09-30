CREATE FUNCTION dbo.fnServer_GetTimeZone(
@PUId int
) 
     RETURNS nVarChar(255)
AS 
BEGIN -- Function
declare @DeptId int,
 	  	  	  	 @TimeZone nVarChar(255)
select @TimeZone = null
select @DeptId = dbo.fnServer_GetDepartment(@PUId)
if (@DeptId is not null)
begin
 	 select @timeZone = Time_Zone from departments where Dept_Id = @DeptId
end
RETURN @TimeZone
END -- Function
