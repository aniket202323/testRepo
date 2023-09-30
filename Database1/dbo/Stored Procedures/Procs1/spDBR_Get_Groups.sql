Create Procedure dbo.spDBR_Get_Groups
@unit_ID int,
@group_id int
AS
 	 if(@unit_ID = 0)
 	 begin
 	  	 select PUG_ID, PUG_Desc from PU_Groups
 	 end
 	 else
 	 begin
 	  	 select PUG_ID, PUG_Desc from PU_Groups where PU_ID = @Unit_ID
 	 end
