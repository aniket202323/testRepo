Create Procedure dbo.spDBR_Get_Units
@line_ID int
AS
 	 
 	 
 	 if(not @line_ID = 0)
 	 begin
 	  	 select PU_ID, PU_Desc from Prod_Units where PL_ID = @line_ID and pu_id > 0
 	 end
 	 
