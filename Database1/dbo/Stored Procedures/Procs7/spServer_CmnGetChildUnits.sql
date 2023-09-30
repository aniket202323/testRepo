CREATE PROCEDURE dbo.spServer_CmnGetChildUnits
@Master_Unit int
 AS
Select PU_Id
  From Prod_Units
  Where Master_Unit = @Master_Unit
