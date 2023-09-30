CREATE PROCEDURE dbo.spCSS_GetUnitName 
@UnitID int,
@UnitDescription nvarchar(100) OUTPUT
AS
Select @UnitDescription = PU_Desc
  From Prod_Units
  Where PU_id = @UnitID
return(100)
