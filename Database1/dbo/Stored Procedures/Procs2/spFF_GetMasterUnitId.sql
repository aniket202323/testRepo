Create Procedure dbo.spFF_GetMasterUnitId
@PU_Id int,
@MasterUnit int OUTPUT
AS
Select @MasterUnit = Master_Unit 
  From Prod_Units 
  Where PU_Id = @PU_Id
If @MasterUnit Is Null
  Select @MasterUnit = @PU_Id
