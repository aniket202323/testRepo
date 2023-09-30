CREATE PROCEDURE dbo.spServer_CmnGetMasterUnits
AS
Select PU_Id From Prod_Units_Base Where (Master_Unit Is NULL) And (PU_Id <> 0)
