CREATE PROCEDURE dbo.spServer_CmnGetMasterUnit
@PU_Id int,
@Master_Unit int OUTPUT
 AS
Select @Master_Unit = NULL
Select @Master_Unit = Master_Unit From Prod_Units_Base Where PU_Id = @PU_Id
If (@Master_Unit Is Null)
  Select @Master_Unit = @PU_Id
