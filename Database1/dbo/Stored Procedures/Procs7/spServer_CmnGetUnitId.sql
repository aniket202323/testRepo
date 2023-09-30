CREATE PROCEDURE dbo.spServer_CmnGetUnitId
@MasterUnit int,
@PU_Desc nvarchar(50),
@PU_Id int OUTPUT
AS
Select @PU_Id = NULL
if (@MasterUnit Is NULL) Or (@MasterUnit = 0)
  Begin
    Select @PU_Id = PU_Id
      From Prod_Units 
      Where (PU_Desc = @PU_Desc)
  End
Else
  Begin
      Select @PU_Id = PU_Id
        From Prod_Units 
        Where (PU_Desc = @PU_Desc) And 
              ((PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))
  End
If @PU_Id Is Null
  Select @PU_Id = 0
