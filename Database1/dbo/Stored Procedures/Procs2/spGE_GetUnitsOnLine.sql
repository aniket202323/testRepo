CREATE Procedure dbo.spGE_GetUnitsOnLine
 	  	  	 @PU_Id int
AS
Declare @PL_Id int
Select @PL_Id = PL_Id From Prod_Units Where PU_Id = @PU_Id
Select PU_Id
  From Prod_Units
  Where PL_Id = @PL_Id
