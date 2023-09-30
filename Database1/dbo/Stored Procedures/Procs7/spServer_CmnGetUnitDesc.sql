CREATE PROCEDURE dbo.spServer_CmnGetUnitDesc
@PU_Id int,
@PU_Desc nvarchar(50) OUTPUT
 AS
Select @PU_Desc = PU_Desc 
 	 From Prod_Units 
 	 Where (PU_Id = @PU_Id)
if @PU_Desc Is Null
  Select @PU_Desc = ''
