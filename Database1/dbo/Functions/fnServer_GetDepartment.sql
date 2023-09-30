CREATE FUNCTION dbo.fnServer_GetDepartment(
@PUId int
) 
     RETURNS int
AS 
BEGIN -- Function
declare @DeptId int,
 	  	  	  	 @Master int,
 	  	  	  	 @Line int
select @DeptId = null
if (@PUid is not null)
begin
 	 select @Master = Master_unit from prod_units_Base where pu_id=@puid
 	 if (@Master is not null)
 	  	 select @PUId = @Master
 	 if (@PUId is not null) 
 	 begin
 	  	 select @Line = pl_id  from prod_units_Base where pu_id = @PUId
 	  	 select @DeptId= dept_id from prod_lines_Base where pl_Id = @Line
 	 end
end
RETURN @DeptId
END -- Function
